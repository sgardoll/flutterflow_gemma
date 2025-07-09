// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String?> downloadAuthenticatedModel(
  String modelIdentifier,
  String hfToken,
  Future Function(int downloaded, int total, double percentage)? onProgress,
) async {
  /*
   * AVAILABLE MULTIMODAL MODELS:
   * 
   * RECOMMENDED FOR WEB/MOBILE:
   * - 'smolvlm-500m': SmolVLM 500M (1.2GB RAM, image+text, best for web)
   * - 'smolvlm-500m-onnx': ONNX version for cross-platform deployment
   * - 'gemma3-1b-web': Web-optimized Gemma3 (text-only, very efficient)
   * 
   * MULTIMODAL MODELS:
   * - 'smolvlm-2b': SmolVLM 2.2B (better quality, more RAM needed)
   * - 'paligemma-3b-224': Google PaliGemma (224px images, OCR capable)
   * - 'paligemma-3b-448': Google PaliGemma (448px images, higher resolution)
   * - 'paligemma-3b-896': Google PaliGemma (896px images, best quality)
   * - 'nanollava': Compact LLAVA variant (1.05B params, efficient)
   * - 'minicpm-v2': MiniCPM Vision model (good balance)
   * - 'idefics2-8b-ocr': Specialized for OCR and document understanding
   * 
   * UTILITIES:
   * - 'rmbg-1.4-onnx': Background removal model (computer vision)
   * 
   * LEGACY TEXT-ONLY:
   * - 'gemma-3n-e4b-it': Gemma 3 Nano 4B
   * - 'gemma-3n-e2b-it': Gemma 3 Nano 2B
   * - 'gemma3-1b-it': Gemma3 1B
   * 
   * Usage Examples:
   * await downloadAuthenticatedModel('smolvlm-500m', token, onProgress);
   * await downloadAuthenticatedModel('paligemma-3b-448', token, onProgress);
   * await downloadAuthenticatedModel('https://custom-url.com/model.safetensors', token, onProgress);
   */

  try {
    print('=== downloadAuthenticatedModel START ===');
    print('Model identifier: $modelIdentifier');
    print('Token provided: ${hfToken.isNotEmpty}');

    // Get the app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    String downloadUrl;
    String fileName;

    // Check if it's a custom URL or predefined model
    if (modelIdentifier.startsWith('http')) {
      // Custom URL provided
      downloadUrl = modelIdentifier;
      // HARDCODED FIX: Intercept the incorrect URL and replace it
      if (downloadUrl ==
          'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-cpu-int4.task') {
        downloadUrl =
            'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
        print('Applied hardcoded fix for incorrect URL');
      }
      fileName = downloadUrl.split('/').last;
      if (!fileName.contains('.')) {
        fileName += '.task'; // Default extension
      }
    } else {
      // Predefined model identifier
      downloadUrl = _getModelDownloadUrl(modelIdentifier);
      fileName = _getModelFileName(modelIdentifier);
    }

    print('Download URL: $downloadUrl');
    print('File name: $fileName');

    final filePath = '${modelsDir.path}/$fileName';
    final file = File(filePath);

    // Check if file already exists
    if (await file.exists()) {
      print('Model file already exists at: $filePath');
      return filePath;
    }

    // Prepare headers for authenticated request
    final headers = <String, String>{
      'Authorization': 'Bearer $hfToken',
      'User-Agent': 'FlutterGemma/1.0',
    };

    print('Starting download...');
    final request = http.Request('GET', Uri.parse(downloadUrl));
    request.headers.addAll(headers);

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      String errorMsg =
          'Download failed with status ${streamedResponse.statusCode}: ${streamedResponse.reasonPhrase}';

      // Provide specific guidance for common errors
      if (streamedResponse.statusCode == 404) {
        errorMsg +=
            '\n\nThis model may not exist at the specified URL. Common causes:';
        errorMsg += '\n• Model identifier "$modelIdentifier" is not available';
        errorMsg += '\n• HuggingFace repository has moved or been renamed';
        errorMsg += '\n• Model file name has changed';
        errorMsg +=
            '\n\nTry using a different model variant or check HuggingFace for available models.';
      } else if (streamedResponse.statusCode == 401 ||
          streamedResponse.statusCode == 403) {
        errorMsg +=
            '\n\nAuthentication failed. Please check your HuggingFace token.';
      }

      print('ERROR: $errorMsg');
      throw Exception(errorMsg);
    }

    final totalBytes = streamedResponse.contentLength ?? 0;
    int downloadedBytes = 0;

    print('Total bytes to download: $totalBytes');

    // Create file sink for writing
    final sink = file.openWrite();

    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      downloadedBytes += chunk.length;

      if (totalBytes > 0 && onProgress != null) {
        final percentage = (downloadedBytes / totalBytes) * 100;
        onProgress(downloadedBytes, totalBytes, percentage);
      }
    }

    await sink.close();

    print('Download completed successfully');
    print('File saved at: $filePath');
    print('Final size: ${await file.length()} bytes');

    return filePath;
  } on SocketException catch (e) {
    String errorMsg =
        'Network Error: Failed to connect to HuggingFace. Please check your internet connection and try again.';
    errorMsg +=
        '\n\nThis can happen on emulators if DNS is not configured correctly.';
    errorMsg += '\nDetails: $e';
    print('ERROR: $errorMsg');
    return null;
  } catch (e) {
    print('Error in downloadAuthenticatedModel: $e');
    return null;
  }
}

