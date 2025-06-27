// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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

    print(
        'createGemmaChat: Creating chat with temperature=$temperature, randomSeed=$randomSeed, topK=$topK');

    // Create a chat instance instead of a session
    final result = await gemmaManager.createChat(
      temperature: temperature,
      randomSeed: randomSeed,
      topK: topK,
    );

    print('createGemmaChat: Chat created successfully = $result');
    return result;
  } catch (e) {
    print('Error creating Gemma chat: $e');
    print('Stack trace: ${e.toString()}');
    return false;
  }
}
