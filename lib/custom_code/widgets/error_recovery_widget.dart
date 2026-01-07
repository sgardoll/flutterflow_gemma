// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart';

import '/app_state.dart';

/// Error Recovery Widget for FlutterFlow
///
/// This widget provides user-friendly error recovery options when Gemma model
/// initialization fails.
///
/// It shows error messages and offers actions to recover from the error.
class ErrorRecoveryWidget extends StatefulWidget {
  const ErrorRecoveryWidget({
    super.key,
    this.width,
    this.height,
    this.showBackButton = true,
    this.customErrorMessage,
  });

  final double? width;
  final double? height;
  final bool showBackButton;
  final String? customErrorMessage;

  @override
  State<ErrorRecoveryWidget> createState() => _ErrorRecoveryWidgetState();
}

class _ErrorRecoveryWidgetState extends State<ErrorRecoveryWidget> {
  bool _isRecovering = false;

  @override
  Widget build(BuildContext context) {
    final appState = FFAppState();
    final errorMessage = widget.customErrorMessage ??
        appState.downloadProgress ??
        'An error occurred during model initialization.';

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).error,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).error,
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon and title
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Initialization Failed',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Error message
          Text(
            errorMessage,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),

          const SizedBox(height: 16.0),

          // Recovery actions
          if (_isRecovering)
            Row(
              children: [
                SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Recovering...',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ],
            )
          else
            Column(
              children: [
                // Try Again button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleTryAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primaryText,
                      foregroundColor: FlutterFlowTheme.of(context).error,
                    ),
                    child: const Text('Try Again'),
                  ),
                ),

                const SizedBox(height: 8.0),

                // Reset button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleReset,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                    child: Text(
                      'Reset and Select Different Model',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                  ),
                ),

                // Back button (optional)
                if (widget.showBackButton) ...[
                  const SizedBox(height: 8.0),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleBack,
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleTryAgain() async {
    setState(() {
      _isRecovering = true;
    });

    try {
      // Use the recovery action to clean up and reset
      await recoverFromInitializationError();

      // After recovery, the user can try initialization again
      // This would typically be handled by the parent widget
      // which would re-trigger the initialization flow
    } catch (e) {
      print('ErrorRecoveryWidget: Recovery failed: $e');
    } finally {
      setState(() {
        _isRecovering = false;
      });
    }
  }

  Future<void> _handleReset() async {
    setState(() {
      _isRecovering = true;
    });

    try {
      // Complete reset including clearing stored URLs
      await recoverFromInitializationError();

      // Clear stored model URL to force re-selection
      final appState = FFAppState();
      appState.update(() {
        appState.downloadUrl = '';
      });
    } catch (e) {
      print('ErrorRecoveryWidget: Reset failed: $e');
    } finally {
      setState(() {
        _isRecovering = false;
      });
    }
  }

  void _handleBack() {
    // Navigate back or trigger parent callback
    Navigator.of(context).maybePop();
  }
}
