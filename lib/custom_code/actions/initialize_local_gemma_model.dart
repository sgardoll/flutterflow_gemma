// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'dart:io';

Future<bool> initializeLocalGemmaModel(
  String localModelPath,
  String modelType,
  String preferredBackend,
  int maxTokens,
  bool supportImage,
  int maxNumImages,
) async {
  try {
    print('Initializing Gemma model from local file: $localModelPath');

    // Validate the local model file exists and has reasonable size
    final file = File(localModelPath);
    if (!await file.exists()) {
      print('Error: Model file does not exist at path: $localModelPath');
      return false;
    }

    final fileSize = await file.length();
    print('Model file size: $fileSize bytes');

    // Model files should be at least a few MB. 1MB is too small for any model.
    if (fileSize < 1024 * 1024) {
      // Less than 1MB
      print(
          'Error: Model file appears to be corrupted or incomplete. Size: $fileSize bytes');
      print('Expected model files to be much larger (typically 100MB+)');
      return false;
    }

    print(
        'Model file validation passed. File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Convert string parameters to enums
    ModelType modelTypeEnum;
    switch (modelType.toLowerCase()) {
      case 'gemma':
      case 'gemmait':
      case 'gemma-it':
      case 'gemma_it':
      case 'gemma-3-4b-it':
      case 'gemma-3-2b-it':
      case 'gemma-1b-it':
        modelTypeEnum = ModelType.gemmaIt;
        break;
      case 'deepseek':
      case 'deep-seek':
      case 'deep_seek':
        modelTypeEnum = ModelType.deepSeek;
        break;
      case 'general':
        modelTypeEnum = ModelType.general;
        break;
      default:
        modelTypeEnum = ModelType.gemmaIt;
    }

    PreferredBackend backendEnum;
    switch (preferredBackend.toLowerCase()) {
      case 'gpu':
        backendEnum = PreferredBackend.gpu;
        break;
      case 'cpu':
        backendEnum = PreferredBackend.cpu;
        break;
      case 'gpufloat16':
      case 'gpu_float16':
      case 'gpu-float16':
        backendEnum = PreferredBackend.gpuFloat16;
        break;
      default:
        backendEnum = PreferredBackend.gpu;
    }

    // For local model files, we need to use a different approach
    // The flutter_gemma plugin expects models to be properly installed
    print('Note: The model file exists but may need to be properly installed.');
    print(
        'Consider using the installGemmaFromAsset or downloadGemmaModel actions first.');

    // Try to create the model - this will work if the model is already properly installed
    final model = await FlutterGemmaPlugin.instance.createModel(
      modelType: modelTypeEnum,
      preferredBackend: backendEnum,
      maxTokens: maxTokens,
      supportImage: supportImage,
      maxNumImages: maxNumImages,
    );

    print('Gemma model initialized successfully!');
    return true;
  } catch (e) {
    print('Error in initializeLocalGemmaModel: $e');

    // Provide more specific error messages
    if (e.toString().contains('file_size')) {
      print('The model file appears to be corrupted or incomplete.');
      print('Please re-download or re-install the model file.');
      print('Try using downloadGemmaModel or installGemmaFromAsset first.');
    } else if (e.toString().contains('RET_CHECK failure')) {
      print('Model file validation failed. The file may be corrupted.');
      print('Please ensure you have a valid model file.');
      print('Gemma models should be in the proper binary format.');
    }

    return false;
  }
}
