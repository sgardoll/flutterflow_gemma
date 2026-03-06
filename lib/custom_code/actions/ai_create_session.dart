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

/// Create a new chat session, clearing previous message history.
///
/// The engine must already be initialized via [aiInitialize].
///
/// ## Returns The session ID string on success, or `null` if the engine isn't
/// ready.
Future<String?> aiCreateSession() async {
  final api = AiRustApi.instance;

  if (!api.isInitialized) {
    debugPrint('aiCreateSession: Engine not initialized.');
    return null;
  }

  try {
    final sessionId = await api.createSession();
    debugPrint('aiCreateSession: Created session $sessionId');
    return sessionId;
  } catch (e) {
    debugPrint('aiCreateSession: Error — $e');
    return null;
  }
}
