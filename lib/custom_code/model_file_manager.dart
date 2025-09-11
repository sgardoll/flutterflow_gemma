/// Model file management for FlutterGemma library
///
/// This class handles downloading, storing, and managing Gemma model files
/// for FlutterFlow applications. It supports both custom URLs and Hugging Face
/// repositories with authentication.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progress callback for download operations
typedef DownloadProgressCallback = Function(
    int downloaded, int total, double percentage);

/// Model file manager class providing download and management capabilities
class ModelFileManager {
  /// Download a model from a network URL or Hugging Face repository
  ///
  /// [url] - The download URL or Hugging Face model identifier
  /// [huggingFaceToken] - Optional HuggingFace authentication token
  /// [onProgress] - Optional progress callback for download status
  ///
  /// Returns the local file path if successful, null if failed
  Future<String?> downloadModelFromNetwork(
    String url, {
    String? huggingFaceToken,
    DownloadProgressCallback? onProgress,
  }) async {
    try {
      print('ModelFileManager: Starting download - $url');

      // Determine if this is a Hugging Face repository or direct URL
      final downloadUrl =
          _isHuggingFaceRepo(url) ? _buildHuggingFaceUrl(url) : url;
      final fileName = _extractFileName(downloadUrl);

      print('ModelFileManager: Download URL - $downloadUrl');
      print('ModelFileManager: File name - $fileName');

      // Platform-specific storage handling
      if (kIsWeb) {
        return await _downloadModelWeb(
            downloadUrl, fileName, huggingFaceToken, onProgress);
      } else {
        return await _downloadModelNative(
            downloadUrl, fileName, huggingFaceToken, onProgress);
      }
    } catch (e) {
      print('ModelFileManager: Download error - $e');
      return null;
    }
  }

  /// Download model for native platforms (iOS/Android)
  Future<String?> _downloadModelNative(
    String downloadUrl,
    String fileName,
    String? huggingFaceToken,
    DownloadProgressCallback? onProgress,
  ) async {
    try {
      // Get the documents directory for storage
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);

      // Check if file already exists
      if (await file.exists()) {
        final fileSize = await file.length();
        print(
            'ModelFileManager: File already exists (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)');
        return filePath;
      }

      // Prepare headers
      final headers = <String, String>{
        'User-Agent': 'FlutterGemma/1.0',
      };

      // Add authorization if HuggingFace token provided
      if (huggingFaceToken != null && huggingFaceToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $huggingFaceToken';
      }

      // Start download
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers.addAll(headers);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final error =
            'Download failed with status ${streamedResponse.statusCode}';
        print('ModelFileManager: $error');
        throw Exception(error);
      }

      final totalBytes = streamedResponse.contentLength ?? 0;
      int downloadedBytes = 0;

      // Create file and download with progress tracking
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

