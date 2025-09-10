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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
          'FlutterGemmaLibrary: Initializing model=$modelType, backend=$backend, vision=$actualSupportImage');

      // Check if model file exists if specified
      if (modelFileName != null) {
        final fileExists = await _checkModelFileExists(modelFileName);
        if (!fileExists) {
          print('FlutterGemmaLibrary: Model file not found: $modelFileName');
          return false;
        }
      }

      // Create the model
      _model = await plugin.createModel(
        modelType: ModelUtils.getModelType(modelType),
        preferredBackend: ModelUtils.getBackend(backend),
        maxTokens: maxTokens,
        supportImage: actualSupportImage,
        maxNumImages: maxNumImages,
      );

      _isInitialized = true;
      _currentModelType = modelType;
      _currentBackend = backend;

      print('FlutterGemmaLibrary: Model initialized successfully');
      return true;
    } catch (e) {
      print('FlutterGemmaLibrary: Error initializing model: $e');

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
      print('FlutterGemmaLibrary: Model not initialized');
      return false;
    }

    try {
      // Close existing session if any
      if (_session != null) {
        await _session!.close();
        _session = null;
      }

      _session = await _model!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      print('FlutterGemmaLibrary: Session created successfully');
      return true;
    } catch (e) {
      print('FlutterGemmaLibrary: Error creating session: $e');
      return false;
    }
  }

  /// Send a message to the model and get a response
  ///
  /// [message] - The text message to send
  /// [imageBytes] - Optional image data for multimodal models
  Future<String?> sendMessage(String message, {Uint8List? imageBytes}) async {
    if (_session == null) {
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

  /// Check if model file exists in documents directory
  Future<bool> _checkModelFileExists(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = path.join(directory.path, fileName);
      final exists = await File(modelPath).exists();

      if (exists) {
        final size = await File(modelPath).length();
        print(
            'FlutterGemmaLibrary: Model file exists: $fileName (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
      }

      return exists;
    } catch (e) {
      print('FlutterGemmaLibrary: Error checking model file: $e');
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
      return fileName.replaceAll(RegExp(r'-int\d+$'), '');
    } catch (e) {
      print('ModelUtils: Error deriving model type: $e');
      return 'gemma-3n-e2b-it'; // Default fallback
    }
  }
}
