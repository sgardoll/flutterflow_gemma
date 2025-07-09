// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<bool> createGemmaSession(
  double? temperature,
  int? topK,
  int? randomSeed,
) async {
  try {
    print('createGemmaSession: Starting session creation...');

    final gemmaManager = GemmaManager();

    // Check if model is initialized
    if (!gemmaManager.isInitialized) {
      print('createGemmaSession: Error - Model not initialized');
      return false;
    }

    // Use defaults if parameters not provided
    final finalTemperature = temperature ?? 0.8;
    final finalTopK = topK ?? 1;
    final finalRandomSeed = randomSeed ?? 1;

    print(
        'Parameters: temp=$finalTemperature, topK=$finalTopK, seed=$finalRandomSeed');

    final success = await gemmaManager.createSession(
      temperature: finalTemperature,
      randomSeed: finalRandomSeed,
      topK: finalTopK,
    );

    if (success) {
      print('createGemmaSession: Session created successfully!');
      print('Ready for chat: ${gemmaManager.hasSession}');
    } else {
      print('createGemmaSession: Session creation failed');
    }

    return success;
  } catch (e) {
    print('createGemmaSession: Error - $e');
    return false;
  }
}
