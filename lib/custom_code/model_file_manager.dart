/// Model file management for FlutterGemma library
///
/// This class handles downloading, storing, and managing Gemma model files
/// for FlutterFlow applications. It supports both custom URLs and Hugging Face
/// repositories with authentication.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gemma/flutter_gemma.dart';

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

  /// Set the model path for the flutter_gemma plugin
  ///
  /// [modelPath] - The path to the model file (filename or full path)
  ///
  /// Returns true if successful, false otherwise
  Future<bool> setModelPath(String modelPath) async {
    try {
      print('ModelFileManager: Setting model path - $modelPath');

      // Determine the correct path format for the platform
      final pathToUse = await _getCorrectModelPath(modelPath);

      print('ModelFileManager: Using path - $pathToUse');
      await FlutterGemmaPlugin.instance.modelManager.setModelPath(pathToUse);

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
      final directory = await getApplicationDocumentsDirectory();
      final models = <Map<String, dynamic>>[];

      final files = await directory.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith('.task')) {
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
    } catch (e) {
      print('ModelFileManager: Error getting downloaded models - $e');
      return [];
    }
  }

  /// Delete a model file
  ///
  /// [modelPath] - The path to the model file to delete
  ///
  /// Returns true if successful, false otherwise
  Future<bool> deleteModel(String modelPath) async {
    try {
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
        print('ModelFileManager: Model deleted - $modelPath');
        return true;
      } else {
        print('ModelFileManager: Model file not found - $modelPath');
        return false;
      }
    } catch (e) {
      print('ModelFileManager: Error deleting model - $e');
      return false;
    }
  }

  /// Clear all downloaded model files
  ///
  /// Returns the number of files deleted
  Future<int> clearAllModels() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().toList();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.task')) {
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
    } catch (e) {
      print('ModelFileManager: Error clearing models - $e');
      return 0;
    }
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

  /// Get the correct model path for the platform
  Future<String> _getCorrectModelPath(String modelPath) async {
    // If it's already a full path, use as-is
    if (path.isAbsolute(modelPath)) {
      return modelPath;
    }

    // If it's just a filename, resolve to documents directory
    final directory = await getApplicationDocumentsDirectory();
    final fullPath = path.join(directory.path, modelPath);

    // On Android, use full path; on iOS, use filename only
    return Platform.isAndroid ? fullPath : modelPath;
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
}
