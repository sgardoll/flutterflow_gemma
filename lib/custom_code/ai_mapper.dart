/// Maps runtime responses into app-safe Dart types.
///
/// Conversion and normalization only. No widget state, no page logic,
/// no runtime calls.

import 'package:path/path.dart' as path;

import 'ai_types.dart';

/// Static mapping utilities for converting between runtime data
/// and the shared [AiModelInfo] / [AiMessageRecord] types.
class AiMapper {
  AiMapper._(); // not instantiable

  // -----------------------------------------------------------------------
  // Model detection
  // -----------------------------------------------------------------------

  /// Derive a canonical model ID from a filename or URL.
  ///
  /// Examples:
  ///   "gemma-3n-E2B-it-int4.task"  →  "gemma-3n-e2b-it"
  ///   "Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task"  →  "gemma3-1b-it"
  static String detectModelId(String pathOrUrl) {
    try {
      final fileName = path.basenameWithoutExtension(pathOrUrl);
      String normalized = fileName
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'-int\d+$'), '')
          .replaceAll(RegExp(r'\.litertlm$'), '')
          .replaceAll(RegExp(r'\.task$'), '');

      // FunctionGemma detection (check first — specialized model)
      if (normalized.contains('functiongemma') ||
          normalized.contains('function-gemma') ||
          normalized.contains('function_gemma') ||
          normalized.contains('tiny_garden') ||
          normalized.contains('tiny-garden') ||
          normalized.contains('tinygarden')) {
        return 'functiongemma-270m-it';
      }

      // Gemma 3N nano models
      if (normalized.contains('gemma-3n-e4b') ||
          normalized.contains('gemma3n-e4b')) {
        return 'gemma-3n-e4b-it';
      }
      if (normalized.contains('gemma-3n-e2b') ||
          normalized.contains('gemma3n-e2b') ||
          normalized.contains('gemma-3n-e2b-it-litert-preview')) {
        return 'gemma-3n-e2b-it';
      }

      // Gemma 3 text models
      if (normalized.contains('gemma3-1b') ||
          normalized.contains('gemma-3-1b')) {
        return 'gemma3-1b-it';
      }
      if (normalized.contains('gemma3-2b') ||
          normalized.contains('gemma-3-2b')) {
        return 'gemma3-2b-it';
      }
      if (normalized.contains('gemma3-7b') ||
          normalized.contains('gemma-3-7b')) {
        return 'gemma3-7b-it';
      }

      // Generic Gemma 3N / 3 fallbacks
      if (normalized.contains('gemma-3n') || normalized.contains('gemma3n')) {
        return 'gemma-3n-e2b-it';
      }
      if (normalized.contains('gemma-3') || normalized.contains('gemma3')) {
        return 'gemma3-1b-it';
      }

      return normalized.isEmpty ? 'gemma-3n-e2b-it' : normalized;
    } catch (_) {
      return 'gemma-3n-e2b-it';
    }
  }

  /// Whether a model ID represents a vision-capable model.
  static bool isVisionCapable(String modelId) {
    final n = modelId.toLowerCase().trim().replaceAll(RegExp(r'[-_\s]+'), '-');

    const visionModels = [
      'gemma-3n-e2b-it',
      'gemma-3n-e4b-it',
      'gemma-2b-it',
      'gemma-7b-it',
    ];
    for (final vm in visionModels) {
      if (n.contains(vm)) return true;
    }

    const indicators = ['vision', 'multimodal', 'multi-modal', 'vl', 'image'];
    for (final ind in indicators) {
      if (n.contains(ind)) return true;
    }
    if (n.contains('mm') && !n.contains('gemma')) return true;

    return false;
  }

  /// Whether a model ID represents a function-calling model.
  static bool isFunctionCallingCapable(String modelId) {
    final n = modelId.toLowerCase().trim().replaceAll(RegExp(r'[-_\s]+'), '-');

    const fcModels = [
      'functiongemma',
      'function-gemma',
      'functiongemma-270m',
      'functiongemma-270m-it',
    ];
    for (final fc in fcModels) {
      if (n.contains(fc)) return true;
    }
    if (n.contains('function') ||
        n.contains('tool-use') ||
        n.contains('tooluse')) {
      return true;
    }
    return false;
  }

  /// A human-readable display name for a model ID.
  static String displayNameForModel(String modelId) {
    switch (modelId) {
      case 'gemma-3n-e4b-it':
        return 'Gemma 3n E4B (4B, Vision)';
      case 'gemma-3n-e2b-it':
        return 'Gemma 3n E2B (2B, Vision)';
      case 'gemma3-1b-it':
        return 'Gemma 3 1B (Text-only)';
      case 'gemma3-2b-it':
        return 'Gemma 3 2B (Text)';
      case 'gemma3-7b-it':
        return 'Gemma 3 7B (Text)';
      case 'functiongemma-270m-it':
        return 'FunctionGemma 270M';
      default:
        return modelId;
    }
  }

  // -----------------------------------------------------------------------
  // Model mapping
  // -----------------------------------------------------------------------

  /// Convert raw file-manager data into an [AiModelInfo].
  ///
  /// The [data] map is the same shape returned by
  /// `ModelFileManager.getDownloadedModels()`.
  static AiModelInfo modelInfoFromFileData(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String? ?? '';
    final modelId = detectModelId(fileName);

    return AiModelInfo(
      id: modelId,
      displayName: displayNameForModel(modelId),
      filePath: data['filePath'] as String?,
      fileSizeBytes: data['fileSize'] as int?,
      supportsVision: isVisionCapable(modelId),
      supportsFunctionCalling: isFunctionCallingCapable(modelId),
      isInstalled: true,
      downloadUrl: data['url'] as String?,
      installedAt: data['modifiedDate'] != null
          ? DateTime.tryParse(data['modifiedDate'] as String)
          : null,
    );
  }

  // -----------------------------------------------------------------------
  // Token limits
  // -----------------------------------------------------------------------

  /// Appropriate max-token setting for a given model ID.
  static int maxTokensForModel(String modelId) {
    final n = modelId.toLowerCase();
    if (n.contains('1b') || n.contains('1-b')) return 2048;
    if (n.contains('2b') || n.contains('2-b')) return 4096;
    if (n.contains('7b') || n.contains('7-b')) return 8192;
    if (n.contains('13b') || n.contains('13-b')) return 16384;
    return 4096;
  }

  // -----------------------------------------------------------------------
  // Error normalization
  // -----------------------------------------------------------------------

  /// Turn an arbitrary runtime error into a user-friendly string.
  static String normalizeError(dynamic error) {
    final s = error.toString();

    if (s.contains('RET_CHECK failure')) {
      return 'Model loading failed — the model file may be incompatible '
          'with this device. Try a different backend or model variant.';
    }
    if (s.contains('forGenAiTasks')) {
      return 'Chat session creation failed — this model version may not '
          'support the requested configuration. Trying fallback...';
    }
    if (s.contains('gpu') || s.contains('delegate') || s.contains('metal')) {
      return 'GPU acceleration unavailable on this device. '
          'Switching to CPU backend.';
    }
    if (s.contains('OutOfMemory') || s.contains('out of memory')) {
      return 'Not enough memory to load this model. '
          'Try a smaller model variant.';
    }

    // Generic fallback — strip noisy prefixes
    final cleaned = s
        .replaceAll('Exception: ', '')
        .replaceAll('PlatformException(', '')
        .replaceAll(RegExp(r'\)$'), '');
    return cleaned.length > 200 ? '${cleaned.substring(0, 200)}...' : cleaned;
  }
}
