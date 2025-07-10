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
import 'gemma_visual_model_selector.dart';
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
  bool _showModelSelector = false;
  String _currentStep = '';
  String _errorMessage = '';
  double _downloadProgress = 0.0;
  String? _selectedModelId;

  final GemmaManager _gemmaManager = GemmaManager();

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.modelId ?? _getDefaultModelForPlatform();
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

  // Handle model selection
  Future<dynamic> _onModelSelected(String modelId) async {
    setState(() {
      _selectedModelId = modelId;
      _showModelSelector = false;
    });
    return Future.value();
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
      // Use selected model or fallback to default
      final modelToDownload = _selectedModelId ?? _getDefaultModelForPlatform();

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

  Widget _buildUnifiedInterface() {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Content with padding
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "Select Model" heading
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      'Select Model',
                      style: theme.headlineSmall.override(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Model selector expandables
                Expanded(
                  child: Column(
                    children: [
                      // Model categories
                      Expanded(
                        child: GemmaVisualModelSelector(
                          selectedModelId: _selectedModelId,
                          onModelSelected: _onModelSelected,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Setup Gemma Model button
                      _buildSetupButton(),

                      const SizedBox(height: 16),

                      // Progress section (if setup in progress)
                      if (_isSetupInProgress) _buildProgressSection(),

                      // Error messages
                      if (_errorMessage.isNotEmpty) _buildErrorSection(),

                      // Success message
                      if (_isSetupComplete) _buildSuccessSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer banner with selected model (full width)
        _buildFooterBanner(),
      ],
    );
  }

  Widget _buildSetupButton() {
    final theme = FlutterFlowTheme.of(context);

    return ElevatedButton(
      onPressed: _isSetupInProgress || _isSetupComplete ? null : _startSetup,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSetupInProgress) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Setting Up...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_isSetupComplete) ...[
            Icon(Icons.check_circle, size: 20),
            const SizedBox(width: 8),
            Text(
              'Setup Complete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Icon(Icons.download, size: 20),
            const SizedBox(width: 8),
            Text(
              'Setup Gemma Model',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            _currentStep,
            style: theme.bodyMedium.override(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: theme.alternate,
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_downloadProgress > 0) ...[
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(1)}%',
              style: theme.bodySmall.override(
                color: theme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: theme.bodyMedium.override(
                color: theme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSection() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStep,
              style: theme.bodyMedium.override(
                color: theme.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBanner() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        'Selected Model: ${_selectedModelId ?? "None"}',
        style: theme.bodySmall.override(
          color: theme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: _buildUnifiedInterface(),
    );
  }
}
