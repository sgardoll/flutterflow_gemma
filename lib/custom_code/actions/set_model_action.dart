// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../flutter_gemma_library.dart';

/// Set the model path for use with the FlutterGemma library
///
/// This action registers a downloaded model file with the FlutterGemma plugin
/// so it can be used for inference.
///
/// The model file should already be present in the device storage (typically
/// downloaded via downloadModelAction).
///
/// ## Usage in FlutterFlow: 1. Download a model first using
/// downloadModelAction 2. Call this action with the model filename 3. The
/// model will be registered and ready for initialization
///
/// ## Parameters: - [modelFileName]: The filename of the model (e.g.,
/// "gemma-2b-it.task")
///
/// ## Returns: - true: Model path set successfully - false: Failed to set
/// model path (check logs for details)
///
/// ## Example: ```dart final success = await
/// setModelAction("gemma-2b-it.task"); if (success) { // Model is ready for
/// initialization } ```
Future<bool> setModelAction(String modelFileName) async {
  try {
    if (modelFileName.trim().isEmpty) {
      print('setModelAction: Error - Model filename is empty');
      return false;
    }

    print('setModelAction: Setting model path for $modelFileName');

    // Get the library instance and model manager
    final gemmaLibrary = FlutterGemmaLibrary.instance;
    final modelManager = gemmaLibrary.modelManager;

    // Set the model path
    final success = await modelManager.setModelPath(modelFileName.trim());

    if (success) {
      print('setModelAction: Model path set successfully');
      return true;
    } else {
      print('setModelAction: Failed to set model path');
      return false;
    }
  } catch (e) {
    print('setModelAction: Error - $e');
    return false;
  }
}
