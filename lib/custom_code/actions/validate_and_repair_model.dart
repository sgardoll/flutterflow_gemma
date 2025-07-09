// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
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

    // Perform enhanced validation
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
    print('Validation failed: ${validationResult['error']}');
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

/// Validate .task files (MediaPipe LiteRT format - ZIP archives)
Future<Map<String, dynamic>> _validateTaskFile(File file) async {
  try {
    final fileSize = await file.length();

    // Basic file size validation - .task files should be reasonably large
    if (fileSize < 1024 * 1024) {
      // Less than 1MB is suspicious
      return {
        'isValid': false,
        'error': 'Task file too small (${fileSize} bytes) - likely incomplete',
        'errorType': 'size_too_small',
        'expectedMinSize': 1024 * 1024,
      };
    }

    // Read the first 8 bytes efficiently using RandomAccessFile
    final raf = await file.open();
    try {
      final headerBytes = await raf.read(8);

      if (headerBytes.length < 8) {
        return {
          'isValid': false,
          'error': 'Cannot read task file header',
          'errorType': 'invalid_header',
        };
      }

      // Validate as ZIP archive format
      return _validateZipHeader(headerBytes, fileSize);
    } finally {
      await raf.close();
    }
  } catch (e) {
    return {
      'isValid': false,
      'error': 'Error validating task file: ${e.toString()}',
      'errorType': 'validation_exception',
    };
  }
}

/// Validate ZIP header for .task files
Map<String, dynamic> _validateZipHeader(List<int> headerBytes, int fileSize) {
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
        return {
          'isValid': false,
          'error': 'Task file corrupted: header contains only zeros',
          'errorType': 'corrupted_header',
          'header': signatureHex,
        };
      }

      // Check for HTML content (download error)
      final textStart = String.fromCharCodes(headerBytes);
      if (textStart.toLowerCase().contains('<html') ||
          textStart.toLowerCase().contains('<!doctype') ||
          textStart.toLowerCase().contains('error')) {
        return {
          'isValid': false,
          'error':
              'Task file corrupted: contains HTML/text instead of binary data',
          'errorType': 'html_content',
          'header': signatureHex,
        };
      }

      return {
        'isValid': false,
        'error': 'Invalid ZIP signature for .task file',
        'errorType': 'invalid_zip_signature',
        'header': signatureHex,
        'note': 'Expected ZIP format (PK signature) for .task files',
      };
    }

    // Valid ZIP file found
    return {
      'isValid': true,
      'format': 'zip_archive',
      'header': signatureHex,
      'zipSignatureOffset': zipSignatureOffset,
      'fileSize': fileSize,
      'note': 'Valid ZIP archive format for .task file',
    };
  } catch (e) {
    return {
      'isValid': false,
      'error': 'Error parsing ZIP header: ${e.toString()}',
      'errorType': 'zip_parsing_error',
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
