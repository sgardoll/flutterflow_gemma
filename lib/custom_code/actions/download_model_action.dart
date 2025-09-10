// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../flutter_gemma_library.dart';

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
///
/// ## Returns:
/// - String: The local file path of the downloaded model (success)
/// - null: Download failed (check logs for details)
///
/// ## Example URLs:
/// - Direct: "https://example.com/path/to/model.task"
/// - HuggingFace: "https://huggingface.co/google/gemma-2b-it/resolve/main/model.task"
Future<String?> downloadModelAction(
  String? huggingFaceToken,
  String downloadUrl,
) async {
  try {
    if (downloadUrl.trim().isEmpty) {
      print('downloadModelAction: Error - Download URL is empty');
      return null;
    }

    print('downloadModelAction: Starting download from $downloadUrl');

    // Get the library instance and model manager
    final gemmaLibrary = FlutterGemmaLibrary.instance;
    final modelManager = gemmaLibrary.modelManager;

    // Start download with optional progress tracking
    final filePath = await modelManager.downloadModelFromNetwork(
      downloadUrl.trim(),
      huggingFaceToken: huggingFaceToken?.trim(),
      onProgress: (downloaded, total, percentage) {
        if (total > 0) {
          print(
              'downloadModelAction: Progress ${percentage.toStringAsFixed(1)}% ($downloaded/$total bytes)');
        }
      },
    );

    if (filePath != null) {
      print('downloadModelAction: Download completed successfully');
      print('downloadModelAction: Model saved to: $filePath');
      return filePath;
    } else {
      print('downloadModelAction: Download failed');
      return null;
    }
  } catch (e) {
    print('downloadModelAction: Error - $e');
    return null;
  }
}
