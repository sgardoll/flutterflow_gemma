// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

Future<dynamic> getHuggingfaceModelInfo(
  String modelIdentifier,
  String hfToken,
) async {
  try {
    final modelData = getPredefinedModelData(modelIdentifier);

    return {
      'name': modelIdentifier,
      'description': getModelDescription(modelIdentifier),
      'fileName': modelData['fileName'],
      'fileSize': getEstimatedModelSize(modelIdentifier),
      'url': modelData['downloadUrl'],
    };
  } catch (e) {
    return {
      'name': modelIdentifier,
      'description': 'AI language model',
      'fileName': 'model.task',
      'fileSize': 2147483648,
      'url':
          'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
    };
  }
}

Map<String, dynamic> getPredefinedModelData(String modelIdentifier) {
  // Map of predefined models to their metadata
  final modelData = <String, Map<String, dynamic>>{
    'paligemma-3b-it': {
      'apiUrl': 'https://huggingface.co/api/models/google/paligemma-3b-it-224',
      // NOTE: Using Gemma 3 as placeholder
      'downloadUrl':
          'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
      'fileName': 'gemma-3n-E4B-it-int4.task',
    },
    'gemma-3-4b-it': {
      'apiUrl': 'https://huggingface.co/api/models/google/gemma-3n-E4B-it',
      'downloadUrl':
          'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
      'fileName': 'gemma-3n-E4B-it-int4.task',
    },
    'gemma-3-nano-e4b-it': {
      'apiUrl': 'https://huggingface.co/api/models/google/gemma-3n-E4B-it',
      'downloadUrl':
          'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
      'fileName': 'gemma-3n-E4B-it-int4.task',
    },
    'gemma-3-nano-e2b-it': {
      'apiUrl': 'https://huggingface.co/api/models/google/gemma-3n-E2B-it',
      'downloadUrl':
          'https://huggingface.co/google/gemma-3n-E2B-it/resolve/main/gemma-3n-E2B-it-int4.task',
      'fileName': 'gemma-3n-E2B-it-int4.task',
    },
    'gemma-3-2b-it': {
      'apiUrl': 'https://huggingface.co/api/models/google/gemma-2-2b-it',
      'downloadUrl':
          'https://huggingface.co/google/gemma-2-2b-it/resolve/main/gemma-2-2b-it-int4.task',
      'fileName': 'gemma-2-2b-it-int4.task',
    },
    'gemma-1b-it': {
      'apiUrl': 'https://huggingface.co/api/models/google/gemma-3-1b-it',
      'downloadUrl':
          'https://huggingface.co/google/gemma-3-1b-it/resolve/main/gemma-3-1b-it-int4.task',
      'fileName': 'gemma-3-1b-it-int4.task',
    },
  };

  return modelData[modelIdentifier] ??
      {
        'apiUrl': 'https://huggingface.co/api/models/google/gemma-3n-E4B-it',
        'downloadUrl':
            'https://huggingface.co/google/gemma-3n-E4B-it/resolve/main/gemma-3n-E4B-it-int4.task',
        'fileName': 'gemma-3n-E4B-it-int4.task',
      };
}

Map<String, dynamic> getBasicModelInfo(
    String modelIdentifier, String fileName) {
  return {
    'name': modelIdentifier,
    'description': getModelDescription(modelIdentifier),
    'fileName': fileName,
    'fileSize': getEstimatedModelSize(modelIdentifier),
    'url': getPredefinedModelData(modelIdentifier)['downloadUrl'],
  };
}

String getModelDescription(String modelIdentifier) {
  final descriptions = <String, String>{
    'paligemma-3b-it':
        'PaliGemma 3B Vision (Note: Using Gemma 3 placeholder model file)',
    'gemma-3-4b-it':
        'Gemma 3 4B Instruct - Multimodal model with vision support',
    'gemma-3-nano-e4b-it': 'Gemma 3 4B Edge - Optimized multimodal model',
    'gemma-3-nano-e2b-it': 'Gemma 3 2B Edge - Compact multimodal model',
    'gemma-3-2b-it': 'Gemma 2 2B Instruct - Balanced text-only model',
    'gemma-1b-it': 'Gemma 3 1B Instruct - Compact text-only model',
  };

  return descriptions[modelIdentifier] ?? 'AI language model';
}

int getEstimatedModelSize(String modelIdentifier) {
  final sizes = <String, int>{
    'paligemma-3b-it': 2147483648, // ~2.0GB (Placeholder size)
    'gemma-3-4b-it': 2147483648, // ~2.0GB
    'gemma-3-nano-e4b-it': 2147483648, // ~2.0GB
    'gemma-3-nano-e2b-it': 1073741824, // ~1.0GB
    'gemma-3-2b-it': 1073741824, // ~1.0GB
    'gemma-1b-it': 582077440, // ~555MB
  };

  return sizes[modelIdentifier] ?? 2147483648; // Default to 2GB
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
