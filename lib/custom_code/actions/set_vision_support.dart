// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/app_state.dart';

/// Manually set vision support flag for testing
///
/// This is a workaround action to manually enable/disable vision support
/// in the app state. This can be useful for testing or when the automatic
/// detection fails.
///
/// Parameters:
/// - [supportsVision]: Whether to enable or disable vision support
///
/// Returns: true if successfully updated
Future<bool> setVisionSupport(bool supportsVision) async {
  try {
    final appState = FFAppState();

    print('setVisionSupport: Setting modelSupportsVision to $supportsVision');
    appState.modelSupportsVision = supportsVision;

    print('setVisionSupport: Vision support updated successfully');
    return true;
  } catch (e) {
    print('setVisionSupport: Error - $e');
    return false;
  }
}
