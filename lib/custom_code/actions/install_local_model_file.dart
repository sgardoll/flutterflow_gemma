// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_gemma/flutter_gemma.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<bool> installLocalModelFile(
  String localModelPath,
  String? localLoraPath,
) async {
  try {
    print('Installing model from local file: $localModelPath');

    // Validate the model file exists
    final modelFile = File(localModelPath);
    if (!await modelFile.exists()) {
      print('Error: Model file does not exist at path: $localModelPath');
      return false;
    }

    final fileSize = await modelFile.length();
    print(
        'Model file size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Check if file is too small (likely corrupted)
    if (fileSize < 1024 * 1024) {
      // Less than 1MB
      print(
          'Error: Model file appears to be corrupted or incomplete. Size: $fileSize bytes');
      print('Expected model files to be much larger (typically 100MB+)');
      return false;
    }

    // Get app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(appDocDir.path, 'gemma_models'));

    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // Copy model file to app directory
    final modelFileName = path.basename(localModelPath);
    final targetModelPath = path.join(modelsDir.path, modelFileName);
    final targetModelFile = File(targetModelPath);

    print('Copying model file to app directory...');
    await modelFile.copy(targetModelPath);
    print('Model file copied to: $targetModelPath');

    // Handle LoRA file if provided
    String? targetLoraPath;
    if (localLoraPath != null) {
      final loraFile = File(localLoraPath);
      if (await loraFile.exists()) {
        final loraFileName = path.basename(localLoraPath);
        targetLoraPath = path.join(modelsDir.path, loraFileName);
        await loraFile.copy(targetLoraPath);
        print('LoRA file copied to: $targetLoraPath');
      } else {
        print('Warning: LoRA file not found at: $localLoraPath');
      }
    }

    // Model file is now in the correct location for flutter_gemma to use
    // No need to call installModelFromAsset for already downloaded files
    print('Model file is ready for use at: $targetModelPath');
    print('Model installed successfully from local file!');
    return true;
  } catch (e) {
    print('Error in installLocalModelFile: $e');

    if (e.toString().contains('file_size') ||
        e.toString().contains('RET_CHECK failure')) {
      print(
          'The model file appears to be corrupted or in an unsupported format.');
      print('Please ensure you have a valid Gemma model file.');
    }

    return false;
  }
}
