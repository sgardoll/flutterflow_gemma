// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import '/app_state.dart';
import '../ai_rust_api.dart';

/// Download and install a model from a URL.
///
/// Updates [FFAppState] with download progress while the transfer is
/// in progress. The engine does NOT need to be initialized before calling
/// this action — installation is a storage operation only.
///
/// ## Parameters
/// - [downloadUrl] — Direct download URL (HuggingFace or CDN).
/// - [authToken] — HuggingFace bearer token (required for HF URLs).
///
/// ## Returns
/// `Future<dynamic>` — a `Map<String, dynamic>` with keys:
///   - `success` (bool)
///   - `filePath` (String? — local path on success)
///   - `errorMessage` (String? — reason on failure)
Future<dynamic> aiInstallModel(
  String downloadUrl,
  String? authToken,
) async {
  final appState = FFAppState();

  if (downloadUrl.trim().isEmpty) {
    return {
      'success': false,
      'filePath': null,
      'errorMessage': 'Download URL is empty.'
    };
  }

  // Signal download start.
  appState.update(() {
    appState.isDownloading = true;
    appState.downloadProgress = 'Starting download...';
    appState.downloadPercentage = 0.0;
    appState.fileName = Uri.tryParse(downloadUrl)?.pathSegments.last ?? '';
  });

  try {
    final result = await AiRustApi.instance.installModel(
      downloadUrl.trim(),
      authToken: authToken?.trim(),
      onProgress: (downloaded, total, percentage) {
        if (total > 0) {
          final dlMB = (downloaded / (1024 * 1024)).toStringAsFixed(1);
          final totMB = (total / (1024 * 1024)).toStringAsFixed(1);
          appState.downloadProgress = '$dlMB MB / $totMB MB';
          appState.downloadPercentage = percentage;
        }
      },
    );

    appState.update(() {
      appState.isDownloading = false;
      appState.downloadProgress = result.success
          ? 'Download complete!'
          : (result.errorMessage ?? 'Download failed.');
      appState.downloadPercentage = result.success ? 100.0 : 0.0;
    });

    return result.toMap();
  } catch (e) {
    appState.update(() {
      appState.isDownloading = false;
      appState.downloadProgress = 'Download failed: ${e.toString()}';
      appState.downloadPercentage = 0.0;
    });
    return {'success': false, 'filePath': null, 'errorMessage': e.toString()};
  }
}
