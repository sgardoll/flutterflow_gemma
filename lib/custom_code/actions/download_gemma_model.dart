// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_gemma/flutter_gemma.dart';
import '../GemmaManager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<bool> downloadGemmaModel(
  String modelUrl,
  String? loraUrl,
  Future Function(int progress)? onProgress,
) async {
  try {
    print('Starting model download from: $modelUrl');

    // Extract filename from URL
    final fileName = modelUrl.split('/').last.split('?').first;

    // Check if model already exists in the app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelPath = path.join(appDocDir.path, fileName);
    final modelFile = File(modelPath);

    if (await modelFile.exists()) {
      print('Model file already exists at: $modelPath');
      final fileSize = await modelFile.length();
      print('File size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');

      // Register the existing model with flutter_gemma
      try {
        final modelManager = FlutterGemmaPlugin.instance.modelManager;

        // Clear any existing model
        try {
          await modelManager.deleteModel();
          print('Cleared existing model registration');
        } catch (e) {
          print('No existing model to clear: $e');
        }

        await Future.delayed(Duration(milliseconds: 500));

        // Register with just the filename
        print('Registering existing model: $fileName');
        await modelManager.setModelPath(fileName);
        print('Existing model registered successfully');

        return true;
      } catch (e) {
        print('Failed to register existing model: $e');
        // Continue with download if registration fails
      }
    }

    // Use the GemmaManager to download
    final modelManager = GemmaManager().modelManager;

    // Subscribe to progress updates
    final progressStream = modelManager.downloadModelFromNetworkWithProgress(
      modelUrl,
      loraUrl: loraUrl,
    );

    bool downloadCompleted = false;

    await for (final progress in progressStream) {
      print('Download progress: $progress%');

      if (onProgress != null) {
        await onProgress(progress);
      }

      // Check if download is complete
      if (progress >= 100) {
        downloadCompleted = true;
        print('Download completed successfully');
      }
    }

    if (!downloadCompleted) {
      print('Download did not complete successfully');
      return false;
    }

    // Add a delay to ensure the model is properly saved
    await Future.delayed(Duration(seconds: 1));

    // The flutter_gemma plugin should have downloaded the model to the correct location
    // Let's verify it exists and register it
    if (await modelFile.exists()) {
      print('Model file verified at: $modelPath');

      // Register with just the filename
      try {
        await FlutterGemmaPlugin.instance.modelManager.setModelPath(fileName);
        print('Model registered with flutter_gemma');
      } catch (e) {
        print('Warning: Could not register model: $e');
      }
    } else {
      print(
          'Warning: Model file not found after download at expected location');

      // Try to find it in the app directory
      final files = await appDocDir.list().toList();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.task')) {
          print('Found model file: ${entity.path}');
          final foundFileName = path.basename(entity.path);

          try {
            await FlutterGemmaPlugin.instance.modelManager
                .setModelPath(foundFileName);
            print('Registered found model: $foundFileName');
            return true;
          } catch (e) {
            print('Could not register found model: $e');
          }
        }
      }
    }

    print('Model download and registration completed');
    return true;
  } catch (e) {
    print('Error downloading model: $e');

    if (e.toString().contains('403') || e.toString().contains('401')) {
      print(
          'Authentication error. The model might require authentication or access permissions.');
      print('Please ensure you have access to the model on HuggingFace.');
    } else if (e.toString().contains('404')) {
      print('Model not found at the specified URL.');
      print('Please check the URL is correct.');
    } else if (e.toString().contains('network')) {
      print('Network error. Please check your internet connection.');
    }

    return false;
  }
}
