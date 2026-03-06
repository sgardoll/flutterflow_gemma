/// Single Dart façade for the AI runtime boundary.
///
/// **Rule:** Nothing else in the project should talk directly to
/// flutter_gemma or raw bridge/runtime code. This file is the only
/// place those imports appear.
///
/// Phase 0 — wraps flutter_gemma.
/// Phase 1 — same signatures, Rust-backed engine behind the scenes.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide ModelFileManager;
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_types.dart';
import 'ai_mapper.dart';
import 'model_file_manager.dart';

/// The single runtime façade for all AI operations.
///
/// Widgets and Actions call this. This calls flutter_gemma.
/// Later, this calls Rust instead.
class AiRustApi {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static final AiRustApi _instance = AiRustApi._internal();
  factory AiRustApi() => _instance;
  AiRustApi._internal();

  /// Convenience accessor.
  static AiRustApi get instance => _instance;

  // ---------------------------------------------------------------------------
  // Internal runtime handles (flutter_gemma specifics — hidden from callers)
  // ---------------------------------------------------------------------------

  FlutterGemmaPlugin get _plugin => FlutterGemmaPlugin.instance;
  final ModelFileManager _fileManager = ModelFileManager();

  InferenceModel? _model;
  InferenceChat? _chat;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  bool _isInitialized = false;
  bool _isGenerating = false;
  bool _chatSupportsVision = false;
  String? _currentModelId;
  String? _currentBackend;
  String? _currentSessionId;

  /// Message history for the active session.
  final List<AiMessageRecord> _messages = [];

  /// Accumulated tokens while generation is in flight.
  String _partialResponse = '';

  /// Monotonically increasing ID counter for messages.
  int _nextMsgId = 0;

  // ---------------------------------------------------------------------------
  // Public read-only accessors
  // ---------------------------------------------------------------------------

  AiEngineStatus get status => AiEngineStatus(
        isInitialized: _isInitialized,
        isGenerating: _isGenerating,
        currentModelId: _currentModelId,
        currentSessionId: _currentSessionId,
        currentBackend: _currentBackend,
      );

  bool get isInitialized => _isInitialized;
  bool get isGenerating => _isGenerating;
  bool get supportsVision => _chatSupportsVision;
  String? get currentSessionId => _currentSessionId;

  // ---------------------------------------------------------------------------
  // Engine lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize the engine: download model if needed, create model instance,
  /// create chat session.
  ///
  /// Returns `true` on success.
  Future<bool> initializeEngine({
    required String modelUrl,
    String? authToken,
    String? modelType,
    String backend = 'gpu',
    double temperature = 0.8,
    void Function(String status, double percentage)? onProgress,
  }) async {
    try {
      // Close any previous model cleanly
      await closeEngine();

      // Resolve URL
      String effectiveUrl = modelUrl;
      if (modelUrl.isEmpty) {
        final stored = await _getStoredModelUrl();
        if (stored != null && stored.isNotEmpty) {
          effectiveUrl = stored;
        } else {
          onProgress?.call('Model URL is missing.', 0.0);
          return false;
        }
      }

      onProgress?.call('Checking model availability...', 5.0);

      // Auto-detect model type
      final detectedModelId = (modelType != null && modelType.isNotEmpty)
          ? modelType
          : AiMapper.detectModelId(effectiveUrl);

      // --- Download / locate model file ---
      //
      // We always go through `_fileManager.downloadModelFromNetwork` which
      // already returns immediately when the file exists on disk.
      // Comparing the stored URL lets us detect when the user switched models.
      final storedUrl = await _getStoredModelUrl();
      final sameUrl = storedUrl == effectiveUrl;
      bool needsDownload = !sameUrl;

      // Quick existence check — if the same URL was stored but the file
      // was somehow deleted, we still need to re-download.
      if (!needsDownload) {
        final models = await _fileManager.getDownloadedModels();
        needsDownload = models.isEmpty;
      }

      String? filePath;
      if (needsDownload) {
        onProgress?.call('Downloading model...', 10.0);
        await _storeModelUrl(effectiveUrl);

        filePath = await _fileManager.downloadModelFromNetwork(
          effectiveUrl,
          huggingFaceToken: authToken,
          onProgress: (downloaded, total, percentage) {
            if (total > 0) {
              onProgress?.call(
                'Downloading model... ${percentage.toStringAsFixed(1)}%',
                percentage,
              );
            }
          },
        );

        if (filePath == null) {
          onProgress?.call('Model download failed.', 0.0);
          return false;
        }
      } else {
        onProgress?.call('Model found locally...', 50.0);

        // Re-download call is safe — returns existing path immediately.
        filePath = await _fileManager.downloadModelFromNetwork(
          effectiveUrl,
          huggingFaceToken: authToken,
        );
      }

      // Register the model file with the flutter_gemma plugin
      if (filePath != null) {
        await _plugin.modelManager.setModelPath(filePath);
        onProgress?.call('Registering model...', 90.0);
      }

      // --- Create model instance (with GPU → CPU fallback) ---

      final modelTypeEnum = _toModelType(detectedModelId);
      final backendEnum = _toBackend(backend);
      final potentiallyVision = AiMapper.isVisionCapable(detectedModelId);
      final maxTokens = AiMapper.maxTokensForModel(detectedModelId);

      onProgress?.call('Creating model instance...', 92.0);

      _model = await _createModelWithFallback(
        modelTypeEnum: modelTypeEnum,
        backendEnum: backendEnum,
        maxTokens: maxTokens,
        supportImage: potentiallyVision,
      );

      if (_model == null) {
        onProgress?.call('Model creation failed on all backends.', 0.0);
        return false;
      }

      // --- Create chat session (multiple fallback strategies) ---

      onProgress?.call('Creating chat session...', 95.0);

      final chatResult = await _createChatWithFallback(
        model: _model!,
        temperature: temperature,
        modelTypeEnum: modelTypeEnum,
        potentiallyVision: potentiallyVision,
      );

      _chat = chatResult.chat;
      _chatSupportsVision = chatResult.visionEnabled;

      if (_chat == null) {
        onProgress?.call('Chat session creation failed.', 0.0);
        return false;
      }

      // --- Done ---

      _isInitialized = true;
      _currentModelId = detectedModelId;
      _currentBackend = backend;

      onProgress?.call('Model ready for chat!', 100.0);
      return true;
    } catch (e) {
      debugPrint('AiRustApi.initializeEngine: $e');
      onProgress?.call(AiMapper.normalizeError(e), 0.0);
      return false;
    }
  }

