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
    print(
        'Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');
    print('Model path: $localModelPath');
    print('Model type: $modelType');
    print('Backend: $preferredBackend');
    print('Support image: $supportImage');
    print('Max tokens: $maxTokens');

    // Validate the model file exists first
    final modelFile = File(localModelPath);
    print('Checking if model file exists...');
    if (!await modelFile.exists()) {
      print(
          'ANDROID DEBUG: Model file does not exist at path: $localModelPath');
      // Check if file exists in common Android locations
      final appDocDir = await getApplicationDocumentsDirectory();
      final altPath = path.join(appDocDir.path, path.basename(localModelPath));
      print('ANDROID DEBUG: Checking alternative path: $altPath');
      if (await File(altPath).exists()) {
        print(
            'ANDROID DEBUG: Found model at alternative path, updating localModelPath');
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

    // Platform-specific debugging: Check where model files are actually located
    print(
        '🔍 ${Platform.isIOS ? "iOS" : "ANDROID"} DEBUG: Checking model file locations...');
    try {
      // Check platform-specific plugin directory
      late Directory pluginDirectory;
      String platformName;
      if (Platform.isIOS) {
        pluginDirectory = await getApplicationDocumentsDirectory();
        platformName = "iOS Documents (plugin working dir)";
      } else {
        pluginDirectory = await getApplicationSupportDirectory();
        platformName = "Android Support (plugin working dir)";
      }

      print('📁 $platformName: ${pluginDirectory.path}');

      final pluginFiles = await pluginDirectory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.task'))
          .toList();
      print('📄 Found ${pluginFiles.length} .task files in plugin directory:');
      for (final file in pluginFiles) {
        final fileName = path.basename(file.path);
        final fileSize = await (file as File).length();
        print(
            '   - $fileName (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)');
      }

      // Check the specific model file we're looking for
      final targetModelPath = path.join(pluginDirectory.path, modelFileName);
      final targetExists = await File(targetModelPath).exists();
      print(
          '🎯 Target model file ($modelFileName) exists in plugin dir: $targetExists');
      if (targetExists) {
        final size = await File(targetModelPath).length();
        print('📏 File size: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB');
      }

      // Also check the other directory for reference
      try {
        final otherDirectory = Platform.isIOS
            ? await getApplicationSupportDirectory()
            : await getApplicationDocumentsDirectory();
        final otherName = Platform.isIOS ? "App Support" : "Documents";
        print('📁 $otherName directory: ${otherDirectory.path}');

        final otherFiles = await otherDirectory
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.task'))
            .toList();
        print('📄 Found ${otherFiles.length} .task files in $otherName:');
        for (final file in otherFiles) {
          print('   - ${path.basename(file.path)}');
        }
      } catch (e) {
        print('⚠️  Could not access other directory: $e');
      }
    } catch (e) {
      print('⚠️  Error during platform debugging: $e');
    }

    print('Step 3: Using backend: $preferredBackend');

    // Step 3: Initialize using GemmaManager
    print(
        '${Platform.isIOS ? "iOS" : "ANDROID"} DEBUG Step 3: Initializing through GemmaManager...');
    print('DEBUG: About to call GemmaManager().initializeModel with:');
    print('  - modelType: $modelType');
    print('  - backend: $preferredBackend');
    print('  - maxTokens: $maxTokens');
    print('  - supportImage: $supportImage');
    print('  - localModelPath: $modelFileName');

    try {
      final gemmaManager = GemmaManager();
      print('DEBUG: GemmaManager instance created');

      print('DEBUG: Initializing with filename only: $modelFileName');
      print(
          'DEBUG: Plugin should find model in its ${Platform.isIOS ? "Documents" : "Support"} directory');

      // ANDROID FIX: Pass the absolute path to the model on Android.
      final path_for_initialization =
          Platform.isAndroid ? localModelPath : modelFileName;

      print(
          'DEBUG: Initializing with path for platform: $path_for_initialization');

      final success = await gemmaManager.initializeModel(
        modelType: modelType,
        backend: preferredBackend,
        maxTokens: maxTokens,
        supportImage: supportImage,
        maxNumImages: 1, // Default value
        localModelPath: path_for_initialization, // Pass platform-specific path
      );

      print('DEBUG: GemmaManager.initializeModel returned: $success');

      if (success) {
        print(
            'DEBUG: Gemma model initialized successfully through GemmaManager!');
        print('DEBUG: Model manager state:');
        print('  - isInitialized: ${gemmaManager.isInitialized}');
        print('  - currentModelType: ${gemmaManager.currentModelType}');
        print('  - currentBackend: ${gemmaManager.currentBackend}');

        // Don't create session here - let the setup widget handle it
        print(
            'DEBUG: Skipping session creation, letting setup widget handle it');
        return true;
      } else {
        print('DEBUG: GemmaManager initialization returned false');
        print(
            'DEBUG: This is likely the root cause of the ${Platform.isIOS ? "iOS" : "Android"} issue');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Exception in GemmaManager initialization: $e');
      print('DEBUG: Stack trace: $stackTrace');

      // Enhanced error detection for E4B/E2B filename transformation bug
      if (e.toString().contains('Model not found at path') &&
          (modelFileName.contains('E4B') || modelFileName.contains('E2B'))) {
        print('🚨 FLUTTER_GEMMA PLUGIN BUG DETECTED 🚨');
        print('═══════════════════════════════════════════════════════════');
        print('ERROR: The flutter_gemma plugin v0.9.0 has a known bug where');
        print('it transforms "E4B" to "E2B" in model filenames internally.');
        print('');
        print('Expected filename: $modelFileName');
        if (e.toString().contains('E2B')) {
          print(
              'Plugin looking for: ${modelFileName.replaceAll('E4B', 'E2B')}');
        } else {
          print(
              'Plugin looking for: ${modelFileName.replaceAll('E2B', 'E4B')}');
        }
        print('');
        print('WORKAROUND: The GemmaManager should automatically handle this.');
        print('If this error persists, try:');
        print('1. Updating flutter_gemma plugin to a newer version');
        print('2. Using a different model variant');
        print('3. Manually renaming the model file');
        print('═══════════════════════════════════════════════════════════');
      }
    }

    // Step 4: If GemmaManager fails, try direct plugin initialization
    print('Step 4: Attempting direct plugin initialization...');
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

      // Enhanced error detection for E4B/E2B filename transformation bug
      if (e.toString().contains('Model not found at path') &&
          (modelFileName.contains('E4B') || modelFileName.contains('E2B'))) {
        print('🚨 DIRECT PLUGIN INITIALIZATION: E4B/E2B BUG DETECTED 🚨');
        print(
            'The direct plugin method also failed due to the filename transformation bug.');
        print('Expected: $modelFileName');
        if (e.toString().contains('E2B')) {
          print(
              'Plugin looking for: ${modelFileName.replaceAll('E4B', 'E2B')}');
        } else {
          print(
              'Plugin looking for: ${modelFileName.replaceAll('E2B', 'E4B')}');
        }
      }
    }

    // Step 5: Try with CPU backend as final fallback
    print('Step 5: Trying CPU backend as final fallback...');
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
    print(
        'ANDROID DEBUG: Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');

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
