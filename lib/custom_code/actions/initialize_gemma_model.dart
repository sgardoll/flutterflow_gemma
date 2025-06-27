// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import '../GemmaManager.dart';

Future<bool> initializeGemmaModel(
  String modelType,
  String preferredBackend,
  int maxTokens,
  bool supportImage,
  int maxNumImages,
) async {
  try {
    final gemmaManager = GemmaManager();

    return await gemmaManager.initializeModel(
      modelType: modelType,
      backend: preferredBackend,
      maxTokens: maxTokens,
      supportImage: supportImage,
      maxNumImages: maxNumImages,
    );
  } catch (e) {
    print('Error in initializeGemmaModel: $e');
    return false;
  }
}
