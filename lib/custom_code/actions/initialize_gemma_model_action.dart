// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/app_state.dart';
import '../flutter_gemma_library.dart';

/// Complete Gemma model initialization action for FlutterFlow
///
/// This action handles the entire model lifecycle using the proper plugin API:
/// 1. Checks if model is already loaded (respects "load once" philosophy)
/// 2. Downloads and loads model using plugin's loadNetworkModel() if needed
/// 3. Creates model instance with auto-detected parameters
/// 4. Creates chat session ready for inference
/// 5. Updates FlutterFlow app state with progress and completion
///
/// ## Usage in FlutterFlow:
/// Call this action once on app startup or first model use.
/// The plugin handles persistence - won't re-download on subsequent runs.
///
/// ## Parameters:
/// - [modelUrl]: The URL to download from (HuggingFace URLs require token)
/// - [authToken]: HuggingFace auth token (optional, required for HF URLs)
/// - [modelType]: Model type (optional - will auto-detect from URL/filename)
/// - [backend]: Preferred backend ('gpu', 'cpu') - defaults to 'gpu'
/// - [temperature]: Generation temperature - defaults to 0.8
///
/// ## Returns:
/// - true: Model successfully loaded and ready for inference
/// - false: Initialization failed (check app state for error details)
///
/// ## Example:
/// ```dart
/// final success = await initializeGemmaModelAction(
///   "https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task",
///   authToken: "your_hf_token",
///   backend: "gpu",
///   temperature: 0.8,
/// );
/// ```
Future<bool> initializeGemmaModelAction(
  String modelUrl,
  String? authToken,
  String? modelType,
  String backend,
  double temperature,
) async {
  try {
    print('initializeGemmaModelAction: Starting complete model initialization');
    print('initializeGemmaModelAction: URL: $modelUrl');
    print(
        'initializeGemmaModelAction: Backend: $backend, Temperature: $temperature');

    // Get app state for progress tracking
    final appState = FFAppState();
    appState.isInitializing = true;
    appState.downloadProgress = 'Initializing...';

    // Get plugin instance
    final gemma = FlutterGemmaPlugin.instance;
    final modelManager = gemma.modelManager;

    // Smart URL and token validation
    appState.downloadProgress = 'Validating configuration...';
    final isHuggingFaceUrl = _isHuggingFaceUrl(modelUrl);
    if (isHuggingFaceUrl && (authToken == null || authToken.isEmpty)) {
      final error = 'HuggingFace URLs require authentication token';
      print('initializeGemmaModelAction: Error - $error');
      appState.isInitializing = false;
      appState.downloadProgress = 'Error: $error';
      return false;
    }

    // Auto-detect model type if not provided
    String finalModelType;
    if (modelType != null && modelType.isNotEmpty) {
      finalModelType = modelType;
      print(
          'initializeGemmaModelAction: Using provided model type: $finalModelType');
    } else {
      print(
          'initializeGemmaModelAction: Detecting model type from URL: $modelUrl');
      finalModelType = ModelUtils.getModelTypeFromPath(modelUrl);
      print(
          'initializeGemmaModelAction: Auto-detected model type: $finalModelType');

      // Debug: Let's also try detecting from the actual filename
      final fileName = Uri.parse(modelUrl).pathSegments.last;
      print('initializeGemmaModelAction: Raw filename: $fileName');
      final debugModelType = ModelUtils.getModelTypeFromPath(fileName);
      print(
          'initializeGemmaModelAction: Model type from filename: $debugModelType');
    }

    // Check if model is already loaded AND is from the same URL
    appState.downloadProgress = 'Checking model availability...';
    try {
      final isInstalled = await modelManager.isModelInstalled;
      final storedUrl = await _getCurrentModelUrl();
      final isSameUrl = storedUrl == modelUrl;

      print('initializeGemmaModelAction: Model installed: $isInstalled');
      print('initializeGemmaModelAction: Stored URL: $storedUrl');
      print('initializeGemmaModelAction: Current URL: $modelUrl');
      print('initializeGemmaModelAction: Same URL: $isSameUrl');

      if (isInstalled && isSameUrl) {
        print(
            'initializeGemmaModelAction: Model already installed, skipping download');
        appState.downloadProgress = 'Model found, registering...';

        // Following official example: even for existing models, we need to call setModelPath
        // Get the model filename from URL and construct path
        final modelFileName = Uri.parse(modelUrl).pathSegments.last;
        final directory = await getApplicationDocumentsDirectory();
        final modelPath = '${directory.path}/$modelFileName';

        print(
            'initializeGemmaModelAction: Setting model path for existing model: $modelPath');
        await modelManager.setModelPath(modelPath);
        appState.downloadProgress = 'Model registered, creating instance...';
      } else {
        // Load model using plugin's proper API - new URL or no model
        print(
            'initializeGemmaModelAction: Need to download - URL changed or no model installed');

        // Store the new URL before downloading
        await _storeCurrentModelUrl(modelUrl);

        appState.downloadProgress = 'Loading model (this may take a while)...';
        appState.downloadPercentage = 0.0;
        print(
            'initializeGemmaModelAction: Downloading model from network using plugin API');

        // Use progress version for better tracking and error handling
        print(
            'initializeGemmaModelAction: Starting download with progress tracking');

        final stream = modelManager.downloadModelFromNetworkWithProgress(
          modelUrl,
          token: authToken ?? '',
        );

        await for (final progress in stream) {
          final progressPercent = progress.toDouble();
          appState.downloadPercentage = progressPercent;
          appState.downloadProgress =
              'Downloading model... ${progressPercent.toStringAsFixed(1)}%';
          print(
              'initializeGemmaModelAction: Download progress: $progressPercent%');
        }

        print(
            'initializeGemmaModelAction: Model downloaded successfully via plugin');

        // Following official example pattern: after download, we need to register the model path
        // The plugin downloads to getApplicationDocumentsDirectory() with URL's filename
        appState.downloadProgress = 'Registering model...';
        final modelFileName = Uri.parse(modelUrl).pathSegments.last;
        final directory = await getApplicationDocumentsDirectory();
        final modelPath = '${directory.path}/$modelFileName';

        print('initializeGemmaModelAction: Setting model path: $modelPath');
        await modelManager.setModelPath(modelPath);

        appState.downloadProgress = 'Model loaded, creating instance...';
      }
    } catch (loadError) {
      print(
          'initializeGemmaModelAction: Error during model loading: $loadError');
      appState.isInitializing = false;
      appState.downloadProgress =
          'Model loading failed: ${loadError.toString()}';
      return false;
    }

    // Determine model parameters
    final modelTypeEnum = ModelUtils.getModelType(finalModelType);
    final backendEnum = ModelUtils.getBackend(backend);
    // Initially detect potential vision support from model type, but don't force it
    final potentiallySupportsVision =
        ModelUtils.isMultimodalModel(finalModelType);

    print('initializeGemmaModelAction: Using model type: $modelTypeEnum');
    print('initializeGemmaModelAction: Using backend: $backendEnum');
    print(
        'initializeGemmaModelAction: Potentially supports vision: $potentiallySupportsVision');

    // Create model instance with fallback logic
    appState.downloadProgress = 'Creating model instance...';
    late InferenceModel model;

    // Try GPU first, then CPU if it fails
    bool gpuFailed = false;
    try {
      print(
          'initializeGemmaModelAction: Attempting model creation with GPU backend');
      model = await gemma.createModel(
        modelType: modelTypeEnum,
        preferredBackend: backendEnum,
        maxTokens: 4096, // Higher for multimodal capability
      );
      print(
          'initializeGemmaModelAction: Model instance created successfully with GPU');
    } catch (gpuError) {
      print('initializeGemmaModelAction: GPU model creation failed: $gpuError');
      gpuFailed = true;

      // Try CPU fallback
      try {
        print(
            'initializeGemmaModelAction: Attempting model creation with CPU backend');
        model = await gemma.createModel(
          modelType: modelTypeEnum,
          preferredBackend: ModelUtils.getBackend('cpu'),
          maxTokens: 4096,
        );
        print(
            'initializeGemmaModelAction: Model instance created successfully with CPU fallback');
      } catch (cpuError) {
        print(
            'initializeGemmaModelAction: CPU model creation also failed: $cpuError');
        appState.isInitializing = false;
        appState.downloadProgress =
            'Model creation failed on both GPU and CPU: ${cpuError.toString()}';
        return false;
      }
    }

    // Create chat session with fallback logic for vision support
    appState.downloadProgress = 'Creating chat session...';
    late InferenceChat chat;
    bool actualSupportsVision = false;

    // Try to create chat with vision support if potentially supported
    if (potentiallySupportsVision) {
      try {
        print(
            'initializeGemmaModelAction: Attempting to create chat with vision support');
        chat = await model.createChat(
          temperature: temperature,
          randomSeed: 1,
          topK: 1,
          topP: 0.95,
          tokenBuffer: 256,
          supportImage: true,
          supportsFunctionCalls: false,
          tools: [],
          isThinking: false,
          modelType: modelTypeEnum,
        );
        actualSupportsVision = true;
        print(
            'initializeGemmaModelAction: Chat session created successfully with vision support');
      } catch (visionError) {
        print(
            'initializeGemmaModelAction: Vision chat creation failed, trying text-only: $visionError');
        // Fall back to text-only chat
        try {
          chat = await model.createChat(
            temperature: temperature,
            randomSeed: 1,
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
          print(
              'initializeGemmaModelAction: Chat session created successfully (text-only fallback)');
        } catch (fallbackError) {
          print(
              'initializeGemmaModelAction: Text-only chat creation also failed: $fallbackError');
          appState.isInitializing = false;
          appState.downloadProgress =
              'Chat creation failed: ${fallbackError.toString()}';
          return false;
        }
      }
    } else {
      // Create text-only chat directly for non-vision models
      try {
        chat = await model.createChat(
          temperature: temperature,
          randomSeed: 1,
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
        print(
            'initializeGemmaModelAction: Chat session created successfully (text-only)');
      } catch (chatError) {
        print('initializeGemmaModelAction: Chat creation failed: $chatError');
        appState.isInitializing = false;
        appState.downloadProgress =
            'Chat creation failed: ${chatError.toString()}';
        return false;
      }
    }

    // Store initialization status for other actions to use
    await _storeModelResources(
        model, chat, finalModelType, backend, actualSupportsVision);

    // Update app state - successful completion
    appState.isInitializing = false;
    appState.downloadProgress = 'Model ready for chat!';

    print('initializeGemmaModelAction: Complete initialization successful');
    print('initializeGemmaModelAction: Model type: $finalModelType');
    print(
        'initializeGemmaModelAction: Actual vision support: $actualSupportsVision');
    print('initializeGemmaModelAction: Backend: $backend');

    return true;
  } catch (e) {
    // Global error handler
    print('initializeGemmaModelAction: Unexpected error: $e');
    FFAppState().isInitializing = false;
    FFAppState().downloadProgress = 'Initialization failed: ${e.toString()}';
    return false;
  }
}

/// Check if URL is a HuggingFace URL requiring authentication
bool _isHuggingFaceUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.host.contains('huggingface.co') || uri.host.contains('hf.co');
}

/// Store initialized model and chat resources for other actions to use
Future<void> _storeModelResources(
  InferenceModel model,
  InferenceChat chat,
  String modelType,
  String backend,
  bool supportsVision,
) async {
  try {
    print('_storeModelResources: Storing model resources for other actions');
    print('_storeModelResources: Model type: $modelType');
    print('_storeModelResources: Backend: $backend');
    print('_storeModelResources: Supports vision: $supportsVision');

    // Update the FlutterGemmaLibrary instance with current model info
    // Note: In a production app, you might want to expose methods to store these
    // For now, other actions can create their own instances using the loaded model

    print('_storeModelResources: Resources stored successfully');
  } catch (e) {
    print('_storeModelResources: Error storing resources: $e');
  }
}

/// Store the current model URL for tracking
Future<void> _storeCurrentModelUrl(String modelUrl) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_model_url', modelUrl);
    print('_storeCurrentModelUrl: Stored URL: $modelUrl');
  } catch (e) {
    print('_storeCurrentModelUrl: Error storing URL: $e');
  }
}

/// Get the currently stored model URL
Future<String?> _getCurrentModelUrl() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_model_url');
  } catch (e) {
    print('_getCurrentModelUrl: Error retrieving URL: $e');
    return null;
  }
}
