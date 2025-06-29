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
    // Normalize the model type for comparison
    final normalizedType =
        modelType.toLowerCase().replaceAll(' ', '-').replaceAll('_', '-');

    print('GemmaManager._isMultimodalModel: Checking model type: "$modelType"');
    print(
        'GemmaManager._isMultimodalModel: Normalized type: "$normalizedType"');

    // List of known multimodal models
    final multimodalModels = [
      'gemma-3-4b-it',
      'gemma-3-12b-it',
      'gemma-3-27b-it',
      'gemma-3-nano-e4b-it',
      'gemma-3-nano-e2b-it',
      'gemma-3-4b-edge',
      'gemma-3-nano',
    ];

    // Check exact matches first
    for (final model in multimodalModels) {
      if (normalizedType.contains(model)) {
        print('GemmaManager._isMultimodalModel: Exact match found for $model');
        return true;
      }
    }

    // Check for common patterns that indicate multimodal support
    final patterns = [
      'gemma-3', // All Gemma 3 models support vision
      'gemma3',
      'nano',
      'vision',
      'multimodal',
      'edge',
      'paligemma', // Google's vision model
    ];

    for (final pattern in patterns) {
      if (normalizedType.contains(pattern)) {
        print(
            'GemmaManager._isMultimodalModel: Pattern match found for $pattern');
        return true;
      }
    }

    print('GemmaManager._isMultimodalModel: No multimodal support detected');
    return false;
  }

  // Initialize the model
  Future<bool> initializeModel({
    required String modelType,
    String backend = 'gpu',
    int maxTokens = 1024,
    bool supportImage = false,
    int maxNumImages = 1,
    String? localModelPath,
    bool forceImageSupport = false, // Add force flag
  }) async {
    try {
      // Close existing model if any
      await closeModel();

      // Check if the model actually supports vision
      // Use force flag to bypass model type check if needed
      final actualSupportImage = forceImageSupport
          ? supportImage
          : (supportImage && _isMultimodalModel(modelType));

      print(
          'GemmaManager: Model=$modelType, RequestedVision=$supportImage, ActualVision=$actualSupportImage, ForceImageSupport=$forceImageSupport');

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
    print('=== GemmaManager.sendMessage Debug ===');
    print('Session exists: ${_session != null}');
    print('Message: $message');
    print('Image bytes provided: ${imageBytes != null}');

    if (_session == null) {
      print('ERROR: No session available');
      return null;
    }

    if (imageBytes != null) {
      print('Image bytes length: ${imageBytes.length}');
      print('Image bytes first 10: ${imageBytes.take(10).toList()}');

      // Check if model actually supports images
      final modelType = _currentModelType?.toLowerCase() ?? '';
      final supportsImages = _isMultimodalModel(modelType);
      print('Model supports images: $supportsImages (model: $modelType)');

      if (!supportsImages) {
        print('WARNING: Model does not support images, sending text-only');
        imageBytes = null;
      }
    }

    try {
      Message msg;
      if (imageBytes != null) {
        print('Creating message with image...');
        msg = Message.withImage(
            text: message, imageBytes: imageBytes, isUser: true);
        print('Message with image created successfully');
      } else {
        print('Creating text-only message...');
        msg = Message.text(text: message, isUser: true);
        print('Text message created successfully');
      }

      print('Adding query chunk to session...');
      await _session!.addQueryChunk(msg);
      print('Query chunk added, getting response...');

      final response = await _session!.getResponse();
      print(
          'Response received: ${response != null ? "Yes (${response.length} chars)" : "No"}');
      print('=== End GemmaManager.sendMessage Debug ===');

      return response;
    } catch (e) {
      print('Error sending message: $e');
      print('Error type: ${e.runtimeType}');

      // Check if it's a session error and recreate session if needed
      if ((e.toString().contains('Session not created') ||
              e.toString().contains('Model is closed')) &&
          imageBytes != null) {
        print(
            'Session/Model error detected with image. Attempting recovery...');

        // Check if model is closed
        if (e.toString().contains('Model is closed')) {
          print('Model is closed. Reinitializing entire model...');

          // Store current configuration
          final modelType = _currentModelType ?? 'Gemma 3 4B Edge';
          final backend = _currentBackend ?? 'gpu';

          // Reinitialize the model
          final modelInitialized = await initializeModel(
            modelType: modelType,
            backend: backend,
            maxTokens: 1024,
            supportImage: true,
            maxNumImages: 1,
          );

          if (!modelInitialized) {
            print('Failed to reinitialize model');
            return null;
          }

          print('Model reinitialized successfully');
        }

        // Try to create/recreate the session
        final sessionCreated = await createSession();
        if (sessionCreated) {
          print('Session created successfully. Retrying message...');

          try {
            Message msg;
            if (imageBytes != null) {
              print('Creating message with image (retry)...');
              msg = Message.withImage(
                  text: message, imageBytes: imageBytes, isUser: true);
              print('Message with image created successfully (retry)');
            } else {
              print('Creating text-only message (retry)...');
              msg = Message.text(text: message, isUser: true);
              print('Text message created successfully (retry)');
            }

            print('Adding query chunk to session (retry)...');
            await _session!.addQueryChunk(msg);
            print('Query chunk added, getting response (retry)...');

            final response = await _session!.getResponse();
            print(
                'Response received (retry): ${response != null ? "Yes (${response.length} chars)" : "No"}');

            return response;
          } catch (retryError) {
            print('Retry also failed: $retryError');
          }
        }
      }

      print('Stack trace: ${StackTrace.current}');

      // If image processing failed, try text-only as fallback
      if (imageBytes != null) {
        print('Attempting fallback to text-only message...');
        try {
          // Ensure we have a valid session
          if (_session == null) {
            await createSession();
          }

          final textMsg = Message.text(text: message, isUser: true);
          await _session!.addQueryChunk(textMsg);
          final fallbackResponse = await _session!.getResponse();
          print(
              'Fallback response received: ${fallbackResponse != null ? "Yes" : "No"}');
          return fallbackResponse;
        } catch (fallbackError) {
          print('Fallback also failed: $fallbackError');
        }
      }

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
