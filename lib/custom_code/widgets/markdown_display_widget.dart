// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownDisplayWidget extends StatelessWidget {
  const MarkdownDisplayWidget({
    super.key,
    this.width,
    this.height,
    required this.markdownData,
    this.selectable = true,
    this.shrinkWrap = false,
  });

  final double? width;
  final double? height;
  final String markdownData;
  final bool selectable;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: MarkdownWidget(
        data: markdownData,
        shrinkWrap: shrinkWrap,
        selectable: selectable,
        config: MarkdownConfig.darkConfig.copy(
          configs: [
            // Paragraph
            PConfig(
              textStyle: TextStyle(
                color: theme.primaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            // Headers
            H1Config(
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            H2Config(
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            H3Config(
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            // Links
            LinkConfig(
              style: TextStyle(
                color: theme.primary,
                decoration: TextDecoration.underline,
              ),
              onTap: (url) async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),

            // Code
            CodeConfig(
              style: TextStyle(
                color: theme.primaryText,
                backgroundColor: theme.secondaryBackground,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),

            // Code blocks
            PreConfig(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.alternate,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              textStyle: TextStyle(
                color: theme.primaryText,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),

            // Blockquotes
            BlockquoteConfig(
              sideColor: theme.primary,
              textColor: theme.secondaryText,
              padding: const EdgeInsets.all(12),
            ),

            // Horizontal rule
            HrConfig(
              height: 1,
              color: theme.alternate,
            ),
          ],
        ),
      ),
    );
  }
}
