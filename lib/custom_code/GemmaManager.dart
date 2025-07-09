import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Simplified Gemma model manager for FlutterFlow

// Enum for available Gemma model IDs
enum GemmaModelId {
  smolvlm500m,
  smolvlm500mOnnx,
  gemma31bWeb,
  smolvlm2b,
  paligemma3b224,
  paligemma3b448,
  paligemma3b896,
  nanollava,
  minicpmV2,
  idefics28bOcr,
  rmbg14Onnx,
  gemma3nE4bIt,
  gemma3nE2bIt,
  gemma31bIt,
  gemma3_9b,
  gemma3_27b,
  gemma3n_1b,
}

// Mapping from enum to model ID string
const Map<GemmaModelId, String> gemmaModelIdStrings = {
  GemmaModelId.smolvlm500m: 'smolvlm-500m',
  GemmaModelId.smolvlm500mOnnx: 'smolvlm-500m-onnx',
  GemmaModelId.gemma31bWeb: 'gemma3-1b-web',
  GemmaModelId.smolvlm2b: 'smolvlm-2b',
  GemmaModelId.paligemma3b224: 'paligemma-3b-224',
  GemmaModelId.paligemma3b448: 'paligemma-3b-448',
  GemmaModelId.paligemma3b896: 'paligemma-3b-896',
  GemmaModelId.nanollava: 'nanollava',
  GemmaModelId.minicpmV2: 'minicpm-v2',
  GemmaModelId.idefics28bOcr: 'idefics2-8b-ocr',
  GemmaModelId.rmbg14Onnx: 'rmbg-1.4-onnx',
  GemmaModelId.gemma3nE4bIt: 'gemma-3n-e4b-it',
  GemmaModelId.gemma3nE2bIt: 'gemma-3n-e2b-it',
  GemmaModelId.gemma31bIt: 'gemma3-1b-it',
  GemmaModelId.gemma3_9b: 'gemma3-9b',
  GemmaModelId.gemma3_27b: 'gemma3-27b',
  GemmaModelId.gemma3n_1b: 'gemma3n-1b',
};

// Optional: Display names for UI
const Map<GemmaModelId, String> gemmaModelDisplayNames = {
  GemmaModelId.smolvlm500m: 'SmolVLM 500M (image+text, best for web)',
  GemmaModelId.smolvlm500mOnnx: 'SmolVLM 500M ONNX (cross-platform)',
  GemmaModelId.gemma31bWeb: 'Gemma3 1B Web (text-only, efficient)',
  GemmaModelId.smolvlm2b: 'SmolVLM 2.2B (better quality)',
  GemmaModelId.paligemma3b224: 'PaliGemma 3B 224px (OCR)',
  GemmaModelId.paligemma3b448: 'PaliGemma 3B 448px (high-res)',
  GemmaModelId.paligemma3b896: 'PaliGemma 3B 896px (best quality)',
  GemmaModelId.nanollava: 'nanoLLaVA (compact, efficient)',
  GemmaModelId.minicpmV2: 'MiniCPM-V2 (good balance)',
  GemmaModelId.idefics28bOcr: 'Idefics2 8B OCR (document understanding)',
  GemmaModelId.rmbg14Onnx: 'RMBG 1.4 ONNX (background removal)',
  GemmaModelId.gemma3nE4bIt: 'Gemma 3 Nano 4B (legacy text-only)',
  GemmaModelId.gemma3nE2bIt: 'Gemma 3 Nano 2B (legacy text-only)',
  GemmaModelId.gemma31bIt: 'Gemma3 1B (legacy text-only)',
  GemmaModelId.gemma3_9b: 'Gemma3 9B (text-only)',
  GemmaModelId.gemma3_27b: 'Gemma3 27B (text-only)',
  GemmaModelId.gemma3n_1b: 'Gemma3 Nano 1B (text-only)',
};

class GemmaManager {
  static final GemmaManager _instance = GemmaManager._internal();
  factory GemmaManager() => _instance;
  GemmaManager._internal();

  // Model and session management
  InferenceModel? _model;
  InferenceModelSession? _session;

  // Configuration
  bool _isInitialized = false;
  String? _currentModelType;
  String? _currentBackend;

