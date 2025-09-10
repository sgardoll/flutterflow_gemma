// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../flutter_gemma_library.dart';

/// Initialize a Gemma model for inference
///
/// This action initializes a model that has been downloaded and set using the
/// previous actions. It creates the model instance, sets up parameters, and
/// creates a session ready for inference.
///
/// ## Usage in FlutterFlow:
/// 1. Download a model using downloadModelAction
/// 2. Set the model path using setModelAction
/// 3. Call this action to initialize the model
/// 4. Use sendMessageAction to interact with the model
///
/// ## Parameters:
/// - [modelType]: Model identifier (auto-derived from filename if not provided)
/// - [backend]: Processing backend ('gpu', 'cpu', 'tpu') - defaults to 'gpu'
/// - [maxTokens]: Maximum tokens to generate - defaults to 1024
/// - [temperature]: Randomness in generation (0.0-1.0) - defaults to 0.8
/// - [randomSeed]: Seed for reproducible results - defaults to 1
/// - [topK]: Top-K sampling parameter - defaults to 1
///
/// ## Returns:
/// - true: Model initialized and session created successfully
/// - false: Initialization failed (check logs for details)
///
/// ## Example:
/// ```dart
/// final success = await initializeModelAction(
///   modelType: "gemma-2b-it",
///   backend: "gpu",
///   maxTokens: 512,
///   temperature: 0.7,
/// );
/// ```
Future<bool> initializeModelAction(
  String? modelType,
  String backend,
  int? maxTokens,
  double temperature,
  int randomSeed,
  int topK,
) async {
  try {
    print('initializeModelAction: Starting model initialization');
    print(
        'initializeModelAction: Parameters - backend: $backend, maxTokens: $maxTokens, temp: $temperature');

    // Get the library instance
    final gemmaLibrary = FlutterGemmaLibrary.instance;

    // Determine model type if not provided (could be derived from set model path)
    final finalModelType = modelType ?? 'gemma-2b-it'; // Default fallback

    print('initializeModelAction: Using model type: $finalModelType');

    // Initialize the model
    final modelInitialized = await gemmaLibrary.initializeModel(
      modelType: finalModelType,
      backend: backend,
      maxTokens: maxTokens ?? 1024,
    );

    if (!modelInitialized) {
      print('initializeModelAction: Model initialization failed');
      return false;
    }

    print('initializeModelAction: Model initialized, creating session...');

    // Create an inference session
    final sessionCreated = await gemmaLibrary.createSession(
      temperature: temperature,
      randomSeed: randomSeed,
      topK: topK,
    );

    if (!sessionCreated) {
      print('initializeModelAction: Session creation failed');
      return false;
    }

    print('initializeModelAction: Model and session ready for inference');
    print(
        'initializeModelAction: Model supports vision: ${gemmaLibrary.supportsVision}');

    return true;
  } catch (e) {
    print('initializeModelAction: Error - $e');
    return false;
  }
}
