// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> debugModelPaths() async {
  try {
    print('=== DEBUG MODEL PATHS START ===');

    // Get app directories
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();

    print('App Documents Directory: ${appDir.path}');
    print('Temp Directory: ${tempDir.path}');

    // Check models directory
    final modelsDir = Directory('${appDir.path}/models');
    print('Models Directory: ${modelsDir.path}');
    print('Models Directory Exists: ${await modelsDir.exists()}');

    if (await modelsDir.exists()) {
      print('--- Models Directory Contents ---');
      try {
        final files = await modelsDir.list().toList();
        if (files.isEmpty) {
          print('No files found in models directory');
        } else {
          for (final file in files) {
            if (file is File) {
              final stat = await file.stat();
              final fileName = file.path.split('/').last;
              final sizeFormatted = _formatFileSize(stat.size);
              print('File: $fileName ($sizeFormatted)');
              print('  Path: ${file.path}');
              print('  Size: ${stat.size} bytes');
              print('  Modified: ${stat.modified}');
              print('  Type: ${stat.type}');
            } else if (file is Directory) {
              print('Directory: ${file.path}');
            }
          }
        }
      } catch (e) {
        print('Error listing models directory: $e');
      }
    }

    // Check for common model locations
    final commonPaths = [
      '${appDir.path}/gemma',
      '${appDir.path}/Downloads',
      '${appDir.path}/cache',
      '${tempDir.path}/models',
    ];

    print('--- Checking Common Model Locations ---');
    for (final path in commonPaths) {
      final dir = Directory(path);
      final exists = await dir.exists();
      print('$path: ${exists ? "EXISTS" : "NOT FOUND"}');

      if (exists) {
        try {
          final files = await dir.list().toList();
          print('  Files: ${files.length}');
          for (final file in files.take(5)) {
            // Limit to first 5 files
            print('    ${file.path.split('/').last}');
          }
          if (files.length > 5) {
            print('    ... and ${files.length - 5} more files');
          }
        } catch (e) {
          print('  Error accessing directory: $e');
        }
      }
    }

    // Check available disk space
    try {
      final appDirStat = await appDir.stat();
      print('--- Directory Permissions ---');
      print('App Directory Type: ${appDirStat.type}');
      print('App Directory Modified: ${appDirStat.modified}');
    } catch (e) {
      print('Error getting directory stats: $e');
    }

    print('=== DEBUG MODEL PATHS END ===');
  } catch (e) {
    print('Error in debugModelPaths: $e');
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
