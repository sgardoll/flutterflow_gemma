// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../flutter_gemma_library.dart';

/// Send a message to the initialized Gemma model and get a response
///
/// This action sends text (and optionally image) input to the model and returns
/// the generated response. The model must be initialized before calling this action.
///
/// ## Usage in FlutterFlow:
/// 1. Initialize the model using initializeModelAction
/// 2. Call this action with your message text
/// 3. For vision models, optionally provide an image
/// 4. Receive the model's text response
///
/// ## Parameters:
/// - [message]: The text message to send to the model
/// - [image]: Optional image file for vision-capable models
///
/// ## Returns:
/// - String: The model's response text (success)
/// - null: Failed to get response (check logs for details)
///
/// ## Example:
/// ```dart
/// // Text-only message
/// final response = await sendMessageAction("Hello, how are you?");
///
/// // Message with image (for vision models)
/// final response = await sendMessageAction(
///   "What do you see in this image?",
///   uploadedImageFile
/// );
/// ```
Future<String?> sendMessageAction(
  String message,
  FFUploadedFile? image,
) async {
  try {
    if (message.trim().isEmpty) {
      print('sendMessageAction: Error - Message is empty');
      return 'Error: Message cannot be empty.';
    }

    print(
        'sendMessageAction: Sending message: ${message.substring(0, message.length < 50 ? message.length : 50)}...');

    // Get the library instance
    final gemmaLibrary = FlutterGemmaLibrary.instance;

    // Check if model is ready
    if (!gemmaLibrary.isInitialized || !gemmaLibrary.hasSession) {
      const error =
          'Model not initialized or no session available. Please run initializeModelAction first.';
      print('sendMessageAction: $error');
      return 'Error: $error';
    }

    // Convert image to bytes if provided
    Uint8List? imageBytes;
    if (image != null && image.bytes != null) {
      imageBytes = image.bytes;
      print('sendMessageAction: Image provided (${imageBytes!.length} bytes)');

      // Check if model supports vision
      if (!gemmaLibrary.supportsVision) {
        print(
            'sendMessageAction: Warning - Model does not support vision, image will be ignored');
      }
    }

    // Send message to the model
    final response = await gemmaLibrary.sendMessage(
      message.trim(),
      imageBytes: imageBytes,
    );

    if (response != null && response.isNotEmpty) {
      print(
          'sendMessageAction: Response received (${response.length} characters)');
      return response;
    } else {
      const error = 'No response received from model. Please try again.';
      print('sendMessageAction: $error');
      return 'Error: $error';
    }
  } catch (e) {
    final error = 'Error processing message: ${e.toString()}';
    print('sendMessageAction: $error');
    return 'Error: $error';
  }
}
