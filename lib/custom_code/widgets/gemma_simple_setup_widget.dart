// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import '../actions/download_authenticated_model.dart';
import '../actions/install_local_model_file.dart';
import '../actions/validate_and_repair_model.dart';
import 'dart:io';

class GemmaSimpleSetupWidget extends StatefulWidget {
  const GemmaSimpleSetupWidget({
    super.key,
    this.width,
    this.height,
    this.hfToken,
    this.modelId,
    this.onComplete,
  });

  final double? width;
  final double? height;
  final String? hfToken; // HuggingFace token
  final String?
      modelId; // Model to download (optional, defaults to efficient model)
  final Future Function()? onComplete; // Callback when setup complete

  @override
  State<GemmaSimpleSetupWidget> createState() => _GemmaSimpleSetupWidgetState();
}

class _GemmaSimpleSetupWidgetState extends State<GemmaSimpleSetupWidget> {
  bool _isSetupInProgress = false;
  bool _isSetupComplete = false;
  String _currentStep = '';
  String _errorMessage = '';
  double _downloadProgress = 0.0;

  final GemmaManager _gemmaManager = GemmaManager();

  @override
  void initState() {
    super.initState();
    _checkExistingSetup();
  }

  // Check if model is already set up
  void _checkExistingSetup() {
    if (_gemmaManager.isInitialized && _gemmaManager.hasSession) {
      setState(() {
        _isSetupComplete = true;
        _currentStep = 'Model ready for use!';
      });
    }
  }

  // Start the complete setup process
  Future<void> _startSetup() async {
    if (widget.hfToken == null || widget.hfToken!.isEmpty) {
      setState(() {
        _errorMessage = 'HuggingFace token is required';
      });
      return;
    }

    setState(() {
      _isSetupInProgress = true;
      _isSetupComplete = false;
      _errorMessage = '';
      _downloadProgress = 0.0;
      _currentStep = 'Starting setup...';
    });

    try {
      // Use platform-appropriate default model
      final modelToDownload = widget.modelId ?? _getDefaultModelForPlatform();

      await _performSetup(modelToDownload);
    } catch (e) {
      setState(() {
        _isSetupInProgress = false;
        _errorMessage = 'Setup failed: ${e.toString()}';
        _currentStep = '';
      });
    }
  }

