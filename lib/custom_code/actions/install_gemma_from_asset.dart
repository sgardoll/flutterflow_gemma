// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import '../GemmaManager.dart';

Future<bool> installGemmaFromAsset(
  String assetPath,
  String? loraPath,
) async {
  try {
    final gemmaManager = GemmaManager();

    return await gemmaManager.installModelFromAsset(
      assetPath,
      loraPath: loraPath,
    );
  } catch (e) {
    print('Error in installGemmaFromAsset: $e');
    return false;
  }
}
