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

/// List all locally installed AI models.
///
/// Returns metadata for each installed model including ID, display name, file
/// size, and capability flags (vision, function-calling).
///
/// Useful for populating a model-selection UI without hardcoding options.
///
/// ## Returns `Future<List<dynamic>>` — each item is a `Map<String, dynamic>`
/// with keys: - `id` (String) - `displayName` (String) - `filePath` (String?)
/// - `fileSizeBytes` (int?) - `fileSizeFormatted` (String) - `supportsVision`
/// (bool) - `supportsFunctionCalling` (bool) - `isInstalled` (bool) -
/// `downloadUrl` (String?) - `installedAt` (int? — millisecondsSinceEpoch)
Future<List<dynamic>> aiListModels() async {
  try {
    final models = await AiRustApi.instance.listModels();
    debugPrint('aiListModels: Found ${models.length} installed model(s).');
    return models.map((m) => m.toMap()).toList();
  } catch (e) {
    debugPrint('aiListModels: Error — $e');
    return [];
  }
}
