// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<List<dynamic>> getDownloadedModels() async {
  try {
    print('getDownloadedModels: Listing downloaded models...');

    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(directory.path, 'models'));

    if (!await modelsDir.exists()) {
      print('getDownloadedModels: Models directory does not exist');
      return [];
    }

    final List<dynamic> models = [];
    final List<FileSystemEntity> files = modelsDir.listSync();

    print(
        'getDownloadedModels: Found ${files.length} files in models directory');

    for (final file in files) {
      if (file is File) {
        final fileName = path.basename(file.path);
        final fileStat = await file.stat();
        final fileSize = fileStat.size;
        final modifiedDate = fileStat.modified;

        // Determine Gemma model type from filename
        String modelType = 'Unknown';
        String description = 'Downloaded model file';

        if (fileName.contains('gemma-3n-E4B-it')) {
          modelType = 'Gemma 3 Nano 4B';
          description = 'Gemma 3 Nano 4B with vision support';
        } else if (fileName.contains('gemma-3n-E2B-it')) {
          modelType = 'Gemma 3 Nano 2B';
          description = 'Gemma 3 Nano 2B with vision support';
        } else if (fileName.contains('gemma3-1b-it')) {
          modelType = 'Gemma3 1B';
          description = 'Gemma3 1B model optimized for mobile deployment';
        } else if (fileName.contains('gemma3-1b-web')) {
          modelType = 'Gemma3 1B Web';
          description = 'Web-optimized Gemma3 1B model';
        } else if (fileName.contains('gemma-3-9b-it')) {
          modelType = 'Gemma3 9B';
          description = 'High-quality 9B text model with strong reasoning';
        } else if (fileName.contains('gemma-3-27b-it')) {
          modelType = 'Gemma3 27B';
          description = 'Large 27B text model with exceptional reasoning';
        } else if (fileName.contains('gemma-3n-1b-it')) {
          modelType = 'Gemma3 Nano 1B';
          description =
              'Compact 1B Nano model for resource-constrained environments';
        } else if (fileName.contains('gemma')) {
          modelType = 'Gemma Model';
          description = 'Gemma language model';
        }

        models.add({
          'fileName': fileName,
          'filePath': file.path,
          'fileSize': fileSize,
          'modifiedDate': modifiedDate.toIso8601String(),
          'modelType': modelType,
          'description': description,
          'sizeFormatted': _formatFileSize(fileSize),
          'dateFormatted': _formatDate(modifiedDate),
          'supportsVision': _checkVisionSupport(fileName),
        });
      }
    }

    // Sort by modification date (newest first)
    models.sort((a, b) => DateTime.parse(b['modifiedDate'])
        .compareTo(DateTime.parse(a['modifiedDate'])));

    print('getDownloadedModels: Returning ${models.length} models');
    return models;
  } catch (e) {
    print('getDownloadedModels: Error - $e');
    return [];
  }
}

bool _checkVisionSupport(String fileName) {
  // Only Gemma 3 Nano vision models support vision
  final gemmaVisionModels = [
    'gemma-3n-e4b-it',
    'gemma-3n-e2b-it',
  ];

  // Text-only Gemma models (explicitly no vision support)
  final textOnlyModels = [
    'gemma-3-9b-it',
    'gemma-3-27b-it',
    'gemma-3n-1b-it',
    'gemma3-1b-it',
    'gemma3-1b-web',
  ];

  // If it's explicitly a text-only model, return false
  if (textOnlyModels.any((model) => fileName.toLowerCase().contains(model))) {
    return false;
  }

  return gemmaVisionModels
      .any((model) => fileName.toLowerCase().contains(model));
}

String _formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  } else if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else {
    return '$bytes bytes';
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}
