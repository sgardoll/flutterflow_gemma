// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import '/custom_code/actions/download_authenticated_model.dart';
import '/custom_code/actions/get_huggingface_model_info.dart';
import '/custom_code/actions/manage_downloaded_models.dart';
import '/custom_code/actions/initialize_local_gemma_model.dart';
import './GemmaManager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GemmaAuthenticatedSetupWidget extends StatefulWidget {
  const GemmaAuthenticatedSetupWidget({
    super.key,
    this.width,
    this.height,
    this.huggingFaceToken = '',
    this.preferredBackend = 'gpu',
    this.maxTokens = 4096,
    this.supportImage = true,
    this.maxNumImages = 1,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    required this.onSetupComplete,
    this.onSetupFailed, // Optional - widget handles errors internally
    this.onProgress,
  });

  final double? width;
  final double? height;
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
  final ScrollController _scrollController = ScrollController();
  bool _isSetupInProgress = false;
  bool _isSetupComplete = false;
  String _currentStep = '';
  String? _errorMessage;
  String? _downloadedModelPath;
  double _downloadProgress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;

  // Enhanced model selection
  String _selectedModel =
      'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';
  String? _customUrl;
  Map<String, dynamic>? _selectedModelInfo;
  List<Map<String, dynamic>> _existingModels = [];
  bool _showCustomUrl = false;
  bool _isLoadingModelInfo = false;

  final TextEditingController _customUrlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  String _enteredToken = '';

  // Predefined model options - Focus on multimodal Gemma 3 models
  final List<Map<String, String>> _modelOptions = [
    {
      'value':
          'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
      'label': 'Gemma 3n E4B (4B parameters) - Recommended',
      'description': 'Optimized 4B model with vision support'
    },
    {
      'value':
          'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
      'label': 'Gemma 3n E2B (2B parameters) - Smaller, faster',
      'description': 'Compact 2B model with vision support'
    },
    {
      'value':
          'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
      'label': 'Gemma 3 1B (Text-only, most compact)',
      'description': 'Most compact model, fastest inference'
    },
    {
      'value': 'other',
      'label': 'Other (Custom URL)',
      'description': 'Specify your own HuggingFace model URL'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadExistingModels();
    _loadModelInfo();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('huggingFaceToken') ?? widget.huggingFaceToken;
    setState(() {
      _enteredToken = token;
      _tokenController.text = token;
    });
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huggingFaceToken', token);
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingModels() async {
    try {
      final models = await manageDownloadedModels(null, null);
      setState(() {
        _existingModels = models.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error loading existing models: $e');
    }
  }

  Future<void> _loadModelInfo() async {
    if (_isLoadingModelInfo) return;

    final modelIdentifier = _showCustomUrl ? _customUrl : _selectedModel;
    if (modelIdentifier == null ||
        modelIdentifier.isEmpty ||
        modelIdentifier.startsWith('http')) {
      setState(() {
        _selectedModelInfo = null;
      });
      return;
    }

    setState(() {
      _isLoadingModelInfo = true;
    });

    try {
      final currentToken =
          _enteredToken.isNotEmpty ? _enteredToken : widget.huggingFaceToken;
      if (modelIdentifier.isNotEmpty) {
        final info =
            await getHuggingfaceModelInfo(modelIdentifier, currentToken);
        setState(() {
          _selectedModelInfo = info;
        });
      }
    } catch (e) {
      print('Error loading model info: $e');
    } finally {
      setState(() {
        _isLoadingModelInfo = false;
      });
    }
  }

  Future<void> _deleteModel(String filePath) async {
    try {
      await manageDownloadedModels('delete', filePath);
      await _loadExistingModels();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting model: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to determine if a model supports vision
  // Uses the standardized detection logic from GemmaManager
  bool _isMultimodalModel(String modelType) {
    return GemmaManager.isMultimodalModel(modelType);
  }

  Future<void> _useExistingModel(String filePath, String modelType) async {
    try {
      print('=== STARTING _useExistingModel ===');
      print('FilePath: $filePath');
      print('ModelType from DB: $modelType');

      // DERIVE modelType from filePath to ensure correctness
      final derivedModelType = GemmaManager.getModelTypeFromPath(filePath);
      print('Derived ModelType from Path: $derivedModelType');

      setState(() {
        _isSetupInProgress = true;
        _currentStep = 'Initializing existing model...';
      });

      // Determine if this model supports vision
      final isMultimodal = _isMultimodalModel(derivedModelType);
      final supportImage = isMultimodal && widget.supportImage;

      print('=== MODEL CAPABILITY DETECTION ===');
      print('Original model type: "$derivedModelType"');
      print('Detected as multimodal: $isMultimodal');
      print('Widget supports image: ${widget.supportImage}');
      print('Final image support: $supportImage');
      print('=== END CAPABILITY DETECTION ===');

      print('About to call initializeLocalGemmaModel...');
      final initSuccess = await initializeLocalGemmaModel(
        filePath,
        derivedModelType, // Use the derived model type
        widget.preferredBackend,
        widget.maxTokens,
        supportImage,
        4, // numOfThreads
        0.8, // temperature
        1.0, // topK
        1.0, // topP
        1, // randomSeed
      );

      print('initializeLocalGemmaModel returned: $initSuccess');

      if (initSuccess) {
        print('Model initialization SUCCESS - now creating session');
        setState(() {
          _currentStep = 'Creating chat session...';
        });

        // Create session after successful model initialization
        final gemmaManager = GemmaManager();
        final sessionSuccess = await gemmaManager.createSession(
          temperature: 0.8,
          randomSeed: 1,
          topK: 1,
        );

        if (sessionSuccess) {
          print('Session creation SUCCESS - setup complete');
          setState(() {
            _isSetupInProgress = false;
            _isSetupComplete = true;
            _currentStep = 'Model and session ready for use!';
          });
          print('About to call onSetupComplete callback...');
          await widget.onSetupComplete();
          print('onSetupComplete callback completed!');
        } else {
          print('Session creation FAILED - showing error to user');
          setState(() {
            _isSetupInProgress = false;
            _isSetupComplete = false;
            _errorMessage = 'Failed to create chat session. Please try again.';
            _currentStep = '';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session creation failed'),
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 4000),
            ),
          );
        }
      } else {
        print('Model initialization FAILED - showing error to user');
        setState(() {
          _isSetupInProgress = false;
          _isSetupComplete = false;
          _errorMessage = 'Failed to initialize model. Please try again.';
          _currentStep = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model initialization failed'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 4000),
          ),
        );
      }
    } catch (e) {
      print('ERROR in _useExistingModel: $e');
      setState(() {
        _isSetupInProgress = false;
        _errorMessage = 'Failed to initialize model: ${e.toString()}';
        _currentStep = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 4000),
        ),
      );
    }
  }

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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Icon(
                    _isSetupComplete
                        ? Icons.check_circle
                        : _isSetupInProgress
                            ? Icons.download
                            : Icons.smart_toy,
                    size: 48,
                    color: _isSetupComplete
                        ? Colors.green
                        : widget.primaryColor ??
                            FlutterFlowTheme.of(context).primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSetupComplete
                        ? 'Gemma Model Ready!'
                        : _isSetupInProgress
                            ? 'Setting Up Gemma Model...'
                            : 'Setup Gemma Model',
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                          fontFamily: 'Inter',
                          color: widget.textColor ??
                              FlutterFlowTheme.of(context).primaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            if (!_isSetupInProgress && !_isSetupComplete) ...[
              const SizedBox(height: 24),

              // HuggingFace Token Input
              Text(
                'HuggingFace Token',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Inter',
                      color: widget.textColor ??
                          FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  hintText:
                      'Enter your HuggingFace token (required for download)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  suffixIcon: Icon(
                    _enteredToken.isNotEmpty
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color:
                        _enteredToken.isNotEmpty ? Colors.green : Colors.grey,
                  ),
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _enteredToken = value;
                  });
                  _saveToken(value);
                  // Save token to app state for future use
                  if (value.isNotEmpty) {
                    FFAppState().update(() {
                      FFAppState().hfToken = value;
                    });
                  }
                  _loadModelInfo();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Get your token at: https://huggingface.co/settings/tokens',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Inter',
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Model Selection
              Text(
                'Choose Model',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Inter',
                      color: widget.textColor ??
                          FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    items: _modelOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(
                          option['label']!,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedModel = value!;
                        _showCustomUrl = value == 'other';
                        if (!_showCustomUrl) {
                          _customUrl = null;
                          _customUrlController.clear();
                        }
                      });
                      _loadModelInfo();
                    },
                  ),
                ),
              ),

              // Custom URL field
              if (_showCustomUrl) ...[
                const SizedBox(height: 16),
                Text(
                  'HuggingFace Model URL',
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Inter',
                        color: widget.textColor ??
                            FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customUrlController,
                  decoration: InputDecoration(
                    hintText:
                        'https://huggingface.co/model/resolve/main/file.task',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  maxLines: 1,
                  scrollPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    _customUrl = value;
                    if (value.isNotEmpty) {
                      _loadModelInfo();
                    }
                  },
                ),
              ],

              // Model Info Card
              if (_selectedModelInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedModelInfo!['name'] ?? 'Unknown Model',
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Inter',
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedModelInfo!['description'] ?? '',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Colors.blue[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Vision support indicator
                      Row(
                        children: [
                          Icon(
                            _isMultimodalModel(_showCustomUrl
                                    ? (_customUrl ?? '')
                                    : _selectedModel)
                                ? Icons.visibility
                                : Icons.text_fields,
                            color: _isMultimodalModel(_showCustomUrl
                                    ? (_customUrl ?? '')
                                    : _selectedModel)
                                ? Colors.green
                                : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isMultimodalModel(_showCustomUrl
                                    ? (_customUrl ?? '')
                                    : _selectedModel)
                                ? 'Supports Images + Text'
                                : 'Text Only',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Inter',
                                      color: _isMultimodalModel(_showCustomUrl
                                              ? (_customUrl ?? '')
                                              : _selectedModel)
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                      if (_selectedModelInfo!['fileSize'] != null &&
                          _selectedModelInfo!['fileSize'] > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Download Size: ${(_selectedModelInfo!['fileSize'] / 1024 / 1024 / 1024).toStringAsFixed(2)} GB',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Existing Models Section
              if (_existingModels.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Downloaded Models',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Inter',
                        color: widget.textColor ??
                            FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...(_existingModels.map((model) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['modelType'],
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Text(
                                '${model['sizeFormatted']} • ${model['dateFormatted']}',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _useExistingModel(
                            model['filePath'],
                            model['modelType'],
                          ),
                          child: Text('Use'),
                        ),
                        IconButton(
                          onPressed: () => _deleteModel(model['filePath']),
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                  );
                }).toList()),
              ],

              const SizedBox(height: 24),

              // Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canDownload() ? _setupGemmaModel : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canDownload()
                        ? (widget.primaryColor ??
                            FlutterFlowTheme.of(context).primary)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getDownloadButtonText(),
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),

              // Helper text when button is disabled
              if (!_canDownload()) ...[
                const SizedBox(height: 8),
                Text(
                  _getHelpText(),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            // Progress Section
            if (_isSetupInProgress) ...[
              const SizedBox(height: 24),

              // Current step
              Text(
                _currentStep,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: widget.textColor ??
                          FlutterFlowTheme.of(context).primaryText,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Progress bar
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
                backgroundColor: Colors.grey.withOpacity(0.3),
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
              ],
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
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

            // Success message
            if (_isSetupComplete) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Model is ready for use!',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canDownload() {
    final currentToken =
        _enteredToken.isNotEmpty ? _enteredToken : widget.huggingFaceToken;
    if (currentToken.isEmpty) return false;
    if (_showCustomUrl) {
      return _customUrl != null && _customUrl!.isNotEmpty;
    }
    return _selectedModel != 'other';
  }

  String _getDownloadButtonText() {
    final currentToken =
        _enteredToken.isNotEmpty ? _enteredToken : widget.huggingFaceToken;

    if (currentToken.isEmpty) {
      return 'Enter HuggingFace Token to Download';
    }

    if (_showCustomUrl && (_customUrl == null || _customUrl!.isEmpty)) {
      return 'Enter Custom Model URL';
    }

    if (_selectedModel == 'other' && !_showCustomUrl) {
      return 'Select a Model to Download';
    }

    return 'Download & Setup Model';
  }

  String _getHelpText() {
    final currentToken =
        _enteredToken.isNotEmpty ? _enteredToken : widget.huggingFaceToken;

    if (currentToken.isEmpty) {
      return 'Please enter a valid HuggingFace token';
    }

    if (_showCustomUrl && (_customUrl == null || _customUrl!.isEmpty)) {
      return 'Please enter a valid model URL';
    }

    if (_selectedModel == 'other' && !_showCustomUrl) {
      return 'Please select a model to download';
    }

    return '';
  }

  Future<void> _setupGemmaModel() async {
    setState(() {
      _isSetupInProgress = true;
      _errorMessage = null;
      _currentStep = 'Preparing to download...';
      _downloadProgress = 0.0;
      _downloadedBytes = 0;
      _totalBytes = 0;
    });

    try {
      final isDirectUrl = _selectedModel.startsWith('http');
      final modelUrl = isDirectUrl
          ? _selectedModel
          : (_showCustomUrl ? _customUrl! : _selectedModelInfo?['url']);

      if (modelUrl == null || modelUrl.isEmpty) {
        throw Exception('No download URL available for selected model');
      }

      setState(() {
        _currentStep = 'Downloading model...';
        if (_selectedModelInfo?['fileSize'] != null) {
          _totalBytes = _selectedModelInfo!['fileSize'];
        }
      });

      final currentToken =
          _enteredToken.isNotEmpty ? _enteredToken : widget.huggingFaceToken;

      // Determine what to download - either a predefined model or custom URL
      final String downloadTarget = modelUrl;

      final String? modelPath = await downloadAuthenticatedModel(
        downloadTarget,
        currentToken,
        (downloaded, total, percentage) async {
          setState(() {
            _downloadedBytes = downloaded;
            _totalBytes = total;
            _downloadProgress = percentage;
          });

          if (widget.onProgress != null) {
            await widget.onProgress!(percentage.round());
          }
        },
      );

      if (modelPath == null) {
        final errorMsg = _showCustomUrl
            ? 'Failed to download model from custom URL: $_customUrl. Please check your HuggingFace token and verify the URL is correct.'
            : 'Failed to download model $_selectedModel. Please check your HuggingFace token and try again.';
        throw Exception(errorMsg);
      }

      setState(() {
        _downloadedModelPath = modelPath;
        _currentStep = 'Model downloaded! Initializing...';
      });

      // Extract model name for initialization
      String modelName;
      if (_selectedModel.startsWith('http')) {
        modelName = GemmaManager.getModelTypeFromPath(_selectedModel);
      } else if (_showCustomUrl) {
        // For custom URLs, try to extract a meaningful model name from the filename
        final fileName =
            _selectedModelInfo?['fileName'] ?? _customUrl!.split('/').last;
        // Extract model identifier from filename (e.g., "gemma-3n-E4B-it-int4.task" -> "gemma-3n-E4B-it")
        modelName = fileName
            .replaceAll(RegExp(r'\.(task|bin|gguf)$'), '')
            .replaceAll(RegExp(r'-int\d+$'), '');
        print('Extracted model name from custom URL: $modelName');
      } else {
        modelName = _selectedModel;
      }

      // Determine if this model supports vision
      final isMultimodal = _isMultimodalModel(modelName);
      final supportImage = isMultimodal && widget.supportImage;

      print('=== DOWNLOADED MODEL CAPABILITY DETECTION ===');
      print('Downloaded model name: "$modelName"');
      print('Detected as multimodal: $isMultimodal');
      print('Widget supports image: ${widget.supportImage}');
      print('Final image support: $supportImage');
      print('=== END DOWNLOADED MODEL CAPABILITY DETECTION ===');

      final initSuccess = await initializeLocalGemmaModel(
        modelPath,
        modelName,
        widget.preferredBackend,
        widget.maxTokens,
        supportImage,
        4, // numOfThreads
        0.8, // temperature
        1.0, // topK
        1.0, // topP
        1, // randomSeed
      );

      if (!initSuccess) {
        throw Exception('Failed to initialize Gemma model');
      }

      setState(() {
        _isSetupInProgress = false;
        _isSetupComplete = true;
        _currentStep = 'Model ready for use!';
      });

      await widget.onSetupComplete();
      await _loadExistingModels(); // Refresh the models list
    } catch (e) {
      setState(() {
        _isSetupInProgress = false;
        _errorMessage = 'Setup failed: ${e.toString()}';
        _currentStep = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 4000),
        ),
      );
    }
  }
}
