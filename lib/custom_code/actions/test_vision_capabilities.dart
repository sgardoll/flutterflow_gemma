// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<String> testVisionCapabilities() async {
  try {
    print('=== VISION CAPABILITY TEST START ===');
    
    final gemmaManager = GemmaManager();
    
    // Check if model is initialized
    if (!gemmaManager.isInitialized) {
      return 'ERROR: No model is currently initialized. Please set up a model first.';
    }
    
    // Report current model details
    final modelType = gemmaManager.currentModelType ?? 'Unknown';
    final backend = gemmaManager.currentBackend ?? 'Unknown';
    final supportsVision = gemmaManager.supportsVision;
    
    print('Current model: $modelType');
    print('Backend: $backend');
    print('Claims vision support: $supportsVision');
    
    // Check if session exists
    if (!gemmaManager.hasSession) {
      print('No session found, attempting to create one...');
      final sessionCreated = await gemmaManager.createSession();
      if (!sessionCreated) {
        return 'ERROR: Could not create session for vision testing.';
      }
    }
    
    print('Starting comprehensive vision capability tests...');
    final testResults = await gemmaManager.testVisionCapabilities();
    
    // Format results for user
    final buffer = StringBuffer();
    buffer.writeln('=== VISION CAPABILITY TEST RESULTS ===\n');
    
    buffer.writeln('Model: ${gemmaManager.currentModelType}');
    buffer.writeln('Backend: ${gemmaManager.currentBackend}\n');
    
    // Overall status
    buffer.writeln('📊 OVERALL STATUS:');
    buffer.writeln('• Model Ready: ${testResults['isReady'] ? '✅' : '❌'}');
    buffer.writeln('• Claims Vision Support: ${testResults['supportsVision'] ? '✅' : '❌'}');
    buffer.writeln('• Can Process Images: ${testResults['canProcessImages'] ? '✅' : '❌'}');
    buffer.writeln('• Responds to Images: ${testResults['respondsToImages'] ? '✅' : '❌'}');
    buffer.writeln('• Gives Reasonable Responses: ${testResults['givesReasonableResponses'] ? '✅' : '❌'}\n');
    
    // Errors
    if (testResults['errors'] != null && (testResults['errors'] as List).isNotEmpty) {
      buffer.writeln('⚠️ ERRORS:');
      for (final error in testResults['errors'] as List) {
        buffer.writeln('• $error');
      }
      buffer.writeln();
    }
    
    // Individual test results
    final testData = testResults['testResults'] as Map<String, dynamic>?;
    if (testData != null) {
      buffer.writeln('🧪 INDIVIDUAL TESTS:');
      
      for (final entry in testData.entries) {
        final testName = entry.key;
        final testResult = entry.value as Map<String, dynamic>;
        
        buffer.writeln('\n${testName.toUpperCase()}:');
        buffer.writeln('  Responded: ${testResult['responded'] ? '✅' : '❌'}');
        
        if (testResult['response'] != null) {
          final response = testResult['response'] as String;
          buffer.writeln('  Response: "${response.length > 100 ? '${response.substring(0, 100)}...' : response}"');
        }
        
        if (testResult['error'] != null) {
          buffer.writeln('  Error: ${testResult['error']}');
        }
      }
    }
    
    // Recommendations
    buffer.writeln('\n💡 RECOMMENDATIONS:');
    
    if (!testResults['isReady']) {
      buffer.writeln('• Initialize a model and create a session before testing vision');
    } else if (!testResults['supportsVision']) {
      buffer.writeln('• Use a multimodal model that supports vision (e.g., Gemma 3)');
    } else if (!testResults['canProcessImages']) {
      buffer.writeln('• Vision processing appears to be non-functional');
      buffer.writeln('• Check if the model file is properly installed');
      buffer.writeln('• Try restarting the app and reinitializing the model');
    } else if (!testResults['respondsToImages']) {
      buffer.writeln('• Model can process images but responses are inconsistent');
      buffer.writeln('• Try simpler images with high contrast');
      buffer.writeln('• Consider using text-based images or diagrams');
    } else if (!testResults['givesReasonableResponses']) {
      buffer.writeln('• Model responds but gives hallucinated/problematic answers');
      buffer.writeln('• This appears to be a limitation of the on-device model');
      buffer.writeln('• Try images with clear text, simple shapes, or high contrast');
      buffer.writeln('• Consider cloud-based vision APIs for complex natural images');
    } else {
      buffer.writeln('• Vision capabilities appear to be working properly!');
      buffer.writeln('• Model should be able to handle image analysis tasks');
    }
    
    buffer.writeln('\n=== END VISION TEST ===');
    
    final result = buffer.toString();
    print(result);
    return result;
    
  } catch (e) {
    final error = 'Vision capability test failed: $e';
    print(error);
    return error;
  }
}