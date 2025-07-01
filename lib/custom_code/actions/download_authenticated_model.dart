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
      // HARDCODED FIX: Intercept the incorrect URL and replace it
      if (downloadUrl ==
          'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-cpu-int4.task') {
        downloadUrl =
            'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
        print('Applied hardcoded fix for incorrect URL');
      }
      fileName = downloadUrl.split('/').last;
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
  } on SocketException catch (e) {
    String errorMsg =
        'Network Error: Failed to connect to HuggingFace. Please check your internet connection and try again.';
    errorMsg +=
        '\n\nThis can happen on emulators if DNS is not configured correctly.';
    errorMsg += '\nDetails: $e';
    print('ERROR: $errorMsg');
    return null;
  } catch (e) {
    print('Error in downloadAuthenticatedModel: $e');
    return null;
  }
}

String _getModelDownloadUrl(String modelIdentifier) {
  final modelUrls = <String, String>{
    'gemma-3n-e4b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    'gemma3-1b-it':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
  };

  final url = modelUrls[modelIdentifier] ??
      // Default fallback URL
      'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';

  print('Mapped model $modelIdentifier to URL: $url');
  return url;
}

String _getModelFileName(String modelIdentifier) {
  final modelFileNames = <String, String>{
    'gemma-3n-e4b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it': 'gemma-3n-E2B-it-int4.task',
    'gemma3-1b-it': 'gemma3-1b-it-int4.task',
  };

  return modelFileNames[modelIdentifier] ?? 'gemma-3n-E4B-it-int4.task';
}
