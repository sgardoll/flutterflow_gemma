// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future closeModel() async {
  try {
    // Get the GemmaManager singleton instance
    final gemmaManager = GemmaManager();

    // Close the model (which also closes the session in correct order)
    await gemmaManager.closeModel();

    print('closeModel: Model and session closed successfully');
  } catch (e) {
    print('closeModel: Error closing model: $e');
  }
}