      print(
          'ModelFileManager: Download completed - ${await file.length()} bytes');
      return filePath;
    } catch (e) {
      print('ModelFileManager: Download error - $e');
      return null;
    }
  }

  /// Download model for web platform using URL-based approach
  Future<String?> _downloadModelWeb(
    String downloadUrl,
    String fileName,
    String? huggingFaceToken,
    DownloadProgressCallback? onProgress,
  ) async {
    try {
      // Check if model URL is already cached
      final prefs = await SharedPreferences.getInstance();
      final existingModel = prefs.getString('model_$fileName');
      if (existingModel != null) {
        print('ModelFileManager: Model already registered for web');
        return fileName; // Return filename as identifier for web
      }

      print(
          'ModelFileManager: Registering model URL for web streaming: $downloadUrl');

      // For web, we don't download the entire file to avoid memory issues
      // Instead, we validate the URL and store metadata for flutter_gemma to use directly

      // Validate the URL is accessible
      final headers = <String, String>{
        'User-Agent': 'FlutterGemma/1.0',
      };

      // Add authorization if HuggingFace token provided
      if (huggingFaceToken != null && huggingFaceToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $huggingFaceToken';
      }

      // Make a HEAD request to validate URL and get file size
      final headRequest = http.Request('HEAD', Uri.parse(downloadUrl));
      headRequest.headers.addAll(headers);

      final headResponse = await headRequest.send();

      if (headResponse.statusCode != 200) {
        final error =
            'URL validation failed with status ${headResponse.statusCode}';
        print('ModelFileManager: $error');
        throw Exception(error);
      }

      final totalBytes = headResponse.contentLength ?? 0;

      // If progress callback is provided, simulate progress for URL registration
      if (onProgress != null && totalBytes > 0) {
        // Simulate quick progress for URL validation
        for (int i = 0; i <= 100; i += 25) {
          final simulatedDownloaded = (totalBytes * i / 100).round();
          onProgress(simulatedDownloaded, totalBytes, i.toDouble());
          await Future.delayed(Duration(milliseconds: 50));
        }
      }

      // Store model metadata for web platform
      // flutter_gemma web implementation will handle direct URL streaming
      await prefs.setString(
          'model_$fileName', downloadUrl); // Store URL directly
      await prefs.setInt('model_${fileName}_size', totalBytes);
      await prefs.setString('model_${fileName}_auth', huggingFaceToken ?? '');

      print('ModelFileManager: Web model registered successfully');
      print('ModelFileManager: Model URL: $downloadUrl');
      print('ModelFileManager: Model size: ${_formatFileSize(totalBytes)}');

      return fileName; // Return filename as identifier for web
    } catch (e) {
      print('ModelFileManager: Web model registration error - $e');
      return null;
    }
  }

  /// Set the model path for the flutter_gemma plugin
  ///
  /// [modelPath] - The path to the model file (filename or full path)
  ///
  /// Returns true if successful, false otherwise
  Future<bool> setModelPath(String modelPath) async {
    try {
      print('ModelFileManager: Setting model path - $modelPath');

      // Use full path for all platforms (following official example pattern)
      String pathToUse;
      if (kIsWeb) {
        // For web, use the URL/path as-is
        pathToUse = modelPath;
      } else {
        // For native platforms, ensure we have the full path
        if (path.isAbsolute(modelPath)) {
          pathToUse = modelPath;
        } else {
          // If just filename, build full path
          final directory = await getApplicationDocumentsDirectory();
          pathToUse = path.join(directory.path, modelPath);
        }
      }

      print('ModelFileManager: Using path - $pathToUse');
      await FlutterGemmaPlugin.instance.modelManager.setModelPath(pathToUse);

      // Store the current model filename for future reference
      await _setCurrentModelFileName(path.basename(modelPath));

      print('ModelFileManager: Model path set successfully');
      return true;
    } catch (e) {
      print('ModelFileManager: Error setting model path - $e');
      return false;
    }
  }

  /// Get a list of downloaded models in the documents directory
  ///
  /// Returns a list of model information maps
  Future<List<Map<String, dynamic>>> getDownloadedModels() async {
    try {
      if (kIsWeb) {
        return await _getDownloadedModelsWeb();
      } else {
        return await _getDownloadedModelsNative();
      }
    } catch (e) {
      print('ModelFileManager: Error getting downloaded models - $e');
      return [];
    }
  }

  /// Get downloaded models for native platforms
  Future<List<Map<String, dynamic>>> _getDownloadedModelsNative() async {
    final directory = await getApplicationDocumentsDirectory();
    final models = <Map<String, dynamic>>[];

    final files = await directory.list().toList();

    for (final file in files) {
      if (file is File &&
          (file.path.endsWith('.task') || file.path.endsWith('.litertlm'))) {
        final fileName = path.basename(file.path);
        final fileStat = await file.stat();

        models.add({
          'fileName': fileName,
          'filePath': file.path,
          'fileSize': fileStat.size,
          'modifiedDate': fileStat.modified.toIso8601String(),
          'sizeFormatted': _formatFileSize(fileStat.size),
          'supportsVision': _checkVisionSupport(fileName),
        });
      }
    }

    // Sort by modification date (newest first)
    models.sort((a, b) => DateTime.parse(b['modifiedDate'])
        .compareTo(DateTime.parse(a['modifiedDate'])));

    return models;
  }

  /// Get downloaded models for web platform
  Future<List<Map<String, dynamic>>> _getDownloadedModelsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final models = <Map<String, dynamic>>[];

    // Get all keys that start with 'model_' but exclude metadata keys
    final keys = prefs
        .getKeys()
        .where((key) =>
            key.startsWith('model_') &&
            !key.contains('_size') &&
            !key.contains('_auth'))
        .toList();

    for (final key in keys) {
      final fileName = key.substring('model_'.length);
      final sizeKey = 'model_${fileName}_size';
      final fileSize = prefs.getInt(sizeKey) ?? 0;
      final modelUrl = prefs.getString(key) ?? '';

      models.add({
        'fileName': fileName,
        'filePath': fileName, // Use filename as path for web
        'fileSize': fileSize,
        'modifiedDate': DateTime.now()
            .toIso8601String(), // Web doesn't have file modification dates
        'sizeFormatted': _formatFileSize(fileSize),
        'supportsVision': _checkVisionSupport(fileName),
        'url': modelUrl, // Store URL for web initialization
      });
    }

    return models;
  }

  /// Delete a model file
  ///
  /// [modelPath] - The path to the model file to delete
  ///
  /// Returns true if successful, false otherwise
  Future<bool> deleteModel(String modelPath) async {
    try {
      if (kIsWeb) {
        return await _deleteModelWeb(modelPath);
      } else {
        return await _deleteModelNative(modelPath);
      }
    } catch (e) {
      print('ModelFileManager: Error deleting model - $e');
      return false;
    }
  }

  /// Delete model for native platforms
  Future<bool> _deleteModelNative(String modelPath) async {
    final file = File(modelPath);
    if (await file.exists()) {
      await file.delete();
      print('ModelFileManager: Model deleted - $modelPath');
      return true;
    } else {
      print('ModelFileManager: Model file not found - $modelPath');
      return false;
    }
  }

  /// Delete model for web platform
  Future<bool> _deleteModelWeb(String modelPath) async {
    final prefs = await SharedPreferences.getInstance();
    final fileName = path.basename(modelPath);

    final keys = [
      'model_$fileName',
      'model_${fileName}_size',
      'model_${fileName}_auth',
    ];

    bool success = true;
    for (final key in keys) {
      if (prefs.containsKey(key)) {
        success &= await prefs.remove(key);
      }
    }

    if (success) {
      print('ModelFileManager: Web model deleted - $modelPath');
    }
    return success;
  }

  /// Clear all downloaded model files
  ///
  /// Returns the number of files deleted
  Future<int> clearAllModels() async {
    try {
      if (kIsWeb) {
        return await _clearAllModelsWeb();
      } else {
        return await _clearAllModelsNative();
      }
    } catch (e) {
      print('ModelFileManager: Error clearing models - $e');
      return 0;
    }
  }

  /// Clear all models for native platforms
  Future<int> _clearAllModelsNative() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = await directory.list().toList();
    int deletedCount = 0;

    for (final file in files) {
      if (file is File &&
          (file.path.endsWith('.task') || file.path.endsWith('.litertlm'))) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          print('ModelFileManager: Failed to delete ${file.path} - $e');
        }
      }
    }

    print('ModelFileManager: Cleared $deletedCount model files');
    return deletedCount;
  }

  /// Clear all models for web platform
  Future<int> _clearAllModelsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((key) => key.startsWith('model_')).toList();
    int deletedCount = 0;

    for (final key in keys) {
      try {
        await prefs.remove(key);
        if (!key.contains('_size') && !key.contains('_url')) {
          deletedCount++; // Count only the main model entries
        }
      } catch (e) {
        print('ModelFileManager: Failed to remove key $key - $e');
      }
    }

    print('ModelFileManager: Cleared $deletedCount web model entries');
    return deletedCount;
  }

  /// Check if a string represents a Hugging Face repository
  bool _isHuggingFaceRepo(String input) {
    // Simple heuristic: if it doesn't start with http and contains slashes,
    // assume it's a HF repo identifier like "google/gemma-2b-it"
    return !input.startsWith('http') && input.contains('/');
  }

  /// Build Hugging Face download URL from repository identifier
  String _buildHuggingFaceUrl(String repoId) {
    // For now, return a placeholder - users should provide full URLs
    // This could be enhanced to auto-detect model files in the repo
    throw Exception(
        'Direct HuggingFace repository IDs not yet supported. Please provide the full download URL.');
  }

  /// Extract filename from URL
  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final fileName = path.basename(uri.path);

      if (fileName.isEmpty || !fileName.contains('.')) {
        // Fallback filename if we can't extract one
        return 'model_${DateTime.now().millisecondsSinceEpoch}.task';
      }

      return fileName;
    } catch (e) {
      // Fallback filename on error
      return 'model_${DateTime.now().millisecondsSinceEpoch}.task';
    }
  }

  /// Check if a model supports vision based on filename
  bool _checkVisionSupport(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.contains('gemma-3n-e4b-it') ||
        lowerName.contains('gemma-3n-e2b-it');
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  /// Store the current model filename for tracking
  Future<void> _setCurrentModelFileName(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_model_file', fileName);
      print('ModelFileManager: Current model file set to: $fileName');
    } catch (e) {
      print('ModelFileManager: Error storing current model filename: $e');
    }
  }

  /// Get the current model filename
  Future<String?> getCurrentModelFileName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_model_file');
    } catch (e) {
      print('ModelFileManager: Error retrieving current model filename: $e');
      return null;
    }
  }
}
