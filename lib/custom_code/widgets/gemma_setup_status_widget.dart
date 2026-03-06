// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:provider/provider.dart';

/// Setup / install / initialization progress UI.
///
/// Displays current download progress, initialization state, and error
/// messages. Surfaces a recovery path when errors occur.
///
/// **Does not own any install logic.** It reads [FFAppState] and delegates
/// to [aiInitialize] via callbacks — no direct [AiRustApi] calls here.
class GemmaSetupStatusWidget extends StatefulWidget {
  const GemmaSetupStatusWidget({
    super.key,
    this.width,
    this.height,
    this.onRetry,
    this.onSelectModel,
  });

  final double? width;
  final double? height;

  /// Called when the user taps "Try Again".
  final Future Function()? onRetry;

  /// Called when the user taps "Select Different Model".
  final Future Function()? onSelectModel;

  @override
  State<GemmaSetupStatusWidget> createState() => _GemmaSetupStatusWidgetState();
}

class _GemmaSetupStatusWidgetState extends State<GemmaSetupStatusWidget> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();

    final isDownloading = appState.isDownloading;
    final isInitializing = appState.isInitializing;
    final isReady = appState.isModelInitialized;
    final progress = appState.downloadProgress;
    final percentage = appState.downloadPercentage;
    final fileName = appState.fileName;

    final isError = progress.toLowerCase().contains('error') ||
        progress.toLowerCase().contains('failed');
    final isActive = isDownloading || isInitializing;

    return Container(
      width: widget.width ?? double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isError
            ? FlutterFlowTheme.of(context).error.withAlpha(15)
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? FlutterFlowTheme.of(context).error.withAlpha(100)
              : FlutterFlowTheme.of(context).alternate,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withAlpha(20),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _buildStatusIcon(context,
                  isError: isError, isReady: isReady, isActive: isActive),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _headerText(
                      isError: isError,
                      isReady: isReady,
                      isDownloading: isDownloading,
                      isInitializing: isInitializing),
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        color: isError
                            ? FlutterFlowTheme.of(context).error
                            : FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ),
            ],
          ),

          // Model name
          if (fileName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],

          // Progress bar (download phase)
          if (isDownloading && percentage > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: FlutterFlowTheme.of(context).alternate,
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],

          // Indeterminate spinner (init phase or unknown download)
          if (isActive && (!isDownloading || percentage == 0)) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: FlutterFlowTheme.of(context).alternate,
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          ],

          // Status text
          if (progress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              progress,
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    color: isError
                        ? FlutterFlowTheme.of(context).error
                        : FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],

          // Ready state callout
          if (isReady && !isError) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: FlutterFlowTheme.of(context).success, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Model ready',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: FlutterFlowTheme.of(context).success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],

          // Error recovery buttons
          if (isError && !_isRetrying) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.onRetry != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                if (widget.onRetry != null && widget.onSelectModel != null)
                  const SizedBox(width: 8),
                if (widget.onSelectModel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onSelectModel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                      child: const Text('Change Model'),
                    ),
                  ),
              ],
            ),
          ],

          // Retrying spinner
          if (_isRetrying) ...[
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Retrying...'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    try {
      if (widget.onRetry != null) await widget.onRetry!();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  Widget _buildStatusIcon(
    BuildContext context, {
    required bool isError,
    required bool isReady,
    required bool isActive,
  }) {
    if (isError) {
      return Icon(Icons.error_outline,
          color: FlutterFlowTheme.of(context).error, size: 28);
    }
    if (isReady) {
      return Icon(Icons.check_circle,
          color: FlutterFlowTheme.of(context).success, size: 28);
    }
    if (isActive) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            FlutterFlowTheme.of(context).primary,
          ),
        ),
      );
    }
    return Icon(Icons.hourglass_empty,
        color: FlutterFlowTheme.of(context).secondaryText, size: 28);
  }

  String _headerText({
    required bool isError,
    required bool isReady,
    required bool isDownloading,
    required bool isInitializing,
  }) {
    if (isError) return 'Setup Failed';
    if (isReady) return 'Model Ready';
    if (isDownloading) return 'Downloading Model';
    if (isInitializing) return 'Initializing Model';
    return 'Setting Up...';
  }
}
