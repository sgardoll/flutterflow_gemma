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

    // Step 2: Clear the app documents directory of any old model files
    final appDocDir = await getApplicationDocumentsDirectory();
    print('App documents directory: ${appDocDir.path}');

    try {
      final documentsFiles = await appDocDir.list().toList();
      for (final entity in documentsFiles) {
        if (entity is File && entity.path.endsWith('.task')) {
          print('Removing old model file: ${entity.path}');
          await entity.delete();
        }
      }
    } catch (e) {
      print('Could not clear old model files: $e');
    }

    // Step 3: Copy the model file to the documents root directory with integrity verification
    final targetModelPath = path.join(appDocDir.path, modelFileName);
    print('Copying model to: $targetModelPath');

    // Delete target file if it exists to ensure clean copy
    final targetFile = File(targetModelPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
      print('Deleted existing target file');
    }

    // Copy with chunked verification to prevent corruption
    await _copyFileWithVerification(modelFile, targetFile);
    print('Model file copied successfully');

    // Step 4: Verify the file was copied correctly
    if (!await targetFile.exists()) {
      print('Error: Failed to copy model file to target location');
      return false;
    }

    final copiedSize = await targetFile.length();
    if (copiedSize != fileSize) {
      print(
          'Error: Copied file size mismatch. Original: $fileSize, Copied: $copiedSize');
      print('This indicates file corruption during copy operation');

      // Delete corrupted file
      await targetFile.delete();
      return false;
    }

    // Additional integrity check - verify file can be read
    try {
      final testBytes = await targetFile.readAsBytes();
      if (testBytes.length != copiedSize) {
        print('Error: File corruption detected during read verification');
        await targetFile.delete();
        return false;
      }
      print('File integrity verification passed');
    } catch (e) {
      print('Error: Cannot read copied file - $e');
      await targetFile.delete();
      return false;
    }

    print(
        'File copy verified. Size: ${(copiedSize / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Step 5: Wait a moment for file system operations to complete
    await Future.delayed(Duration(milliseconds: 200));

    // Step 6: Register the model with the plugin with platform-specific handling
    print('Registering model with plugin: $modelFileName');
    try {
      String pathToRegister;

      if (Platform.isAndroid) {
        // Android needs the full path
        pathToRegister = targetModelPath;
        print('Android: Registering full path: $pathToRegister');
      } else {
        // iOS uses just the filename
        pathToRegister = modelFileName;
        print('iOS: Registering filename: $pathToRegister');
      }

      await modelManager.setModelPath(pathToRegister);
      print('Model path registered successfully!');

      // Small delay to let the registration complete
      await Future.delayed(Duration(milliseconds: 300));

      return true;
    } catch (e) {
      print('Error registering model: $e');
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

/// Copy file with verification to prevent corruption
Future<void> _copyFileWithVerification(File source, File target) async {
  const chunkSize = 1024 * 1024; // 1MB chunks

  final sourceStream = source.openRead();
  final targetSink = target.openWrite();

  try {
    await for (final chunk in sourceStream) {
      targetSink.add(chunk);
    }
    await targetSink.flush();
  } finally {
    await targetSink.close();
  }

  // Wait for file system sync
  await Future.delayed(Duration(milliseconds: 100));
}
