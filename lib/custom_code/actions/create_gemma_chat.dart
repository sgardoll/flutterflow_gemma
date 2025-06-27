// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import '../GemmaManager.dart';

Future<bool> createGemmaChat(
  double temperature,
  int randomSeed,
  int topK,
) async {
  try {
    final gemmaManager = GemmaManager();

    print('createGemmaChat: Checking if model is initialized...');
    if (!gemmaManager.isInitialized) {
      print('createGemmaChat: Model not initialized');
      return false;
    }

    print('createGemmaChat: Model is initialized, checking session...');

    // Check if we already have a session (which we do from initialization)
    if (gemmaManager.hasSession) {
      print('createGemmaChat: Session already exists, ready to use!');
      return true;
    }

    print('createGemmaChat: No session found, creating new session...');

    // Create a session instead of a chat (which already works)
    final result = await gemmaManager.createSession(
      temperature: temperature,
      randomSeed: randomSeed,
      topK: topK,
    );

    print('createGemmaChat: Session created successfully = $result');
    return result;
  } catch (e) {
    print('Error creating Gemma session: $e');
    print('Stack trace: ${e.toString()}');
    return false;
  }
}
