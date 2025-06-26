// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

Future<bool> initializeLocalGemmaModel(
  String localModelPath,
  String modelType,
  String preferredBackend,
  int maxTokens,
  bool supportImage,
  int maxNumImages,
) async {
  try {
    print('Initializing Gemma model from local file: $localModelPath');

    // Convert string parameters to enums
    ModelType modelTypeEnum;
    switch (modelType.toLowerCase()) {
      case 'gemma':
      case 'gemmait':
      case 'gemma-it':
      case 'gemma_it':
      case 'gemma-3-4b-it':
      case 'gemma-3-2b-it':
      case 'gemma-1b-it':
        modelTypeEnum = ModelType.gemmaIt;
        break;
      case 'deepseek':
      case 'deep-seek':
      case 'deep_seek':
        modelTypeEnum = ModelType.deepSeek;
        break;
      case 'general':
        modelTypeEnum = ModelType.general;
        break;
      default:
        modelTypeEnum = ModelType.gemmaIt;
    }

    PreferredBackend backendEnum;
    switch (preferredBackend.toLowerCase()) {
      case 'gpu':
        backendEnum = PreferredBackend.gpu;
        break;
      case 'cpu':
        backendEnum = PreferredBackend.cpu;
        break;
      case 'gpufloat16':
      case 'gpu_float16':
      case 'gpu-float16':
        backendEnum = PreferredBackend.gpuFloat16;
        break;
      default:
        backendEnum = PreferredBackend.gpu;
    }

    // Create model using the local file path
    final model = await FlutterGemmaPlugin.instance.createModel(
      modelType: modelTypeEnum,
      preferredBackend: backendEnum,
      maxTokens: maxTokens,
      supportImage: supportImage,
      maxNumImages: maxNumImages,
    );

    print('Gemma model initialized successfully from local file!');
    return true;
  } catch (e) {
    print('Error in initializeLocalGemmaModel: $e');
    return false;
  }
}
