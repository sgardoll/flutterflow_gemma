import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:typed_data';
import 'dart:math' as math;
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
  dynamic _chat; // Use dynamic type since InferenceChat is not exposed

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

    // Also check for display names used in the UI
    final multimodalDisplayNames = [
      'gemma 3 4b edge',
      'gemma 3 12b edge',
      'gemma 3 27b edge',
      'gemma 3 nano',
    ];

    return multimodalModels.any(
            (model) => modelType.toLowerCase().contains(model.toLowerCase())) ||
        multimodalDisplayNames.any((displayName) =>
            modelType.toLowerCase().contains(displayName.toLowerCase())) ||
        modelType.toLowerCase().contains('nano') ||
        modelType.toLowerCase().contains('vision') ||
        modelType.toLowerCase().contains('multimodal');
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

      // If a local model path is provided, ensure it's properly registered
      if (localModelPath != null && localModelPath.isNotEmpty) {
        try {
          // Get just the filename for the plugin
          final modelFileName = path.basename(localModelPath);
          print('GemmaManager: Using model filename: $modelFileName');

          // Verify the model file exists in documents directory
          final appDocDir = await getApplicationDocumentsDirectory();
          final expectedPath = path.join(appDocDir.path, modelFileName);
          final modelFile = File(expectedPath);

          if (!await modelFile.exists()) {
            print(
                'GemmaManager: Model file not found at expected path: $expectedPath');

            // Try to find and copy the model from its current location
            if (localModelPath != expectedPath) {
              final sourceFile = File(localModelPath);
              if (await sourceFile.exists()) {
                print(
                    'GemmaManager: Copying model from $localModelPath to $expectedPath');
                await sourceFile.copy(expectedPath);
                print('GemmaManager: Model copied successfully');
              } else {
                print(
                    'GemmaManager: Source model file not found at: $localModelPath');
                return false;
              }
            } else {
              return false;
            }
          }

          // Register the model with the plugin's model manager
          print('GemmaManager: Registering model with plugin: $modelFileName');
          try {
            // Android needs the full path, iOS uses just the filename
            String pathToRegister;
            if (Platform.isAndroid) {
              pathToRegister = expectedPath; // Full path for Android
              print('GemmaManager: Android - Using full path: $pathToRegister');
            } else {
              pathToRegister = modelFileName; // Just filename for iOS
              print('GemmaManager: iOS - Using filename: $pathToRegister');
            }

            await modelManager.setModelPath(pathToRegister);
            print('GemmaManager: Model path registered successfully');
          } catch (pathError) {
            print('GemmaManager: Failed to register model path: $pathError');
            // Continue anyway as the plugin might still find it
          }
        } catch (e) {
          print('GemmaManager: Error preparing model file: $e');
          return false;
        }
      }

      // Check if the model actually supports vision
      final actualSupportImage = supportImage && _isMultimodalModel(modelType);

      print(
          'GemmaManager: Model=$modelType, RequestedVision=$supportImage, ActualVision=$actualSupportImage');

      // Create the model with enhanced debugging
      final enumModelType = _getModelType(modelType);
      final enumBackend = _getBackend(backend);

      print('GemmaManager: Creating model with:');
      print('  ModelType enum: $enumModelType');
      print('  Backend enum: $enumBackend');
      print('  MaxTokens: $maxTokens');
      print('  SupportImage: $actualSupportImage');

      _model = await FlutterGemmaPlugin.instance.createModel(
        modelType: enumModelType,
        preferredBackend: enumBackend,
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

      // If TensorFlow Lite model building failed, try different model types
      if (e.toString().contains('Error building tflite model') ||
          e.toString().contains('RET_CHECK failure')) {
        print(
            'TensorFlow Lite model building failed, trying alternative model types...');

        final alternativeTypes = [ModelType.gemmaIt, ModelType.general];
        final currentType = _getModelType(modelType);

        for (final altType in alternativeTypes) {
          if (altType == currentType) continue; // Skip the one we already tried

          try {
            print('Trying ModelType: $altType');
            _model = await FlutterGemmaPlugin.instance.createModel(
              modelType: altType,
              preferredBackend: _getBackend(backend),
              maxTokens: maxTokens,
              supportImage: false, // Disable image support for fallback
              maxNumImages: 1,
            );

            _isInitialized = true;
            _currentModelType = modelType;
            _currentBackend = backend;

            print(
                'Model initialized successfully with alternative type: $altType');
            return true;
          } catch (altError) {
            print('Alternative type $altType also failed: $altError');
          }
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

  // Create a chat instance for conversation
  Future<bool> createChat({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    print('GemmaManager.createChat: Starting...');
    print(
        'GemmaManager.createChat: _isInitialized=$_isInitialized, _model!=null=${_model != null}');

    if (!_isInitialized || _model == null) {
      print(
          'GemmaManager.createChat: Model not initialized or null, returning false');
      return false;
    }

    try {
      print('GemmaManager.createChat: Creating chat instance...');
      print(
          'GemmaManager.createChat: Parameters - temperature=$temperature, randomSeed=$randomSeed, topK=$topK');

      // Add a small delay to see if timing is an issue
      await Future.delayed(Duration(milliseconds: 100));

      _chat = await _model!.createChat(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );
      print('GemmaManager.createChat: Chat created successfully!');
      return true;
    } catch (e) {
      print('Error creating chat: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Send message using chat (maintains conversation history)
  Future<String?> sendChatMessage(String message,
      {Uint8List? imageBytes}) async {
    if (_chat == null) {
      print('GemmaManager.sendChatMessage: No chat instance available');
      return null;
    }

    try {
      print('GemmaManager.sendChatMessage: Sending message: $message');

      Message msg;
      if (imageBytes != null) {
        msg = Message.withImage(
            text: message, imageBytes: imageBytes, isUser: true);
      } else {
        msg = Message.text(text: message, isUser: true);
      }

      // Add message to chat
      await _chat.addQueryChunk(msg);

      // Generate response
      final response = await _chat.generateChatResponse();

      if (response != null && response.length > 50) {
        print(
            'GemmaManager.sendChatMessage: Got response: ${response.substring(0, 50)}...');
      } else {
        print('GemmaManager.sendChatMessage: Got response: $response');
      }

      return response;
    } catch (e) {
      print('Error sending chat message: $e');
      print('Error stack trace: ${e.toString()}');
      return null;
    }
  }

  // Send message and get response (for session-based approach)
  Future<String?> sendMessage(String message, {Uint8List? imageBytes}) async {
    if (_session == null) {
      print('GemmaManager.sendMessage: No session available');
      return null;
    }

    try {
      print('GemmaManager.sendMessage: Sending message: $message');

      // Debug image handling
      if (imageBytes != null) {
        print(
            'GemmaManager.sendMessage: Image bytes provided, size: ${imageBytes.length}');
        print(
            'GemmaManager.sendMessage: Current model type: $_currentModelType');
        print(
            'GemmaManager.sendMessage: Is multimodal model: ${_isMultimodalModel(_currentModelType ?? '')}');

        // Validate image data
        if (imageBytes.length < 100) {
          print(
              'GemmaManager.sendMessage: WARNING - Image seems too small, might be corrupted');
        }

        // Check first few bytes to ensure it's a valid image format
        if (imageBytes.length >= 4) {
          final header = imageBytes.take(4).toList();
          if (header[0] == 0xFF && header[1] == 0xD8) {
            print('GemmaManager.sendMessage: Detected JPEG format');
          } else if (header[0] == 0x89 &&
              header[1] == 0x50 &&
              header[2] == 0x4E &&
              header[3] == 0x47) {
            print('GemmaManager.sendMessage: Detected PNG format');
          } else {
            print(
                'GemmaManager.sendMessage: WARNING - Unknown image format, header: ${header.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
          }
        }
      } else {
        print('GemmaManager.sendMessage: No image bytes provided');
      }

      Message msg;
      if (imageBytes != null && _isMultimodalModel(_currentModelType ?? '')) {
        print('GemmaManager.sendMessage: Creating message with image');
        try {
          msg = Message.withImage(
              text: message, imageBytes: imageBytes, isUser: true);
          print('GemmaManager.sendMessage: Successfully created image message');
        } catch (imageError) {
          print(
              'GemmaManager.sendMessage: Error creating image message: $imageError');
          print('GemmaManager.sendMessage: Falling back to text-only message');
          msg = Message.text(text: message, isUser: true);
        }
      } else {
        print('GemmaManager.sendMessage: Creating text-only message');
        if (imageBytes != null) {
          print(
              'GemmaManager.sendMessage: WARNING - Image provided but model does not support multimodal');
        }
        msg = Message.text(text: message, isUser: true);
      }

      // Add the user message to the session
      await _session!.addQueryChunk(msg);

      // Get the model's response
      final response = await _session!.getResponse();

      if (response != null && response.length > 50) {
        print(
            'GemmaManager.sendMessage: Got response: ${response.substring(0, 50)}...');
      } else {
        print('GemmaManager.sendMessage: Got response: $response');
      }

      // Clean the response to remove any repeated patterns
      String? cleanedResponse = response;
      if (response != null && response.isNotEmpty) {
        cleanedResponse = _cleanResponse(response);

        // Only add the model's response back to the session if it's significantly different
        // to avoid context pollution and infinite loops
        final responseMsg = Message.text(text: cleanedResponse, isUser: false);
        await _session!.addQueryChunk(responseMsg);
      }

      return cleanedResponse;
    } catch (e) {
      print('Error sending message: $e');
      print('Error stack trace: ${e.toString()}');
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

    // Close chat if exists
    if (_chat != null) {
      try {
        await _chat.close();
      } catch (e) {
        print('Error closing chat: $e');
      }
      _chat = null;
    }

    if (_model != null) {
      await _model!.close();
      _model = null;
    }

    _isInitialized = false;
    _currentModelType = null;
    _currentBackend = null;
  }

  // Helper method to clean response text and remove repeated patterns
  String _cleanResponse(String response) {
    if (response.isEmpty) return response;

    // Remove excessive repetitions of the same phrase
    String cleaned = response;

    // Split into words and check for repeated patterns
    final words = response.split(' ');
    if (words.length > 10) {
      // Look for patterns that repeat more than 2 times
      for (int patternLength = 1; patternLength <= 5; patternLength++) {
        if (words.length >= patternLength * 3) {
          final pattern = words.take(patternLength).join(' ');

          // Count how many times this pattern repeats at the start
          int repeatCount = 0;
          for (int i = 0;
              i < words.length - patternLength + 1;
              i += patternLength) {
            final currentPattern = words.skip(i).take(patternLength).join(' ');
            if (currentPattern == pattern) {
              repeatCount++;
            } else {
              break;
            }
          }

          // If pattern repeats more than 2 times, keep only first 2 occurrences
          if (repeatCount > 2) {
            final remainingWords = words.skip(patternLength * 2).toList();
            cleaned = (words.take(patternLength * 2).toList() + remainingWords)
                .join(' ');
            break;
          }
        }
      }
    }

    // Additional cleanup: remove excessive whitespace and trim
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If the cleaned response is significantly shorter or the same, return it
    // Otherwise, return a truncated version of the original to be safe
    if (cleaned.length < response.length * 0.8 && cleaned.length > 50) {
      return cleaned;
    }

    // If cleaning made it too short, return original but truncated if too long
    if (response.length > 2000) {
      return response.substring(0, 2000) + '...';
    }

    return response;
  }

  // Helper method to convert string to ModelType enum
  ModelType _getModelType(String modelType) {
    // Using the actual ModelType enum from flutter_gemma package
    // Available types: general, gemmaIt, deepSeek
    final lowerType = modelType.toLowerCase();

    // For Gemma 3 models and newer, use 'general' type
    if (lowerType.contains('gemma 3') ||
        lowerType.contains('gemma3') ||
        lowerType.contains('gemma-3') ||
        lowerType.contains('1b') ||
        lowerType.contains('4b') ||
        lowerType.contains('8b') ||
        lowerType.contains('27b')) {
      print('GemmaManager: Using ModelType.general for: $modelType');
      return ModelType.general;
    }

    switch (lowerType) {
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
        // For unknown models, try general first as it's more flexible
        print(
            'GemmaManager: Using ModelType.general as fallback for: $modelType');
        return ModelType.general;
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

  // Helper method to resolve the actual model file path
  Future<String?> _resolveModelFilePath(String inputPath) async {
    try {
      print('GemmaManager: Resolving model path for: $inputPath');

      // Get the documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final baseFileName = path.basename(inputPath);

      // First, try the exact path if it's a full path
      if (inputPath.contains('/')) {
        final file = File(inputPath);
        if (await file.exists()) {
          print('GemmaManager: Found exact file at: $inputPath');
          return inputPath; // Return the full path for the plugin
        }
      }

      // Try the filename in the documents directory
      final directPath = path.join(appDocDir.path, baseFileName);
      final directFile = File(directPath);
      if (await directFile.exists()) {
        print('GemmaManager: Found file in documents: $directPath');
        return directPath;
      }

      // If file is in subdirectory, copy it to the documents root
      if (inputPath.contains('/') && inputPath.contains('models/')) {
        final sourceFile = File(inputPath);
        if (await sourceFile.exists()) {
          final targetPath = path.join(appDocDir.path, baseFileName);
          print(
              'GemmaManager: Copying model from subdirectory to documents root: $targetPath');
          await sourceFile.copy(targetPath);
          print('GemmaManager: Model copied successfully to documents root');
          return targetPath;
        }
      }

      // Search for .task files in the documents directory
      print(
          'GemmaManager: Searching for .task files in documents directory...');
      final files = await appDocDir.list().toList();
      final taskFiles = files
          .where((f) => f is File && f.path.endsWith('.task'))
          .cast<File>();

      if (taskFiles.isEmpty) {
        print('GemmaManager: No .task files found in documents directory');
        return null;
      }

      // List all found .task files
      for (final taskFile in taskFiles) {
        final taskFileName = path.basename(taskFile.path);
        print('GemmaManager: Found .task file: $taskFileName');
      }

      // If there's only one .task file, use it
      if (taskFiles.length == 1) {
        final taskFile = taskFiles.first;
        final taskFileName = path.basename(taskFile.path);
        print('GemmaManager: Using single .task file found: $taskFileName');

        // Ensure the file is in the documents root directory
        final expectedPath = path.join(appDocDir.path, taskFileName);
        if (taskFile.path != expectedPath) {
          print(
              'GemmaManager: Copying task file to documents root: $expectedPath');
          await taskFile.copy(expectedPath);
        }
        return expectedPath;
      }

      // Try to find a file that contains similar name components
      final searchTerms = baseFileName
          .toLowerCase()
          .replaceAll('.task', '')
          .split(RegExp(r'[_\-\.]'))
          .where((term) => term.length > 2)
          .toList();

      for (final taskFile in taskFiles) {
        final taskFileName = path.basename(taskFile.path).toLowerCase();
        bool isMatch = false;

        // Check if the task file contains any of our search terms
        for (final term in searchTerms) {
          if (taskFileName.contains(term)) {
            isMatch = true;
            break;
          }
        }

        if (isMatch) {
          final actualFileName = path.basename(taskFile.path);
          print('GemmaManager: Found matching file: $actualFileName');

          // Ensure the file is in the documents root directory
          final expectedPath = path.join(appDocDir.path, actualFileName);
          if (taskFile.path != expectedPath) {
            print(
                'GemmaManager: Copying matching file to documents root: $expectedPath');
            await taskFile.copy(expectedPath);
          }
          return expectedPath;
        }
      }

      // If no specific match found, but we have .task files, use the first one
      if (taskFiles.isNotEmpty) {
        final firstFile = taskFiles.first;
        final firstName = path.basename(firstFile.path);
        print(
            'GemmaManager: No specific match found, using first .task file: $firstName');

        // Ensure the file is in the documents root directory
        final expectedPath = path.join(appDocDir.path, firstName);
        if (firstFile.path != expectedPath) {
          print(
              'GemmaManager: Copying first file to documents root: $expectedPath');
          await firstFile.copy(expectedPath);
        }
        return expectedPath;
      }

      print('GemmaManager: No suitable model file found');
      return null;
    } catch (e) {
      print('GemmaManager: Error resolving model path: $e');
      return null;
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentModelType => _currentModelType;
  String? get currentBackend => _currentBackend;
  bool get hasSession => _session != null;
  bool get hasChat => _chat != null;
}
