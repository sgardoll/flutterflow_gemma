// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/app_state.dart';
import '../ai_rust_api.dart';

/// Initialize the AI engine with the given model configuration.
///
/// Handles the complete lifecycle:
///   download → register → create model → create chat session
///
/// Updates FFAppState with progress and final status.
///
/// ## Parameters
/// - [modelUrl] — HuggingFace or direct download URL
/// - [authToken] — HuggingFace bearer token (required for HF URLs)
/// - [modelType] — Optional override (auto-detected from URL if empty)
/// - [backend] — 'gpu' (default) or 'cpu'
/// - [temperature] — Generation temperature (default 0.8)
///
/// ## Returns
/// `true` if the engine is ready for chat, `false` otherwise.
Future<bool> aiInitialize(
  String modelUrl,
  String? authToken,
  String? modelType,
  String backend,
  double temperature,
) async {
  final appState = FFAppState();
  final api = AiRustApi.instance;

  try {
    // Reset state before attempting initialization
    appState.update(() {
      appState.isInitializing = true;
      appState.isDownloading = false;
      appState.isModelInitialized = false;
      appState.downloadProgress = 'Initializing...';
      appState.downloadPercentage = 0.0;
    });

    final success = await api.initializeEngine(
      modelUrl: modelUrl,
      authToken: authToken,
      modelType: modelType,
      backend: backend,
      temperature: temperature,
      onProgress: (status, percentage) {
        appState.downloadProgress = status;
        appState.downloadPercentage = percentage;

        // Track download vs init phase
        if (status.toLowerCase().contains('download')) {
          appState.isDownloading = true;
        } else {
          appState.isDownloading = false;
        }
      },
    );

    // Update final state
    appState.update(() {
      appState.isInitializing = false;
      appState.isDownloading = false;
      appState.isModelInitialized = success;
      appState.modelSupportsVision = api.supportsVision;
      appState.downloadProgress =
          success ? 'Model ready for chat!' : 'Initialization failed.';
    });

    // If init succeeded, auto-create a session
    if (success) {
      await api.createSession();
    }

    return success;
  } catch (e) {
    appState.update(() {
      appState.isInitializing = false;
      appState.isDownloading = false;
      appState.isModelInitialized = false;
      appState.downloadProgress = 'Error: ${e.toString()}';
      appState.downloadPercentage = 0.0;
    });

    // Attempt cleanup
    try {
      await api.closeEngine();
    } catch (_) {}

    return false;
  }
}
