// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<String?> sendGemmaMessage(
  String message,
) async {
  try {
    print('sendGemmaMessage: Sending message...');
    print('Message: $message');

    final gemmaManager = GemmaManager();

    // Check if model and session are ready
    if (!gemmaManager.isInitialized) {
      print('sendGemmaMessage: Error - Model not initialized');
      return 'Error: Model not initialized. Please run initializeGemmaModel first.';
    }

    if (!gemmaManager.hasSession) {
      print('sendGemmaMessage: Error - No session available');
      return 'Error: No session available. Please run createGemmaSession first.';
    }

    // Validate message
    if (message.trim().isEmpty) {
      print('sendGemmaMessage: Error - Empty message');
      return 'Error: Message cannot be empty.';
    }

    print('sendGemmaMessage: Sending to model...');
    final response = await gemmaManager.sendMessage(message.trim());

    if (response != null && response.isNotEmpty) {
      print('sendGemmaMessage: Response received (${response.length} chars)');
      return response;
    } else {
      print('sendGemmaMessage: No response received');
      return 'Sorry, I could not generate a response. Please try again.';
    }
  } catch (e) {
    print('sendGemmaMessage: Error - $e');
    return 'Error: ${e.toString()}';
  }
}