  // Perform the complete setup workflow
  Future<void> _performSetup(String modelId) async {
    try {
      // Step 1: Download model
      setState(() {
        _currentStep = 'Downloading model...';
      });

      String? downloadPath = await downloadAuthenticatedModel(
        modelId,
        widget.hfToken!,
        (downloaded, total, percentage) async {
          setState(() {
            _downloadProgress = percentage / 100.0;
          });
        },
      );

      if (downloadPath == null) {
        throw Exception('Failed to download model');
      }

      // Step 2: Validate downloaded model
      setState(() {
        _currentStep = 'Validating model file...';
        _downloadProgress = 1.0;
      });

      final validationResult =
          await validateAndRepairModel(downloadPath, widget.hfToken, modelId);

      if (!validationResult['isValid']) {
        // Check if file is genuinely corrupted vs format issues
        print('Model validation failed: ${validationResult['error']}');

        // Only delete files that are genuinely corrupted
        final shouldDeleteFile =
            validationResult['errorType'] == 'corrupted_header' ||
                validationResult['errorType'] == 'html_content' ||
                validationResult['errorType'] == 'size_too_small' ||
                validationResult['errorType'] == 'empty_file';

        if (shouldDeleteFile) {
          setState(() {
            _currentStep = 'Model corrupted - deleting and re-downloading...';
          });

          // Delete the corrupted file
          try {
            final corruptedFile = File(downloadPath);
            if (await corruptedFile.exists()) {
              await corruptedFile.delete();
              print('Deleted corrupted model file: $downloadPath');
            }
          } catch (e) {
            print('Error deleting corrupted file: $e');
          }
        } else {
          // File exists but has validation issues - try to use it anyway
          setState(() {
            _currentStep =
                'Model validation failed, but file appears intact. Proceeding...';
          });
          print(
              'Model validation failed but file not deleted: ${validationResult['errorType']}');

          // Skip to initialization instead of re-downloading
          setState(() {
            _currentStep = 'Installing model...';
          });

          final installSuccess =
              await installLocalModelFile(downloadPath, null);
          if (!installSuccess) {
            throw Exception('Failed to install model');
          }

          setState(() {
            _currentStep = 'Initializing model...';
          });

          // Derive model type from path
          final modelType = GemmaManager.getModelTypeFromPath(downloadPath);
          final supportsVision = GemmaManager.isMultimodalModel(modelType);

          // Try GPU first, then fall back to CPU for iOS compatibility
          bool initSuccess = await _gemmaManager.initializeModel(
            modelType: modelType,
            backend: 'gpu',
            maxTokens: 1024,
            supportImage: supportsVision,
            maxNumImages: 1,
            localModelPath: _getModelFileName(downloadPath),
          );

          // iOS-specific fallback: If GPU fails, try CPU
          if (!initSuccess && Platform.isIOS) {
            setState(() {
              _currentStep = 'GPU failed, trying CPU backend...';
            });

            print('GPU initialization failed on iOS, attempting CPU fallback');

            initSuccess = await _gemmaManager.initializeModel(
              modelType: modelType,
              backend: 'cpu',
              maxTokens: 1024,
              supportImage: false, // Disable vision for CPU on iOS
              maxNumImages: 1,
              localModelPath: _getModelFileName(downloadPath),
            );
          }

          if (!initSuccess) {
            throw Exception(
                'Failed to initialize model on both GPU and CPU backends');
          }

          // Create session
          setState(() {
            _currentStep = 'Creating session...';
          });

          final sessionSuccess = await _gemmaManager.createSession(
            temperature: 0.8,
            randomSeed: 1,
            topK: 1,
          );

          if (!sessionSuccess) {
            throw Exception('Failed to create session');
          }

          // Setup complete
          setState(() {
            _isSetupInProgress = false;
            _isSetupComplete = true;
            _currentStep = 'Setup complete! Model ready for use.';
          });

          // Call completion callback
          if (widget.onComplete != null) {
            await widget.onComplete!();
          }
          return;
        }

        // Only re-download if we actually deleted the file
        if (shouldDeleteFile) {
          // Re-download the model
          setState(() {
            _currentStep = 'Re-downloading model...';
            _downloadProgress = 0.0;
          });

          downloadPath = await downloadAuthenticatedModel(
            modelId,
            widget.hfToken!,
            (downloaded, total, percentage) async {
              setState(() {
                _downloadProgress = percentage / 100.0;
                _currentStep =
                    'Re-downloading model... ${percentage.toStringAsFixed(1)}%';
              });
            },
          );

          if (downloadPath == null) {
            throw Exception('Failed to re-download model after corruption');
          }

          // Validate the re-downloaded model
          final revalidationResult =
              await validateAndRepairModel(downloadPath, null, null);

          if (!revalidationResult['isValid']) {
            throw Exception(
                'Re-downloaded model is still corrupted: ${revalidationResult['error']}');
          }

          setState(() {
            _currentStep = 'Model re-downloaded and validated successfully';
            _downloadProgress = 1.0;
          });
        } else {
          throw Exception(
              'Model validation failed: ${validationResult['error']}. ${validationResult['recommendation']}');
        }
      }

      // Step 3: Install model
      setState(() {
        _currentStep = 'Installing model...';
      });

      final installSuccess = await installLocalModelFile(downloadPath, null);
      if (!installSuccess) {
        throw Exception('Failed to install model');
      }

      // Step 3: Initialize model
      setState(() {
        _currentStep = 'Initializing model...';
      });

      // Derive model type from path
      final modelType = GemmaManager.getModelTypeFromPath(downloadPath);
      final supportsVision = GemmaManager.isMultimodalModel(modelType);

      // Try GPU first, then fall back to CPU for iOS compatibility
      bool initSuccess = await _gemmaManager.initializeModel(
        modelType: modelType,
        backend: 'gpu',
        maxTokens: 1024,
        supportImage: supportsVision,
        maxNumImages: 1,
        localModelPath: _getModelFileName(downloadPath),
      );

      // iOS-specific fallback: If GPU fails, try CPU
      if (!initSuccess && Platform.isIOS) {
        setState(() {
          _currentStep = 'GPU failed, trying CPU backend...';
        });

        print('GPU initialization failed on iOS, attempting CPU fallback');

        initSuccess = await _gemmaManager.initializeModel(
          modelType: modelType,
          backend: 'cpu',
          maxTokens: 1024,
          supportImage: false, // Disable vision for CPU on iOS
          maxNumImages: 1,
          localModelPath: _getModelFileName(downloadPath),
        );
      }

      if (!initSuccess) {
        throw Exception(
            'Failed to initialize model on both GPU and CPU backends');
      }

      // Step 4: Create session
      setState(() {
        _currentStep = 'Creating session...';
      });

      final sessionSuccess = await _gemmaManager.createSession(
        temperature: 0.8,
        randomSeed: 1,
        topK: 1,
      );

      if (!sessionSuccess) {
        throw Exception('Failed to create session');
      }

      // Setup complete
      setState(() {
        _isSetupInProgress = false;
        _isSetupComplete = true;
        _currentStep = 'Setup complete! Model ready for use.';
      });

      // Call completion callback
      if (widget.onComplete != null) {
        await widget.onComplete!();
      }
    } catch (e) {
      setState(() {
        _isSetupInProgress = false;
        _errorMessage = 'Setup failed: ${e.toString()}';
        _currentStep = '';
      });
    }
  }

  // Extract filename from path
  String _getModelFileName(String filePath) {
    return filePath.split('/').last;
  }

  // Get platform-appropriate default model
  String _getDefaultModelForPlatform() {
    if (Platform.isIOS) {
      // iOS works best with .task files specifically built for iOS
      // Avoid web-optimized models as they cause TensorFlow Lite errors
      return 'gemma3-1b-it'; // Standard iOS-compatible .task file
    } else if (Platform.isAndroid) {
      // Android can handle various formats
      return 'gemma3-1b-it'; // Standard Android-compatible .task file
    } else {
      // Web/other platforms
      return 'gemma3-1b-web'; // Web-optimized for browser deployment
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            'Gemma Model Setup',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20),

          // Status/Error Messages
          if (_errorMessage.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            color: Colors.red,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          if (_isSetupComplete) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentStep,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Progress Section
          if (_isSetupInProgress) ...[
            Column(
              children: [
                Text(
                  _currentStep,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                if (_downloadProgress > 0) ...[
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ],

                SizedBox(height: 16),

                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],

          // Setup Button
          if (!_isSetupInProgress && !_isSetupComplete) ...[
            ElevatedButton(
              onPressed: _startSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Setup Gemma Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Model Info
          if (!_isSetupInProgress) ...[
            SizedBox(height: 16),
            Text(
              _isSetupComplete
                  ? 'Model: ${_gemmaManager.currentModelType ?? "Unknown"}'
                  : 'Model: ${widget.modelId ?? "gemma3-1b-it (default)"}',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
