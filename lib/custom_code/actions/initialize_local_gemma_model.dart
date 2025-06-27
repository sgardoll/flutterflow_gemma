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
import 'install_local_model_file.dart';

Future<bool> initializeLocalGemmaModel(
  String localModelPath,
  String modelType,
  String preferredBackend,
  int maxTokens,
  bool supportImage,
  int numOfThreads,
  double temperature,
  double topK,
  double topP,
  int randomSeed,
) async {
  try {
    // Step 0: Debug current state
    print('=== Starting Gemma Model Initialization ===');
    print('Input localModelPath: $localModelPath');
    print('Model type: $modelType');
    print('Backend: $preferredBackend');

    // Get the model filename for initialization
    final modelFileName = path.basename(localModelPath);
    print('Extracted filename: $modelFileName');

    // Step 1: Check if this is a full path or just a filename
    bool isFullPath = localModelPath.contains('/');
    File? modelFile;

    if (isFullPath) {
      // This is a full path - validate the file exists
      modelFile = File(localModelPath);
      if (!await modelFile.exists()) {
        print('Error: Model file does not exist at full path: $localModelPath');

        // Try to find the file in the documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        final altPath = path.join(appDocDir.path, modelFileName);
        final altFile = File(altPath);

        if (await altFile.exists()) {
          print('Found model file in documents directory: $altPath');
          modelFile = altFile;
        } else {
          print('Model file not found in documents directory either: $altPath');
          return false;
        }
      }

      final fileSize = await modelFile.length();
      print(
          'Model file validation passed. File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');

      // Model file validation
      if (fileSize < 1024 * 1024) {
        print('Error: Model file appears to be too small (less than 1MB)');
        return false;
      }

      // Install the model file
      print('Step 1: Installing model file...');
      final installSuccess = await installLocalModelFile(localModelPath, null);

      if (!installSuccess) {
        print('Failed to install model file');
        return false;
      }
    } else {
      // This is just a filename - check if it exists in documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final fullPath = path.join(appDocDir.path, localModelPath);
      modelFile = File(fullPath);

      if (!await modelFile.exists()) {
        print(
            'Error: Model file does not exist in documents directory: $fullPath');

        // Try to find any .task file that contains similar name components
        print('Searching for similar model files...');
        final files = await appDocDir.list().toList();
        final taskFiles = files
            .where((f) => f is File && f.path.endsWith('.task'))
            .cast<File>();

        for (final taskFile in taskFiles) {
          final taskFileName = path.basename(taskFile.path);
          print('Found task file: $taskFileName');

          // Check if this might be the intended file (case-insensitive partial match)
          if (taskFileName.toLowerCase().contains('gemma') ||
              taskFileName.toLowerCase().contains(
                  modelFileName.toLowerCase().split('.').first.toLowerCase())) {
            print('Potential match found: $taskFileName');
            // Update the filename to use the actual file found
            final actualFile = File(taskFile.path);
            if (await actualFile.exists()) {
              print('Using found model file: ${taskFile.path}');
              modelFile = actualFile;
              // Update modelFileName to match the actual file
              final actualFileName = path.basename(taskFile.path);
              print('Updated model filename to: $actualFileName');
              break;
            }
          }
        }

        if (modelFile == null || !await modelFile.exists()) {
          print('No suitable model file found');
          return false;
        }
      }
    }

    // Use the actual filename from the resolved file path
    final actualModelFileName = path.basename(modelFile!.path);
    print('Step 2: Using actual model filename: $actualModelFileName');

    print('Step 3: Using backend: $preferredBackend');

    // Step 4: Initialize using GemmaManager
    print('Step 4: Initializing through GemmaManager...');
    try {
      final success = await GemmaManager().initializeModel(
        modelType: modelType,
        backend: preferredBackend,
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: 1, // Default value
        localModelPath: actualModelFileName, // Use the actual filename found
      );

      if (success) {
        print('Gemma model initialized successfully through GemmaManager!');

        // Create a session with the provided parameters
        final sessionSuccess = await GemmaManager().createSession(
          temperature: temperature.clamp(0.0, 2.0),
          randomSeed: randomSeed,
          topK: topK.clamp(1, 40).toInt(),
        );

        if (sessionSuccess) {
          print('Session created successfully!');
          return true;
        } else {
          print('Model initialized but failed to create session');
          return true; // Still consider it successful
        }
      } else {
        print('GemmaManager initialization returned false');
      }
    } catch (e) {
      print('Error initializing Gemma model through GemmaManager: $e');
    }

    // Step 5: If GemmaManager fails, try direct plugin initialization
    print('Step 5: Attempting direct plugin initialization...');
    try {
      final plugin = FlutterGemmaPlugin.instance;

      // Verify the model path is set
      final modelManager = plugin.modelManager;
      try {
        await modelManager.setModelPath(actualModelFileName);
        print('Model path confirmed: $actualModelFileName');
      } catch (e) {
        print('Failed to set model path: $e');

        // Try to find the model in documents directory again
        final appDocDir = await getApplicationDocumentsDirectory();
        final fullModelPath = path.join(appDocDir.path, actualModelFileName);

        if (await File(fullModelPath).exists()) {
          print('Model found at: $fullModelPath');
          await modelManager.setModelPath(actualModelFileName);
          print('Model path set using found file');
        } else {
          print('Model file not found at expected location: $fullModelPath');
          return false;
        }
      }

      // Create the model using the correct method from GemmaManager
      PreferredBackend backend;
      switch (preferredBackend.toLowerCase()) {
        case 'gpu':
          backend = PreferredBackend.gpu;
          break;
        case 'gpufloat16':
        case 'gpu_float16':
        case 'gpu-float16':
          backend = PreferredBackend.gpuFloat16;
          break;
        case 'gpumixed':
        case 'gpu_mixed':
        case 'gpu-mixed':
          backend = PreferredBackend.gpuMixed;
          break;
        case 'gpufull':
        case 'gpu_full':
        case 'gpu-full':
          backend = PreferredBackend.gpuFull;
          break;
        case 'tpu':
          backend = PreferredBackend.tpu;
          break;
        default:
          backend = PreferredBackend.cpu;
      }

      ModelType modelTypeEnum;
      switch (modelType.toLowerCase()) {
        case 'gemma':
        case 'gemmait':
        case 'gemma-it':
        case 'gemma_it':
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

      // Create the model directly
      final model = await plugin.createModel(
        modelType: modelTypeEnum,
        preferredBackend: backend,
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: 1,
      );

      print('Direct plugin initialization successful!');

      // Create a session
      final session = await model.createSession(
        temperature: temperature.clamp(0.0, 2.0),
        randomSeed: randomSeed,
        topK: topK.clamp(1, 40).toInt(),
      );

      print('Session created via direct plugin!');

      // Close the model and session since we created them locally
      await session.close();
      await model.close();

      return true;
    } catch (e) {
      print('Direct plugin initialization failed: $e');
    }

    // Step 6: Try with CPU backend as final fallback
    print('Step 6: Trying CPU backend as final fallback...');
    try {
      final success = await GemmaManager().initializeModel(
        modelType: modelType,
        backend: 'cpu',
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: 1,
        localModelPath: actualModelFileName,
      );

      if (success) {
        print('CPU fallback initialization successful!');
        return true;
      }
    } catch (e) {
      print('CPU backend initialization also failed: $e');
    }

    print('All initialization attempts failed');
    return false;
  } catch (e) {
    print('Error in initializeLocalGemmaModel: $e');

    if (e.toString().contains('Gemma Model is not installed')) {
      print('The model needs to be properly installed first.');
      print(
          'This can happen if the model file is not in the expected location');
      print('or the model manager has not processed it correctly.');
      print(
          'Try using installLocalModelFile action first, then retry initialization.');
    } else if (e.toString().contains('failedToInitializeEngine')) {
      print('The model engine failed to initialize.');
      print('This usually indicates:');
      print('1. The model file is corrupted or incomplete');
      print('2. The model format is not compatible with this device');
      print('3. Insufficient memory or resources');
      print('4. The model file path is incorrect');
    } else if (e.toString().contains('open() failed')) {
      print('Failed to open the model file.');
      print('Check that the model file exists and is readable.');
    }

    return false;
  }
}
