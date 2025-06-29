// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<FFUploadedFile?> resizeImageToConstraints(
  FFUploadedFile originalImage,
  int maxSizeBytes,
  int quality,
) async {
  try {
    // Validate input
    if (originalImage.bytes == null || originalImage.bytes!.isEmpty) {
      print('resizeImageToConstraints: Invalid image - no bytes');
      return null;
    }

    // If image is already under the size limit, return as-is
    if (originalImage.bytes!.length <= maxSizeBytes) {
      print('resizeImageToConstraints: Image already under size limit');
      return originalImage;
    }

    // Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(originalImage.bytes!);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // Calculate resize factor to fit within size constraints
    Uint8List? resizedBytes;

    // Start with original dimensions and gradually reduce
    int targetWidth = image.width;
    int targetHeight = image.height;

    // Try different scale factors until we get under the size limit
    for (double scale = 1.0; scale >= 0.1; scale -= 0.1) {
      targetWidth = (image.width * scale).round();
      targetHeight = (image.height * scale).round();

      // Ensure minimum dimensions
      if (targetWidth < 50 || targetHeight < 50) {
        break;
      }

      // Create resized image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the image scaled
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint(),
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage =
          await picture.toImage(targetWidth, targetHeight);

      // Convert to bytes with quality compression
      final ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        resizedBytes = byteData.buffer.asUint8List();

        // If we're under the size limit, we're done
        if (resizedBytes.length <= maxSizeBytes) {
          print(
              'resizeImageToConstraints: Successfully resized to ${targetWidth}x${targetHeight}, ${resizedBytes.length} bytes');
          break;
        }
      }

      // Clean up
      resizedImage.dispose();
      picture.dispose();
    }

    // Clean up original image
    image.dispose();

    if (resizedBytes == null || resizedBytes.length > maxSizeBytes) {
      print(
          'resizeImageToConstraints: Could not resize image to fit constraints');
      return null;
    }

    // Create new FFUploadedFile with resized data
    final resizedFile = FFUploadedFile(
      name: originalImage.name ?? 'resized_image.png',
      bytes: resizedBytes,
      width: targetWidth.toDouble(),
      height: targetHeight.toDouble(),
    );

    print(
        'resizeImageToConstraints: Final size: ${resizedBytes.length} bytes (${(resizedBytes.length / 1024).toStringAsFixed(1)} KB)');

    return resizedFile;
  } catch (e) {
    print('Error in resizeImageToConstraints: $e');
    return null;
  }
}
