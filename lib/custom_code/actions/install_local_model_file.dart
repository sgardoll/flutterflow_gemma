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

    // Get the flutter_gemma model manager
    final modelManager = FlutterGemmaPlugin.instance.modelManager;
    final modelFileName = path.basename(localModelPath);

    // Step 1: Clear any existing model completely
    try {
      print('Clearing any existing model state...');
      await modelManager.deleteModel();
      print('Existing model state cleared');
    } catch (e) {
      print('No existing model to clear: $e');
    }

    // Step 2: Use platform-specific directories
    late Directory targetDirectory;
    if (Platform.isIOS) {
      // iOS plugin expects models in Documents directory
      targetDirectory = await getApplicationDocumentsDirectory();
      print('iOS: Using documents directory: ${targetDirectory.path}');
    } else {
      // Android: Use documents directory as a more accessible location
      targetDirectory = await getApplicationDocumentsDirectory();
      print('Android: Using documents directory: ${targetDirectory.path}');
    }

    try {
      final targetFiles = await targetDirectory.list().toList();
      for (final entity in targetFiles) {
        if (entity is File && entity.path.endsWith('.task')) {
          print('Removing old model file: ${entity.path}');
          await entity.delete();
        }
      }
    } catch (e) {
      print('Could not clear old model files: $e');
    }

    // Also clear the other directory for good measure
    try {
      final otherDirectory = Platform.isIOS
          ? await getApplicationSupportDirectory()
          : await getApplicationDocumentsDirectory();
      final otherFiles = await otherDirectory.list().toList();
      for (final entity in otherFiles) {
        if (entity is File && entity.path.endsWith('.task')) {
          print('Removing old model file from other directory: ${entity.path}');
          await entity.delete();
        }
      }
    } catch (e) {
      print('Could not clear other directory: $e');
    }

    // Step 3: Copy the model file to the platform-specific directory
    final targetModelPath = path.join(targetDirectory.path, modelFileName);
    print('Copying model to platform directory: $targetModelPath');

    await modelFile.copy(targetModelPath);
    print('Model file copied successfully');

    // Step 4: Verify the file was copied correctly
    final copiedFile = File(targetModelPath);
    if (!await copiedFile.exists()) {
      print('Error: Failed to copy model file to target location');
      return false;
    }

    final copiedSize = await copiedFile.length();
    if (copiedSize != fileSize) {
      print(
          'Error: Copied file size mismatch. Original: $fileSize, Copied: $copiedSize');
      return false;
    }

    print(
        'File copy verified. Size: ${(copiedSize / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Step 5: Wait a moment for file system operations to complete
    await Future.delayed(Duration(milliseconds: 200));

    // Step 6: Register the model with the plugin
    print('Registering model with plugin: $modelFileName');
    try {
      // ANDROID FIX: Always use the absolute path for Android to avoid
      // path resolution issues in the native plugin code.
      final pathToRegister =
          Platform.isAndroid ? targetModelPath : modelFileName;

      print('Registering with path: "$pathToRegister"');
      await modelManager.setModelPath(pathToRegister);
      print('Model path registered successfully!');

      // Small delay to let the registration complete
      await Future.delayed(Duration(milliseconds: 300));

      return true;
    } catch (e) {
      print('Error registering model path: $e');
      return false;
    }
  } catch (e) {
    print('Error in installLocalModelFile: $e');

    if (e.toString().contains('file_size') ||
        e.toString().contains('RET_CHECK failure')) {
      print(
          'The model file appears to be corrupted or in an unsupported format.');
      print('Please ensure you have a valid Gemma model file.');
    } else if (e.toString().contains('permission')) {
      print('Permission denied. Check file system permissions.');
    } else if (e.toString().contains('space')) {
      print('Insufficient storage space to copy the model file.');
    }

    return false;
  }
}
