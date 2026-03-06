// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../ai_rust_api.dart';

/// Delete a locally installed model file.
///
/// If the deleted model is currently loaded, the engine is closed first
/// to avoid leaving the app in an inconsistent state.
///
/// ## Parameters
/// - [modelPath] — Full file path of the model to delete (from [AiModelInfo.filePath]).
///
/// ## Returns
/// `true` if the model was deleted successfully.
Future<bool> aiDeleteModel(String modelPath) async {
  if (modelPath.trim().isEmpty) {
    debugPrint('aiDeleteModel: modelPath is empty.');
    return false;
  }

  final api = AiRustApi.instance;

  // Close the engine if this model is currently active.
  if (api.isInitialized) {
    debugPrint('aiDeleteModel: Closing active engine before deletion.');
    await api.closeEngine();
  }

  try {
    final deleted = await api.deleteModel(modelPath.trim());
    debugPrint('aiDeleteModel: deleted=$deleted path=$modelPath');
    return deleted;
  } catch (e) {
    debugPrint('aiDeleteModel: Error — $e');
    return false;
  }
}