String _getModelDownloadUrl(String modelIdentifier) {
  final modelUrls = <String, String>{
    // Existing Gemma models
    'gemma-3n-e4b-it':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    'gemma3-1b-it':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',

    // New Multimodal Models - SmolVLM (Recommended for on-device)
    'smolvlm-500m':
        'https://huggingface.co/HuggingFaceTB/SmolVLM-500M-Instruct/resolve/main/model.safetensors',
    'smolvlm-500m-onnx':
        'https://huggingface.co/HuggingFaceTB/SmolVLM-500M-Instruct/resolve/main/onnx/model.onnx',
    'smolvlm-2b':
        'https://huggingface.co/HuggingFaceTB/SmolVLM-Instruct/resolve/main/model.safetensors',
    'smolvlm-2b-onnx':
        'https://huggingface.co/HuggingFaceTB/SmolVLM-Instruct/resolve/main/onnx/model.onnx',

    // PaliGemma Models (Google's multimodal)
    'paligemma-3b-224':
        'https://huggingface.co/google/paligemma-3b-pt-224/resolve/main/model.safetensors',
    'paligemma-3b-448':
        'https://huggingface.co/google/paligemma-3b-pt-448/resolve/main/model.safetensors',
    'paligemma-3b-896':
        'https://huggingface.co/google/paligemma-3b-pt-896/resolve/main/model.safetensors',

    // Efficient Multimodal Models
    'nanollava':
        'https://huggingface.co/mlx-community/nanoLLaVA/resolve/main/model.safetensors',
    'minicpm-v2':
        'https://huggingface.co/openbmb/MiniCPM-V-2/resolve/main/model.safetensors',

    // LiteRT Web-Optimized Models
    'gemma3-1b-web':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4-web.task',
    'gemma3-1b-int8-web':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int8-web.task',

    // Vision-specific models
    'idefics2-8b-ocr':
        'https://huggingface.co/huz-relay/idefics2-8b-ocr/resolve/main/model.safetensors',

    // Background removal (computer vision utility)
    'rmbg-1.4-onnx':
        'https://huggingface.co/briaai/RMBG-1.4/resolve/main/onnx/model_fp16.onnx',
  };

  final url = modelUrls[modelIdentifier] ??
      // Default to SmolVLM-500M as it's most suitable for web deployment
      'https://huggingface.co/HuggingFaceTB/SmolVLM-500M-Instruct/resolve/main/model.safetensors';

  print('Mapped model $modelIdentifier to URL: $url');
  return url;
}