  // Model file manager
  ModelFileManager get modelManager => FlutterGemmaPlugin.instance.modelManager;

  // Standardized model type normalization function
  static String _normalizeModelType(String modelType) {
    return modelType
        .toLowerCase()
        .trim()
        .replaceAll(' ', '-')
        .replaceAll('_', '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  // Helper function to determine if a model supports vision
  static bool isMultimodalModel(String modelType) {
    final normalizedType = _normalizeModelType(modelType);

    // List of known multimodal models
    final multimodalModels = [
      'gemma-3n-e4b-it',
      'gemma-3n-e2b-it',
      'gemma3-1b-it',
      'smolvlm',
      'paligemma',
      'nanollava',
      'minicpm-v',
      'idefics',
    ];

    // Check exact matches first
    for (final model in multimodalModels) {
      if (normalizedType.contains(model)) {
        return true;
      }
    }

    // Check for patterns that indicate multimodal support
    final multimodalPatterns = [
      'gemma-3',
      'gemma3',
      'vision',
      'multimodal',
      '3n-e',
    ];

    for (final pattern in multimodalPatterns) {
      if (normalizedType.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  // Helper function to derive model type from a file path
  static String getModelTypeFromPath(String filePath) {
    try {
      final fileName = path.basenameWithoutExtension(filePath);
      final normalizedName = fileName.replaceAll(RegExp(r'-int\d+$'), '');
      return normalizedName;
    } catch (e) {
      print('GemmaManager.getModelTypeFromPath: Error deriving model type: $e');
      return 'gemma-3n-e4b-it';
    }
  }

  // Check if model file exists in platform-specific plugin directory
  Future<bool> _checkModelFileExists(String filename) async {
    try {
      // Use Documents directory for both platforms
      final pluginDirectory = await getApplicationDocumentsDirectory();

      final modelPath = path.join(pluginDirectory.path, filename);
      final exists = await File(modelPath).exists();

      if (exists) {
        final size = await File(modelPath).length();
        print(
            'GemmaManager: Model file exists: $filename (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
      }

      return exists;
    } catch (e) {
      print('GemmaManager: Error checking model file: $e');
      return false;
    }
  }

  // Initialize the model
  Future<bool> initializeModel({
    required String modelType,
    String backend = 'gpu',
    int maxTokens = 1024,
    bool supportImage = false,
    int maxNumImages = 1,
    String? localModelPath,
  }) async {
    try {
      // Close existing model if any
      await closeModel();

      // Check if model file exists
      if (localModelPath != null) {
        final fileExists = await _checkModelFileExists(localModelPath);
        if (!fileExists) {
          print('GemmaManager: Model file not found: $localModelPath');
          return false;
        }
      }

      // Check if the model actually supports vision
      final actualSupportImage = supportImage && isMultimodalModel(modelType);

      print(
          'GemmaManager: Initializing model=$modelType, backend=$backend, vision=$actualSupportImage');

      // Create the model
      _model = await FlutterGemmaPlugin.instance.createModel(
        modelType: _getModelType(modelType),
        preferredBackend: _getBackend(backend),
        maxTokens: maxTokens,
        supportImage: actualSupportImage,
        maxNumImages: maxNumImages,
      );

      _isInitialized = true;
      _currentModelType = modelType;
      _currentBackend = backend;

      print('GemmaManager: Model initialized successfully');
      return true;
    } catch (e) {
      print('GemmaManager: Error initializing model: $e');

      // Enhanced iOS-specific error handling
      if (Platform.isIOS && e.toString().contains('RET_CHECK failure')) {
        print('GemmaManager: iOS TensorFlow Lite error detected');
        print('GemmaManager: This model may not be compatible with iOS');

        // Disable vision for iOS compatibility
        if (supportImage && backend != 'cpu') {
          print('GemmaManager: Attempting iOS fallback without vision...');
          try {
            await closeModel();

            _model = await FlutterGemmaPlugin.instance.createModel(
              modelType: _getModelType(modelType),
              preferredBackend: PreferredBackend.cpu,
              maxTokens: maxTokens,
              supportImage: false, // Disable vision for iOS compatibility
              maxNumImages: 1,
            );

            _isInitialized = true;
            _currentModelType = modelType;
            _currentBackend = 'cpu';

            print('GemmaManager: iOS CPU fallback without vision successful');
            return true;
          } catch (iosError) {
            print('GemmaManager: iOS CPU fallback failed: $iosError');
          }
        }
      }

      // General CPU fallback for GPU errors
      if ((e.toString().contains('GPU') ||
              e.toString().contains('delegate') ||
              e.toString().contains('RET_CHECK failure')) &&
          backend != 'cpu') {
        print('GemmaManager: Attempting general CPU fallback...');
        try {
          await closeModel();

          _model = await FlutterGemmaPlugin.instance.createModel(
            modelType: _getModelType(modelType),
            preferredBackend: PreferredBackend.cpu,
            maxTokens: maxTokens,
            supportImage: Platform.isIOS
                ? false
                : (supportImage && isMultimodalModel(modelType)),
            maxNumImages: maxNumImages,
          );

          _isInitialized = true;
          _currentModelType = modelType;
          _currentBackend = 'cpu';

          print('GemmaManager: General CPU fallback successful');
          return true;
        } catch (cpuError) {
          print('GemmaManager: General CPU fallback failed: $cpuError');
        }
      }

      return false;
    }
  }

  // Create a session for inference
  Future<bool> createSession({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isInitialized || _model == null) {
      print('GemmaManager: Model not initialized');
      return false;
    }

    // Close existing session if any
    if (_session != null) {
      await closeSession();
    }

    try {
      _session = await _model!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      print('GemmaManager: Session created successfully');
      return true;
    } catch (e) {
      print('GemmaManager: Error creating session: $e');
      return false;
    }
  }

  // Send message and get response
  Future<String?> sendMessage(String message, {Uint8List? imageBytes}) async {
    if (_session == null) {
      print('GemmaManager: No session available');
      return null;
    }

    try {
      Message msg;

      // Check if image is provided and model supports vision
      if (imageBytes != null && isMultimodalModel(_currentModelType ?? '')) {
        print('GemmaManager: Sending message with image');
        msg = Message.withImage(
            text: message, imageBytes: imageBytes, isUser: true);
      } else {
        if (imageBytes != null) {
          print(
              'GemmaManager: Model does not support images, sending text only');
        }
        msg = Message.text(text: message, isUser: true);
      }

      await _session!.addQueryChunk(msg);
      final response = await _session!.getResponse();

      return response;
    } catch (e) {
      print('GemmaManager: Error sending message: $e');
      return null;
    }
  }

  // Close current session
  Future<void> closeSession() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
    }
  }

  // Close the model
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

  // Helper method to convert string to ModelType enum
  ModelType _getModelType(String modelType) {
    final normalized = modelType.toLowerCase().replaceAll('_', '-');

    // Handle SmolVLM models
    if (normalized.contains('smolvlm')) {
      return ModelType.gemmaIt; // SmolVLM uses gemmaIt type
    }

    // Handle Gemma 3 Nano models
    if (normalized.contains('gemma-3n') || normalized.contains('gemma3n')) {
      return ModelType.gemmaIt; // Gemma 3 Nano uses gemmaIt type
    }

    // Handle other Gemma 3 models
    if (normalized.contains('gemma-3') || normalized.contains('gemma3')) {
      return ModelType.gemmaIt;
    }

    // Handle specific model types
    switch (normalized) {
      case 'deepseek':
      case 'deep-seek':
      case 'deep_seek':
        return ModelType.deepSeek;
      case 'general':
        return ModelType.general;
      default:
        return ModelType.gemmaIt;
    }
  }

  // Helper method to convert string to PreferredBackend enum
  PreferredBackend _getBackend(String backend) {
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

  /// Returns a list of all available model ID strings
  static List<String> getAvailableModelIds() {
    return gemmaModelIdStrings.values.toList();
  }

  /// Returns a map of model ID string to display name
  static Map<String, String> getModelIdDisplayNames() {
    return {
      for (final entry in gemmaModelIdStrings.entries)
        entry.value: gemmaModelDisplayNames[entry.key] ?? entry.value,
    };
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentModelType => _currentModelType;
  String? get currentBackend => _currentBackend;
  bool get hasSession => _session != null;
  bool get supportsVision => isMultimodalModel(_currentModelType ?? '');
}
