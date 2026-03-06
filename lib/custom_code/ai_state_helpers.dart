/// Tiny coordination helpers for FlutterFlow-facing runtime state.
///
/// Keeps polling-driven widgets readable without becoming a second engine.
/// No hidden business logic, no runtime calls, no widget state.

import 'ai_types.dart';

/// Helpers for working with [AiMessageRecord] lists in polling-driven UIs.
class AiStateHelpers {
  AiStateHelpers._(); // not instantiable

  /// Sort messages by timestamp (oldest first).
  static List<AiMessageRecord> sorted(List<AiMessageRecord> messages) {
    final copy = List<AiMessageRecord>.from(messages);
    copy.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return copy;
  }

  /// Find the latest assistant message that is still generating.
  static AiMessageRecord? pendingAssistantMessage(
    List<AiMessageRecord> messages,
  ) {
    for (int i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (!m.isUser &&
          (m.status == AiMessageStatus.generating ||
              m.status == AiMessageStatus.pending)) {
        return m;
      }
    }
    return null;
  }

  /// True when there is no in-flight generation.
  static bool isGenerationComplete(List<AiMessageRecord> messages) {
    return pendingAssistantMessage(messages) == null;
  }

  /// The most recent user message, or null.
  static AiMessageRecord? latestUserMessage(List<AiMessageRecord> messages) {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser) return messages[i];
    }
    return null;
  }

  /// The most recent assistant message (partial or complete), or null.
  static AiMessageRecord? latestAssistantMessage(
    List<AiMessageRecord> messages,
  ) {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isUser) return messages[i];
    }
    return null;
  }

  /// Count of completed assistant responses.
  static int completedResponseCount(List<AiMessageRecord> messages) {
    return messages
        .where((m) => !m.isUser && m.status == AiMessageStatus.complete)
        .length;
  }

  /// Whether the latest exchange ended in an error.
  static bool hasRecentError(List<AiMessageRecord> messages) {
    if (messages.isEmpty) return false;
    final last = messages.last;
    return !last.isUser && last.status == AiMessageStatus.error;
  }
}
