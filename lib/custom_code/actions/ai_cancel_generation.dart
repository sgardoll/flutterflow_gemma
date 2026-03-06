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

import '../ai_rust_api.dart';

/// Cancel the current in-flight AI generation.
///
/// Any tokens already generated are committed as a cancelled message so the
/// user can see partial output. The widget's polling loop will detect the
/// state change on its next tick.
///
/// ## Returns `true` if a generation was active and was cancelled. `false` if
/// nothing was generating.
Future<bool> aiCancelGeneration() async {
  final cancelled = await AiRustApi.instance.cancelGeneration();
  debugPrint('aiCancelGeneration: cancelled=$cancelled');
  return cancelled;
}
