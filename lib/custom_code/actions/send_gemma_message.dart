// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/flutter_gemma_library.dart';
import 'index.dart'; // Imports other custom actions

/// Send a text message to the Gemma model and get a response
///
/// This action sends a text message to the currently initialized Gemma model
/// and returns the AI-generated response.
///
/// Parameters: - message: The text message to send to the model
///
/// Returns: String response from the model, or null if error occurred
Future<String?> sendGemmaMessage(String message) async {
  try {
    print('FlutterFlow Action: Sending message to Gemma model');
    print('Message: $message');

    // Validate input
    if (message.trim().isEmpty) {
      print('FlutterFlow Action: Empty message provided');
      return 'Please provide a message to send.';
    }

    // Get the FlutterGemma library instance
    final gemma = FlutterGemmaLibrary.instance;

    // Check if model is initialized
    if (!gemma.isInitialized) {
      print('FlutterFlow Action: Model not initialized');
      return 'Please initialize a model first before sending messages.';
    }

    // Send the message
    final response = await gemma.sendMessage(message.trim());

    if (response != null) {
      print('FlutterFlow Action: Received response from model');
      print('Response length: ${response.length} characters');
      return response;
    } else {
      print('FlutterFlow Action: No response received from model');
      return 'Sorry, I was unable to generate a response. Please try again.';
    }
  } catch (e) {
    print('FlutterFlow Action Error: $e');
    return 'An error occurred while processing your message. Please try again.';
  }
}
