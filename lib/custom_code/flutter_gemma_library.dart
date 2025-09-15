/// Main entry point for the FlutterGemma library
///
/// This library provides on-device AI capabilities using Google's Gemma models
/// for FlutterFlow applications. It supports both text and vision models with
/// easy integration through custom actions and widgets.
///
/// ## Usage in FlutterFlow:
/// 1. Set up Library Values for your model download URLs
/// 2. Use custom actions to download, set, initialize, and interact with models
/// 3. Integrate the chat widget for user interactions
///
/// ## Required imports in your FlutterFlow actions:
/// ```dart
/// import '/custom_code/flutter_gemma_library.dart';
///
/// // Access the plugin instance
/// final gemma = FlutterGemmaLibrary.instance;
/// final modelManager = gemma.modelManager;
/// ```

import 'package:flutter_gemma/flutter_gemma.dart' hide ModelFileManager;
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'model_file_manager.dart';

/// Main FlutterGemma library class providing a clean API for FlutterFlow integration
class FlutterGemmaLibrary {
  static final FlutterGemmaLibrary _instance = FlutterGemmaLibrary._internal();
  factory FlutterGemmaLibrary() => _instance;
  FlutterGemmaLibrary._internal();

  /// Singleton instance access
  static FlutterGemmaLibrary get instance => _instance;

  /// Access to the underlying flutter_gemma plugin
  FlutterGemmaPlugin get plugin => FlutterGemmaPlugin.instance;

  /// Model file management interface
  late final ModelFileManager _modelManager = ModelFileManager();
  ModelFileManager get modelManager => _modelManager;

  // Model and session management
  InferenceModel? _model;
  InferenceModelSession? _session;
  InferenceChat? _chat;

  // Current model state
  bool _isInitialized = false;
  String? _currentModelType;
  String? _currentBackend;

  /// Check if a model is currently initialized
  bool get isInitialized => _isInitialized;

  /// Get the current model type (if any)
  String? get currentModelType => _currentModelType;

  /// Get the current backend (if any)
  String? get currentBackend => _currentBackend;

  /// Check if there's an active session
  bool get hasSession => _session != null || _chat != null;

  /// Check if the current model supports vision
  /// Only specific Gemma models support vision - not all of them
  bool get supportsVision => _chatSupportsVision;

  /// Internal flag to track if chat was created with vision support
  bool _chatSupportsVision = false;