  /// Close the engine — release model, chat, messages, reset state.
  Future<void> closeEngine() async {
    _isGenerating = false;
    _partialResponse = '';

    if (_chat != null) {
      _chat = null;
      _chatSupportsVision = false;
    }

    if (_model != null) {
      try {
        await _model!.close();
      } catch (_) {}
      _model = null;
    }

    _isInitialized = false;
    _currentModelId = null;
    _currentBackend = null;
    _currentSessionId = null;
    _messages.clear();
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Create a new chat session. Returns the session ID, or null on failure.
  ///
  /// This clears message history and starts fresh.
  Future<String?> createSession() async {
    if (!_isInitialized || _chat == null) return null;

    _messages.clear();
    _partialResponse = '';
    _isGenerating = false;
    _nextMsgId = 0;

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _currentSessionId = sessionId;

    return sessionId;
  }

  /// Get all messages for the current session.
  ///
  /// If generation is in flight, the list includes a partial assistant
  /// message with [AiMessageStatus.generating].
  List<AiMessageRecord> getSessionMessages() {
    final result = List<AiMessageRecord>.from(_messages);

    if (_isGenerating && _partialResponse.isNotEmpty) {
      result.add(AiMessageRecord.assistantPartial(
        id: 'partial_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentSessionId ?? '',
        text: _partialResponse,
      ));
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Message sending
  // ---------------------------------------------------------------------------

  /// Send a text message. Starts generation asynchronously.
  ///
  /// Returns `true` if the message was accepted and generation started.
  /// The caller should poll [getSessionMessages] to track progress.
  Future<bool> sendTextMessage(String text) async {
    return _sendMessage(text, imageBytes: null);
  }

  /// Send a text + image message. Starts generation asynchronously.
  Future<bool> sendImageMessage(String text, Uint8List imageBytes) async {
    return _sendMessage(text, imageBytes: imageBytes);
  }

  /// Cancel the current generation. Returns true if cancelled.
  Future<bool> cancelGeneration() async {
    if (!_isGenerating) return false;
    _isGenerating = false;

    // Commit whatever we have so far
    if (_partialResponse.isNotEmpty) {
      _messages.add(AiMessageRecord(
        id: _genMsgId(),
        sessionId: _currentSessionId ?? '',
        text: _partialResponse,
        isUser: false,
        isPartial: false,
        timestamp: DateTime.now(),
        status: AiMessageStatus.cancelled,
      ));
      _partialResponse = '';
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Model management
  // ---------------------------------------------------------------------------

  /// List locally installed models.
  Future<List<AiModelInfo>> listModels() async {
    final rawList = await _fileManager.getDownloadedModels();
    return rawList.map(AiMapper.modelInfoFromFileData).toList();
  }

  /// Install (download) a model. Returns an [AiInstallResult].
  Future<AiInstallResult> installModel(
    String url, {
    String? authToken,
    void Function(int downloaded, int total, double percentage)? onProgress,
  }) async {
    try {
      final filePath = await _fileManager.downloadModelFromNetwork(
        url,
        huggingFaceToken: authToken,
        onProgress: onProgress,
      );

      if (filePath == null) return AiInstallResult.fail('Download failed');
      return AiInstallResult.ok(filePath);
    } catch (e) {
      return AiInstallResult.fail(AiMapper.normalizeError(e));
    }
  }

  /// Delete an installed model.
  Future<bool> deleteModel(String modelPath) async {
    return _fileManager.deleteModel(modelPath);
  }

  /// Device capabilities (basic heuristic).
  AiCapabilityInfo getDeviceCapabilities() {
    if (kIsWeb) {
      return const AiCapabilityInfo(
        supportsGpu: false,
        supportsCpu: true,
        supportsTpu: false,
        recommendedBackend: 'cpu',
        platform: 'web',
      );
    }

    final isIos = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return AiCapabilityInfo(
      supportsGpu: isAndroid, // iOS uses CPU via CoreML
      supportsCpu: true,
      supportsTpu: false,
      recommendedBackend: isAndroid ? 'gpu' : 'cpu',
      platform: isIos ? 'ios' : (isAndroid ? 'android' : 'other'),
    );
  }

  // ===========================================================================
  // Private helpers — flutter_gemma specifics hidden below this line
  // ===========================================================================

  // --- message sending internals ---

  Future<bool> _sendMessage(String text, {Uint8List? imageBytes}) async {
    if (!_isInitialized || _chat == null || _isGenerating) return false;
    if (_currentSessionId == null) return false;

    // Add user message to history
    _messages.add(AiMessageRecord.userText(
      id: _genMsgId(),
      sessionId: _currentSessionId!,
      text: text,
      imageBytes: imageBytes,
    ));

    // Build the flutter_gemma Message
    Message msg;
    if (imageBytes != null && _chatSupportsVision) {
      msg = Message.withImage(
        text: text,
        imageBytes: imageBytes,
        isUser: true,
      );
    } else {
      msg = Message.text(text: text, isUser: true);
    }

    // Fire-and-forget generation
    _isGenerating = true;
    _partialResponse = '';

    // ignore: unawaited_futures
    _runGeneration(msg);

    return true;
  }

  Future<void> _runGeneration(Message msg) async {
    try {
      await _chat!.addQueryChunk(msg);

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (!_isGenerating) break; // cancelled

        if (response is TextResponse) {
          final token = response.token;
          if (token.isNotEmpty) {
            _partialResponse += token;
          }
        } else if (response is FunctionCallResponse) {
          _partialResponse = 'Function call: ${response.name}';
          break;
        }
        // ThinkingResponse — skip silently, wait for real tokens
      }

      // Commit final response
      final finalText = _partialResponse.isNotEmpty
          ? _partialResponse
          : 'I received your message but could not generate a response.';

      _messages.add(AiMessageRecord.assistantComplete(
        id: _genMsgId(),
        sessionId: _currentSessionId ?? '',
        text: finalText,
      ));
    } catch (e) {
      debugPrint('AiRustApi._runGeneration error: $e');
      _messages.add(AiMessageRecord.error(
        id: _genMsgId(),
        sessionId: _currentSessionId ?? '',
        text: AiMapper.normalizeError(e),
      ));
    } finally {
      _partialResponse = '';
      _isGenerating = false;
    }
  }

  // --- model creation with fallback ---

  Future<InferenceModel?> _createModelWithFallback({
    required ModelType modelTypeEnum,
    required PreferredBackend backendEnum,
    required int maxTokens,
    required bool supportImage,
  }) async {
    // Attempt preferred backend first
    try {
      return await _plugin.createModel(
        modelType: modelTypeEnum,
        preferredBackend: backendEnum,
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: supportImage ? 1 : 0,
      );
    } catch (gpuError) {
      debugPrint('AiRustApi: primary backend failed: $gpuError');
    }

    // CPU fallback
    if (backendEnum != PreferredBackend.cpu) {
      try {
        return await _plugin.createModel(
          modelType: modelTypeEnum,
          preferredBackend: PreferredBackend.cpu,
          maxTokens: maxTokens,
          supportImage: supportImage,
          maxNumImages: supportImage ? 1 : 0,
        );
      } catch (cpuError) {
        debugPrint('AiRustApi: CPU fallback also failed: $cpuError');
      }
    }

    return null;
  }

  // --- chat creation with fallback strategies ---

  Future<_ChatCreationResult> _createChatWithFallback({
    required InferenceModel model,
    required double temperature,
    required ModelType modelTypeEnum,
    required bool potentiallyVision,
  }) async {
    final strategies = <_ChatStrategy>[];

    // Strategy 1: text-only, full params
    strategies.add(_ChatStrategy(
      label: 'text-only full',
      vision: false,
      create: () => model.createChat(
        temperature: temperature,
        randomSeed: DateTime.now().millisecondsSinceEpoch,
        topK: 1,
        topP: 0.95,
        tokenBuffer: 256,
        supportImage: false,
        supportsFunctionCalls: false,
        tools: [],
        isThinking: false,
        modelType: modelTypeEnum,
      ),
    ));

    // Strategy 2: text-only, minimal
    strategies.add(_ChatStrategy(
      label: 'text-only minimal',
      vision: false,
      create: () => model.createChat(
        temperature: temperature,
        modelType: modelTypeEnum,
      ),
    ));

    // Strategy 3: bare minimum
    strategies.add(_ChatStrategy(
      label: 'bare minimum',
      vision: false,
      create: () => model.createChat(),
    ));

    // Vision strategies (only if model might support it)
    if (potentiallyVision) {
      strategies.add(_ChatStrategy(
        label: 'vision minimal',
        vision: true,
        create: () => model.createChat(
          temperature: temperature,
          supportImage: true,
          modelType: modelTypeEnum,
        ),
      ));

      strategies.add(_ChatStrategy(
        label: 'vision full',
        vision: true,
        create: () => model.createChat(
          temperature: temperature,
          randomSeed: DateTime.now().millisecondsSinceEpoch,
          topK: 1,
          topP: 0.95,
          tokenBuffer: 256,
          supportImage: true,
          supportsFunctionCalls: false,
          tools: [],
          isThinking: false,
          modelType: modelTypeEnum,
        ),
      ));
    }

    for (final strategy in strategies) {
      try {
        final chat = await strategy.create();
        debugPrint('AiRustApi: chat created with strategy "${strategy.label}"');
        return _ChatCreationResult(chat: chat, visionEnabled: strategy.vision);
      } catch (e) {
        debugPrint('AiRustApi: strategy "${strategy.label}" failed: $e');
      }
    }

    return const _ChatCreationResult(chat: null, visionEnabled: false);
  }

  // --- enum converters (flutter_gemma-specific, hidden) ---

  static ModelType _toModelType(String modelId) {
    final n = modelId.toLowerCase();
    if (n.contains('gemma')) return ModelType.gemmaIt;
    if (n.contains('deepseek') || n.contains('deep-seek')) {
      return ModelType.deepSeek;
    }
    return ModelType.gemmaIt;
  }

  static PreferredBackend _toBackend(String backend) {
    switch (backend.toLowerCase()) {
      case 'cpu':
        return PreferredBackend.cpu;
      case 'gpufloat16':
      case 'gpu_float16':
      case 'gpu-float16':
        return PreferredBackend.gpuFloat16;
      case 'gpumixed':
      case 'gpu_mixed':
      case 'gpu-mixed':
        return PreferredBackend.gpuMixed;
      case 'gpufull':
      case 'gpu_full':
      case 'gpu-full':
        return PreferredBackend.gpuFull;
      case 'tpu':
        return PreferredBackend.tpu;
      default:
        return PreferredBackend.gpu;
    }
  }

  // --- URL persistence ---

  Future<void> _storeModelUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_model_url', url);
    } catch (_) {}
  }

  Future<String?> _getStoredModelUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_model_url');
    } catch (_) {
      return null;
    }
  }

  // --- ID generation ---

  String _genMsgId() => 'msg_${_nextMsgId++}';
}

// ---------------------------------------------------------------------------
// Private helper types
// ---------------------------------------------------------------------------

class _ChatStrategy {
  final String label;
  final bool vision;
  final Future<InferenceChat> Function() create;
  const _ChatStrategy({
    required this.label,
    required this.vision,
    required this.create,
  });
}

class _ChatCreationResult {
  final InferenceChat? chat;
  final bool visionEnabled;
  const _ChatCreationResult({required this.chat, required this.visionEnabled});
}
