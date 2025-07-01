// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import './GemmaManager.dart';

Future<bool> createGemmaSession(
  double temperature,
  int randomSeed,
  int topK,
) async {
  try {
    print('createGemmaSession: Starting session creation...');
    print('Parameters: temp=$temperature, seed=$randomSeed, topK=$topK');

    final gemmaManager = GemmaManager();
    print(
        'createGemmaSession: GemmaManager initialized=${gemmaManager.isInitialized}');
    print('createGemmaSession: Already has session=${gemmaManager.hasSession}');

    // If we already have a session, just return true
    if (gemmaManager.hasSession) {
      print('createGemmaSession: Session already exists, skipping creation');
      return true;
    }

    final result = await gemmaManager.createSession(
      temperature: temperature,
      randomSeed: randomSeed,
      topK: topK,
    );

    print('createGemmaSession: Session creation result=$result');
    return result;
  } catch (e) {
    print('Error in createGemmaSession: $e');
    return false;
  }
}
