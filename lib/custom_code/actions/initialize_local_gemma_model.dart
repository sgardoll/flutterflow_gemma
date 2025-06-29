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
  int numOfThreads,
  double temperature,
  double topK,
  double topP,
  int randomSeed,
) async {
  try {
    print('=== ANDROID DEBUG: initializeLocalGemmaModel ===');
    print('Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');
    print('Model path: $localModelPath');
    print('Model type: $modelType');
    print('Backend: $preferredBackend');
    print('Support image: $supportImage');
    print('Max tokens: $maxTokens');
    
    // Validate the model file exists first
    final modelFile = File(localModelPath);
    print('Checking if model file exists...');
    if (!await modelFile.exists()) {
      print('ANDROID DEBUG: Model file does not exist at path: $localModelPath');
      // Check if file exists in common Android locations
      final appDocDir = await getApplicationDocumentsDirectory();
      final altPath = path.join(appDocDir.path, path.basename(localModelPath));
      print('ANDROID DEBUG: Checking alternative path: $altPath');
      if (await File(altPath).exists()) {
        print('ANDROID DEBUG: Found model at alternative path, updating localModelPath');
        localModelPath = altPath;
      } else {
        print('ANDROID DEBUG: Model file not found at either location');
        return false;
      }
    }

    final fileSize = await modelFile.length();
    print('ANDROID DEBUG: Model file validated successfully');
    print('Model file size: $fileSize bytes');

    // Model file validation
    if (fileSize < 1024 * 1024) {
      print('Error: Model file appears to be too small (less than 1MB)');
      return false;
    }

    print(
        'Model file validation passed. File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Step 1: Install the model file
    print('Step 1: Installing model file...');
    final installSuccess = await installLocalModelFile(localModelPath, null);

    if (!installSuccess) {
      print('Failed to install model file');
      return false;
    }

    // Step 2: Get the model filename for initialization
    final modelFileName = path.basename(localModelPath);
    print('Step 2: Preparing to initialize model: $modelFileName');

    print('Step 3: Using backend: $preferredBackend');

    // Step 4: Initialize using GemmaManager
    print('ANDROID DEBUG Step 4: Initializing through GemmaManager...');
    print('ANDROID DEBUG: About to call GemmaManager().initializeModel with:');
    print('  - modelType: $modelType');
    print('  - backend: $preferredBackend');
    print('  - maxTokens: $maxTokens');
    print('  - supportImage: $supportImage');
    print('  - localModelPath: $modelFileName');
    
    try {
      final gemmaManager = GemmaManager();
      print('ANDROID DEBUG: GemmaManager instance created');
      
      final success = await gemmaManager.initializeModel(
        modelType: modelType,
        backend: preferredBackend,
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: 1, // Default value
        localModelPath: modelFileName, // Pass the filename
      );

      print('ANDROID DEBUG: GemmaManager.initializeModel returned: $success');

      if (success) {
        print('ANDROID DEBUG: Gemma model initialized successfully through GemmaManager!');
        print('ANDROID DEBUG: Model manager state:');
        print('  - isInitialized: ${gemmaManager.isInitialized}');
        print('  - currentModelType: ${gemmaManager.currentModelType}');
        print('  - currentBackend: ${gemmaManager.currentBackend}');

        // Don't create session here - let the setup widget handle it
        print('ANDROID DEBUG: Skipping session creation, letting setup widget handle it');
        return true;
      } else {
        print('ANDROID DEBUG: GemmaManager initialization returned false');
        print('ANDROID DEBUG: This is likely the root cause of the Android issue');
      }
    } catch (e, stackTrace) {
      print('ANDROID DEBUG: Exception in GemmaManager initialization: $e');
      print('ANDROID DEBUG: Stack trace: $stackTrace');
    }

    // Step 5: If GemmaManager fails, try direct plugin initialization
    print('Step 5: Attempting direct plugin initialization...');
    try {
      final plugin = FlutterGemmaPlugin.instance;

      // Verify the model path is set
      final modelManager = plugin.modelManager;
      try {
        await modelManager.setModelPath(modelFileName);
        print('Model path confirmed: $modelFileName');
      } catch (e) {
        print('Failed to set model path: $e');

        // Try to find the model in documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        final fullModelPath = path.join(appDocDir.path, modelFileName);

        if (await File(fullModelPath).exists()) {
          print('Model found at: $fullModelPath');
          await modelManager.setModelPath(modelFileName);
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
        localModelPath: modelFileName,
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
  } catch (e, stackTrace) {
    print('ANDROID DEBUG: Top-level error in initializeLocalGemmaModel: $e');
    print('ANDROID DEBUG: Stack trace: $stackTrace');
    print('ANDROID DEBUG: Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');

    if (e.toString().contains('Gemma Model is not installed')) {
      print('ANDROID DEBUG: Model not installed error');
      print('The model needs to be properly installed first.');
      print(
          'This can happen if the model file is not in the expected location');
      print('or the model manager has not processed it correctly.');
      print(
          'Try using installLocalModelFile action first, then retry initialization.');
    } else if (e.toString().contains('failedToInitializeEngine')) {
      print('ANDROID DEBUG: Engine initialization failed');
      print('The model engine failed to initialize.');
      print('This usually indicates:');
      print('1. The model file is corrupted or incomplete');
      print('2. The model format is not compatible with this device');
      print('3. Insufficient memory or resources');
      print('4. The model file path is incorrect');
      if (Platform.isAndroid) {
        print('5. Android-specific: App permissions or security restrictions');
        print('6. Android-specific: Native library loading issues');
      }
    } else if (e.toString().contains('open() failed')) {
      print('Failed to open the model file.');
      print('Check that the model file exists and is readable.');
    }

    return false;
  }
}
