// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';

class GemmaModelSetupWidget extends StatefulWidget {
  const GemmaModelSetupWidget({
    super.key,
    this.width,
    this.height,
    this.useAssetModel = true,
    this.assetPath = 'assets/models/gemma-3n-E2B-it-int4.task',
    this.modelUrl = '',
    this.loraPath,
    this.loraUrl,
    this.modelType = 'gemma-2b-it',
    this.preferredBackend = 'gpu',
    this.maxTokens = 1024,
    this.supportImage = false,
    this.maxNumImages = 1,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    required this.onSetupComplete,
    this.onSetupFailed,
    this.onProgress,
  });

  final double? width;
  final double? height;
  final bool useAssetModel;
  final String assetPath;
  final String modelUrl;
  final String? loraPath;
  final String? loraUrl;
  final String modelType;
  final String preferredBackend;
  final int maxTokens;
  final bool supportImage;
  final int maxNumImages;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Future Function() onSetupComplete;
  final Future Function(String error)? onSetupFailed;
  final Future Function(int progress)? onProgress;

  @override
  State<GemmaModelSetupWidget> createState() => _GemmaModelSetupWidgetState();
}

class _GemmaModelSetupWidgetState extends State<GemmaModelSetupWidget> {
  bool _isSetupInProgress = false;
  bool _isSetupComplete = false;
  int _downloadProgress = 0;
  String _currentStep = '';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Icon(
            _isSetupComplete
                ? Icons.check_circle
                : _isSetupInProgress
                    ? Icons.download
                    : Icons.smart_toy,
            size: 48,
            color: _isSetupComplete
                ? Colors.green
                : widget.primaryColor ?? FlutterFlowTheme.of(context).primary,
          ),
          const SizedBox(height: 16),

          Text(
            _isSetupComplete
                ? 'Gemma Model Ready!'
                : _isSetupInProgress
                    ? 'Setting Up Gemma Model...'
                    : 'Initialize Gemma Model',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Inter',
                  color: widget.textColor ??
                      FlutterFlowTheme.of(context).primaryText,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _currentStep.isEmpty
                ? widget.useAssetModel
                    ? 'Ready to install model from app assets'
                    : 'Ready to download model from network'
                : _currentStep,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: widget.textColor?.withValues(alpha: 0.7) ??
                      FlutterFlowTheme.of(context).secondaryText,
                ),
            textAlign: TextAlign.center,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Inter',
                            color: Colors.red,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Progress indicator
          if (_isSetupInProgress) ...[
            LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress / 100.0 : null,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.primaryColor ?? FlutterFlowTheme.of(context).primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _downloadProgress > 0 ? '$_downloadProgress%' : 'Initializing...',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Inter',
                    color: widget.textColor ??
                        FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            const SizedBox(height: 16),
          ],

          // Action button
          if (!_isSetupInProgress && !_isSetupComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _setupGemmaModel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor ??
                      FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.useAssetModel ? 'Install Model' : 'Download Model',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),

          if (_isSetupComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onSetupComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue to Chat',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future _setupGemmaModel() async {
    setState(() {
      _isSetupInProgress = true;
      _downloadProgress = 0;
      _errorMessage = null;
      _currentStep = widget.useAssetModel
          ? 'Installing model from assets...'
          : 'Downloading model from network...';
    });

    try {
      final gemmaManager = GemmaManager();
      bool installSuccess = false;

      if (widget.useAssetModel) {
        // Install from asset
        setState(() {
          _currentStep = 'Installing model from assets...';
        });

        // Use the stream version for progress if available
        try {
          await for (final progress
              in gemmaManager.installModelFromAssetWithProgress(
            widget.assetPath,
            loraPath: widget.loraPath,
          )) {
            setState(() {
              _downloadProgress = progress;
            });
            if (widget.onProgress != null) {
              await widget.onProgress!(progress);
            }
          }
          installSuccess = true;
        } catch (e) {
          // Fallback to simple install without progress
          installSuccess = await installGemmaFromAsset(
            widget.assetPath,
            widget.loraPath,
          );
        }
      } else {
        // Download from network
        setState(() {
          _currentStep = 'Downloading model from network...';
        });

        // Use the stream version for progress if available
        try {
          await for (final progress
              in gemmaManager.downloadModelFromNetworkWithProgress(
            widget.modelUrl,
            loraUrl: widget.loraUrl,
          )) {
            setState(() {
              _downloadProgress = progress;
            });
            if (widget.onProgress != null) {
              await widget.onProgress!(progress);
            }
          }
          installSuccess = true;
        } catch (e) {
          // Fallback to simple download without progress
          installSuccess = await downloadGemmaModel(
            widget.modelUrl,
            widget.loraUrl,
          );
        }
      }

      if (!installSuccess) {
        throw Exception(
            'Failed to ${widget.useAssetModel ? "install" : "download"} model');
      }

      // Initialize the model
      setState(() {
        _currentStep = 'Initializing Gemma model...';
        _downloadProgress = 0;
      });

      final initSuccess = await initializeGemmaModel(
        widget.modelType,
        widget.preferredBackend,
        widget.maxTokens,
        widget.supportImage,
        widget.maxNumImages,
      );

      if (!initSuccess) {
        throw Exception('Failed to initialize Gemma model');
      }

      // Setup complete
      setState(() {
        _isSetupInProgress = false;
        _isSetupComplete = true;
        _currentStep = 'Model ready for use!';
      });
    } catch (e) {
      setState(() {
        _isSetupInProgress = false;
        _errorMessage = 'Setup failed: ${e.toString()}';
        _currentStep = '';
      });

      if (widget.onSetupFailed != null) {
        await widget.onSetupFailed!(e.toString());
      }
    }
  }
}
