// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../ai_rust_api.dart';
import '../ai_types.dart';

/// Fetch all messages for the current session.
///
/// If generation is in progress, the list includes a partial assistant
/// message with [AiMessageStatus.generating].
///
/// Designed to be called on a polling timer from the chat widget.
///
/// ## Returns
/// A list of [AiMessageRecord] sorted oldest-first.
/// Returns an empty list if no session is active.
List<AiMessageRecord> aiGetSessionMessages() {
  final api = AiRustApi.instance;
  return api.getSessionMessages();
}
