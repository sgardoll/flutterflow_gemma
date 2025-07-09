// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String?> downloadAuthenticatedModel(
  String modelIdentifier,
  String hfToken,
  Future Function(int downloaded, int total, double percentage)? onProgress,
) async {
  /*
   * AVAILABLE GEMMA MODELS:
   * 
   * VISION + TEXT MODELS:
   * - 'gemma-3n-e4b-it': Gemma 3 Nano 4B (vision + text)
   * - 'gemma-3n-e2b-it': Gemma 3 Nano 2B (vision + text)
   * 
   * TEXT-ONLY MODELS:
   * - 'gemma3-1b-web': Web-optimized Gemma3 1B (text-only)
   * - 'gemma3-1b-it': Gemma3 1B (text-only)
   * - 'gemma3-9b': Gemma3 9B (text-only)
   * - 'gemma3-27b': Gemma3 27B (text-only)
   * - 'gemma3n-1b': Gemma3 Nano 1B (text-only)
   * 
   * Usage Examples:
   * await downloadAuthenticatedModel('gemma-3n-e2b-it', token, onProgress);
   * await downloadAuthenticatedModel('gemma3-9b', token, onProgress);
   * await downloadAuthenticatedModel('https://custom-url.com/model.task', token, onProgress);
   */

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
      final fileSize = await file.length();
      print(
          'Model file already exists at: $filePath (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)');
      return filePath;
    } else {
      print('No existing model file found at: $filePath');
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

    // Simple completion confirmation
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
    // Gemma vision models
    'gemma-3n-e4b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',

    // Gemma text-only models
    'gemma3-1b-it':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
    'gemma3-1b-web':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4-web.task',
    'gemma3-9b':
        'https://huggingface.co/google/gemma-3-9b-it/resolve/main/gemma-3-9b-it.task',
    'gemma3-27b':
        'https://huggingface.co/google/gemma-3-27b-it/resolve/main/gemma-3-27b-it.task',
    'gemma3n-1b':
        'https://huggingface.co/google/gemma-3n-1b-it/resolve/main/gemma-3n-1b-it.task',
  };

  final url = modelUrls[modelIdentifier] ??
      // Default to Gemma 3 Nano 2B as it's the most balanced model
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';

  print('Mapped model $modelIdentifier to URL: $url');
  return url;
}

String _getModelFileName(String modelIdentifier) {
  final modelFileNames = <String, String>{
    // Gemma vision models
    'gemma-3n-e4b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it': 'gemma-3n-E2B-it-int4.task',

    // Gemma text-only models
    'gemma3-1b-it': 'gemma3-1b-it-int4.task',
    'gemma3-1b-web': 'gemma3-1b-it-int4-web.task',
    'gemma3-9b': 'gemma-3-9b-it.task',
    'gemma3-27b': 'gemma-3-27b-it.task',
    'gemma3n-1b': 'gemma-3n-1b-it.task',
  };

  return modelFileNames[modelIdentifier] ?? 'gemma-3n-E2B-it-int4.task';
}

/// Get detailed information about available Gemma models
Map<String, dynamic>? getModelInfo(String modelIdentifier) {
  final modelInfo = <String, Map<String, dynamic>>{
    // Gemma vision models
    'gemma-3n-e4b-it': {
      'name': 'Gemma 3 Nano 4B',
      'size': '4B parameters',
      'type': 'vision-text',
      'capabilities': [
        'image-captioning',
        'vqa',
        'text-generation',
        'instruction-following'
      ],
      'memory_requirement': '3GB RAM',
      'optimized_for': 'vision-tasks',
      'formats': ['task'],
      'description': 'Gemma 3 Nano 4B with vision and text capabilities',
    },
    'gemma-3n-e2b-it': {
      'name': 'Gemma 3 Nano 2B',
      'size': '2B parameters',
      'type': 'vision-text',
      'capabilities': [
        'image-captioning',
        'vqa',
        'text-generation',
        'instruction-following'
      ],
      'memory_requirement': '2GB RAM',
      'optimized_for': 'vision-tasks',
      'formats': ['task'],
      'description': 'Gemma 3 Nano 2B with vision and text capabilities',
    },

    // Gemma text-only models
    'gemma3-1b-it': {
      'name': 'Gemma3 1B',
      'size': '1B parameters',
      'type': 'text-only',
      'capabilities': ['text-generation', 'instruction-following'],
      'memory_requirement': '800MB RAM',
      'optimized_for': 'efficiency',
      'formats': ['task'],
      'description': 'Compact Gemma3 1B model for mobile deployment',
    },
    'gemma3-1b-web': {
      'name': 'Gemma3 1B Web',
      'size': '1B parameters',
      'type': 'text-only',
      'capabilities': ['text-generation', 'instruction-following'],
      'memory_requirement': '700MB RAM',
      'optimized_for': 'web',
      'formats': ['task'],
      'description': 'Web-optimized Gemma3 1B model with LiteRT',
    },
    'gemma3-9b': {
      'name': 'Gemma3 9B',
      'size': '9B parameters',
      'type': 'text-only',
      'capabilities': ['text-generation', 'instruction-following', 'reasoning'],
      'memory_requirement': '6GB RAM',
      'optimized_for': 'quality',
      'formats': ['task'],
      'description':
          'High-quality text model with strong reasoning capabilities',
    },
    'gemma3-27b': {
      'name': 'Gemma3 27B',
      'size': '27B parameters',
      'type': 'text-only',
      'capabilities': [
        'text-generation',
        'instruction-following',
        'reasoning',
        'complex-tasks'
      ],
      'memory_requirement': '18GB RAM',
      'optimized_for': 'quality',
      'formats': ['task'],
      'description':
          'Largest Gemma3 model with exceptional reasoning and complex task handling',
    },
    'gemma3n-1b': {
      'name': 'Gemma3 Nano 1B',
      'size': '1B parameters',
      'type': 'text-only',
      'capabilities': ['text-generation', 'instruction-following'],
      'memory_requirement': '800MB RAM',
      'optimized_for': 'efficiency',
      'formats': ['task'],
      'description':
          'Compact Gemma3 Nano model for resource-constrained environments',
    },
  };

  return modelInfo[modelIdentifier];
}

/// Get list of recommended Gemma models for different use cases
Map<String, List<String>> getModelRecommendations() {
  return {
    'web_deployment': ['gemma3-1b-web', 'gemma3n-1b', 'gemma3-1b-it'],
    'mobile_apps': ['gemma3n-1b', 'gemma3-1b-it', 'gemma-3n-e2b-it'],
    'vision_tasks': ['gemma-3n-e2b-it', 'gemma-3n-e4b-it'],
    'text_generation': ['gemma3-9b', 'gemma3-27b', 'gemma3-1b-it'],
    'low_memory': ['gemma3n-1b', 'gemma3-1b-web', 'gemma3-1b-it'],
    'high_quality': ['gemma3-27b', 'gemma3-9b', 'gemma-3n-e4b-it'],
    'balanced': ['gemma-3n-e2b-it', 'gemma3-9b', 'gemma3-1b-it'],
  };
}
