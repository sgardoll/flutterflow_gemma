import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:typed_data';

// Custom class to manage Gemma model functionality for FlutterFlow
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

  // Helper function to determine if a model supports vision
  bool _isMultimodalModel(String modelType) {
    final multimodalModels = [
      'gemma-3-4b-it',
      'gemma-3-12b-it',
      'gemma-3-27b-it',
      'gemma-3-nano-e4b-it',
      'gemma-3-nano-e2b-it',
    ];
    return multimodalModels.any((model) =>
        modelType.toLowerCase().contains(model.toLowerCase()) ||
        modelType.toLowerCase().contains('nano') ||
        modelType.toLowerCase().contains('vision') ||
        modelType.toLowerCase().contains('multimodal'));
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

      // If a local model path is provided, set it first
      if (localModelPath != null && localModelPath.isNotEmpty) {
        try {
          print('Setting model path in GemmaManager: $localModelPath');
          await modelManager.setModelPath(localModelPath);
          print('Model path set successfully in GemmaManager');

          // Add a small delay to ensure the path is registered
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print('Warning: Failed to set model path in GemmaManager: $e');
          // Continue anyway as the path might have been set elsewhere
        }
      }

      // Check if the model actually supports vision
      final actualSupportImage = supportImage && _isMultimodalModel(modelType);

      print(
          'GemmaManager: Model=$modelType, RequestedVision=$supportImage, ActualVision=$actualSupportImage');

      // Create the model - using dynamic to avoid enum issues
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

      return true;
    } catch (e) {
      print('Error initializing Gemma model: $e');

      // If image support failed, try without it
      if (supportImage && e.toString().contains('Vision')) {
        print(
            'Vision initialization failed, retrying without image support...');
        try {
          _model = await FlutterGemmaPlugin.instance.createModel(
            modelType: _getModelType(modelType),
            preferredBackend: _getBackend(backend),
            maxTokens: maxTokens,
            supportImage: false,
            maxNumImages: 1,
          );

          _isInitialized = true;
          _currentModelType = modelType;
          _currentBackend = backend;

          print('Model initialized successfully without vision support');
          return true;
        } catch (fallbackError) {
          print('Fallback initialization also failed: $fallbackError');
        }
      }

      return false;
    }
  }

  // Create a session for single inferences
  Future<bool> createSession({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    print('GemmaManager.createSession: Starting...');
    print(
        'GemmaManager.createSession: _isInitialized=$_isInitialized, _model!=null=${_model != null}');
    print('GemmaManager.createSession: hasExistingSession=${_session != null}');

    if (!_isInitialized || _model == null) {
      print(
          'GemmaManager.createSession: Model not initialized or null, returning false');
      return false;
    }

    // Close existing session if any
    if (_session != null) {
      print('GemmaManager.createSession: Closing existing session...');
      await closeSession();
    }

    try {
      print(
          'GemmaManager.createSession: About to call _model!.createSession...');
      _session = await _model!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );
      print('GemmaManager.createSession: Session created successfully!');
      return true;
    } catch (e) {
      print('Error creating session: $e');
      return false;
    }
  }

  // Send message and get response
  Future<String?> sendMessage(String message, {Uint8List? imageBytes}) async {
    if (_session == null) return null;

    try {
      Message msg;
      if (imageBytes != null) {
        msg = Message.withImage(
            text: message, imageBytes: imageBytes, isUser: true);
      } else {
        msg = Message.text(text: message, isUser: true);
      }

      await _session!.addQueryChunk(msg);
      return await _session!.getResponse();
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Stream response
  Stream<String>? getResponseStream(String message, {Uint8List? imageBytes}) {
    if (_session == null) return null;

    try {
      Message msg;
      if (imageBytes != null) {
        msg = Message.withImage(
            text: message, imageBytes: imageBytes, isUser: true);
      } else {
        msg = Message.text(text: message, isUser: true);
      }

      _session!.addQueryChunk(msg);
      return _session!.getResponseAsync();
    } catch (e) {
      print('Error getting response stream: $e');
      return null;
    }
  }

  // Get token count for a message
  Future<int?> getTokenCount(String text) async {
    if (_session == null) return null;

    try {
      return await _session!.sizeInTokens(text);
    } catch (e) {
      print('Error getting token count: $e');
      return null;
    }
  }

  // Download model from network
  Future<bool> downloadModelFromNetwork(String url, {String? loraUrl}) async {
    try {
      await modelManager.downloadModelFromNetwork(url, loraUrl: loraUrl);
      return true;
    } catch (e) {
      print('Error downloading model: $e');
      return false;
    }
  }

  // Download model from network with progress
  Stream<int> downloadModelFromNetworkWithProgress(String url,
      {String? loraUrl}) {
    return modelManager.downloadModelFromNetworkWithProgress(url,
        loraUrl: loraUrl);
  }

  // Install model from assets
  Future<bool> installModelFromAsset(String assetPath,
      {String? loraPath}) async {
    try {
      await modelManager.installModelFromAsset(assetPath, loraPath: loraPath);
      return true;
    } catch (e) {
      print('Error installing model from asset: $e');
      return false;
    }
  }

  // Install model from assets with progress
  Stream<int> installModelFromAssetWithProgress(String assetPath,
      {String? loraPath}) {
    return modelManager.installModelFromAssetWithProgress(assetPath,
        loraPath: loraPath);
  }

  // Close current session
  Future closeSession() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
    }
  }

  // Close the model
  Future closeModel() async {
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
    // Using the actual ModelType enum from flutter_gemma package
    // Available types: general, gemmaIt, deepSeek
    switch (modelType.toLowerCase()) {
      case 'gemma':
      case 'gemmait':
      case 'gemma-it':
      case 'gemma_it':
      case 'gemmanano':
      case 'gemma-nano':
      case 'gemma_nano':
      case 'gemma2':
      case 'gemma-2':
      case 'gemma_2':
        return ModelType.gemmaIt;
      case 'deepseek':
      case 'deep-seek':
      case 'deep_seek':
        return ModelType.deepSeek;
      case 'general':
        return ModelType.general;
      default:
        // Default to gemmaIt if no match found
        return ModelType.gemmaIt;
    }
  }

  // Helper method to convert string to PreferredBackend enum
  PreferredBackend _getBackend(String backend) {
    // Using the actual PreferredBackend enum from flutter_gemma package
    // Available types: unknown, cpu, gpu, gpuFloat16, gpuMixed, gpuFull, tpu
    switch (backend.toLowerCase()) {
      case 'gpu':
        return PreferredBackend.gpu;
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
        // Default to GPU if no match found
        return PreferredBackend.gpu;
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentModelType => _currentModelType;
  String? get currentBackend => _currentBackend;
  bool get hasSession => _session != null;
}