String _getModelFileName(String modelIdentifier) {
  final modelFileNames = <String, String>{
    // Existing Gemma models
    'gemma-3n-e4b-it': 'gemma-3n-E4B-it-int4.task',
    'gemma-3n-e2b-it': 'gemma-3n-E2B-it-int4.task',
    'gemma3-1b-it': 'gemma3-1b-it-int4.task',

    // New Multimodal Models - SmolVLM (Recommended for on-device)
    'smolvlm-500m': 'smolvlm-500m-instruct.safetensors',
    'smolvlm-500m-onnx': 'smolvlm-500m-instruct.onnx',
    'smolvlm-2b': 'smolvlm-2b-instruct.safetensors',
    'smolvlm-2b-onnx': 'smolvlm-2b-instruct.onnx',

    // PaliGemma Models (Google's multimodal)
    'paligemma-3b-224': 'paligemma-3b-pt-224.safetensors',
    'paligemma-3b-448': 'paligemma-3b-pt-448.safetensors',
    'paligemma-3b-896': 'paligemma-3b-pt-896.safetensors',

    // Efficient Multimodal Models
    'nanollava': 'nanollava.safetensors',
    'minicpm-v2': 'minicpm-v2.safetensors',

    // LiteRT Web-Optimized Models
    'gemma3-1b-web': 'gemma3-1b-it-int4-web.task',
    'gemma3-1b-int8-web': 'gemma3-1b-it-int8-web.task',

    // Vision-specific models
    'idefics2-8b-ocr': 'idefics2-8b-ocr.safetensors',

    // Background removal (computer vision utility)
    'rmbg-1.4-onnx': 'rmbg-1.4-fp16.onnx',
  };

  return modelFileNames[modelIdentifier] ?? 'smolvlm-500m-instruct.safetensors';
}

