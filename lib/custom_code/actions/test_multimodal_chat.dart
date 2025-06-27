// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'dart:typed_data';

Future<String> testMultimodalChat(FFUploadedFile imageFile) async {
  try {
    final gemmaManager = GemmaManager();

    if (!gemmaManager.isInitialized) {
      return 'ERROR: Model not initialized';
    }

    // Get image bytes
    final imageBytes = imageFile.bytes;
    if (imageBytes == null) {
      return 'ERROR: No image data found';
    }

    print('testMultimodalChat: Testing with ${imageBytes.length} byte image');

    // Check image format
    if (imageBytes.length >= 4) {
      final header = imageBytes.take(4).toList();
      String format = 'unknown';
      if (header[0] == 0xFF && header[1] == 0xD8) {
        format = 'JPEG';
      } else if (header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47) {
        format = 'PNG';
      }
      print('testMultimodalChat: Image format detected: $format');
    }

    // Close any existing session/chat and create a fresh chat instance
    print('testMultimodalChat: Creating fresh chat instance...');
    await gemmaManager.closeSession();

    // Create chat instance specifically for multimodal
    final chatCreated = await gemmaManager.createChat(
      temperature: 0.7,
      randomSeed: 42,
      topK: 40,
    );

    if (!chatCreated) {
      return 'ERROR: Failed to create chat instance';
    }

    print(
        'testMultimodalChat: Chat created successfully, sending test message...');

    // Send test message with image using chat
    final response = await gemmaManager.sendChatMessage(
      'I am testing the vision capabilities. Please describe what you see in this image in detail. If you cannot see any image, please say "I cannot see any image".',
      imageBytes: imageBytes,
    );

    if (response == null) {
      return 'ERROR: No response from model';
    }

    print(
        'testMultimodalChat: Got response: ${response.length > 100 ? response.substring(0, 100) + "..." : response}');

    // Analyze the response
    final lowerResponse = response.toLowerCase();
    if (lowerResponse.contains('cannot see') ||
        lowerResponse.contains('no image') ||
        lowerResponse.contains('don\'t see') ||
        lowerResponse.contains('share') ||
        lowerResponse.contains('upload')) {
      return 'VISION NOT WORKING: The model cannot see the image. Response: $response';
    } else if (lowerResponse.contains('image') ||
        lowerResponse.contains('see') ||
        lowerResponse.contains('shows') ||
        lowerResponse.contains('appears') ||
        lowerResponse.contains('looks')) {
      return 'VISION WORKING: $response';
    } else {
      return 'UNCLEAR: $response';
    }
  } catch (e) {
    print('Error in testMultimodalChat: $e');
    return 'ERROR: $e';
  }
}
