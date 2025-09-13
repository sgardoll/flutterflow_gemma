// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
  try {
    print('initializeGemmaModelAction: Starting complete model initialization');
    print('initializeGemmaModelAction: URL: $modelUrl');
    print(
        'initializeGemmaModelAction: Backend: $backend, Temperature: $temperature');

    // Get app state for progress tracking
    final appState = FFAppState();
    appState.isInitializing = true;
    appState.downloadProgress = 'Initializing...';

    // Get the FlutterGemmaLibrary singleton
    final gemmaLibrary = FlutterGemmaLibrary.instance;

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

    // Use the complete initialization method from the library
    // This will handle all the heavy lifting and update the internal state
    print('initializeGemmaModelAction: Delegating to library singleton');

    final success = await gemmaLibrary.initializeModelComplete(
      modelUrl: modelUrl,
      authToken: authToken,
      modelType: modelType,
      backend: backend,
      temperature: temperature,
      appState: appState,
      onProgress: (status, percentage) {
        // Update app state with progress
        appState.downloadProgress = status;
        appState.downloadPercentage = percentage;
        if (status.contains('Downloading')) {
          appState.isDownloading = true;
          appState.fileName = Uri.parse(modelUrl).pathSegments.last;
        } else {
          appState.isDownloading = false;
        }
      },
    );

    if (success) {
      // Update app state - successful completion
      appState.isInitializing = false;
      appState.downloadProgress = 'Model ready for chat!';

      print('initializeGemmaModelAction: Complete initialization successful');
      print(
          'initializeGemmaModelAction: Model type: ${gemmaLibrary.currentModelType}');
      print(
          'initializeGemmaModelAction: Vision support: ${gemmaLibrary.supportsVision}');
      print(
          'initializeGemmaModelAction: Backend: ${gemmaLibrary.currentBackend}');
    } else {
      // Update app state - failed
      appState.isInitializing = false;
      appState.downloadProgress =
          'Initialization failed. Check logs for details.';
      print('initializeGemmaModelAction: Initialization failed');
    }

    return success;
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
