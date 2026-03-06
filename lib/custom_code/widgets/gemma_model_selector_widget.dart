// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../ai_rust_api.dart';
import '../ai_types.dart';

/// Model selection and configuration UI.
///
/// Displays available models (installed + well-known downloadable ones), lets
/// the user pick one, enter a HuggingFace token, and save the configuration
/// into FFAppState so the page can trigger [aiInitialize].
///
/// This widget contains **no** capability calculation, no runtime mapping,
/// and no device heuristics. It reads from [AiRustApi] and writes to
/// [FFAppState] only.
class GemmaModelSelectorWidget extends StatefulWidget {
  const GemmaModelSelectorWidget({
    super.key,
    this.width,
    this.height,
    this.onConfigSaved,
  });

  final double? width;
  final double? height;

  /// Called with (modelUrl, authToken) after the user taps Save.
  final Future Function(String modelUrl, String authToken)? onConfigSaved;

  @override
  State<GemmaModelSelectorWidget> createState() =>
      _GemmaModelSelectorWidgetState();
}

class _GemmaModelSelectorWidgetState extends State<GemmaModelSelectorWidget> {
  // -----------------------------------------------------------------------
  // Well-known downloadable models (kept here, not in the API boundary)
  // -----------------------------------------------------------------------

  static const _knownModels = {
    'Gemma 3n E4B (4B, Vision)':
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    'Gemma 3n E2B (2B, Vision)':
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    'Gemma 3 1B (Text-only)':
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
  };

  // -----------------------------------------------------------------------
  // State
  // -----------------------------------------------------------------------

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  String? _selectedKey; // key in _knownModels or 'custom' or 'installed:X'
  bool _isSaving = false;
  List<AiModelInfo> _installedModels = [];
  bool _loadingInstalled = true;
  bool _tokenVisible = false;

  @override
  void initState() {
    super.initState();

    // Restore previously saved config from FFAppState.
    final appState = FFAppState();
    _urlController.text = appState.downloadUrl;
    _tokenController.text = appState.hfToken;

    // Pre-select if the saved URL matches a known model.
    if (appState.downloadUrl.isNotEmpty) {
      for (final entry in _knownModels.entries) {
        if (entry.value == appState.downloadUrl) {
          _selectedKey = entry.key;
          break;
        }
      }
      _selectedKey ??= 'custom';
    }

    _loadInstalledModels();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledModels() async {
    try {
      final list = await AiRustApi.instance.listModels();
      if (mounted) {
        setState(() {
          _installedModels = list;
          _loadingInstalled = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInstalled = false);
    }
  }

  Future<void> _handleSave() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a model URL.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appState = FFAppState();
      appState.update(() {
        appState.downloadUrl = url;
        appState.hfToken = token;
      });

      if (widget.onConfigSaved != null) {
        await widget.onConfigSaved!(url, token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuration saved.'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
        ),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 4),
            Text(
              'Choose a model or enter a custom URL:',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const SizedBox(height: 16),

            // Installed models section
            if (_loadingInstalled)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_installedModels.isNotEmpty) ...[
              Text(
                'Installed',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 8),
              ..._installedModels.map((m) {
                final key = 'installed:${m.id}';
                return _ModelTile(
                  label: m.displayName,
                  subtitle: m.fileSizeFormatted,
                  badge: m.supportsVision ? 'Vision' : null,
                  selected: _selectedKey == key,
                  onTap: () => setState(() {
                    _selectedKey = key;
                    _urlController.text = m.filePath ?? '';
                  }),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Available to Download',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 8),
            ],

            // Known downloadable models
            ..._knownModels.entries.map((e) => _ModelTile(
                  label: e.key,
                  selected: _selectedKey == e.key,
                  onTap: () => setState(() {
                    _selectedKey = e.key;
                    _urlController.text = e.value;
                  }),
                )),

            // Custom URL option
            _ModelTile(
              label: 'Custom URL',
              selected: _selectedKey == 'custom',
              onTap: () => setState(() {
                _selectedKey = 'custom';
                _urlController.clear();
              }),
            ),

            // Custom URL text field
            if (_selectedKey == 'custom') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Model URL',
                  hintText: 'https://huggingface.co/...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // HuggingFace token
            Text(
              'HuggingFace Token (required for HF downloads):',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              obscureText: !_tokenVisible,
              decoration: InputDecoration(
                labelText: 'HuggingFace Token',
                hintText: 'hf_...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _tokenVisible ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _tokenVisible = !_tokenVisible),
                      tooltip: _tokenVisible ? 'Hide token' : 'Show token',
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: () => launchUrl(
                        Uri.parse('https://huggingface.co/settings/tokens'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://huggingface.co/settings/tokens'),
              ),
              child: Text(
                'Get your token at huggingface.co/settings/tokens',
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
              ),
            ),

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget — reusable model tile
// ---------------------------------------------------------------------------

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? FlutterFlowTheme.of(context).primary.withAlpha(25)
                : FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).alternate,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).secondaryText,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          color: FlutterFlowTheme.of(context).primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
