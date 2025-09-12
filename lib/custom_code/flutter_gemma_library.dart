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
import 'dart:typed_data';
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
  bool get hasSession => _session != null;

  /// Check if the current model supports vision
  bool get supportsVision =>
      _currentModelType != null &&
      ModelUtils.isMultimodalModel(_currentModelType!);

  /// Initialize a model with the specified parameters
  ///
  /// [modelType] - The model identifier (derived from filename if not provided)
  /// [backend] - Preferred backend ('gpu', 'cpu', 'tpu')
  /// [maxTokens] - Maximum tokens to generate
  /// [supportImage] - Enable image support for multimodal models
  /// [maxNumImages] - Maximum number of images to support
  /// [modelFileName] - The model file to use (should be in documents directory)
  /// [backend] - Preferred backend ('gpu', 'cpu', 'tpu'). Defaults to
  /// 'gpu' but automatically falls back to 'cpu' when GPU is unavailable
  /// or when running on an Android emulator.
  Future<bool> initializeModel({
    required String modelType,
    String backend = 'gpu',
    int maxTokens = 1024,
    bool? supportImage,
    int maxNumImages = 1,
    String? modelFileName,
  }) async {
    var effectiveBackend = backend.toLowerCase();
    try {
      // Close any existing model
      await closeModel();

      // Determine if model supports vision
      final actualSupportImage =
          (supportImage ?? ModelUtils.isMultimodalModel(modelType)) &&
              ModelUtils.isMultimodalModel(modelType);

      print(
          'FlutterGemmaLibrary: Initializing model=$modelType, requestedBackend=$effectiveBackend, vision=$actualSupportImage');

      // Check if model file exists if specified
      if (modelFileName != null) {
        final fileExists = await _checkModelFileExists(modelFileName);
        if (!fileExists) {
          print('FlutterGemmaLibrary: Model file not found: $modelFileName');
          return false;
        }
      }

      // Determine effective backend before model creation
      if (effectiveBackend.startsWith('gpu')) {
        try {
          if (await _isAndroidEmulator()) {
            print(
                'FlutterGemmaLibrary: Android emulator detected, using CPU backend instead of $effectiveBackend');
            effectiveBackend = 'cpu';
          } else if (!await _hasAndroidGpu()) {
            print(
                'FlutterGemmaLibrary: GPU support could not be confirmed, defaulting to CPU backend');
            effectiveBackend = 'cpu';
          } else {
            print(
                'FlutterGemmaLibrary: GPU support confirmed, using $effectiveBackend backend');
          }
        } catch (checkError) {
          print(
              'FlutterGemmaLibrary: Error checking GPU capability: $checkError');
          print(
              'FlutterGemmaLibrary: Falling back to CPU backend due to uncertain GPU support');
          effectiveBackend = 'cpu';
        }
      }

      // Create the model with additional error handling
      try {
        _model = await plugin.createModel(
          modelType: ModelUtils.getModelType(modelType),
          preferredBackend: ModelUtils.getBackend(effectiveBackend),
          maxTokens: maxTokens,
          supportImage: actualSupportImage,
          maxNumImages: maxNumImages,
        );
      } catch (modelCreationError) {
        print(
            'FlutterGemmaLibrary: Model creation failed: $modelCreationError');
        // Rethrow to be handled by the outer catch block
        throw modelCreationError;
      }

      _isInitialized = true;
      _currentModelType = modelType;
      _currentBackend = effectiveBackend;

      print(
          'FlutterGemmaLibrary: Model initialized successfully using $effectiveBackend backend');
      return true;
    } catch (e) {
      print('FlutterGemmaLibrary: Error initializing model: $e');

      // Provide specific error analysis
      final errorString = e.toString();
      if (errorString.contains('RET_CHECK failure')) {
        print(
            'FlutterGemmaLibrary: TensorFlow Lite model loading error detected');
        print(
            'FlutterGemmaLibrary: This usually indicates a model type/file mismatch');
        print(
            'FlutterGemmaLibrary: Model type: $modelType, Backend: $effectiveBackend');
      }

      // Try CPU fallback for common issues
      if (_shouldTryCpuFallback(e, effectiveBackend)) {
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
          'FlutterGemmaLibrary: Creating session with model: $_currentModelType, backend: $_currentBackend');

      // Check if we're on web platform and handle differently if needed
      if (kIsWeb) {
        print(
            'FlutterGemmaLibrary: Web platform detected, attempting session creation');
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
              'FlutterGemmaLibrary: Continuing without session for web platform');
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
    if (_session == null) {
      if (kIsWeb && _model != null) {
        print(
            'FlutterGemmaLibrary: No session on web, attempting direct model inference');
        // For web, try to create a temporary session for this message
        try {
          final tempSession = await _model!.createSession(
            temperature: 0.8,
            randomSeed: 1,
            topK: 1,
          );

          Message msg;
          if (imageBytes != null && supportsVision) {
            msg = Message.withImage(
                text: message, imageBytes: imageBytes, isUser: true);
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

      print('FlutterGemmaLibrary: No session available');
      return null;
    }

    try {
      Message msg;

      // Use image if provided and model supports it
      if (imageBytes != null && supportsVision) {
        msg = Message.withImage(
            text: message, imageBytes: imageBytes, isUser: true);
      } else {
        if (imageBytes != null && !supportsVision) {
          print(
              'FlutterGemmaLibrary: Model does not support images, sending text only');
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

  /// Close the model and cleanup resources
  Future<void> closeModel() async {
    await closeSession();

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
          'FlutterGemmaLibrary: Model file exists: $fileName (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
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
          'FlutterGemmaLibrary: Web model registered: $fileName (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
      print('FlutterGemmaLibrary: Model URL: $modelUrl');
    }

    return exists;
  }

  /// Detect if the app is running on an Android emulator.
  Future<bool> _isAndroidEmulator() async {
    if (!Platform.isAndroid) return false;
    try {
      final cpuInfo = await File('/proc/cpuinfo').readAsString();
      final lower = cpuInfo.toLowerCase();
      return lower.contains('goldfish') || lower.contains('ranchu');
    } catch (e) {
      print(
          'FlutterGemmaLibrary: Failed to read /proc/cpuinfo for emulator detection: $e');
      return false;
    }
  }

  /// Best-effort check for GPU support on Android devices.
  Future<bool> _hasAndroidGpu() async {
    if (!Platform.isAndroid) return true;
    try {
      return await File('/dev/kgsl-3d0').exists();
    } catch (e) {
      print('FlutterGemmaLibrary: Error checking GPU device: $e');
      return false;
    }
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
}

/// Utility class for model-related helper functions
class ModelUtils {
  /// Determine if a model supports multimodal (vision) capabilities
  static bool isMultimodalModel(String modelType) {
    final normalizedType =
        modelType.toLowerCase().trim().replaceAll(RegExp(r'[-_\s]+'), '-');

    // Gemma models that support vision
    final multimodalModels = [
      'gemma-3n-e4b-it',
      'gemma-3n-e2b-it',
    ];

    return multimodalModels.any((model) => normalizedType.contains(model));
  }

  /// Convert string to ModelType enum
  static ModelType getModelType(String modelType) {
    final normalized = modelType.toLowerCase().replaceAll('_', '-');

    // Most Gemma models use gemmaIt type
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
              RegExp(r'-int\d+$'), '') // Remove quantization suffix (-int4)
          .replaceAll(RegExp(r'\.litertlm$'), '') // Remove .litertlm extension
          .replaceAll(RegExp(r'\.task$'), ''); // Remove .task extension

      // Special handling for common model naming patterns
      if (normalized.contains('gemma-3n-e4b') ||
          normalized.contains('gemma3n-e4b')) {
        return 'gemma-3n-e4b-it';
      } else if (normalized.contains('gemma-3n-e2b') ||
          normalized.contains('gemma3n-e2b')) {
        return 'gemma-3n-e2b-it';
      } else if (normalized.contains('gemma-3n') ||
          normalized.contains('gemma3n')) {
        return 'gemma3n-1b'; // Generic Gemma 3 Nano fallback
      } else if (normalized.contains('gemma-3') ||
          normalized.contains('gemma3')) {
        return 'gemma3-1b-it'; // Generic Gemma 3 fallback
      }

      // Return the normalized name if no specific pattern matches
      return normalized.isEmpty ? 'gemma-3n-e2b-it' : normalized;
    } catch (e) {
      print('ModelUtils: Error deriving model type: $e');
      return 'gemma-3n-e2b-it'; // Default fallback
    }
  }
}
