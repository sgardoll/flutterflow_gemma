/// Shared data models for the AI runtime boundary.
///
/// These types are used across Actions and Widgets. They define the
/// project-wide contract. Nothing in this file should reference
/// flutter_gemma, FlutterFlow state, or UI code.

import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Message types
// ---------------------------------------------------------------------------

/// Status of a single message in a chat session.
enum AiMessageStatus {
  /// User message submitted, waiting for engine to start.
  pending,

  /// Assistant response is being generated (partial text available).
  generating,

  /// Response generation finished successfully.
  complete,

  /// Generation encountered an error.
  error,

  /// Generation was cancelled by the user.
  cancelled,
}

/// A single message in a chat session.
///
/// Both user prompts and assistant responses use this type.
class AiMessageRecord {
  final String id;
  final String sessionId;
  final String text;
  final bool isUser;

  /// True while the assistant is still generating tokens.
  final bool isPartial;
  final Uint8List? imageBytes;
  final DateTime timestamp;
  final AiMessageStatus status;

  const AiMessageRecord({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    this.isPartial = false,
    this.imageBytes,
    required this.timestamp,
    this.status = AiMessageStatus.complete,
  });

  /// Convenience: create a user text message.
  factory AiMessageRecord.userText({
    required String id,
    required String sessionId,
    required String text,
    Uint8List? imageBytes,
  }) {
    return AiMessageRecord(
      id: id,
      sessionId: sessionId,
      text: text,
      isUser: true,
      imageBytes: imageBytes,
      timestamp: DateTime.now(),
      status: AiMessageStatus.complete,
    );
  }

  /// Convenience: create a partial (in-progress) assistant message.
  factory AiMessageRecord.assistantPartial({
    required String id,
    required String sessionId,
    required String text,
  }) {
    return AiMessageRecord(
      id: id,
      sessionId: sessionId,
      text: text,
      isUser: false,
      isPartial: true,
      timestamp: DateTime.now(),
      status: AiMessageStatus.generating,
    );
  }

  /// Convenience: create a completed assistant message.
  factory AiMessageRecord.assistantComplete({
    required String id,
    required String sessionId,
    required String text,
  }) {
    return AiMessageRecord(
      id: id,
      sessionId: sessionId,
      text: text,
      isUser: false,
      isPartial: false,
      timestamp: DateTime.now(),
      status: AiMessageStatus.complete,
    );
  }

  /// Convenience: create an error message.
  factory AiMessageRecord.error({
    required String id,
    required String sessionId,
    required String text,
  }) {
    return AiMessageRecord(
      id: id,
      sessionId: sessionId,
      text: text,
      isUser: false,
      isPartial: false,
      timestamp: DateTime.now(),
      status: AiMessageStatus.error,
    );
  }

  AiMessageRecord copyWith({
    String? id,
    String? sessionId,
    String? text,
    bool? isUser,
    bool? isPartial,
    Uint8List? imageBytes,
    DateTime? timestamp,
    AiMessageStatus? status,
  }) {
    return AiMessageRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isPartial: isPartial ?? this.isPartial,
      imageBytes: imageBytes ?? this.imageBytes,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  /// Serialize to a plain map — safe for FlutterFlow action return values.
  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'text': text,
        'isUser': isUser,
        'isPartial': isPartial,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': status.name,
      };
}

// ---------------------------------------------------------------------------
// Model types
// ---------------------------------------------------------------------------

/// Metadata about an available AI model.
class AiModelInfo {
  final String id;
  final String displayName;
  final String? filePath;
  final int? fileSizeBytes;
  final bool supportsVision;
  final bool supportsFunctionCalling;
  final bool isInstalled;
  final String? downloadUrl;
  final DateTime? installedAt;

  const AiModelInfo({
    required this.id,
    required this.displayName,
    this.filePath,
    this.fileSizeBytes,
    this.supportsVision = false,
    this.supportsFunctionCalling = false,
    this.isInstalled = false,
    this.downloadUrl,
    this.installedAt,
  });

  /// Formatted file size for display.
  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Unknown';
    final bytes = fileSizeBytes!;
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes bytes';
  }

  /// Serialize to a plain map — safe for FlutterFlow action return values.
  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'fileSizeFormatted': fileSizeFormatted,
        'supportsVision': supportsVision,
        'supportsFunctionCalling': supportsFunctionCalling,
        'isInstalled': isInstalled,
        'downloadUrl': downloadUrl,
        'installedAt': installedAt?.millisecondsSinceEpoch,
      };
}

// ---------------------------------------------------------------------------
// Engine & capability types
// ---------------------------------------------------------------------------

/// Current state of the AI runtime engine.
class AiEngineStatus {
  final bool isInitialized;
  final bool isGenerating;
  final String? currentModelId;
  final String? currentSessionId;
  final String? currentBackend;
  final String? errorMessage;

  const AiEngineStatus({
    this.isInitialized = false,
    this.isGenerating = false,
    this.currentModelId,
    this.currentSessionId,
    this.currentBackend,
    this.errorMessage,
  });
}

/// Device/runtime capability information.
class AiCapabilityInfo {
  final bool supportsGpu;
  final bool supportsCpu;
  final bool supportsTpu;
  final String? recommendedBackend;
  final String platform;

  const AiCapabilityInfo({
    this.supportsGpu = false,
    this.supportsCpu = true,
    this.supportsTpu = false,
    this.recommendedBackend,
    required this.platform,
  });

  /// Serialize to a plain map — safe for FlutterFlow action return values.
  Map<String, dynamic> toMap() => {
        'supportsGpu': supportsGpu,
        'supportsCpu': supportsCpu,
        'supportsTpu': supportsTpu,
        'recommendedBackend': recommendedBackend,
        'platform': platform,
      };
}

/// Result of a model install/download operation.
class AiInstallResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  const AiInstallResult({
    required this.success,
    this.filePath,
    this.errorMessage,
  });

  factory AiInstallResult.ok(String filePath) =>
      AiInstallResult(success: true, filePath: filePath);

  factory AiInstallResult.fail(String error) =>
      AiInstallResult(success: false, errorMessage: error);

  /// Serialize to a plain map — safe for FlutterFlow action return values.
  Map<String, dynamic> toMap() => {
        'success': success,
        'filePath': filePath,
        'errorMessage': errorMessage,
      };
}
