// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class GemmaAuthenticatedSetupWidget extends StatefulWidget {
  const GemmaAuthenticatedSetupWidget({
    super.key,
    this.width,
    this.height,
    this.modelName = 'gemma-3-4b-it',
    this.huggingFaceToken = '',
    this.preferredBackend = 'gpu',
    this.maxTokens = 4096,
    this.supportImage = true,
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
  final String modelName;
  final String huggingFaceToken;
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
  State<GemmaAuthenticatedSetupWidget> createState() =>
      _GemmaAuthenticatedSetupWidgetState();
}

class _GemmaAuthenticatedSetupWidgetState
    extends State<GemmaAuthenticatedSetupWidget> {
  bool _isSetupInProgress = false;
  bool _isSetupComplete = false;
  String _currentStep = '';
  String? _errorMessage;
  String? _downloadedModelPath;
  double _downloadProgress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String _downloadSpeed = '';

  // Model sizes in bytes (approximate)
  final Map<String, int> _modelSizes = {
    'gemma-3-4b-it': 6500000000, // ~6.5GB
    'gemma-3-2b-it': 3100000000, // ~3.1GB
    'gemma-1b-it': 500000000, // ~0.5GB
  };

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
                ? 'Gemma 3-4B-IT Ready!'
                : _isSetupInProgress
                    ? 'Setting Up Gemma Model...'
                    : 'Setup Gemma 3-4B-IT',
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
                ? widget.huggingFaceToken.isEmpty
                    ? 'Please provide your Hugging Face token'
                    : 'Ready to download and setup Gemma 3-4B-IT model'
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
            // Model size info
            if (_totalBytes > 0) ...[
              Text(
                'Model Size: ${(_totalBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Inter',
                      color: widget.textColor ??
                          FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                'Estimated Size: ${(_modelSizes[widget.modelName]! / 1024 / 1024 / 1024).toStringAsFixed(1)} GB',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Inter',
                      color: widget.textColor ??
                          FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 8),
            ],

            LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.primaryColor ?? FlutterFlowTheme.of(context).primary,
              ),
            ),
            const SizedBox(height: 8),

            // Progress details
            if (_downloadProgress > 0 && _totalBytes > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_downloadProgress.toStringAsFixed(1)}%',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: widget.textColor ??
                              FlutterFlowTheme.of(context).primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${(_downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(_totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: widget.textColor ??
                              FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            Text(
              _downloadProgress > 0
                  ? 'Downloading...'
                  : 'This may take several minutes...',
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
                onPressed:
                    widget.huggingFaceToken.isEmpty ? null : _setupGemmaModel,
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
                  'Download & Setup Model',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),

          if (_downloadedModelPath != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Model Downloaded',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Path: ${_downloadedModelPath!}',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future _setupGemmaModel() async {
    setState(() {
      _isSetupInProgress = true;
      _errorMessage = null;
      _currentStep = 'Downloading Gemma 3-4B-IT model...';
      _downloadProgress = 0.0;
      _downloadedBytes = 0;
      _totalBytes = 0;
    });

    try {
      // Step 1: Download the model
      setState(() {
        _currentStep = 'Downloading model from Hugging Face...';
      });

      final modelPath = await downloadAuthenticatedModel(
        widget.modelName,
        widget.huggingFaceToken,
        (downloaded, total, percentage) async {
          setState(() {
            _downloadedBytes = downloaded;
            _totalBytes = total;
            _downloadProgress = percentage;
          });

          // Call the widget's progress callback if provided
          if (widget.onProgress != null) {
            await widget.onProgress!(percentage.round());
          }
        },
      );

      if (modelPath == null) {
        throw Exception(
            'Failed to download model. Check your Hugging Face token and permissions.');
      }

      setState(() {
        _downloadedModelPath = modelPath;
        _currentStep = 'Model downloaded! Initializing...';
      });

      // Step 2: Initialize the model
      final initSuccess = await initializeLocalGemmaModel(
        modelPath,
        widget.modelName,
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
        _currentStep = 'Gemma 3-4B-IT ready for use!';
      });

      await widget.onSetupComplete();
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
