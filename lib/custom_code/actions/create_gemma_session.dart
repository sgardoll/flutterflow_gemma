// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<bool> createGemmaSession(
  double temperature,
  int randomSeed,
  int topK,
) async {
  try {
    final gemmaManager = GemmaManager();

    return await gemmaManager.createSession(
      temperature: temperature,
      randomSeed: randomSeed,
      topK: topK,
    );
  } catch (e) {
    print('Error in createGemmaSession: $e');
    return false;
  }
}
