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

    // Enhanced file validation - check for corruption
    if (!await _validateModelFile(modelFile)) {
      print(
          'Error: Model file validation failed - file appears to be corrupted');
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

    // Clear old model files (but not the current file being installed)
    await _clearOldModelFiles(targetDirectory, currentFilePath: localModelPath);

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

    // Validate copied file integrity
    if (!await _validateModelFile(copiedFile)) {
      print('Error: Copied model file validation failed');
      await copiedFile.delete();
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

/// Enhanced file validation to detect corruption
Future<bool> _validateModelFile(File modelFile) async {
  try {
    final fileSize = await modelFile.length();

    // Check if file is too small (likely corrupted)
    if (fileSize < 1024 * 1024) {
      // Less than 1MB
      print(
          'Error: Model file appears to be corrupted or incomplete. Size: $fileSize bytes');
      print('Expected model files to be much larger (typically 100MB+)');
      return false;
    }

    // For .task files, validate they start with proper headers
    if (modelFile.path.endsWith('.task')) {
      return await _validateTaskFile(modelFile);
    }

    // For other formats, do basic checks
    return await _validateGenericFile(modelFile);
  } catch (e) {
    print('Error validating model file: $e');
    return false;
  }
}

/// Validate .task files (MediaPipe LiteRT format - ZIP archives)
Future<bool> _validateTaskFile(File file) async {
  try {
    final fileSize = await file.length();

    // Basic file size validation - .task files should be reasonably large
    if (fileSize < 1024 * 1024) {
      // Less than 1MB is suspicious
      print(
          'Error: Task file too small (${fileSize} bytes) - likely incomplete');
      return false;
    }

    // Read the first 8 bytes efficiently using RandomAccessFile
    final raf = await file.open();
    try {
      final headerBytes = await raf.read(8);

      if (headerBytes.length < 8) {
        print('Error: Cannot read task file header');
        return false;
      }

      // Validate as ZIP archive format
      return _validateZipHeader(headerBytes, fileSize);
    } finally {
      await raf.close();
    }
  } catch (e) {
    print('Error validating task file: $e');
    return false;
  }
}

/// Validate ZIP header for .task files
bool _validateZipHeader(List<int> headerBytes, int fileSize) {
  try {
    final signatureHex =
        headerBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

    print('Task file validation - ZIP header: $signatureHex');

    // Check for ZIP file signature (PK header)
    // ZIP local file header: 50 4b 03 04 ("PK\x03\x04")
    // Note: Some ZIP files may have padding at the beginning

    // Look for ZIP signature in first 8 bytes
    bool foundZipSignature = false;
    int zipSignatureOffset = -1;

    for (int i = 0; i <= 4; i++) {
      if (i + 3 < headerBytes.length &&
          headerBytes[i] == 0x50 &&
          headerBytes[i + 1] == 0x4B &&
          headerBytes[i + 2] == 0x03 &&
          headerBytes[i + 3] == 0x04) {
        foundZipSignature = true;
        zipSignatureOffset = i;
        break;
      }
    }

    if (!foundZipSignature) {
      // Check if it could be corrupted (all zeros or HTML content)
      if (headerBytes.every((b) => b == 0)) {
        print('ERROR: Task file corrupted - header contains only zeros');
        return false;
      }

      // Check for HTML content (download error)
      final textStart = String.fromCharCodes(headerBytes);
      if (textStart.toLowerCase().contains('<html') ||
          textStart.toLowerCase().contains('<!doctype') ||
          textStart.toLowerCase().contains('error')) {
        print(
            'ERROR: Task file corrupted - contains HTML instead of binary data');
        return false;
      }

      print(
          'ERROR: Invalid ZIP signature for .task file - expected ZIP format');
      return false;
    }

    // Valid ZIP file found
    print(
        'Valid ZIP archive format for .task file (offset: $zipSignatureOffset)');
    return true;
  } catch (e) {
    print('Error parsing ZIP header: $e');
    return false;
  }
}

/// Generic file validation for other formats
Future<bool> _validateGenericFile(File file) async {
  try {
    final fileSize = await file.length();

    // Check if we can read the file
    final stream = file.openRead(0, 1024);
    await stream.first;

    print('Generic file validation passed for file of size: ${fileSize} bytes');
    return true;
  } catch (e) {
    print('Error in generic file validation: $e');
    return false;
  }
}

/// Clear old model files from directory
Future<void> _clearOldModelFiles(Directory targetDirectory,
    {String? currentFilePath}) async {
  try {
    final targetFiles = await targetDirectory.list().toList();
    for (final entity in targetFiles) {
      if (entity is File && entity.path.endsWith('.task')) {
        // Don't delete the current file being installed
        if (currentFilePath != null && entity.path == currentFilePath) {
          print('Preserving current model file: ${entity.path}');
          continue;
        }

        // Don't delete if it's the same file name as the current one
        if (currentFilePath != null &&
            path.basename(entity.path) == path.basename(currentFilePath)) {
          print('Preserving model file with same name: ${entity.path}');
          continue;
        }

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
    if (otherDirectory.path != targetDirectory.path) {
      final otherFiles = await otherDirectory.list().toList();
      for (final entity in otherFiles) {
        if (entity is File && entity.path.endsWith('.task')) {
          // Don't delete the current file being installed
          if (currentFilePath != null && entity.path == currentFilePath) {
            print(
                'Preserving current model file in other directory: ${entity.path}');
            continue;
          }

          // Don't delete if it's the same file name as the current one
          if (currentFilePath != null &&
              path.basename(entity.path) == path.basename(currentFilePath)) {
            print(
                'Preserving model file with same name in other directory: ${entity.path}');
            continue;
          }

          print('Removing old model file from other directory: ${entity.path}');
          await entity.delete();
        }
      }
    }
  } catch (e) {
    print('Could not clear other directory: $e');
  }
}