  /// Initialize a model and chat with the complete workflow
  ///
  /// This method handles the complete initialization process:
  /// 1. Downloads model if needed
  /// 2. Creates model instance
  /// 3. Creates chat session
  /// 4. Updates internal state AND FFAppState (single source of truth)
  ///
  /// [modelUrl] - The URL to download the model from
  /// [authToken] - Optional authentication token for HuggingFace
  /// [modelType] - Optional model type override
  /// [backend] - Preferred backend ('gpu', 'cpu') - defaults to 'gpu'
  /// [temperature] - Generation temperature - defaults to 0.8
  /// [onProgress] - Optional callback to update progress/status
  /// [appState] - FFAppState instance to update (single source of truth)
  Future<bool> initializeModelComplete({
    required String modelUrl,
    String? authToken,
    String? modelType,
    String backend = 'gpu',
    double temperature = 0.8,
    Function(String status, double percentage)? onProgress,
    dynamic appState,
  }) async {
    try {
      // Close any existing model
      await closeModel();

      print('FlutterGemmaLibrary: Starting complete model initialization');

      // Use stored URL if incoming URL is empty
      String effectiveModelUrl = modelUrl;
      if (modelUrl.isEmpty) {
        final storedUrl = await _getCurrentModelUrl();
        if (storedUrl != null && storedUrl.isNotEmpty) {
          print(
            'FlutterGemmaLibrary: modelUrl is empty, using stored URL: $storedUrl',
          );
          effectiveModelUrl = storedUrl;
        } else {
          print(
            'FlutterGemmaLibrary: Error: modelUrl is empty and no stored URL found.',
          );
          onProgress?.call('Model URL is missing.', 0.0);
          return false;
        }
      }

      print('FlutterGemmaLibrary: URL: $effectiveModelUrl');
      print(
        'FlutterGemmaLibrary: Backend: $backend, Temperature: $temperature',
      );

      onProgress?.call('Initializing...', 0.0);

      // Auto-detect model type if not provided
      String finalModelType;
      if (modelType != null && modelType.isNotEmpty) {
        finalModelType = modelType;
        print(
            'FlutterGemmaLibrary: Using provided model type: $finalModelType');
      } else {
        finalModelType = ModelUtils.getModelTypeFromPath(effectiveModelUrl);
        print('FlutterGemmaLibrary: Auto-detected model type: $finalModelType');
      }

      onProgress?.call('Checking model availability...', 5.0);

      // Check if model is already loaded AND is from the same URL
      final modelManager = plugin.modelManager;

      try {
        final isInstalled = await modelManager.isModelInstalled;
        final storedUrl = await _getCurrentModelUrl();
        final isSameUrl = storedUrl == effectiveModelUrl;

        print('FlutterGemmaLibrary: Model installed: $isInstalled');
        print('FlutterGemmaLibrary: Same URL: $isSameUrl');

        if (!isInstalled || !isSameUrl) {
          print('FlutterGemmaLibrary: Downloading model...');
          onProgress?.call('Loading model (this may take a while)...', 10.0);

          // Store the new URL before downloading
          await _storeCurrentModelUrl(effectiveModelUrl);

          // Download model using the custom file manager (which handles path setting)
          final filePath = await _modelManager.downloadModelFromNetwork(
            effectiveModelUrl,
            huggingFaceToken: authToken,
            onProgress: (downloaded, total, percentage) {
              if (total > 0) {
                final progressPercent = (downloaded / total) * 100;
                print(
                    'FlutterGemmaLibrary: Download progress: $progressPercent%');
                onProgress?.call(
                  'Downloading model... ${progressPercent.toStringAsFixed(1)}%',
                  progressPercent,
                );
              }
            },
          );

          if (filePath == null) {
            throw Exception('Model download failed');
          }

          print(
              'FlutterGemmaLibrary: Model downloaded successfully to: $filePath');

          // Set the model path for the plugin
          await modelManager.setModelPath(filePath);
          print('FlutterGemmaLibrary: Model path set to: $filePath');

          onProgress?.call('Registering model...', 90.0);
        } else {
          print(
            'FlutterGemmaLibrary: Model already installed, skipping download',
          );
          onProgress?.call('Model found, registering...', 50.0);
        }
      } catch (loadError) {
        print('FlutterGemmaLibrary: Error during model loading: $loadError');
        onProgress?.call('Model loading failed: ${loadError.toString()}', 0.0);
        return false;
      }

      // Determine model parameters
      final modelTypeEnum = ModelUtils.getModelType(finalModelType);
      final backendEnum = ModelUtils.getBackend(backend);
      final potentiallySupportsVision = ModelUtils.isMultimodalModel(
        finalModelType,
      );

      // Determine appropriate max tokens based on model size
      final maxTokens = _getMaxTokensForModel(finalModelType);

      print('FlutterGemmaLibrary: Using model type: $modelTypeEnum');
      print('FlutterGemmaLibrary: Using backend: $backendEnum');
      print(
          'FlutterGemmaLibrary: Final model type for vision check: $finalModelType');
      print('FlutterGemmaLibrary: Max tokens: $maxTokens');
      print(
        'FlutterGemmaLibrary: Potentially supports vision: $potentiallySupportsVision',
      );

      onProgress?.call('Creating model instance...', 92.0);

      // Create model instance with fallback logic
      try {
        print('FlutterGemmaLibrary: Creating model with GPU backend');
        _model = await plugin.createModel(
          modelType: modelTypeEnum,
          preferredBackend: backendEnum,
          maxTokens: maxTokens,
          supportImage: potentiallySupportsVision, // Enable vision support
          maxNumImages: potentiallySupportsVision
              ? 1
              : 0, // Set max images for vision models
        );
      } catch (gpuError) {
        print('FlutterGemmaLibrary: GPU model creation failed: $gpuError');

        // Try CPU fallback
        try {
          print('FlutterGemmaLibrary: Trying CPU fallback');
          _model = await plugin.createModel(
            modelType: modelTypeEnum,
            preferredBackend: ModelUtils.getBackend('cpu'),
            maxTokens: maxTokens,
            supportImage: potentiallySupportsVision, // Enable vision support
            maxNumImages: potentiallySupportsVision
                ? 1
                : 0, // Set max images for vision models
          );
        } catch (cpuError) {
          print(
            'FlutterGemmaLibrary: CPU model creation also failed: $cpuError',
          );
          onProgress?.call(
            'Model creation failed on both GPU and CPU: ${cpuError.toString()}',
            0.0,
          );
          return false;
        }
      }

      onProgress?.call('Creating chat session...', 95.0);

      // Create chat session with improved vision support detection
      bool actualSupportsVision = false;

      // First, try to create chat based on detected model capabilities
      if (potentiallySupportsVision) {
        print(
          'FlutterGemmaLibrary: Model potentially supports vision, attempting vision chat',
        );

        // Try different approaches for vision support
        final visionApproaches = [
          // Approach 1: Standard vision chat with all parameters
          () async {
            return await _model!.createChat(
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
            );
          },
          // Approach 2: Simplified vision chat (some models might not support all parameters)
          () async {
            return await _model!.createChat(
              temperature: temperature,
              supportImage: true,
              modelType: modelTypeEnum,
            );
          },
        ];

        bool visionChatCreated = false;
        for (int i = 0;
            i < visionApproaches.length && !visionChatCreated;
            i++) {
          try {
            print('FlutterGemmaLibrary: Trying vision approach ${i + 1}');
            _chat = await visionApproaches[i]();
            actualSupportsVision = true;
            _chatSupportsVision = true; // Track that chat supports vision
            visionChatCreated = true;
            print(
              'FlutterGemmaLibrary: Vision chat created successfully with approach ${i + 1}',
            );
          } catch (visionError) {
            print(
              'FlutterGemmaLibrary: Vision approach ${i + 1} failed: $visionError',
            );
          }
        }

        // If vision chat failed, fall back to text-only
        if (!visionChatCreated) {
          print(
            'FlutterGemmaLibrary: All vision approaches failed, falling back to text-only',
          );
          try {
            _chat = await _model!.createChat(
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
            );
            actualSupportsVision = false;
            _chatSupportsVision = false; // Track that chat is text-only
            print('FlutterGemmaLibrary: Text-only chat created successfully');
          } catch (fallbackError) {
            print(
              'FlutterGemmaLibrary: Text-only chat creation also failed: $fallbackError',
            );
            return false;
          }
        }
      } else {
        // Create text-only chat directly for non-vision models
        print(
          'FlutterGemmaLibrary: Model does not support vision, creating text-only chat',
        );
        try {
          _chat = await _model!.createChat(
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
          );
          actualSupportsVision = false;
          print('FlutterGemmaLibrary: Text-only chat created successfully');
        } catch (chatError) {
          print('FlutterGemmaLibrary: Chat creation failed: $chatError');
          return false;
        }
      }

      // Update internal state
      _isInitialized = true;
      _currentModelType = finalModelType;
      _currentBackend = backend;

      // CRITICAL: Update FFAppState to maintain single source of truth
      if (appState != null) {
        appState.isModelInitialized = true;
        appState.modelSupportsVision = actualSupportsVision;
        print(
          'FlutterGemmaLibrary: Updated FFAppState - isModelInitialized: true, modelSupportsVision: $actualSupportsVision',
        );
      }

      onProgress?.call('Model ready for chat!', 100.0);

      print('FlutterGemmaLibrary: Complete initialization successful');
      print('FlutterGemmaLibrary: Model type: $finalModelType');
      print(
        'FlutterGemmaLibrary: Actual vision support: $actualSupportsVision',
      );
      print('FlutterGemmaLibrary: Backend: $backend');

      return true;
    } catch (e) {
      print('FlutterGemmaLibrary: Error in complete initialization: $e');
      return false;
    }
  }

