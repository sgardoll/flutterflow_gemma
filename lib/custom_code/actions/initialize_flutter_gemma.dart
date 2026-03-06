// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions
// Begin custom widget code

import 'package:flutter_gemma/flutter_gemma.dart';

/// Initialize the FlutterGemma plugin.
///
/// Call this before any other AI operations. Can be called multiple times
/// safely (it's a no-op if already initialized).
///
/// ## Returns `true` if initialization succeeded, `false` otherwise.
Future<bool> initializeFlutterGemma() async {
  try {
    await FlutterGemma.initialize();
    return true;
  } catch (e) {
    debugPrint('initializeFlutterGemma: Error — $e');
    return false;
  }
}
