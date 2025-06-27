// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<bool> manageConversationHistory(
  String message,
  int maxTokenLimit,
) async {
  try {
    final gemmaManager = GemmaManager();

    if (!gemmaManager.isInitialized) {
      print('ManageConversationHistory: Model not initialized');
      return false;
    }

    // Get token count for the current message
    final messageTokenCount = await gemmaManager.getTokenCount(message);

    if (messageTokenCount == null) {
      print('ManageConversationHistory: Could not get token count for message');
      return false;
    }

    print('ManageConversationHistory: Message tokens: $messageTokenCount');
    print('ManageConversationHistory: Max token limit: $maxTokenLimit');

    // If the message alone exceeds 80% of the limit, we need to clear history
    final tokenThreshold = (maxTokenLimit * 0.8).round();

    if (messageTokenCount > tokenThreshold) {
      print(
          'ManageConversationHistory: Message too long, would exceed safe threshold');
      return false;
    }

    // Clear session and create a new one to reset conversation history
    // This prevents token accumulation issues
    print(
        'ManageConversationHistory: Clearing session to reset conversation history');

    await gemmaManager.closeSession();

    // Create a new session with same parameters
    final sessionCreated = await gemmaManager.createSession(
      temperature: 0.8,
      randomSeed: 1,
      topK: 1,
    );

    if (sessionCreated) {
      print('ManageConversationHistory: New session created successfully');
      return true;
    } else {
      print('ManageConversationHistory: Failed to create new session');
      return false;
    }
  } catch (e) {
    print('ManageConversationHistory error: $e');
    return false;
  }
}