  /// Initialize a model with the specified parameters (legacy method)
  ///
  /// [modelType] - The model identifier (derived from filename if not provided)
  /// [backend] - Preferred backend ('gpu', 'cpu', 'tpu')
  /// [maxTokens] - Maximum tokens to generate
  /// [supportImage] - Enable image support for multimodal models
  /// [maxNumImages] - Maximum number of images to support
  /// [modelFileName] - The model file to use (should be in documents directory)
  Future<bool> initializeModel({
    required String modelType,
    String backend = 'gpu',
    int maxTokens = 1024,
    bool? supportImage,
    int maxNumImages = 1,
    String? modelFileName,
  }) async {
    try {
      // Close any existing model
      await closeModel();

      // Determine if model supports vision
      final actualSupportImage =
          (supportImage ?? ModelUtils.isMultimodalModel(modelType)) &&
              ModelUtils.isMultimodalModel(modelType);

      print(
        'FlutterGemmaLibrary: Initializing model=$modelType, backend=$backend, vision=$actualSupportImage',
      );

      // Check if model file exists if specified
      if (modelFileName != null) {
        final fileExists = await _checkModelFileExists(modelFileName);
        if (!fileExists) {
          print('FlutterGemmaLibrary: Model file not found: $modelFileName');
          return false;
        }
      }

      // Create the model with additional error handling
      try {
        _model = await plugin.createModel(
          modelType: ModelUtils.getModelType(modelType),
          preferredBackend: ModelUtils.getBackend(backend),
          maxTokens: maxTokens,
          supportImage: actualSupportImage,
          maxNumImages: maxNumImages,
        );
      } catch (modelCreationError) {
        print(
          'FlutterGemmaLibrary: Model creation failed: $modelCreationError',
        );
        // Rethrow to be handled by the outer catch block
        throw modelCreationError;
      }

      _isInitialized = true;
      _currentModelType = modelType;
      _currentBackend = backend;

      print('FlutterGemmaLibrary: Model initialized successfully');
      return true;
    } catch (e) {
      print('FlutterGemmaLibrary: Error initializing model: $e');

      // Provide specific error analysis
      final errorString = e.toString();
      if (errorString.contains('RET_CHECK failure')) {
        print(
          'FlutterGemmaLibrary: TensorFlow Lite model loading error detected',
        );
        print(
          'FlutterGemmaLibrary: This usually indicates a model type/file mismatch',
        );
        print('FlutterGemmaLibrary: Model type: $modelType, Backend: $backend');
      }

      // Try CPU fallback for common issues
      if (_shouldTryCpuFallback(e, backend)) {
        print('FlutterGemmaLibrary: Attempting CPU fallback...');
        return await initializeModel(
          modelType: modelType,
          backend: 'cpu',
          maxTokens: maxTokens,
          supportImage: Platform.isIOS ? false : supportImage,
          maxNumImages: maxNumImages,
          modelFileName: modelFileName,
        );
      }

      print('FlutterGemmaLibrary: All initialization attempts failed');
      return false;
    }
  }

