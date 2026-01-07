// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'index.dart'; // Imports other custom actions

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
  final appState = FFAppState();

  try {
    print('initializeGemmaModelAction: Starting complete model initialization');
    print('initializeGemmaModelAction: URL: $modelUrl');
    print(
        'initializeGemmaModelAction: Backend: $backend, Temperature: $temperature');

    // Reset any previous error state and set initializing
    _resetErrorState(appState);
    appState.isInitializing = true;
    appState.downloadProgress = 'Initializing...';

    // Smart URL and token validation
    appState.downloadProgress = 'Validating configuration...';
    if (!_validateConfiguration(modelUrl, authToken, appState)) {
      return false;
    }

    // Use the FlutterGemmaLibrary's complete initialization method
    final gemmaLibrary = FlutterGemmaLibrary.instance;

    // Step 1: Load the model using the plugin's proper API
    appState.downloadProgress = 'Loading model...';
    appState.isDownloading = true;
    appState.fileName = Uri.parse(modelUrl).pathSegments.last;

    print('initializeGemmaModelAction: Loading model from: $modelUrl');

    try {
      // Use the library's complete initialization method which handles everything
      final success = await gemmaLibrary.initializeModelComplete(
        modelUrl: modelUrl,
        authToken: authToken,
        modelType: modelType,
        backend: backend,
        temperature: temperature,
        onProgress: (status, percentage) {
          appState.downloadProgress = status;
          appState.downloadPercentage = percentage;
        },
        appState: appState,
      );

      if (!success) {
        print('initializeGemmaModelAction: Model initialization failed');
        _setErrorState(appState, 'Model initialization failed');
        return false;
      }

      print('initializeGemmaModelAction: Model loaded successfully');
      appState.isDownloading = false;
    } catch (loadError) {
      print('initializeGemmaModelAction: Model loading failed: $loadError');
      _setErrorState(appState, 'Model loading failed: ${loadError.toString()}');
      return false;
    }

    // The initializeModelComplete method handles everything including:
    // - Model downloading and loading
    // - Model instance creation
    // - Chat session creation
    // - Resource storage in the library

    // Update final app state
    appState.isInitializing = false;
    appState.isModelInitialized = true;
    appState.modelSupportsVision = gemmaLibrary.supportsVision;
    appState.downloadProgress = 'Model ready for chat!';

    print('initializeGemmaModelAction: Initialization completed successfully');
    return true;
  } catch (e) {
    // Global error handler with improved error recovery
    print('initializeGemmaModelAction: Unexpected error: $e');
    _handleCriticalError(appState, e);
    return false;
  }
}

/// Reset error state before attempting new initialization
void _resetErrorState(FFAppState appState) {
  appState.update(() {
    appState.isInitializing = false;
    appState.isDownloading = false;
    appState.isModelInitialized = false;
    appState.downloadProgress = '';
    appState.downloadPercentage = 0.0;
    appState.fileName = '';
  });
}

/// Set error state with user-friendly message
void _setErrorState(FFAppState appState, String error) {
  appState.update(() {
    appState.isInitializing = false;
    appState.isDownloading = false;
    appState.isModelInitialized = false;
    appState.downloadProgress = error;
    appState.downloadPercentage = 0.0;
  });
}

/// Handle critical errors that may require cleanup
Future<void> _handleCriticalError(FFAppState appState, dynamic error) async {
  appState.update(() {
    appState.isInitializing = false;
    appState.isDownloading = false;
    appState.isModelInitialized = false;
    appState.downloadProgress = 'Initialization failed: ${error.toString()}';
    appState.downloadPercentage = 0.0;
  });

// Attempt to cleanup any partially initialized resources
  try {
    final gemmaLibrary = FlutterGemmaLibrary.instance;
    await gemmaLibrary.closeModel().catchError((cleanupError) {
      print(
          'initializeGemmaModelAction: CRITICAL - Error during cleanup: $cleanupError');
    });
  } catch (cleanupError) {
    print(
        'initializeGemmaModelAction: CRITICAL - Error initiating cleanup: $cleanupError');
    // Critical since we couldn't even start cleanup
  }
}

/// Validate configuration parameters
bool _validateConfiguration(
    String modelUrl, String? authToken, FFAppState appState) {
  final isHuggingFaceUrl = _isHuggingFaceUrl(modelUrl);

  if (isHuggingFaceUrl && (authToken == null || authToken.isEmpty)) {
    final error = 'HuggingFace URLs require authentication token';
    print('initializeGemmaModelAction: Error - $error');
    _setErrorState(appState, error);
    return false;
  }

  if (!_isSupportedModelFile(modelUrl)) {
    final error =
        'Unsupported model file. Use a .task, .tflite, or .bin LiteRT model.';
    print('initializeGemmaModelAction: Error - $error');
    _setErrorState(appState, error);
    return false;
  }

  return true;
}

/// Check if URL is a HuggingFace URL requiring authentication
bool _isHuggingFaceUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.host.contains('huggingface.co') || uri.host.contains('hf.co');
}

/// Check for supported LiteRT/MediaPipe model formats.
bool _isSupportedModelFile(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final path = uri.path.toLowerCase();
  return path.endsWith('.task') ||
      path.endsWith('.tflite') ||
      path.endsWith('.bin');
}
