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

/// Send a vision + text message to the current AI session.
///
/// Generation runs asynchronously — poll [aiGetSessionMessages] to
/// track progress and retrieve the final response.
///
/// If the current model does not support vision, falls back to text-only.
///
/// ## Parameters
/// - [message] — The user prompt text.
/// - [image] — The image file to attach (FFUploadedFile with bytes).
///
/// ## Returns
/// `true` if the message was accepted and generation started.
/// `false` if the engine is not ready, already generating, or both inputs empty.
Future<bool> aiSendImageMessage(
  String message,
  FFUploadedFile? image,
) async {
  final api = AiRustApi.instance;

  if (!api.isInitialized) {
    debugPrint('aiSendImageMessage: Engine not initialized.');
    return false;
  }

  final text = message.trim();
  final bytes = image?.bytes;

  if (text.isEmpty && (bytes == null || bytes.isEmpty)) {
    debugPrint('aiSendImageMessage: Both message and image are empty.');
    return false;
  }

  final prompt = text.isNotEmpty ? text : 'Analyze this image';

  try {
    // Use vision path only when both bytes are present and model supports it.
    if (bytes != null && bytes.isNotEmpty && api.supportsVision) {
      // Basic size guard: skip images >10 MB to avoid OOM.
      if (bytes.length > 10 * 1024 * 1024) {
        debugPrint(
            'aiSendImageMessage: Image too large (${bytes.length} bytes), falling back to text.');
        return await api.sendTextMessage(prompt);
      }
      final accepted = await api.sendImageMessage(prompt, bytes);
      debugPrint('aiSendImageMessage: vision accepted=$accepted');
      return accepted;
    }

    // Model is text-only or no image provided — send as text.
    final accepted = await api.sendTextMessage(prompt);
    debugPrint('aiSendImageMessage: text-only accepted=$accepted');
    return accepted;
  } catch (e) {
    debugPrint('aiSendImageMessage: Error — $e');
    return false;
  }
}
