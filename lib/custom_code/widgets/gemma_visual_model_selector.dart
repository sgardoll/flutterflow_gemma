// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'dart:io';

class GemmaVisualModelSelector extends StatefulWidget {
  const GemmaVisualModelSelector({
    super.key,
    this.width,
    this.height,
    this.selectedModelId,
    this.onModelSelected,
  });

  final double? width;
  final double? height;
  final String? selectedModelId;
  final Future Function(String modelId)? onModelSelected;

  @override
  State<GemmaVisualModelSelector> createState() =>
      _GemmaVisualModelSelectorState();
}

class _GemmaVisualModelSelectorState extends State<GemmaVisualModelSelector> {
  String? _selectedModelId;

  // Direct list of 3 models as requested
  final List<GemmaModelId> _models = [
    GemmaModelId.gemma3nE4bIt, // Gemma 3n 4B
    GemmaModelId.gemma3nE2bIt, // Gemma 3n 2B
    GemmaModelId.gemma31bIt, // Gemma 3 1B
  ];

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.selectedModelId;
  }

  void _selectModel(String modelId) {
    setState(() {
      _selectedModelId = modelId;
    });
    widget.onModelSelected?.call(modelId);
  }

  String _getDefaultModelForPlatform() {
    if (Platform.isIOS) {
      return 'gemma3-1b-it';
    } else if (Platform.isAndroid) {
      return 'gemma3-1b-it';
    } else {
      return 'gemma3-1b-web';
    }
  }

  bool _isModelRecommended(GemmaModelId modelId) {
    final modelIdString = gemmaModelIdStrings[modelId] ?? '';
    final defaultModel = _getDefaultModelForPlatform();
    return modelIdString == defaultModel;
  }

  Widget _buildModelTile(GemmaModelId modelId) {
    final theme = FlutterFlowTheme.of(context);
    final modelIdString = gemmaModelIdStrings[modelId] ?? '';
    final displayName = gemmaModelDisplayNames[modelId] ?? modelIdString;
    final isSelected = _selectedModelId == modelIdString;
    final isRecommended = _isModelRecommended(modelId);
    final supportsVision = GemmaManager.isMultimodalModel(modelIdString);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.3)
              : theme.alternate.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectModel(modelIdString),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.alternate,
                    width: 2,
                  ),
                  color: isSelected ? theme.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(width: 16),

              // Model info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.titleMedium.override(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.primary
                                  : theme.primaryText,
                            ),
                          ),
                        ),

                        // Badges
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Recommended',
                              style: theme.bodySmall.override(
                                color: theme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Capabilities
                    Row(
                      children: [
                        if (supportsVision) ...[
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vision',
                            style: theme.bodyMedium.override(
                              color: theme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: theme.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Text',
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ListView(
        children: _models.map((model) => _buildModelTile(model)).toList(),
      ),
    );
  }
}
