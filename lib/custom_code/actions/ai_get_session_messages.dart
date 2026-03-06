// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../ai_rust_api.dart';

/// Fetch all messages for the current session.
///
/// If generation is in progress, the list includes a partial assistant
/// message with status 'generating'.
///
/// Designed to be called on a polling timer from FlutterFlow pages.
/// The chat widget calls AiRustApi directly; this action is the
/// FlutterFlow-facing counterpart.
///
/// ## Returns
/// `Future<List<dynamic>>` — each item is a `Map<String, dynamic>` with keys:
///   - `id` (String)
///   - `sessionId` (String)
///   - `text` (String)
///   - `isUser` (bool)
///   - `isPartial` (bool)
///   - `timestamp` (int — millisecondsSinceEpoch)
///   - `status` (String — 'pending' | 'generating' | 'complete' | 'error' | 'cancelled')
Future<List<dynamic>> aiGetSessionMessages() async {
  final messages = AiRustApi.instance.getSessionMessages();
  return messages.map((m) => m.toMap()).toList();
}