/// Get detailed information about available models
Map<String, dynamic>? getModelInfo(String modelIdentifier) {
  final modelInfo = <String, Map<String, dynamic>>{
    // Recommended for Web/Mobile
    'smolvlm-500m': {
      'name': 'SmolVLM 500M Instruct',
      'size': '507M parameters',
      'type': 'multimodal',
      'capabilities': ['image-captioning', 'vqa', 'ocr', 'text-reading'],
      'memory_requirement': '1.2GB GPU RAM',
      'optimized_for': 'web',
      'formats': ['safetensors'],
      'description': 'Smallest multimodal model, perfect for web deployment',
    },
    'smolvlm-500m-onnx': {
      'name': 'SmolVLM 500M ONNX',
      'size': '507M parameters',
      'type': 'multimodal',
      'capabilities': ['image-captioning', 'vqa', 'ocr', 'text-reading'],
      'memory_requirement': '1.2GB RAM',
      'optimized_for': 'cross-platform',
      'formats': ['onnx'],
      'description': 'ONNX version for cross-platform deployment',
    },
    'smolvlm-2b': {
      'name': 'SmolVLM 2.2B Instruct',
      'size': '2.25B parameters',
      'type': 'multimodal',
      'capabilities': [
        'image-captioning',
        'vqa',
        'document-understanding',
        'chart-comprehension'
      ],
      'memory_requirement': '5GB GPU RAM',
      'optimized_for': 'quality',
      'formats': ['safetensors'],
      'description':
          'Higher quality multimodal model with document understanding',
    },

    // PaliGemma Models
    'paligemma-3b-224': {
      'name': 'PaliGemma 3B (224px)',
      'size': '2.93B parameters',
      'type': 'multimodal',
      'capabilities': [
        'image-captioning',
        'vqa',
        'ocr',
        'object-detection',
        'segmentation'
      ],
      'memory_requirement': '6GB GPU RAM',
      'image_resolution': '224x224',
      'optimized_for': 'general-tasks',
      'formats': ['safetensors'],
      'description': 'Google\'s vision-language model for general tasks',
      'license': 'gemma',
    },
    'paligemma-3b-448': {
      'name': 'PaliGemma 3B (448px)',
      'size': '2.93B parameters',
      'type': 'multimodal',
      'capabilities': [
        'image-captioning',
        'vqa',
        'ocr',
        'object-detection',
        'segmentation'
      ],
      'memory_requirement': '8GB GPU RAM',
      'image_resolution': '448x448',
      'optimized_for': 'high-resolution',
      'formats': ['safetensors'],
      'description': 'Higher resolution version for detailed image analysis',
      'license': 'gemma',
    },
    'paligemma-3b-896': {
      'name': 'PaliGemma 3B (896px)',
      'size': '2.93B parameters',
      'type': 'multimodal',
      'capabilities': [
        'image-captioning',
        'vqa',
        'ocr',
        'object-detection',
        'segmentation'
      ],
      'memory_requirement': '12GB GPU RAM',
      'image_resolution': '896x896',
      'optimized_for': 'ultra-high-resolution',
      'formats': ['safetensors'],
      'description': 'Ultra high resolution for detailed document analysis',
      'license': 'gemma',
    },

    // Compact Models
    'nanollava': {
      'name': 'nanoLLaVA',
      'size': '1.05B parameters',
      'type': 'multimodal',
      'capabilities': ['image-captioning', 'vqa'],
      'memory_requirement': '3GB RAM',
      'optimized_for': 'efficiency',
      'formats': ['safetensors', 'mlx'],
      'description': 'Compact LLAVA variant optimized for Apple Silicon',
    },
    'minicpm-v2': {
      'name': 'MiniCPM-V-2',
      'size': '2B parameters',
      'type': 'multimodal',
      'capabilities': ['image-captioning', 'vqa', 'visual-reasoning'],
      'memory_requirement': '4GB GPU RAM',
      'optimized_for': 'balance',
      'formats': ['safetensors'],
      'description': 'Good balance of size and capability',
    },

    // Specialized Models
    'idefics2-8b-ocr': {
      'name': 'Idefics2 8B OCR',
      'size': '8.4B parameters',
      'type': 'multimodal',
      'capabilities': ['ocr', 'document-understanding', 'visual-reasoning'],
      'memory_requirement': '16GB GPU RAM',
      'optimized_for': 'ocr-documents',
      'formats': ['safetensors'],
      'description': 'Specialized for OCR and document understanding',
    },
    'rmbg-1.4-onnx': {
      'name': 'RMBG 1.4',
      'size': '88MB',
      'type': 'computer-vision',
      'capabilities': ['background-removal'],
      'memory_requirement': '512MB RAM',
      'optimized_for': 'image-processing',
      'formats': ['onnx'],
      'description': 'Background removal utility model',
    },

    // Web-Optimized
    'gemma3-1b-web': {
      'name': 'Gemma3 1B Web',
      'size': '1B parameters',
      'type': 'text-only',
      'capabilities': ['text-generation', 'instruction-following'],
      'memory_requirement': '700MB RAM',
      'optimized_for': 'web',
      'formats': ['task'],
      'description': 'Web-optimized text model with LiteRT',
    },
    'gemma3-1b-int8-web': {
      'name': 'Gemma3 1B INT8 Web',
      'size': '1B parameters',
      'type': 'text-only',
      'capabilities': ['text-generation', 'instruction-following'],
      'memory_requirement': '1GB RAM',
      'optimized_for': 'web',
      'formats': ['task'],
      'description': 'INT8 quantized version for better quality',
    },
  };

  return modelInfo[modelIdentifier];
}

/// Get list of recommended models for different use cases
Map<String, List<String>> getModelRecommendations() {
  return {
    'web_deployment': ['smolvlm-500m', 'gemma3-1b-web', 'smolvlm-500m-onnx'],
    'mobile_apps': ['smolvlm-500m', 'nanollava', 'gemma3-1b-web'],
    'multimodal_tasks': ['smolvlm-500m', 'smolvlm-2b', 'paligemma-3b-448'],
    'ocr_documents': ['idefics2-8b-ocr', 'paligemma-3b-896', 'smolvlm-2b'],
    'image_processing': ['rmbg-1.4-onnx', 'paligemma-3b-224'],
    'low_memory': ['smolvlm-500m', 'nanollava', 'gemma3-1b-web'],
    'high_quality': ['paligemma-3b-896', 'idefics2-8b-ocr', 'smolvlm-2b'],
  };
}