  /// Create a new inference session
  ///
  /// [temperature] - Randomness in generation (0.0 to 1.0)
  /// [randomSeed] - Seed for reproducible results
  /// [topK] - Top-K sampling parameter
  Future<bool> createSession({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isInitialized || _model == null) {
      print('FlutterGemmaLibrary: Model not initialized or is null');
      return false;
    }

    try {
      // Close existing session if any
      if (_session != null) {
        await _session!.close();
        _session = null;
      }

      // Additional validation before creating session
      print(
        'FlutterGemmaLibrary: Creating session with model: $_currentModelType, backend: $_currentBackend',
      );

      // Check if we're on web platform and handle differently if needed
      if (kIsWeb) {
        print(
          'FlutterGemmaLibrary: Web platform detected, attempting session creation',
        );
        try {
          _session = await _model!.createSession(
            temperature: temperature,
            randomSeed: randomSeed,
            topK: topK,
          );
        } catch (webError) {
          print('FlutterGemmaLibrary: Web session creation failed: $webError');
          // On web, sometimes we can still use the model without a session
          // Mark as successful but with no session
          print(
            'FlutterGemmaLibrary: Continuing without session for web platform',
          );
          return true;
        }
      } else {
        // Native platform session creation
        _session = await _model!.createSession(
          temperature: temperature,
          randomSeed: randomSeed,
          topK: topK,
        );
      }

      print('FlutterGemmaLibrary: Session created successfully');
      return true;
    } catch (e) {
      print('FlutterGemmaLibrary: Error creating session: $e');

      // For web platform, allow graceful degradation
      if (kIsWeb) {
        print('FlutterGemmaLibrary: Web platform - continuing without session');
        return true;
      }

      return false;
    }
  }

