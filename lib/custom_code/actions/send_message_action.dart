// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import '/custom_code/flutter_gemma_library.dart';

Future<void> sendMessageAction(
  BuildContext context,
  String text,
  Future Function() onMessageSent,
  Future Function() onResponseStream,
  Future Function(String) onResponse,
  Future Function() onThinking,
  Future Function(String) onError,
  bool isVisionModel,
  FFUploadedFile? image,
) async {
  try {
    // Show the thinking indicator
    await onThinking();

    // Get the active session from your Gemma service instance
    final gemma = (GemmaChatService.instance.gemma as FlutterGemma);
    final model = gemma.initializedModel;
    if (model == null) {
      throw Exception("Model is not initialized");
    }
    final session = model.currentSession;
    if (session == null) {
      throw Exception("Session is not initialized");
    }

    // Convert the uploaded image file to bytes
    Uint8List? imageBytes;
    if (image != null && image.bytes != null) {
      imageBytes = image.bytes;
    }

    // THIS IS THE KEY CHANGE:
    // We are now calling the low-level addQueryChunk method directly,
    // passing both the text and the image bytes in our unified Message object.
    await session.addQueryChunk(text: text, imageBytes: imageBytes);
    await onMessageSent();

    // Start listening to the response stream
    final stream = session.getResponseAsync();
    await onResponseStream();

    String fullResponse = '';
    await for (final response in stream) {
      fullResponse += response;
      await onResponse(fullResponse);
    }
  } catch (e) {
    // Handle any errors that occur
    await onError(e.toString());
  }
}
