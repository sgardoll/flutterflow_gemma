// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

Future<bool> initializeGemmaModel(
  String filePath,
  String? modelType,
  String? backend,
) async {
  try {
    print('initializeGemmaModel: Starting initialization...');
    print('File path: $filePath');
    print('Model type: $modelType');
    print('Backend: $backend');

    final gemmaManager = GemmaManager();

    // Derive model type from path if not provided
    final finalModelType =
        modelType ?? GemmaManager.getModelTypeFromPath(filePath);
    final finalBackend = backend ?? 'gpu';

    // Check if model supports vision
    final supportsVision = GemmaManager.isMultimodalModel(finalModelType);

    print('Final model type: $finalModelType');
    print('Supports vision: $supportsVision');
    print('Backend: $finalBackend');

    // Get just the filename from the full path
    final modelFileName = filePath.split('/').last;

    final success = await gemmaManager.initializeModel(
      modelType: finalModelType,
      backend: finalBackend,
      maxTokens: 1024,
      supportImage: supportsVision,
      maxNumImages: 1,
      localModelPath: modelFileName,
    );

    if (success) {
      print('initializeGemmaModel: Model initialized successfully!');
      print('Model: ${gemmaManager.currentModelType}');
      print('Backend: ${gemmaManager.currentBackend}');
      print('Supports vision: ${gemmaManager.supportsVision}');
    } else {
      print('initializeGemmaModel: Model initialization failed');
    }

    return success;
  } catch (e) {
    print('initializeGemmaModel: Error - $e');
    return false;
  }
}