  /// Send a message to the model and get a response
  ///
  /// [message] - The text message to send
  /// [imageBytes] - Optional image data for multimodal models
  Future<String?> sendMessage(String message, {Uint8List? imageBytes}) async {
    // Use new chat API if available
    if (_chat != null) {
      try {
        print('FlutterGemmaLibrary: Sending message using chat API');

        // Create the appropriate message type
        Message msg;
        if (imageBytes != null && _chatSupportsVision) {
          print('FlutterGemmaLibrary: Sending message with image');
          print('FlutterGemmaLibrary: Image size: ${imageBytes.length} bytes');
          print(
            'FlutterGemmaLibrary: Chat supports vision: $_chatSupportsVision',
          );
          msg = Message.withImage(
            text: message,
            imageBytes: imageBytes,
            isUser: true,
          );
          print('FlutterGemmaLibrary: Created Message.withImage successfully');
          print('FlutterGemmaLibrary: Message text: ${msg.text}');
          print(
            'FlutterGemmaLibrary: Message has image: ${msg.imageBytes != null}',
          );
          print(
            'FlutterGemmaLibrary: Message image size: ${msg.imageBytes?.length ?? 0}',
          );
        } else {
          if (imageBytes != null && !_chatSupportsVision) {
            print(
              'FlutterGemmaLibrary: Chat does not support images (_chatSupportsVision=$_chatSupportsVision), sending text only',
            );
          }
          msg = Message.text(text: message, isUser: true);
        }

        // Add the message to chat context
        print('FlutterGemmaLibrary: Adding message to chat context...');
        await _chat!.addQueryChunk(msg);
        print('FlutterGemmaLibrary: Message added to chat successfully');

        // Generate response using streaming for better image processing
        print('FlutterGemmaLibrary: Generating response...');

        // Use streaming response for better image processing (Context7 approach)
        String fullResponse = '';
        bool hasResponse = false;

        await for (final response in _chat!.generateChatResponseAsync()) {
          hasResponse = true;

          if (response is TextResponse) {
            final token = response.token;
            print('FlutterGemmaLibrary: Received token: "$token"');

            if (token.isNotEmpty) {
              fullResponse += token;
            }
          } else if (response is FunctionCallResponse) {
            print(
                'FlutterGemmaLibrary: Model wants to call function: ${response.name} with args: ${response.args}');
            fullResponse = 'Function call requested: ${response.name}';
            break; // Function calls are complete responses
          } else if (response is ThinkingResponse) {
            print('FlutterGemmaLibrary: Model thinking: ${response.content}');
            // Continue to get the final response after thinking
          } else {
            print(
                'FlutterGemmaLibrary: Unknown response type: ${response.runtimeType}');
          }
        }

        print('FlutterGemmaLibrary: Full response: "$fullResponse"');

        // Return the accumulated response or a fallback
        if (fullResponse.isNotEmpty) {
          return fullResponse;
        } else if (hasResponse) {
          return 'I received your message but could not generate a proper response. Please try again.';
        } else {
          return 'Hello! How can I help you today?';
        }
      } catch (e) {
        print('FlutterGemmaLibrary: Error sending message via chat: $e');
        return null;
      }
    }

    // Fallback to session-based approach
    if (_session == null) {
      if (kIsWeb && _model != null) {
        print(
          'FlutterGemmaLibrary: No session on web, attempting direct model inference',
        );
        // For web, try to create a temporary session for this message
        try {
          final tempSession = await _model!.createSession(
            temperature: 0.8,
            randomSeed: DateTime.now().millisecondsSinceEpoch,
            topK: 1,
          );

          Message msg;
          if (imageBytes != null && _chatSupportsVision) {
            msg = Message.withImage(
              text: message,
              imageBytes: imageBytes,
              isUser: true,
            );
          } else {
            msg = Message.text(text: message, isUser: true);
          }

          await tempSession.addQueryChunk(msg);
          final response = await tempSession.getResponse();
          await tempSession.close(); // Clean up temp session

          return response;
        } catch (e) {
          print('FlutterGemmaLibrary: Web direct inference failed: $e');
          return 'Sorry, I encountered an error processing your message on the web platform.';
        }
      }

      print('FlutterGemmaLibrary: No session or chat available');
      return null;
    }

    try {
      Message msg;

      // Use image if provided and model supports it
      if (imageBytes != null && supportsVision) {
        msg = Message.withImage(
          text: message,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        if (imageBytes != null && !supportsVision) {
          print(
            'FlutterGemmaLibrary: Model does not support images, sending text only',
          );
        }
        msg = Message.text(text: message, isUser: true);
      }

      await _session!.addQueryChunk(msg);
      final response = await _session!.getResponse();

      return response;
    } catch (e) {
      print('FlutterGemmaLibrary: Error sending message: $e');
      return null;
    }
  }

  /// Close the current session
  Future<void> closeSession() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
    }
  }

  /// Close the current chat
  Future<void> closeChat() async {
    if (_chat != null) {
      // Note: Need to verify if InferenceChat has a close method in flutter_gemma 0.10.5
      // For now, just set to null to release the reference
      _chat = null;
      _chatSupportsVision = false;
    }
  }

  /// Store initialized model and chat resources
  void storeInitializedResources(
    InferenceModel model,
    InferenceChat chat,
    String modelType,
    String backend,
    bool supportsVision,
  ) {
    _model = model;
    _chat = chat;
    _isInitialized = true;
    _currentModelType = modelType;
    _currentBackend = backend;
    _chatSupportsVision = supportsVision;

    print('FlutterGemmaLibrary: Stored initialized resources');
    print('FlutterGemmaLibrary: Model type: $modelType');
    print('FlutterGemmaLibrary: Backend: $backend');
    print('FlutterGemmaLibrary: Supports vision: $supportsVision');
  }

  /// Close the model and cleanup resources
  Future<void> closeModel() async {
    await closeSession();
    await closeChat();

    if (_model != null) {
      await _model!.close();
      _model = null;
    }

    _isInitialized = false;
    _currentModelType = null;
    _currentBackend = null;
  }

  /// Check if model file exists (platform-specific)
  Future<bool> _checkModelFileExists(String fileName) async {
    try {
      if (kIsWeb) {
        return await _checkWebModelExists(fileName);
      } else {
        return await _checkNativeModelExists(fileName);
      }
    } catch (e) {
      print('FlutterGemmaLibrary: Error checking model file: $e');
      return false;
    }
  }

  /// Check if model exists on native platforms
  Future<bool> _checkNativeModelExists(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = path.join(directory.path, fileName);
    final exists = await File(modelPath).exists();

    if (exists) {
      final size = await File(modelPath).length();
      print(
        'FlutterGemmaLibrary: Model file exists: $fileName (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)',
      );
    }

    return exists;
  }

  /// Check if model exists on web platform
  Future<bool> _checkWebModelExists(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final modelUrl = prefs.getString('model_$fileName');
    final exists = modelUrl != null && modelUrl.isNotEmpty;

    if (exists) {
      final size = prefs.getInt('model_${fileName}_size') ?? 0;
      print(
        'FlutterGemmaLibrary: Web model registered: $fileName (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)',
      );
      print('FlutterGemmaLibrary: Model URL: $modelUrl');
    }

    return exists;
  }

  /// Determine if we should try CPU fallback for the given error
  bool _shouldTryCpuFallback(dynamic error, String currentBackend) {
    if (currentBackend == 'cpu') return false; // Already using CPU

    final errorString = error.toString().toLowerCase();
    return errorString.contains('gpu') ||
        errorString.contains('delegate') ||
        errorString.contains('ret_check failure') ||
        errorString.contains('metal');
  }

  /// Store the current model URL for tracking
  Future<void> _storeCurrentModelUrl(String modelUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_model_url', modelUrl);
      print('FlutterGemmaLibrary: Stored URL: $modelUrl');
    } catch (e) {
      print('FlutterGemmaLibrary: Error storing URL: $e');
    }
  }

  /// Get the currently stored model URL
  Future<String?> _getCurrentModelUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_model_url');
    } catch (e) {
      print('FlutterGemmaLibrary: Error retrieving URL: $e');
      return null;
    }
  }

  /// Determine appropriate max tokens based on model size
  int _getMaxTokensForModel(String modelType) {
    final normalizedType = modelType.toLowerCase().trim();

    // Smaller models have lower token limits
    if (normalizedType.contains('1b') || normalizedType.contains('1-b')) {
      return 2048; // 1B models typically support 2048 tokens
    } else if (normalizedType.contains('2b') ||
        normalizedType.contains('2-b')) {
      return 4096; // 2B models typically support 4096 tokens
    } else if (normalizedType.contains('7b') ||
        normalizedType.contains('7-b')) {
      return 8192; // 7B models typically support 8192 tokens
    } else if (normalizedType.contains('13b') ||
        normalizedType.contains('13-b')) {
      return 16384; // 13B models typically support 16384 tokens
    } else {
      return 4096; // Default fallback
    }
  }
}

