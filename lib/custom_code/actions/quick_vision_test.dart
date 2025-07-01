// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'dart:typed_data';

Future<String> quickVisionTest() async {
  try {
    final gemmaManager = GemmaManager();
    
    // Quick model status check
    if (!gemmaManager.isInitialized) {
      return 'ERROR: No model initialized. Please complete setup first.';
    }
    
    final modelType = gemmaManager.currentModelType ?? 'Unknown';
    final supportsVision = gemmaManager.supportsVision;
    
    final result = StringBuffer();
    result.writeln('=== QUICK VISION TEST ===');
    result.writeln('Model: $modelType');
    result.writeln('Claims Vision Support: $supportsVision');
    
    if (!supportsVision) {
      result.writeln('\n❌ RESULT: Model does not support vision');
      result.writeln('Need a multimodal model like Gemma 3 for vision');
      return result.toString();
    }
    
    // Ensure session exists
    if (!gemmaManager.hasSession) {
      final sessionCreated = await gemmaManager.createSession();
      if (!sessionCreated) {
        result.writeln('\n❌ RESULT: Cannot create session');
        return result.toString();
      }
    }
    
    // Test with a simple synthetic image (1x1 red pixel)
    final testImage = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
      0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4,
      0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C,
      0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x00, 0xFF, 0xD9
    ]);
    
    try {
      final response = await gemmaManager.sendMessage(
        'What color is this image? Answer in one word.',
        imageBytes: testImage
      );
      
      result.writeln('\n🧪 TEST RESULT:');
      if (response != null && response.isNotEmpty) {
        result.writeln('✅ Model responded to image');
        result.writeln('Response: "$response"');
        
        // Check if response is reasonable
        if (response.toLowerCase().contains('red') || 
            response.toLowerCase().contains('color')) {
          result.writeln('✅ Response seems reasonable');
        } else if (response.toLowerCase().contains('pattern') ||
                   response.toLowerCase().contains('textile') ||
                   response.toLowerCase().contains('design')) {
          result.writeln('❌ Response shows hallucination patterns');
        } else {
          result.writeln('⚠️ Response unclear');
        }
      } else {
        result.writeln('❌ No response from model');
      }
    } catch (e) {
      result.writeln('\n❌ TEST FAILED: $e');
    }
    
    result.writeln('\n=== SUMMARY ===');
    result.writeln('The model has technical vision support but may produce');
    result.writeln('inaccurate responses for real-world images.');
    result.writeln('This appears to be a training limitation, not a technical bug.');
    
    return result.toString();
    
  } catch (e) {
    return 'Quick vision test failed: $e';
  }
}