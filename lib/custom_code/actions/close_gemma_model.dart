// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<void> closeGemmaModel() async {
  try {
    final gemmaManager = GemmaManager();
    await gemmaManager.closeModel();
    print('Gemma model closed successfully');
  } catch (e) {
    print('Error in closeGemmaModel: $e');
  }
}