/// Utility class for model-related helper functions
class ModelUtils {
  /// Determine if a model supports multimodal (vision) capabilities
  /// Only specific Gemma models support vision - not all of them
  static bool isMultimodalModel(String modelType) {
    final normalizedType = modelType.toLowerCase().trim().replaceAll(
          RegExp(r'[-_\s]+'),
          '-',
        );

    print('ModelUtils: Checking vision support for model type: "$modelType"');
    print('ModelUtils: Normalized type: "$normalizedType"');

    // Only specific Gemma models support vision
    final visionCapableModels = [
      'gemma-3n-e2b-it', // Gemma 3N E2B IT supports vision
      'gemma-3n-e4b-it', // Gemma 3N E4B IT supports vision
      'gemma-2b-it', // Some Gemma 2B models support vision
      'gemma-7b-it', // Some Gemma 7B models support vision
    ];

    // Check if this is a vision-capable model
    for (final visionModel in visionCapableModels) {
      if (normalizedType.contains(visionModel)) {
        print('ModelUtils: Found vision-capable model: $visionModel');
        return true;
      }
    }

    // Check for explicit vision indicators (with word boundaries to avoid false matches)
    final visionIndicators = [
      'vision',
      'multimodal',
      'multi-modal',
      'vl', // vision-language
      'image',
    ];

    for (final indicator in visionIndicators) {
      if (normalizedType.contains(indicator)) {
        print('ModelUtils: Found vision indicator: $indicator');
        return true;
      }
    }

    // Check for 'mm' as a standalone indicator (not part of 'gemma')
    if (normalizedType.contains('mm') && !normalizedType.contains('gemma')) {
      print('ModelUtils: Found vision indicator: mm (standalone)');
      return true;
    }

    print('ModelUtils: No vision support detected for: $normalizedType');
    return false;
  }

