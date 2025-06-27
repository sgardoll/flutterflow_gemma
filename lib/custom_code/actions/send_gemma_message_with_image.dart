// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<String?> sendGemmaMessageWithImage(
  String message,
  FFUploadedFile imageFile,
) async {
  try {
    final gemmaManager = GemmaManager();

    // Convert FFUploadedFile to Uint8List
    final imageBytes = imageFile.bytes;

    if (imageBytes == null) {
      print('Error: Image file has no bytes');
      return null;
    }

    // Use sendMessage for session-based messaging with image support
    return await gemmaManager.sendMessage(
      message,
      imageBytes: imageBytes,
    );
  } catch (e) {
    print('Error in sendGemmaMessageWithImage: $e');
    return null;
  }
}
