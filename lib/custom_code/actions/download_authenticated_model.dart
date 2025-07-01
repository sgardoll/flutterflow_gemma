// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String?> downloadAuthenticatedModel(
  String modelIdentifier,
  String hfToken,
  Future Function(int downloaded, int total, double percentage)? onProgress,
) async {
  try {
    print('=== downloadAuthenticatedModel START ===');
    print('Model identifier: $modelIdentifier');
    print('Token provided: ${hfToken.isNotEmpty}');

    // Get the app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    String downloadUrl;
    String fileName;

    // Check if it's a custom URL or predefined model
    if (modelIdentifier.startsWith('http')) {
      // Custom URL provided
      downloadUrl = modelIdentifier;
      fileName = modelIdentifier.split('/').last;
      if (!fileName.contains('.')) {
        fileName += '.task'; // Default extension
      }
    } else {
      // Predefined model identifier
      downloadUrl = _getModelDownloadUrl(modelIdentifier);
      fileName = _getModelFileName(modelIdentifier);
    }

    print('Download URL: $downloadUrl');
    print('File name: $fileName');

    final filePath = '${modelsDir.path}/$fileName';
    final file = File(filePath);

    // Check if file already exists
    if (await file.exists()) {
      print('Model file already exists at: $filePath');
      return filePath;
    }

    // Prepare headers for authenticated request
    final headers = <String, String>{
      'Authorization': 'Bearer $hfToken',
      'User-Agent': 'FlutterGemma/1.0',
    };

    print('Starting download...');
    final request = http.Request('GET', Uri.parse(downloadUrl));
    request.headers.addAll(headers);

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      String errorMsg =
          'Download failed with status ${streamedResponse.statusCode}: ${streamedResponse.reasonPhrase}';

      // Provide specific guidance for common errors
      if (streamedResponse.statusCode == 404) {
        errorMsg +=
            '\n\nThis model may not exist at the specified URL. Common causes:';
        errorMsg += '\n• Model identifier "$modelIdentifier" is not available';
        errorMsg += '\n• HuggingFace repository has moved or been renamed';
        errorMsg += '\n• Model file name has changed';
        errorMsg +=
            '\n\nTry using a different model variant or check HuggingFace for available models.';
      } else if (streamedResponse.statusCode == 401 ||
          streamedResponse.statusCode == 403) {
        errorMsg +=
            '\n\nAuthentication failed. Please check your HuggingFace token.';
      }

      print('ERROR: $errorMsg');
      throw Exception(errorMsg);
    }

    final totalBytes = streamedResponse.contentLength ?? 0;
    int downloadedBytes = 0;

    print('Total bytes to download: $totalBytes');

    // Create file sink for writing
    final sink = file.openWrite();

    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      downloadedBytes += chunk.length;

      if (totalBytes > 0 && onProgress != null) {
        final percentage = (downloadedBytes / totalBytes) * 100;
        onProgress(downloadedBytes, totalBytes, percentage);
      }
    }

    await sink.close();

    print('Download completed successfully');
    print('File saved at: $filePath');
    print('Final size: ${await file.length()} bytes');

    return filePath;
  } catch (e) {
    print('Error in downloadAuthenticatedModel: $e');
    return null;
  }
}

String _getModelDownloadUrl(String modelIdentifier) {
  // Map of predefined models to their HuggingFace download URLs
  // ONLY Gemma 3n models have official .task files available
  final modelUrls = <String, String>{
    // ✅ AVAILABLE: Gemma 3n models with official .task files
    'gemma-3-nano-e4b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3-nano-e2b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',

    // Alternative identifiers for the same models
    'gemma-3n-e4b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',

    // ❌ NO OFFICIAL .TASK FILES: These models don't have .task format
    // Using Gemma 3n E4B as fallback for models without .task files
    'paligemma-3b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3-4b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3-2b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    'gemma-1b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
  };

  final url = modelUrls[modelIdentifier] ??
      // Default fallback URL - Gemma 3n E4B (multimodal)
      'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';

  print('Mapped model $modelIdentifier to URL: $url');
  return url;
}

String _getModelFileName(String modelIdentifier) {
  // Map of predefined models to their file names
  final modelFileNames = <String, String>{
    // Gemma 3n models (official .task files)
    'gemma-3-nano-e4b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3-nano-e2b-it': 'gemma-3n-E2B-it-int4.task',
    'gemma-3n-e4b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it': 'gemma-3n-E2B-it-int4.task',

    // Models without .task files (using Gemma 3n files as substitutes)
    'paligemma-3b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3-4b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3-2b-it': 'gemma-3n-E2B-it-int4.task',
    'gemma-1b-it': 'gemma-3n-E2B-it-int4.task',
  };

  return modelFileNames[modelIdentifier] ?? 'gemma-3n-E4B-it-int4.task';
}