  /// Convert string to ModelType enum
  static ModelType getModelType(String modelType) {
    final normalized = modelType.toLowerCase().replaceAll('_', '-');

    // All Gemma models (including Gemma3) use gemmaIt type
    if (normalized.contains('gemma')) {
      return ModelType.gemmaIt;
    }

    // Handle other model types
    switch (normalized) {
      case 'deepseek':
      case 'deep-seek':
        return ModelType.deepSeek;
      case 'general':
        return ModelType.general;
      default:
        return ModelType.gemmaIt;
    }
  }

  /// Convert string to PreferredBackend enum
  static PreferredBackend getBackend(String backend) {
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
      case 'unknown':
        return PreferredBackend.unknown;
      default:
        return PreferredBackend.gpu;
    }
  }

  /// Derive model type from file path
  static String getModelTypeFromPath(String filePath) {
    try {
      final fileName = path.basenameWithoutExtension(filePath);

      // Normalize the filename for consistent processing
      String normalized = fileName
          .toLowerCase() // Handle case variations (E2B -> e2b)
          .trim()
          .replaceAll(
            RegExp(r'-int\d+$'),
            '',
          ) // Remove quantization suffix (-int4)
          .replaceAll(RegExp(r'\.litertlm$'), '') // Remove .litertlm extension
          .replaceAll(RegExp(r'\.task$'), ''); // Remove .task extension

      // Special handling for common model naming patterns
      if (normalized.contains('gemma-3n-e4b') ||
          normalized.contains('gemma3n-e4b')) {
        return 'gemma-3n-e4b-it';
      } else if (normalized.contains('gemma-3n-e2b') ||
          normalized.contains('gemma3n-e2b') ||
          normalized.contains('gemma-3n-e2b-it-litert-preview')) {
        return 'gemma-3n-e2b-it';
      } else if (normalized.contains('gemma3-1b') ||
          normalized.contains('gemma-3-1b')) {
        return 'gemma3-1b-it';
      } else if (normalized.contains('gemma3-2b') ||
          normalized.contains('gemma-3-2b')) {
        return 'gemma3-2b-it';
      } else if (normalized.contains('gemma3-7b') ||
          normalized.contains('gemma-3-7b')) {
        return 'gemma3-7b-it';
      } else if (normalized.contains('gemma-3n') ||
          normalized.contains('gemma3n')) {
        return 'gemma-3n-e2b-it'; // Default to E2B for vision support
      } else if (normalized.contains('gemma-3') ||
          normalized.contains('gemma3')) {
        return 'gemma3-1b-it'; // Default to 1B for Gemma3 models
      }

      // Return the normalized name if no specific pattern matches
      return normalized.isEmpty ? 'gemma-3n-e2b-it' : normalized;
    } catch (e) {
      print('ModelUtils: Error deriving model type: $e');
      return 'gemma-3n-e2b-it'; // Default fallback
    }
  }
}
