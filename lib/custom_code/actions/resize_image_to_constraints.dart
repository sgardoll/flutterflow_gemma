// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'index.dart'; // Imports other custom actions

import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

Future<FFUploadedFile?> resizeImageToConstraints(
  FFUploadedFile originalImage,
  int maxSizeBytes,
  int quality,
) async {
  try {
    print('=== RESIZE IMAGE DEBUG ===');
    print('Input image: ${originalImage.name}');
    print('Max size: ${(maxSizeBytes / 1024).toStringAsFixed(1)} KB');
    print('Quality: $quality');

    // Validate input
    if (originalImage.bytes == null || originalImage.bytes!.isEmpty) {
      print('resizeImageToConstraints: Invalid image - no bytes');
      return null;
    }

    final originalSize = originalImage.bytes!.length;
    print('Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB');

    // Detect original image format
    final originalFormat = _detectImageFormat(originalImage.bytes!);
    print('Original format: $originalFormat');

    // Check if we need to convert format even if size is OK
    bool needsFormatConversion =
        (originalFormat == 'PNG' || originalFormat == 'unknown');

    // If image is already under the size limit AND is JPEG, return as-is
    if (originalSize <= maxSizeBytes && !needsFormatConversion) {
      print(
          'resizeImageToConstraints: Image already under size limit and in JPEG format');
      return originalImage;
    }

    if (originalSize <= maxSizeBytes && needsFormatConversion) {
      print(
          'resizeImageToConstraints: Image under size limit but needs format conversion to JPEG');
    }

    // Decode the image with error handling
    ui.Codec? codec;
    ui.FrameInfo? frameInfo;
    ui.Image? image;

    try {
      codec = await ui.instantiateImageCodec(originalImage.bytes!);
      frameInfo = await codec.getNextFrame();
      image = frameInfo.image;
      print('Image decoded successfully: ${image.width}x${image.height}');
    } catch (decodeError) {
      print('ERROR: Failed to decode image - $decodeError');
      return null;
    }

    print('Original dimensions: ${image.width}x${image.height}');

    // Calculate optimal scale factor to fit within size constraints
    Uint8List? resizedBytes;
    int targetWidth = image.width;
    int targetHeight = image.height;

    // Determine scale factors to try
    List<double> scaleFactors = [];

    if (originalSize <= maxSizeBytes && needsFormatConversion) {
      // Just format conversion - try original size first, then slightly smaller
      scaleFactors = [1.0, 0.95, 0.9, 0.85, 0.8];
      print('Format conversion mode - trying original size first');
    } else {
      // Actual resizing needed
      double compressionRatio = originalSize / (image.width * image.height);
      double targetPixels = maxSizeBytes / compressionRatio;
      double scaleFactor =
          math.sqrt(targetPixels / (image.width * image.height));

      print('Compression ratio: ${compressionRatio.toStringAsFixed(2)}');
      print('Target scale factor: ${scaleFactor.toStringAsFixed(2)}');

      // Add the calculated scale factor and some variations
      for (double factor = scaleFactor; factor >= 0.1; factor -= 0.1) {
        scaleFactors.add(factor);
      }

      // Also try some common scale factors
      scaleFactors.addAll([0.8, 0.6, 0.5, 0.4, 0.3, 0.2]);
      scaleFactors = scaleFactors.toSet().toList(); // Remove duplicates
      scaleFactors.sort((a, b) => b.compareTo(a)); // Sort descending
    }

    for (double scale in scaleFactors) {
      targetWidth = (image.width * scale).round();
      targetHeight = (image.height * scale).round();

      // Ensure minimum dimensions for vision models
      if (targetWidth < 224 || targetHeight < 224) {
        print('Skipping scale $scale - dimensions too small for vision models');
        continue;
      }

      // Ensure maximum dimensions for memory constraints
      if (targetWidth > 2048 || targetHeight > 2048) {
        print('Skipping scale $scale - dimensions too large');
        continue;
      }

      print('Trying scale $scale -> ${targetWidth}x${targetHeight}');

      // Create resized image with better quality
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Use high-quality paint for better image scaling
      final Paint paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      // Draw the image scaled
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage =
          await picture.toImage(targetWidth, targetHeight);

      // Convert to JPEG for better vision model compatibility
      final ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData != null) {
        // Convert RGBA data to proper JPEG using image package
        final rawBytes = byteData.buffer.asUint8List();
        final image = img.Image.fromBytes(
          width: targetWidth,
          height: targetHeight,
          bytes: rawBytes.buffer,
          format: img.Format.uint8,
          numChannels: 4,
        );

        // Encode as JPEG with quality setting
        resizedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
        final newSize = resizedBytes.length;
        print('New size: ${(newSize / 1024).toStringAsFixed(1)} KB (JPEG)');

        // If we're under the size limit, we're done
        if (newSize <= maxSizeBytes) {
          print(
              'SUCCESS: Resized to ${targetWidth}x${targetHeight}, ${(newSize / 1024).toStringAsFixed(1)} KB (JPEG)');
          break;
        } else {
          print('Still too large, trying smaller scale...');
        }
      }

      // Clean up
      resizedImage.dispose();
      picture.dispose();
    }

    // Clean up original image and codec
    image?.dispose();
    codec?.dispose();

    if (resizedBytes == null || resizedBytes.length > maxSizeBytes) {
      print(
          'FAILED: Could not resize image to fit constraints of ${(maxSizeBytes / 1024).toStringAsFixed(1)} KB');
      return null;
    }

    // Create new FFUploadedFile with resized data
    String outputName = originalImage.name ?? 'resized_image.jpg';
    if (!outputName.toLowerCase().endsWith('.jpg') &&
        !outputName.toLowerCase().endsWith('.jpeg')) {
      outputName = outputName.replaceAll(RegExp(r'\.[^.]+$'), '.jpg');
    }

    final resizedFile = FFUploadedFile(
      name: outputName,
      bytes: resizedBytes,
      width: targetWidth.toDouble(),
      height: targetHeight.toDouble(),
    );

    print(
        'FINAL RESULT: ${outputName}, ${(resizedBytes.length / 1024).toStringAsFixed(1)} KB, ${targetWidth}x${targetHeight}');
    print('=== End Resize Debug ===');

    return resizedFile;
  } catch (e) {
    print('ERROR in resizeImageToConstraints: $e');
    print('Stack trace: ${StackTrace.current}');
    return null;
  }
}

