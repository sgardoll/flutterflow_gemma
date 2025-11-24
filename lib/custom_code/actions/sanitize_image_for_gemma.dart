// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';

Future<String> sanitizeImageForGemma(String? base64Image) async {
  // Check if image exists
  if (base64Image == null) {
    return "";
  }

  // 1. Remove standard whitespace/newlines that break the AI tokenizer
  String cleanString = base64Image.replaceAll(RegExp(r'\s+'), '');

  // 2. Ensure no URI headers (like "data:image/png;base64,") are present
  if (cleanString.contains(',')) {
    cleanString = cleanString.split(',').last;
  }

  return cleanString;
}
