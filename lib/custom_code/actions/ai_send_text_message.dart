// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../ai_rust_api.dart';

/// Send a text message to the current AI session.
///
/// Generation runs asynchronously — poll [aiGetSessionMessages] to
/// track progress and retrieve the final response.
///
/// ## Parameters
/// - [message] — The user prompt text.
///
/// ## Returns
/// `true` if the message was accepted and generation started.
/// `false` if the engine is not ready, already generating, or input is empty.
Future<bool> aiSendTextMessage(String message) async {
  final api = AiRustApi.instance;

  if (!api.isInitialized) {
    debugPrint('aiSendTextMessage: Engine not initialized.');
    return false;
  }

  final text = message.trim();
  if (text.isEmpty) {
    debugPrint('aiSendTextMessage: Empty message.');
    return false;
  }

  try {
    final accepted = await api.sendTextMessage(text);
    debugPrint('aiSendTextMessage: accepted=$accepted');
    return accepted;
  } catch (e) {
    debugPrint('aiSendTextMessage: Error — $e');
    return false;
  }
}
