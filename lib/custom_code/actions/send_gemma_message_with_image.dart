// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'manage_conversation_history.dart';

Future<String?> sendGemmaMessageWithImage(
  String message,
  FFUploadedFile imageFile,
) async {
  try {
    final gemmaManager = GemmaManager();

    // Convert FFUploadedFile to Uint8List
    final imageBytes = imageFile.bytes;

    if (imageBytes == null) {
      print('Error: Image file has no bytes');
      return null;
    }

    // Enhanced prompt for better image understanding
    String enhancedMessage = message;
    if (message.toLowerCase().contains('what is this') ||
        message.toLowerCase().contains('what are these') ||
        message.toLowerCase().contains('identify') ||
        message.toLowerCase().contains('describe')) {
      enhancedMessage =
          "I'm sharing an image with you. Please analyze and describe what you see in this image. " +
              message;
    }

    // First, try to send the message normally
    try {
      return await gemmaManager.sendMessage(
        enhancedMessage,
        imageBytes: imageBytes,
      );
    } catch (e) {
      // If we get a token limit error, clear conversation history and retry
      if (e.toString().contains('maxTokens') ||
          e.toString().contains('Input is too long') ||
          e.toString().contains('OUT_OF_RANGE')) {
        print(
            'Token limit reached, clearing conversation history and retrying...');

        // Clear conversation history and create new session
        final historyCleared =
            await manageConversationHistory(enhancedMessage, 2048);

        if (historyCleared) {
          // Retry sending the message with fresh session
          return await gemmaManager.sendMessage(
            enhancedMessage,
            imageBytes: imageBytes,
          );
        } else {
          print('Failed to clear conversation history');
          return 'Sorry, the conversation has become too long. Please restart the chat.';
        }
      } else {
        // Re-throw other errors
        throw e;
      }
    }
  } catch (e) {
    print('Error in sendGemmaMessageWithImage: $e');
    return null;
  }
}
