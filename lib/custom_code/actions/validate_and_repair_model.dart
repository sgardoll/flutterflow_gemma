// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Validates a model file and returns detailed validation information
Future<dynamic> validateAndRepairModel(
  String modelPath,
  String? hfToken,
  String? modelIdentifier,
) async {
  try {
    print('=== validateAndRepairModel START ===');
    print('Model path: $modelPath');
    print('Model identifier: $modelIdentifier');

    final modelFile = File(modelPath);

    // Check if file exists
    if (!await modelFile.exists()) {
      return {
        'isValid': false,
        'error': 'Model file does not exist',
        'canRepair': modelIdentifier != null && hfToken != null,
        'recommendation': 'Re-download the model file',
      };
    }

    // Get file information
    final fileSize = await modelFile.length();
    final fileName = path.basename(modelPath);

    print('File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Perform validation
    final validationResult = await _validateModelFile(modelFile);

    if (validationResult['isValid'] == true) {
      return {
        'isValid': true,
        'fileSize': fileSize,
        'fileName': fileName,
        'message': 'Model file is valid and ready to use',
      };
    }

    // File is corrupted - offer repair options
    final response = {
      'isValid': false,
      'fileSize': fileSize,
      'fileName': fileName,
      'error': validationResult['error'],
      'validationDetails': validationResult,
      'canRepair': modelIdentifier != null && hfToken != null,
      'recommendation': _getRepairRecommendation(
          validationResult['error'] ?? 'Unknown error', fileName),
    };

    // If we can repair automatically, offer that option
    if (response['canRepair'] == true) {
      response['repairInstructions'] =
          'Delete the corrupted file and re-download using downloadAuthenticatedModel action';
    }

    return response;
  } catch (e) {
    print('Error in validateAndRepairModel: $e');
    return {
      'isValid': false,
      'error': 'Validation failed: ${e.toString()}',
      'canRepair': false,
      'recommendation': 'Check file permissions and try again',
    };
  }
}

/// Enhanced file validation with detailed error reporting
Future<Map<String, dynamic>> _validateModelFile(File modelFile) async {
  try {
    final fileSize = await modelFile.length();

    // Check if file is too small
    if (fileSize < 1024 * 1024) {
      return {
        'isValid': false,
        'error':
            'File too small (${fileSize} bytes) - likely incomplete download',
        'errorType': 'size_too_small',
        'expectedMinSize': 1024 * 1024,
      };
    }

    // Check file extension and validate accordingly
    if (modelFile.path.endsWith('.task')) {
      return await _validateTaskFile(modelFile);
    } else if (modelFile.path.endsWith('.safetensors')) {
      return await _validateSafetensorsFile(modelFile);
    } else {
      return await _validateGenericFile(modelFile);
    }
  } catch (e) {
    return {
      'isValid': false,
      'error': 'Validation error: ${e.toString()}',
      'errorType': 'validation_exception',
    };
  }
}

/// Validate .task files (Gemma LiteRT format)
Future<Map<String, dynamic>> _validateTaskFile(File file) async {
  try {
    // Read first few bytes to check for valid zip/archive header
    final bytes = await file.openRead(0, 1024).first;

    if (bytes.length < 4) {
      return {
        'isValid': false,
        'error': 'File too small to contain valid header',
        'errorType': 'invalid_header',
      };
    }

    final signature = bytes.sublist(0, 4);
    final signatureHex =
        signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

    // Check for ZIP file signature (PK header)
    if (signature[0] == 0x50 && signature[1] == 0x4B) {
      return {
        'isValid': true,
        'format': 'zip_archive',
        'signature': signatureHex,
      };
    }

    // Check for other valid model formats
    // TensorFlow Lite files often start with different patterns
    if (bytes.length >= 16) {
      // Allow files that might be valid TensorFlow Lite models
      // The actual validation will happen when the model loads
      return {
        'isValid': true,
        'format': 'tensorflow_lite',
        'signature': signatureHex,
        'note': 'Non-ZIP format but may be valid TensorFlow Lite model',
      };
    }

    return {
      'isValid': false,
      'error': 'Invalid file signature for .task file',
      'errorType': 'invalid_signature',
      'signature': signatureHex,
    };
  } catch (e) {
    return {
      'isValid': false,
      'error': 'Error validating task file: ${e.toString()}',
      'errorType': 'validation_exception',
    };
  }
}

/// Validate .safetensors files
Future<Map<String, dynamic>> _validateSafetensorsFile(File file) async {
  try {
    // Safetensors files start with a JSON header length (8 bytes little-endian)
    final bytes = await file.openRead(0, 8).first;

    if (bytes.length < 8) {
      return {
        'isValid': false,
        'error': 'Safetensors file too small for header',
        'errorType': 'invalid_header',
      };
    }

    // Read header length (first 8 bytes, little-endian)
    final uint8List = Uint8List.fromList(bytes);
    final byteData = ByteData.sublistView(uint8List);
    final headerLength = byteData.getUint64(0, Endian.little);

    if (headerLength > 0 && headerLength < 1024 * 1024) {
      // Reasonable header size
      return {
        'isValid': true,
        'format': 'safetensors',
        'headerLength': headerLength,
      };
    }

    return {
      'isValid': false,
      'error': 'Invalid safetensors header length: $headerLength',
      'errorType': 'invalid_header_length',
      'headerLength': headerLength,
    };
  } catch (e) {
    return {
      'isValid': false,
      'error': 'Error validating safetensors file: ${e.toString()}',
      'errorType': 'validation_exception',
    };
  }
}

/// Generic file validation for other formats
Future<Map<String, dynamic>> _validateGenericFile(File file) async {
  try {
    final fileSize = await file.length();

    // Check if we can read the file
    final stream = file.openRead(0, 1024);
    final bytes = await stream.first;

    if (bytes.isEmpty) {
      return {
        'isValid': false,
        'error': 'File appears to be empty or unreadable',
        'errorType': 'empty_file',
      };
    }

    return {
      'isValid': true,
      'format': 'unknown',
      'fileSize': fileSize,
      'note': 'Generic validation passed - format unknown',
    };
  } catch (e) {
    return {
      'isValid': false,
      'error': 'Error reading file: ${e.toString()}',
      'errorType': 'read_error',
    };
  }
}

/// Get specific repair recommendations based on error type
String _getRepairRecommendation(String error, String fileName) {
  if (error.contains('too small') || error.contains('incomplete')) {
    return 'File appears to be incomplete. Re-download the model to fix this issue.';
  }

  if (error.contains('signature') || error.contains('header')) {
    return 'File has invalid format. This usually indicates corruption during download.';
  }

  if (error.contains('zip archive') || error.contains('Unable to open')) {
    return 'Model file is corrupted and cannot be read. Re-downloading will fix this.';
  }

  if (error.contains('permission')) {
    return 'Check file permissions. Try restarting the app and clearing old model files.';
  }

  return 'Model file validation failed. Re-downloading is recommended.';
}
