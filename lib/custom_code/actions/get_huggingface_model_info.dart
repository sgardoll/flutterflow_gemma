// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<dynamic> getHuggingfaceModelInfo(
  String modelIdentifier,
  String? huggingFaceToken,
) async {
  try {
    // Predefined models with their exact information
    final Map<String, Map<String, dynamic>> predefinedModels = {
      'gemma-3-4b-it': {
        'name': 'Gemma 3 4B Instruct',
        'description': 'Multimodal text and image input, 128K context window',
        'url':
            'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
        'fileSize': 4400000000, // ~4.4GB based on litert performance table
        'fileName': 'gemma-3n-E4B-it-int4.task',
        'provider': 'Google',
        'repository': 'google/gemma-3n-E4B-it-litert-preview',
      },
      'gemma-3-nano-e4b-it': {
        'name': 'Gemma 3 4B Edge',
        'description': 'Optimized 4B model with vision support',
        'url':
            'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
        'fileSize': 4400000000, // ~4.4GB based on litert performance table
        'fileName': 'gemma-3n-E4B-it-int4.task',
        'provider': 'Google',
        'repository': 'google/gemma-3n-E4B-it-litert-preview',
      },
      'gemma-3-2b-it': {
        'name': 'Gemma 3 2B Instruct',
        'description': 'Multimodal text and image input, efficient 2B model',
        'url':
            'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
        'fileSize': 2500000000, // ~2.5GB estimated
        'fileName': 'gemma-3n-E2B-it-int4.task',
        'provider': 'Google',
        'repository': 'google/gemma-3n-E2B-it-litert-preview',
      },
      'gemma-3-nano-e2b-it': {
        'name': 'Gemma 3 2B Edge',
        'description': 'Compact 2B model with vision support',
        'url':
            'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
        'fileSize': 2500000000, // ~2.5GB estimated
        'fileName': 'gemma-3n-E2B-it-int4.task',
        'provider': 'Google',
        'repository': 'google/gemma-3n-E2B-it-litert-preview',
      },
      'gemma-1b-it': {
        'name': 'Gemma 3 1B Instruct',
        'description': 'Compact 1B model optimized for mobile deployment',
        'url':
            'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
        'fileSize': 555000000, // 555MB from HuggingFace files list
        'fileName': 'Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
        'provider': 'LiteRT Community',
        'repository': 'litert-community/Gemma3-1B-IT',
      },
    };

    // Check if it's a predefined model
    if (predefinedModels.containsKey(modelIdentifier)) {
      return predefinedModels[modelIdentifier];
    }

    // Handle custom HuggingFace URL
    if (modelIdentifier.startsWith('https://huggingface.co/')) {
      return await _parseCustomHuggingFaceUrl(
          modelIdentifier, huggingFaceToken);
    }

    // Handle repository format (e.g., "google/gemma-3-1b-it")
    if (modelIdentifier.contains('/') && !modelIdentifier.startsWith('http')) {
      return await _getRepositoryInfo(modelIdentifier, huggingFaceToken);
    }

    return null;
  } catch (e) {
    print('Error getting HuggingFace model info: $e');
    return null;
  }
}

Future<dynamic> _parseCustomHuggingFaceUrl(
  String url,
  String? token,
) async {
  try {
    // Parse URL to extract repository and file information
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    if (pathSegments.length < 4 || !pathSegments.contains('resolve')) {
      return null;
    }

    final repoOwner = pathSegments[0];
    final repoName = pathSegments[1];
    final repository = '$repoOwner/$repoName';
    final fileName = pathSegments.last;

    // Get file size from HuggingFace API
    final fileSize = await _getFileSize(repository, fileName, token);

    return {
      'name': fileName,
      'description': 'Custom model from HuggingFace',
      'url': url,
      'fileSize': fileSize ?? 0,
      'fileName': fileName,
      'provider': repoOwner,
      'repository': repository,
    };
  } catch (e) {
    print('Error parsing custom HuggingFace URL: $e');
    return null;
  }
}

Future<dynamic> _getRepositoryInfo(
  String repository,
  String? token,
) async {
  try {
    // Get repository information from HuggingFace API
    final headers = <String, String>{
      'User-Agent': 'FlutterFlow-App/1.0',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('https://huggingface.co/api/models/$repository'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return {
        'name': data['modelId'] ?? repository,
        'description':
            data['cardData']?['model_description'] ?? 'Model from HuggingFace',
        'url': '', // Will need to be specified by user
        'fileSize': 0, // Unknown without specific file
        'fileName': '',
        'provider': repository.split('/')[0],
        'repository': repository,
        'tags': data['tags'] ?? [],
        'downloads': data['downloads'] ?? 0,
      };
    }

    return null;
  } catch (e) {
    print('Error getting repository info: $e');
    return null;
  }
}

Future<int?> _getFileSize(
  String repository,
  String fileName,
  String? token,
) async {
  try {
    final headers = <String, String>{
      'User-Agent': 'FlutterFlow-App/1.0',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Get file list from repository
    final response = await http.get(
      Uri.parse('https://huggingface.co/api/models/$repository/tree/main'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> files = json.decode(response.body);

      for (final file in files) {
        if (file['path'] == fileName) {
          return file['size'] as int?;
        }
      }
    }

    return null;
  } catch (e) {
    print('Error getting file size: $e');
    return null;
  }
}