// Helper function to detect image format
String _detectImageFormat(Uint8List imageBytes) {
  if (imageBytes.length < 8) return 'unknown';

  // Check for JPEG header (FF D8 FF)
  if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8 && imageBytes[2] == 0xFF) {
    return 'JPEG';
  }

  // Check for PNG header (89 50 4E 47 0D 0A 1A 0A)
  if (imageBytes.length >= 8 &&
      imageBytes[0] == 0x89 &&
      imageBytes[1] == 0x50 &&
      imageBytes[2] == 0x4E &&
      imageBytes[3] == 0x47 &&
      imageBytes[4] == 0x0D &&
      imageBytes[5] == 0x0A &&
      imageBytes[6] == 0x1A &&
      imageBytes[7] == 0x0A) {
    return 'PNG';
  }

  // Check for WebP header (RIFF....WEBP)
  if (imageBytes.length >= 12 &&
      imageBytes[0] == 0x52 &&
      imageBytes[1] == 0x49 &&
      imageBytes[2] == 0x46 &&
      imageBytes[3] == 0x46 &&
      imageBytes[8] == 0x57 &&
      imageBytes[9] == 0x45 &&
      imageBytes[10] == 0x42 &&
      imageBytes[11] == 0x50) {
    return 'WebP';
  }

  return 'unknown';
}
