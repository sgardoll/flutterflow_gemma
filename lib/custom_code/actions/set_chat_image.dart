// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<bool> setChatImage(
  FFUploadedFile imageFile,
) async {
  try {
    // Validate the image file
    if (imageFile.bytes == null || imageFile.bytes!.isEmpty) {
      print('setChatImage: Invalid image file - no bytes');
      return false;
    }

    // Check file size (max 10MB)
    if (imageFile.bytes!.length > 10 * 1024 * 1024) {
      print('setChatImage: Image too large (${imageFile.bytes!.length} bytes)');
      return false;
    }

    // Validate image format by checking first few bytes
    final bytes = imageFile.bytes!;
    bool isValidImage = false;

    // Check for common image formats
    if (bytes.length >= 4) {
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        isValidImage = true;
      }
      // PNG
      else if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        isValidImage = true;
      }
      // WebP
      else if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        isValidImage = true;
      }
      // GIF
      else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        isValidImage = true;
      }
      // BMP
      else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        isValidImage = true;
      }
    }

    if (!isValidImage) {
      print('setChatImage: Invalid image format');
      return false;
    }

    print(
        'setChatImage: Valid image file set (${imageFile.name}, ${imageFile.bytes!.length} bytes)');

    // Store in app state for the widget to access
    // Note: This is a simplified approach. In a real implementation,
    // you might want to use a more sophisticated state management solution
    FFAppState().update(() {
      // You would need to add these fields to your app state
      // FFAppState().selectedChatImage = imageFile;
      // FFAppState().hasChatImage = true;
    });

    return true;
  } catch (e) {
    print('Error in setChatImage: $e');
    return false;
  }
}
