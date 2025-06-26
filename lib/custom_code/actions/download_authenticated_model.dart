// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String?> downloadAuthenticatedModel(
  String modelName,
  String huggingFaceToken,
  Future Function(int downloaded, int total, double percentage)? onProgress,
) async {
  try {
    // Model URLs mapping
    final Map<String, String> modelUrls = {
      'gemma-3-4b-it':
          'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
      'gemma-3-2b-it':
          'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
      'gemma-1b-it':
          'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
    };

    final modelUrl = modelUrls[modelName];
    if (modelUrl == null) {
      print('Error: Unknown model name: $modelName');
      return null;
    }

    // Get the app's documents directory
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(directory.path, 'models'));

    // Create models directory if it doesn't exist
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // Extract filename from URL
    final fileName = modelUrl.split('/').last;
    final filePath = path.join(modelsDir.path, fileName);
    final file = File(filePath);

    // Check if file already exists
    if (await file.exists()) {
      final fileSize = await file.length();
      print('Model file already exists: $filePath (${fileSize} bytes)');
      return filePath;
    }

    print('Downloading model from: $modelUrl');
    print('Saving to: $filePath');

    // Download with authentication and progress tracking
    final headers = <String, String>{
      'Authorization': 'Bearer $huggingFaceToken',
      'User-Agent': 'FlutterFlow-App/1.0',
    };

    final request = http.Request('GET', Uri.parse(modelUrl));
    request.headers.addAll(headers);

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      final contentLength = streamedResponse.contentLength ?? 0;
      print(
          'Total file size: ${contentLength} bytes (${(contentLength / 1024 / 1024 / 1024).toStringAsFixed(2)} GB)');

      if (onProgress != null && contentLength > 0) {
        await onProgress(0, contentLength, 0.0);
      }

      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);

        if (onProgress != null && contentLength > 0) {
          final percentage = (downloadedBytes / contentLength) * 100;
          await onProgress(downloadedBytes, contentLength, percentage);
        }
      }

      await sink.close();
      final fileSize = await file.length();

      print('Model downloaded successfully!');
      print('File saved to: $filePath');
      print('File size: ${fileSize} bytes');

      return filePath;
    } else if (streamedResponse.statusCode == 401) {
      print('Error: Authentication failed. Check your Hugging Face token.');
      print('Make sure you have access to the model repository.');
      return null;
    } else if (streamedResponse.statusCode == 404) {
      print('Error: Model file not found at URL: $modelUrl');
      return null;
    } else {
      print('Error downloading model: ${streamedResponse.statusCode}');
      print('Response reason: ${streamedResponse.reasonPhrase}');
      return null;
    }
  } catch (e) {
    print('Error in downloadAuthenticatedModel: $e');
    return null;
  }
}
