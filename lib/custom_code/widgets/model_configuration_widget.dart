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
import 'package:url_launcher/url_launcher.dart';

/// Model Configuration Widget for FlutterFlow
///
/// Allows users to select a Gemma model from pre-configured options or enter
/// a custom URL, along with their HuggingFace token.
///
/// Updates FFAppState with the selected configuration.
class ModelConfigurationWidget extends StatefulWidget {
  const ModelConfigurationWidget({
    super.key,
    this.width,
    this.height,
    this.onConfigurationSaved,
  });

  final double? width;
  final double? height;
  final Future Function(String? modelUrl, String? token)? onConfigurationSaved;

  @override
  State<ModelConfigurationWidget> createState() =>
      _ModelConfigurationWidgetState();
}

class _ModelConfigurationWidgetState extends State<ModelConfigurationWidget> {
  late TextEditingController _modelUrlController;
  late TextEditingController _tokenController;
  String? _selectedModel;
  bool _isSaving = false;

  final defaultModels = {
    'Gemma 3n E4B (4B, Vision)':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'Gemma 3n E2B (2B, Vision)':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    'Gemma 3 1B (Text-only)':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
  };

  @override
  void initState() {
    super.initState();
    final appState = FFAppState();
    _modelUrlController = TextEditingController(text: appState.downloadUrl);
    _tokenController = TextEditingController(text: appState.hfToken);

    if (appState.downloadUrl.isNotEmpty) {
      _selectedModel = defaultModels.entries
          .firstWhere(
            (entry) => entry.value == appState.downloadUrl,
            orElse: () => defaultModels.entries.first,
          )
          .key;
    }
  }

  @override
  void dispose() {
    _modelUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final modelUrl = _modelUrlController.text.trim();
    final token = _tokenController.text.trim();

    if (modelUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or enter a model URL')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final appState = FFAppState();
      appState.update(() {
        appState.downloadUrl = modelUrl;
        appState.hfToken = token;
      });

      if (widget.onConfigurationSaved != null) {
        await widget.onConfigurationSaved!(modelUrl, token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration saved successfully'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving configuration: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a Model',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a model or enter a custom URL:',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
          const SizedBox(height: 12),
          ...defaultModels.entries.map((entry) {
            final isSelected = _selectedModel == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedModel = entry.key;
                    _modelUrlController.text = entry.value;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? FlutterFlowTheme.of(context).primary.withAlpha(25)
                        : FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).alternate,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).secondaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _selectedModel = 'custom';
                _modelUrlController.clear();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedModel == 'custom'
                    ? FlutterFlowTheme.of(context).primary.withAlpha(25)
                    : FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedModel == 'custom'
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).alternate,
                  width: _selectedModel == 'custom' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedModel == 'custom'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _selectedModel == 'custom'
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).secondaryText,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Custom URL',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontWeight: _selectedModel == 'custom'
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedModel == 'custom') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _modelUrlController,
              decoration: InputDecoration(
                labelText: 'Model URL',
                hintText: 'https://huggingface.co/...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'HuggingFace Token (required for download):',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'HuggingFace Token',
              hintText: 'hf_...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.open_in_new, size: 20),
                onPressed: () {
                  launchUrl(
                      Uri.parse('https://huggingface.co/settings/tokens'));
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get your token at huggingface.co/settings/tokens',
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }
}
