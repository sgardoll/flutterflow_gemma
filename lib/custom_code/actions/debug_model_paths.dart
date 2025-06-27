// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String> debugModelPaths() async {
  final gemmaManager = GemmaManager();
  final buffer = StringBuffer();

  buffer.writeln('=== Gemma Model Debug Information ===\n');

  // 1. Check GemmaManager state
  buffer.writeln('📱 GemmaManager Status:');
  buffer.writeln('- Initialized: ${gemmaManager.isInitialized}');
  buffer.writeln(
      '- Current Model Type: ${gemmaManager.currentModelType ?? 'None'}');
  buffer.writeln('- Current Backend: ${gemmaManager.currentBackend ?? 'None'}');

  // 2. Check if current model supports vision
  if (gemmaManager.currentModelType != null) {
    final modelType = gemmaManager.currentModelType!;
    final multimodalModels = [
      'gemma-3-4b-it',
      'gemma-3-12b-it',
      'gemma-3-27b-it',
      'gemma-3-nano-e4b-it',
      'gemma-3-nano-e2b-it',
    ];

    final multimodalDisplayNames = [
      'gemma 3 4b edge',
      'gemma 3 12b edge',
      'gemma 3 27b edge',
      'gemma 3 nano',
    ];

    final isMultimodal = multimodalModels.any(
            (model) => modelType.toLowerCase().contains(model.toLowerCase())) ||
        multimodalDisplayNames.any((displayName) =>
            modelType.toLowerCase().contains(displayName.toLowerCase())) ||
        modelType.toLowerCase().contains('nano') ||
        modelType.toLowerCase().contains('vision') ||
        modelType.toLowerCase().contains('multimodal');

    buffer.writeln('- Detected as Multimodal: $isMultimodal');

    // Check specific patterns
    buffer.writeln('\n🔍 Pattern Analysis:');
    buffer.writeln(
        '- Contains "gemma 3 4b edge": ${modelType.toLowerCase().contains('gemma 3 4b edge')}');
    buffer.writeln(
        '- Contains "nano": ${modelType.toLowerCase().contains('nano')}');
    buffer.writeln(
        '- Contains "vision": ${modelType.toLowerCase().contains('vision')}');
    buffer.writeln(
        '- Contains "multimodal": ${modelType.toLowerCase().contains('multimodal')}');
  }

  buffer.writeln('\n');

  // 3. Check documents directory for model files
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    buffer.writeln('📁 Documents Directory: ${appDocDir.path}');

    final files = await appDocDir.list().toList();
    final modelFiles = files
        .where((f) =>
            f is File &&
            (f.path.endsWith('.task') ||
                f.path.endsWith('.bin') ||
                f.path.endsWith('.tflite')))
        .cast<File>();

    buffer.writeln('\n📊 Found Model Files:');
    if (modelFiles.isEmpty) {
      buffer.writeln('- No model files found');
    } else {
      for (final file in modelFiles) {
        final fileName = path.basename(file.path);
        final fileSize = await file.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        buffer.writeln('- $fileName (${fileSizeMB}MB)');

        // Check if this looks like a multimodal model
        final isMultimodalFile = fileName.toLowerCase().contains('3n-e') ||
            fileName.toLowerCase().contains('nano') ||
            fileName.toLowerCase().contains('vision') ||
            fileName.toLowerCase().contains('multimodal') ||
            fileName.toLowerCase().contains('gemma-3');
        buffer.writeln('  - Appears multimodal: $isMultimodalFile');
      }
    }
  } catch (e) {
    buffer.writeln('❌ Error checking documents directory: $e');
  }

  // 4. Test model initialization capabilities
  buffer.writeln('\n🧪 Vision Capability Test:');
  if (gemmaManager.isInitialized) {
    try {
      // Test if we can send a message with image bytes
      final testImageBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        // Minimal JPEG data for testing
        ...List.filled(100, 0xFF) // Dummy image data
      ]);

      buffer.writeln(
          '- Created test image bytes (${testImageBytes.length} bytes)');
      buffer.writeln('- Testing vision message creation...');

      // This will tell us if the model actually accepts image messages
      try {
        final response = await gemmaManager.sendMessage(
          'This is a test to check if you can process images. Just respond with "I can see images" if you received an image with this message.',
          imageBytes: testImageBytes,
        );

        if (response != null) {
          buffer.writeln('✅ Model accepted image message');
          buffer.writeln(
              '- Response: ${response.length > 100 ? response.substring(0, 100) + '...' : response}');

          // Check if the response indicates vision capability
          final hasVisionKeywords = response.toLowerCase().contains('image') ||
              response.toLowerCase().contains('see') ||
              response.toLowerCase().contains('visual') ||
              response.toLowerCase().contains('picture');
          buffer.writeln(
              '- Response mentions vision concepts: $hasVisionKeywords');
        } else {
          buffer.writeln('❌ No response from model');
        }
      } catch (e) {
        buffer.writeln('❌ Error sending test image message: $e');
      }
    } catch (e) {
      buffer.writeln('❌ Error in vision test: $e');
    }
  } else {
    buffer.writeln('- Model not initialized, cannot test vision');
  }

  // 5. Platform-specific information
  buffer.writeln('\n📱 Platform Information:');
  buffer.writeln('- Platform: ${Platform.operatingSystem}');
  buffer.writeln('- Platform version: ${Platform.operatingSystemVersion}');

  // 6. Recommendations
  buffer.writeln('\n💡 Recommendations:');
  if (!gemmaManager.isInitialized) {
    buffer.writeln('- Initialize the model first');
  } else if (gemmaManager.currentModelType != null) {
    final modelType = gemmaManager.currentModelType!;
    if (!modelType.toLowerCase().contains('3n-e') &&
        !modelType.toLowerCase().contains('nano') &&
        !modelType.toLowerCase().contains('gemma 3')) {
      buffer.writeln('- Consider using a Gemma 3 model with vision support');
      buffer.writeln('- Recommended: gemma-3n-E4B-it or gemma-3n-E2B-it');
    } else {
      buffer.writeln('- Model appears compatible with vision');
      buffer.writeln('- Ensure model was initialized with supportImage=true');
    }
  }

  return buffer.toString();
}
