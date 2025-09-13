// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'index.dart'; // Imports other custom actions

import '../flutter_gemma_library.dart';

/// Close the current Gemma model and clean up resources
///
/// This action closes the active model session and frees up system resources.
/// Use this when you're done with the model or want to switch to a different model.
///
/// ## Usage in FlutterFlow:
/// - Call this action when you want to stop using the current model
/// - Useful for freeing memory or switching between models
/// - The model will need to be re-initialized after closing
///
/// ## Returns:
/// - Future<void>: Completes when model is successfully closed
Future<void> closeModel() async {
  try {
    print('closeModel: Closing Gemma model and session...');

    // Get the library instance and close the model
    final gemmaLibrary = FlutterGemmaLibrary.instance;
    await gemmaLibrary.closeModel();

    print('closeModel: Model and session closed successfully');
  } catch (e) {
    print('closeModel: Error closing model: $e');
  }
}
