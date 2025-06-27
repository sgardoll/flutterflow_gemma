// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'dart:typed_data';

Future<String> testVisionCapabilities() async {
  try {
    final gemmaManager = GemmaManager();

    if (!gemmaManager.isInitialized) {
      return 'ERROR: Model not initialized';
    }

    // Create a minimal test image (JPEG header)
    final testImageBytes = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, // JPEG signature
      0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, // JFIF marker
      // Add minimal JPEG data
      ...List.filled(200, 0xFF)
    ]);

    print('Testing vision with ${testImageBytes.length} byte test image');

    // Send a test message with the image
    final response = await gemmaManager.sendMessage(
      'I am sending you a test image. If you can see this image, please respond with "VISION_WORKING". If you cannot see any image, respond with "VISION_NOT_WORKING".',
      imageBytes: testImageBytes,
    );

    if (response == null) {
      return 'ERROR: No response from model';
    }

    // Analyze the response
    if (response.toLowerCase().contains('vision_working') ||
        response.toLowerCase().contains('vision working')) {
      return 'SUCCESS: Vision is working - $response';
    } else if (response.toLowerCase().contains('vision_not_working') ||
        response.toLowerCase().contains('vision not working')) {
      return 'FAIL: Vision not working - $response';
    } else if (response.toLowerCase().contains('image') ||
        response.toLowerCase().contains('see') ||
        response.toLowerCase().contains('visual')) {
      return 'PARTIAL: Model mentions visual concepts - $response';
    } else {
      return 'UNCLEAR: Response does not clearly indicate vision status - $response';
    }
  } catch (e) {
    print('Error testing vision capabilities: $e');
    return 'ERROR: $e';
  }
}
