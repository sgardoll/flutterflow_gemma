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

class _GemmaVisualModelSelectorState extends State<GemmaVisualModelSelector>
    with TickerProviderStateMixin {
  String? _selectedModelId;
  String? _expandedCategory;
  late AnimationController _animationController;

  // Model categories and their models
  final Map<String, List<GemmaModelId>> _modelCategories = {
    'Gemma 3': [
      GemmaModelId.gemma31bWeb,
      GemmaModelId.gemma31bIt,
      GemmaModelId.gemma3_9b,
      GemmaModelId.gemma3_27b,
    ],
    'Gemma 3n': [
      GemmaModelId.gemma3nE4bIt,
      GemmaModelId.gemma3nE2bIt,
      GemmaModelId.gemma3n_1b,
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.selectedModelId;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategory == category) {
        _expandedCategory = null;
        _animationController.reverse();
      } else {
        _expandedCategory = category;
        _animationController.forward();
      }
    });
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

  Widget _buildCategoryCard(String category, List<GemmaModelId> models) {
    final isExpanded = _expandedCategory == category;
    final theme = FlutterFlowTheme.of(context);

    // Determine category characteristics
    final isVisionCategory = category == 'Gemma 3n';
    final categoryIcon =
        isVisionCategory ? Icons.visibility : Icons.text_fields;
    final categoryDescription =
        isVisionCategory ? 'Vision + Text Models' : 'Text-Only Models';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded
              ? theme.primary.withValues(alpha: 0.3)
              : theme.alternate.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Category header
          InkWell(
            onTap: () => _toggleCategory(category),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: theme.primary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Category info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: theme.titleMedium.override(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryDescription,
                          style: theme.bodySmall.override(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand/collapse indicator
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable models list
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: models
                          .map((model) => _buildModelTile(model))
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTile(GemmaModelId modelId) {
    final theme = FlutterFlowTheme.of(context);
    final modelIdString = gemmaModelIdStrings[modelId] ?? '';
    final displayName = gemmaModelDisplayNames[modelId] ?? modelIdString;
    final isSelected = _selectedModelId == modelIdString;
    final isRecommended = _isModelRecommended(modelId);
    final supportsVision = GemmaManager.isMultimodalModel(modelIdString);

    return InkWell(
      onTap: () => _selectModel(modelIdString),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.alternate.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primary : theme.alternate,
                  width: 2,
                ),
                color: isSelected ? theme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(width: 12),

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
                          style: theme.bodyMedium.override(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected ? theme.primary : theme.primaryText,
                          ),
                        ),
                      ),

                      // Badges
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Recommended',
                            style: theme.bodySmall.override(
                              color: theme.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Capabilities
                  Row(
                    children: [
                      if (supportsVision) ...[
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Vision',
                          style: theme.bodySmall.override(
                            color: theme.primary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.text_fields,
                        size: 14,
                        color: theme.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Text',
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                          fontSize: 11,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: widget.width,
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  Icons.model_training,
                  color: theme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Model',
                  style: theme.headlineSmall.override(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Model categories
          Expanded(
            child: ListView(
              children: _modelCategories.entries
                  .map((entry) => _buildCategoryCard(entry.key, entry.value))
                  .toList(),
            ),
          ),

          // Selected model info
          if (_selectedModelId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: $_selectedModelId',
                      style: theme.bodySmall.override(
                        color: theme.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
}
