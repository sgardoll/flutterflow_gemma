import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:typed_data';
import 'dart:math' as Math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

  // Retry tracking to prevent infinite loops
  int _initializationRetries = 0;
  static const int _maxRetries = 3;

  // Model file manager
  ModelFileManager get modelManager => FlutterGemmaPlugin.instance.modelManager;

  // Standardized model type normalization function
  static String _normalizeModelType(String modelType) {
    return modelType
        .toLowerCase()
        .trim()
        .replaceAll(' ', '-')
        .replaceAll('_', '-')
        .replaceAll(RegExp(r'-+'), '-'); // Remove multiple consecutive dashes
  }

  // Helper function to determine if a model supports vision
  static bool isMultimodalModel(String modelType) {
    final normalizedType = _normalizeModelType(modelType);

    print('GemmaManager.isMultimodalModel: Checking model type: "$modelType"');
    print('GemmaManager.isMultimodalModel: Normalized type: "$normalizedType"');

    // List of known multimodal models with all naming variations
    final multimodalModels = [
      'gemma-3n-e4b-it', // From URL extraction
      'gemma-3n-e2b-it', // From URL extraction
      'gemma3-1b-it',
    ];

    // Check exact matches first
    for (final model in multimodalModels) {
      if (normalizedType.contains(model)) {
        print('GemmaManager.isMultimodalModel: Exact match found for $model');
        return true;
      }
    }

    // Check for patterns that strongly indicate multimodal support
    final strongPatterns = [
      'gemma-3', // All Gemma 3 models are multimodal
      'gemma3',
      'paligemma',
      'vision',
      'multimodal',
      '3n-e', // Gemma 3 nano edge patterns
    ];

    for (final pattern in strongPatterns) {
      if (normalizedType.contains(pattern)) {
        print(
            'GemmaManager.isMultimodalModel: Strong pattern match found for $pattern');
        return true;
      }
    }

    // Additional checks for edge/nano patterns (these are typically multimodal)
    if (normalizedType.contains('nano') && normalizedType.contains('gemma')) {
      print(
          'GemmaManager.isMultimodalModel: Gemma nano model detected (multimodal)');
      return true;
    }

    if (normalizedType.contains('edge') && normalizedType.contains('gemma')) {
      print(
          'GemmaManager.isMultimodalModel: Gemma edge model detected (multimodal)');
      return true;
    }

    print('GemmaManager.isMultimodalModel: No multimodal support detected');
    return false;
  }

  // Instance method that uses the static version
  bool _isMultimodalModel(String modelType) {
    return GemmaManager.isMultimodalModel(modelType);
  }

  // Helper function to derive model type from a file path
  static String getModelTypeFromPath(String filePath) {
    try {
      // Get the base filename without extension
      final fileName = path.basenameWithoutExtension(filePath);

      // Normalize by removing common suffixes like "-int4", "-int8", etc.
      final normalizedName = fileName.replaceAll(RegExp(r'-int\d+$'), '');

      print(
          'GemmaManager.getModelTypeFromPath: Derived "$normalizedName" from "$filePath"');
      return normalizedName;
    } catch (e) {
      print('GemmaManager.getModelTypeFromPath: Error deriving model type: $e');
      // Fallback to a generic but safe default
      return 'google/gemma-1b-it';
    }
  }

  // Helper method to check if model file exists in platform-specific plugin directory
  Future<bool> _checkModelFileExists(String filename) async {
    try {
      // Use platform-specific directory
      late Directory pluginDirectory;
      if (Platform.isIOS) {
        // iOS plugin expects models in Documents directory
        pluginDirectory = await getApplicationDocumentsDirectory();
      } else {
        // Android plugin expects models in app support directory
        pluginDirectory = await getApplicationSupportDirectory();
      }

      final modelPath = path.join(pluginDirectory.path, filename);
      final exists = await File(modelPath).exists();

      if (exists) {
        final size = await File(modelPath).length();
        print(
            'GemmaManager: Model file exists in ${Platform.isIOS ? "iOS Documents" : "Android Support"} directory: $filename');
        print(
            'GemmaManager: Size: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB');
      } else {
        print(
            'GemmaManager: Model file NOT found in ${Platform.isIOS ? "iOS Documents" : "Android Support"} directory: $filename');
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
    bool forceImageSupport = false, // Add force flag
    bool isRetry = false, // Internal flag to track retries
  }) async {
    try {
      // Reset retry counter on new initialization (not retries)
      if (!isRetry) {
        _initializationRetries = 0;
      }

      // Close existing model if any
      await closeModel();

      // Check if model file exists in plugin's working directory
      if (localModelPath != null) {
        final fileExists = await _checkModelFileExists(localModelPath);
        if (!fileExists) {
          print(
              'GemmaManager: Model file not found in plugin directory: $localModelPath');
          return false;
        }
      }

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
      _initializationRetries = 0; // Reset on success

      return true;
    } catch (e) {
      print('Error initializing Gemma model: $e');

      // Handle model not found errors
      if (e.toString().contains('Model not found at path') &&
          localModelPath != null) {
        print('🔍 Model initialization failed: Model not found');
        print('📁 Expected model: $localModelPath');
        print(
            '🔧 Ensure model is installed in plugin\'s working directory (app support)');

        // Check if the model actually exists where we think it should (platform-specific)
        late Directory pluginDirectory;
        if (Platform.isIOS) {
          pluginDirectory = await getApplicationDocumentsDirectory();
        } else {
          pluginDirectory = await getApplicationSupportDirectory();
        }

        final expectedPath = path.join(pluginDirectory.path, localModelPath);
        final exists = await File(expectedPath).exists();

        if (exists) {
          print('⚠️  Model file exists but plugin cannot find it');
          print('🐛 This may be a plugin working directory issue');
        } else {
          print(
              '❌ Model file is missing from expected location: $expectedPath');
          print('💡 Try re-downloading/re-installing the model');
        }
      }

      // If initialization fails, try to fallback gracefully
      if (e.toString().contains('failed to initialize') ||
          e.toString().contains('GPU') ||
          e.toString().contains('delegate')) {
        print('GPU initialization failed. Attempting to fall back to CPU...');
        try {
          // Close the failed model explicitly before retrying
          await closeModel();

          _model = await FlutterGemmaPlugin.instance.createModel(
            modelType: _getModelType(modelType),
            preferredBackend: PreferredBackend.cpu, // Force CPU
            maxTokens: maxTokens,
            supportImage: supportImage,
            maxNumImages: maxNumImages,
          );

          _isInitialized = true;
          _currentModelType = modelType;
          _currentBackend = 'cpu'; // Update backend to CPU
          _initializationRetries = 0; // Reset on success

          print('Successfully initialized model with CPU fallback');
          return true;
        } catch (cpuError) {
          print('CPU fallback also failed: $cpuError');
          return false;
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

      // Add a small delay to allow the system to stabilize after heavy model loading
      await Future.delayed(const Duration(milliseconds: 500));

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
      print('=== VISION DEBUG: Image Analysis ===');
      print('Image bytes length: ${imageBytes.length}');
      print('Image bytes first 10: ${imageBytes.take(10).toList()}');
      print(
          'Image bytes last 10: ${imageBytes.skip(imageBytes.length - 10).toList()}');

      // Analyze image header to detect format
      final imageFormat = _detectImageFormat(imageBytes);
      print('Detected image format: $imageFormat');

      // Check for common image corruption patterns
      final isCorrupted = _detectImageCorruption(imageBytes);
      print('Image corruption detected: $isCorrupted');

      // Check image size constraints
      final sizeInfo = _analyzeImageSize(imageBytes);
      print('Image size analysis: $sizeInfo');

      // Check if model actually supports images
      final modelType = _currentModelType ?? '';
      final supportsImages = _isMultimodalModel(modelType);
      print('Model supports images: $supportsImages (model: $modelType)');

      if (!supportsImages) {
        print(
            'WARNING: Model "$modelType" does not support images, sending text-only');
        print(
            'INFO: To enable image support, use a multimodal model like gemma-3-4b-it or gemma-3-nano-e4b-it');
        imageBytes = null;
      } else {
        // Enhanced vision prompt when image is provided
        if (message.trim().isEmpty ||
            message.trim().toLowerCase() == 'analyze this image') {
          message =
              'Please analyze this image and describe what you see in detail.';
          print('Enhanced vision prompt: $message');
        }
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
              final enhancedMessage = _enhanceVisionPrompt(message);
              msg = Message.withImage(
                  text: enhancedMessage, imageBytes: imageBytes, isUser: true);
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

  // Image analysis helper methods
  String _detectImageFormat(Uint8List imageBytes) {
    if (imageBytes.length < 8) return 'unknown';

    // Check for JPEG header (FF D8 FF)
    if (imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF) {
      return 'JPEG';
    }

    // Check for PNG header (89 50 4E 47 0D 0A 1A 0A)
    if (imageBytes.length >= 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47 &&
        imageBytes[4] == 0x0D &&
        imageBytes[5] == 0x0A &&
        imageBytes[6] == 0x1A &&
        imageBytes[7] == 0x0A) {
      return 'PNG';
    }

    // Check for WebP header (RIFF....WEBP)
    if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return 'WebP';
    }

    return 'unknown';
  }

  bool _detectImageCorruption(Uint8List imageBytes) {
    // Check for obviously corrupted data
    if (imageBytes.length < 100) return true;

    // Check for too many null bytes (indicates corruption)
    int nullCount = 0;
    for (int i = 0; i < Math.min(100, imageBytes.length); i++) {
      if (imageBytes[i] == 0) nullCount++;
    }

    // If more than 50% null bytes in first 100 bytes, likely corrupted
    if (nullCount > 50) return true;

    // Check for invalid format headers
    final format = _detectImageFormat(imageBytes);
    if (format == 'unknown') return true;

    return false;
  }

  String _analyzeImageSize(Uint8List imageBytes) {
    final sizeKB = (imageBytes.length / 1024).toStringAsFixed(1);
    final sizeMB = (imageBytes.length / (1024 * 1024)).toStringAsFixed(2);

    if (imageBytes.length < 1024) {
      return '${imageBytes.length} bytes (TOO SMALL - likely corrupted)';
    } else if (imageBytes.length > 10 * 1024 * 1024) {
      return '$sizeMB MB (TOO LARGE - may cause memory issues)';
    } else {
      return '$sizeKB KB (acceptable size)';
    }
  }

  // Enhanced vision prompt generation
  String _enhanceVisionPrompt(String originalMessage) {
    final message = originalMessage.trim();

    // If empty or generic, provide a structured vision prompt
    if (message.isEmpty ||
        message.toLowerCase() == 'analyze this image' ||
        message.toLowerCase() == 'what is this image showing?' ||
        message.toLowerCase() == 'describe this image') {
      return '''Look at this photograph and describe exactly what you see. This is a real photograph, not a pattern, design, or artwork.

Identify:
- What real-world objects, people, animals, or plants are visible
- The actual setting or location (indoor/outdoor, specific place)
- Specific details about lighting, colors, and composition
- Any text, signs, or writing visible in the image
- The style of photography (close-up, wide shot, etc.)

Do NOT describe this as:
- A pattern, design, or artwork
- A textile or fabric
- An abstract composition
- A computer-generated image

Focus on what is actually photographed in the real world.''';
    }

    // If the message doesn't explicitly mention the image, make it clear
    if (!message.toLowerCase().contains('image') &&
        !message.toLowerCase().contains('picture') &&
        !message.toLowerCase().contains('photo') &&
        !message.toLowerCase().contains('see') &&
        !message.toLowerCase().contains('look') &&
        !message.toLowerCase().contains('show')) {
      return 'Looking at this real photograph: $message';
    }

    // Otherwise, use the original message but emphasize it's a photograph
    return 'Looking at this photograph: $message';
  }

  // Comprehensive vision model testing
  Future<Map<String, dynamic>> testVisionCapabilities() async {
    final results = <String, dynamic>{
      'isReady': false,
      'supportsVision': false,
      'canProcessImages': false,
      'respondsToImages': false,
      'givesReasonableResponses': false,
      'errors': <String>[],
      'testResults': <String, dynamic>{},
    };

    if (!_isInitialized || _session == null) {
      results['errors'].add('Model or session not ready');
      return results;
    }

    results['isReady'] = true;

    if (!_isMultimodalModel(_currentModelType ?? '')) {
      results['errors'].add('Model does not claim vision support');
      return results;
    }

    results['supportsVision'] = true;

    try {
      // Test 1: Simple geometric test image (solid color square)
      final simpleTestResult = await _testWithSimpleImage();
      results['testResults']['simpleImage'] = simpleTestResult;

      // Test 2: Text-based test image
      final textTestResult = await _testWithTextImage();
      results['testResults']['textImage'] = textTestResult;

      // Test 3: Basic shape recognition
      final shapeTestResult = await _testWithShapeImage();
      results['testResults']['shapeImage'] = shapeTestResult;

      // Analyze overall performance
      results['canProcessImages'] = simpleTestResult['responded'] == true;
      results['respondsToImages'] = [
        simpleTestResult,
        textTestResult,
        shapeTestResult
      ].any((test) => test['responded'] == true);

      // Check for reasonable responses (not hallucinations)
      final responses = [
        simpleTestResult['response'],
        textTestResult['response'],
        shapeTestResult['response']
      ]
          .where((r) => r != null && (r as String).isNotEmpty)
          .cast<String>()
          .toList();

      results['givesReasonableResponses'] =
          responses.any((response) => !_isResponseProblematic(response));
    } catch (e) {
      results['errors'].add('Testing error: $e');
    }

    return results;
  }

  // Test with a simple solid color image
  Future<Map<String, dynamic>> _testWithSimpleImage() async {
    try {
      // Create a simple red square (2x2 pixels) in PNG format
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, // IHDR length
        0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x00, 0x02, // Width: 2
        0x00, 0x00, 0x00, 0x02, // Height: 2
        0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth 8, RGB
        0x9D, 0x19, 0x48, 0x2C, // CRC
        0x00, 0x00, 0x00, 0x12, // IDAT length
        0x49, 0x44, 0x41, 0x54, // IDAT
        0x08, 0x1D, 0x01, 0x07, 0x00, 0xF8, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0x00,
        0x00, 0xFF, 0x00, 0x00, 0x02, 0x07, 0x01, 0x02, // Red pixels
        0x9A, 0x1C, 0x18, 0xE9, // CRC
        0x00, 0x00, 0x00, 0x00, // IEND length
        0x49, 0x45, 0x4E, 0x44, // IEND
        0xAE, 0x42, 0x60, 0x82 // CRC
      ]);

      print('Testing with simple red square image...');
      final response = await sendMessage(
          'What color is this image? Describe what you see.',
          imageBytes: testImageBytes);

      return {
        'responded': response != null && response.isNotEmpty,
        'response': response,
        'testType': 'simple_color',
        'expectedKeywords': ['red', 'square', 'color'],
      };
    } catch (e) {
      return {
        'responded': false,
        'error': e.toString(),
        'testType': 'simple_color',
      };
    }
  }

  // Test with text-like content
  Future<Map<String, dynamic>> _testWithTextImage() async {
    try {
      // Simple 1x1 white pixel (text images usually work better)
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
        0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x00, 0x01, // Width: 1
        0x00, 0x00, 0x00, 0x01, // Height: 1
        0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
        0x90, 0x77, 0x53, 0xDE, // CRC
        0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
        0x49, 0x44, 0x41, 0x54, // IDAT
        0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00,
        0x02, 0x00, 0x01, // White pixel
        0xE5, 0x27, 0xDE, 0xFC, // CRC
        0x00, 0x00, 0x00, 0x00, // IEND chunk length
        0x49, 0x45, 0x4E, 0x44, // IEND
        0xAE, 0x42, 0x60, 0x82 // CRC
      ]);

      print('Testing with minimal white image...');
      final response = await sendMessage('Describe this image in one word.',
          imageBytes: testImageBytes);

      return {
        'responded': response != null && response.isNotEmpty,
        'response': response,
        'testType': 'minimal_image',
        'expectedKeywords': ['white', 'small', 'pixel', 'blank'],
      };
    } catch (e) {
      return {
        'responded': false,
        'error': e.toString(),
        'testType': 'minimal_image',
      };
    }
  }

  // Test with basic shape
  Future<Map<String, dynamic>> _testWithShapeImage() async {
    try {
      // Very basic test - just see if it responds at all
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00,
        0x90, 0x77, 0x53, 0xDE,
        0x00, 0x00, 0x00, 0x0C,
        0x49, 0x44, 0x41, 0x54,
        0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00,
        0x02, 0x00, 0x01,
        0xE5, 0x27, 0xDE, 0xFC,
        0x00, 0x00, 0x00, 0x00,
        0x49, 0x45, 0x4E, 0x44,
        0xAE, 0x42, 0x60, 0x82
      ]);

      print('Testing basic image processing...');
      final response =
          await sendMessage('What do you see?', imageBytes: testImageBytes);

      return {
        'responded': response != null && response.isNotEmpty,
        'response': response,
        'testType': 'basic_processing',
      };
    } catch (e) {
      return {
        'responded': false,
        'error': e.toString(),
        'testType': 'basic_processing',
      };
    }
  }

  // Check if a response shows problematic patterns
  bool _isResponseProblematic(String response) {
    final lower = response.toLowerCase();

    final problematicPatterns = [
      'repeating pattern',
      'textile',
      'fabric',
      'woven',
      'abstract pattern',
      'appears to be a design',
      'typographic exercise',
      'artistic exploration',
      'intricate detail',
      'somewhat abstract',
    ];

    return problematicPatterns.any((pattern) => lower.contains(pattern));
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentModelType => _currentModelType;
  String? get currentBackend => _currentBackend;
  bool get hasSession => _session != null;
  bool get supportsVision => _isMultimodalModel(_currentModelType ?? '');
}
