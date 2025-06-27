// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'package:flutter_gemma/flutter_gemma.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String> debugModelPaths() async {
  try {
    final resultLines = <String>[];

    // Get the application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    resultLines.add('Documents Directory: ${appDocDir.path}');
    resultLines.add('');

    // List all files in documents directory
    resultLines.add('=== Documents Directory Files ===');
    try {
      final files = await appDocDir.list().toList();
      int fileCount = 0;
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final name = path.basename(entity.path);
          final sizeFormatted =
              '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB';
          final isTaskFile = entity.path.endsWith('.task');
          resultLines.add('File: $name');
          resultLines.add('  Path: ${entity.path}');
          resultLines.add('  Size: $sizeFormatted');
          resultLines.add('  Is Task File: $isTaskFile');
          resultLines.add('');
          fileCount++;
        }
      }
      resultLines.add('Total files in documents: $fileCount');
    } catch (e) {
      resultLines.add('Error listing documents files: ${e.toString()}');
    }
    resultLines.add('');

    // Check if there's a models subdirectory
    final modelsSubdir = Directory(path.join(appDocDir.path, 'models'));
    final modelsSubdirExists = await modelsSubdir.exists();
    resultLines.add('=== Models Subdirectory ===');
    resultLines.add('Models subdirectory exists: $modelsSubdirExists');

    if (modelsSubdirExists) {
      try {
        final files = await modelsSubdir.list().toList();
        int fileCount = 0;
        for (final entity in files) {
          if (entity is File) {
            final stat = await entity.stat();
            final name = path.basename(entity.path);
            final sizeFormatted =
                '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB';
            final isTaskFile = entity.path.endsWith('.task');
            resultLines.add('File: $name');
            resultLines.add('  Path: ${entity.path}');
            resultLines.add('  Size: $sizeFormatted');
            resultLines.add('  Is Task File: $isTaskFile');
            resultLines.add('');
            fileCount++;
          }
        }
        resultLines.add('Total files in models directory: $fileCount');
      } catch (e) {
        resultLines.add('Error listing models files: ${e.toString()}');
      }
    }
    resultLines.add('');

    // Try to get the current model path from the model manager
    resultLines.add('=== Model Manager Status ===');
    try {
      final modelManager = FlutterGemmaPlugin.instance.modelManager;
      resultLines.add('Model manager accessible: true');
    } catch (e) {
      resultLines.add('Model manager accessible: false');
      resultLines.add('Error: ${e.toString()}');
    }
    resultLines.add('');

    // Find all .task files across the entire app directory structure
    resultLines.add('=== All Task Files Found ===');
    try {
      final allTaskFiles = <Map<String, dynamic>>[];
      await _findTaskFilesRecursively(appDocDir.parent, allTaskFiles);

      if (allTaskFiles.isEmpty) {
        resultLines.add('No .task files found');
      } else {
        resultLines.add('Found ${allTaskFiles.length} .task files:');
        for (final taskFile in allTaskFiles) {
          resultLines.add('File: ${taskFile['name']}');
          resultLines.add('  Path: ${taskFile['path']}');
          if (taskFile.containsKey('sizeFormatted')) {
            resultLines.add('  Size: ${taskFile['sizeFormatted']}');
          }
          if (taskFile.containsKey('error')) {
            resultLines.add('  Error: ${taskFile['error']}');
          }
          resultLines.add('');
        }
      }
    } catch (e) {
      resultLines.add('Error searching for task files: ${e.toString()}');
    }

    return resultLines.join('\n');
  } catch (e) {
    return 'Error: ${e.toString()}\nFailed to debug model paths';
  }
}

Future<void> _findTaskFilesRecursively(
    Directory dir, List<Map<String, dynamic>> taskFiles) async {
  try {
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.task')) {
        try {
          final stat = await entity.stat();
          taskFiles.add({
            'name': path.basename(entity.path),
            'path': entity.path,
            'size': stat.size,
            'sizeFormatted':
                '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB',
          });
        } catch (e) {
          taskFiles.add({
            'name': path.basename(entity.path),
            'path': entity.path,
            'error': e.toString(),
          });
        }
      } else if (entity is Directory) {
        // Recurse into subdirectories, but skip certain system directories
        final dirName = path.basename(entity.path);
        if (!dirName.startsWith('.') &&
            dirName != 'Caches' &&
            dirName != 'tmp' &&
            dirName != 'Preferences') {
          try {
            await _findTaskFilesRecursively(entity, taskFiles);
          } catch (e) {
            // Ignore errors from directories we can't access
          }
        }
      }
    }
  } catch (e) {
    // Ignore errors from directories we can't access
  }
}
