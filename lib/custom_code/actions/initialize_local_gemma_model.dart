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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

    // Step 1: Install the model using the model manager
    print('Step 1: Installing model using model manager...');

    try {
      // Get the GemmaManager instance
      final gemmaManager = GemmaManager();
      final modelManager = gemmaManager.modelManager;

      // Get app documents directory for proper model installation
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory(path.join(appDocDir.path, 'gemma_models'));

      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      // Copy model file to the expected location if not already there
      final modelFileName = path.basename(localModelPath);
      final targetModelPath = path.join(modelsDir.path, modelFileName);
      final targetModelFile = File(targetModelPath);

      if (!await targetModelFile.exists() ||
          targetModelPath != localModelPath) {
        print('Copying model file to correct location...');
        await file.copy(targetModelPath);
        print('Model file copied to: $targetModelPath');
      } else {
        print('Model file already in correct location: $targetModelPath');
      }

      // Install the model from the local file using the model manager
      // The model manager expects the file to be in a specific location
      print('Installing model file using model manager...');

      // Use the install method that works with local files
      // Since we have a local file, we need to use installModelFromAsset approach
      // or copy the file to the assets location that the model manager expects

      // For now, let's try to use the model manager's install capabilities
      // by treating our local file as if it were downloaded
      await modelManager.installModelFromAsset(targetModelPath);
      print('Model installed successfully via model manager');
    } catch (installError) {
      print('Model manager installation failed: $installError');
      print('Attempting alternative initialization approach...');

      // If model manager fails, we can still try to initialize directly
      // but this may not work with all Flutter Gemma versions
    }

    // Step 2: Initialize the model using GemmaManager
    print('Step 2: Initializing model...');

    final gemmaManager = GemmaManager();

    // Convert string parameters to proper values for GemmaManager
    final success = await gemmaManager.initializeModel(
      modelType: modelType,
      backend: preferredBackend,
      maxTokens: maxTokens,
      supportImage: supportImage,
      maxNumImages: maxNumImages,
      localModelPath: localModelPath,
    );

    if (success) {
      print('Gemma model initialized successfully!');
      return true;
    } else {
      print('Failed to initialize model through GemmaManager');

      // Step 3: Fallback - try direct Flutter Gemma plugin initialization
      print('Step 3: Attempting direct plugin initialization...');

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

      // Try to create the model directly
      final model = await FlutterGemmaPlugin.instance.createModel(
        modelType: modelTypeEnum,
        preferredBackend: backendEnum,
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: maxNumImages,
      );

      print('Direct plugin initialization successful!');
      return true;
    }
  } catch (e) {
    print('Error in initializeLocalGemmaModel: $e');

    // Provide more specific error messages
    if (e.toString().contains('not installed') ||
        e.toString().contains('model not found')) {
      print('The model needs to be properly installed first.');
      print(
          'This can happen if the model file is not in the expected location');
      print('or the model manager has not processed it correctly.');
      print(
          'Try using installLocalModelFile action first, then retry initialization.');
    } else if (e.toString().contains('file_size')) {
      print('The model file appears to be corrupted or incomplete.');
      print('Please re-download or re-install the model file.');
      print('Try using downloadGemmaModel or installGemmaFromAsset first.');
    } else if (e.toString().contains('RET_CHECK failure')) {
      print('Model file validation failed. The file may be corrupted.');
      print('Please ensure you have a valid model file.');
      print('Gemma models should be in the proper binary format.');
    } else if (e.toString().contains('backend')) {
      print('Backend initialization failed. Try switching to CPU backend.');
      print('GPU backend may not be available on this device.');
    }

    return false;
  }
}
