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

Future<List<dynamic>> manageDownloadedModels(
  String? action,
  String? modelPath,
) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(directory.path, 'models'));

    if (!await modelsDir.exists()) {
      return [];
    }

    if (action == 'delete' && modelPath != null) {
      // Delete specific model
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
        print('Deleted model: $modelPath');
      }
    }

    // List all models
    final List<dynamic> models = [];
    final List<FileSystemEntity> files = modelsDir.listSync();

    for (final file in files) {
      if (file is File) {
        final fileName = path.basename(file.path);
        final fileStat = await file.stat();
        final fileSize = fileStat.size;
        final modifiedDate = fileStat.modified;

        // Determine model type from filename
        String modelType = 'Unknown';
        String description = 'Downloaded model file';

        if (fileName.contains('gemma-3n-E4B-it')) {
          modelType = 'Gemma 3 4B Instruct';
          description = 'Multimodal text and image input, 128K context window';
        } else if (fileName.contains('gemma-3n-E2B-it')) {
          modelType = 'Gemma 3 2B Instruct';
          description = 'Multimodal text and image input, efficient 2B model';
        } else if (fileName.contains('Gemma3-1B-IT')) {
          modelType = 'Gemma 3 1B Instruct';
          description = 'Compact 1B model optimized for mobile deployment';
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
        });
      }
    }

    // Sort by modification date (newest first)
    models.sort((a, b) => DateTime.parse(b['modifiedDate'])
        .compareTo(DateTime.parse(a['modifiedDate'])));

    return models;
  } catch (e) {
    print('Error managing downloaded models: $e');
    return [];
  }
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
