// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../flutter_gemma_library.dart';
import '/app_state.dart';

/// Download a Gemma model from a network URL
///
/// This action downloads model files from custom URLs or authenticated
/// Hugging Face repositories. Use Library Values in FlutterFlow to store
/// your model download URLs.
///
/// ## Usage in FlutterFlow:
/// 1. Create a Library Value with your model download URL
/// 2. Call this action with the URL and optional HuggingFace token
/// 3. The model will be downloaded to the device storage
///
/// ## Parameters:
/// - [huggingFaceToken]: Optional authentication token for HuggingFace models
/// - [downloadUrl]: The direct download URL for the model file
/// - [onProgressUpdate]: Optional callback to receive download progress updates
///
/// ## Returns:
/// - String: The local file path of the downloaded model (success)
/// - null: Download failed (check logs for details)
///
/// ## Progress Updates:
/// The onProgressUpdate callback receives a formatted string with current progress:
/// - "Starting download..."
/// - "150MB / 330MB"
/// - "Download completed!"
/// - "Model already exists (330MB)"
///
/// ## Example URLs:
/// - Direct: "https://example.com/path/to/model.task"
/// - HuggingFace: "https://huggingface.co/google/gemma-2b-it/resolve/main/model.task"
///
/// ## FlutterFlow Usage with Progress:
/// ```dart
/// String progressText = "";
///
/// final result = await downloadModelAction(
///   token,
///   url,
///   (progress) => setState(() => progressText = progress)
/// );
/// ```
Future<String?> downloadModelAction(
  String? huggingFaceToken,
  String downloadUrl,
  Future Function(String downloadProgress)? onProgressUpdate,
) async {
  try {
    if (downloadUrl.trim().isEmpty) {
      print('downloadModelAction: Error - Download URL is empty');
      return null;
    }

    print('downloadModelAction: Starting download from $downloadUrl');

    // Get app state instance to update progress
    final appState = FFAppState();

    // Set downloading state
    appState.isDownloading = true;
    appState.downloadPercentage = 0.0;
    appState.downloadProgress = 'Starting download...';

    // Get the library instance and model manager
    final gemmaLibrary = FlutterGemmaLibrary.instance;
    final modelManager = gemmaLibrary.modelManager;

    // Start download with progress tracking
    final filePath = await modelManager.downloadModelFromNetwork(
      downloadUrl.trim(),
      huggingFaceToken: huggingFaceToken?.trim(),
      onProgress: (downloaded, total, percentage) {
        if (total > 0) {
          // Update app state with progress
          appState.downloadPercentage = percentage;
          final downloadedMB = (downloaded / (1024 * 1024)).toStringAsFixed(1);
          final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
          appState.downloadProgress = '$downloadedMB MB / $totalMB MB';

          // Call the optional callback if provided
          if (onProgressUpdate != null) {
            onProgressUpdate(appState.downloadProgress);
          }

          print(
              'downloadModelAction: Progress ${percentage.toStringAsFixed(1)}% ($downloaded/$total bytes)');
        }
      },
    );

    // Clear downloading state
    appState.isDownloading = false;

    if (filePath != null) {
      appState.downloadProgress = 'Download completed!';
      print('downloadModelAction: Download completed successfully');
      print('downloadModelAction: Model saved to: $filePath');
      return filePath;
    } else {
      appState.downloadProgress = 'Download failed';
      print('downloadModelAction: Download failed');
      return null;
    }
  } catch (e) {
    // Clear downloading state on error
    FFAppState().isDownloading = false;
    FFAppState().downloadProgress = 'Download failed: ${e.toString()}';
    print('downloadModelAction: Error - $e');
    return null;
  }
}
