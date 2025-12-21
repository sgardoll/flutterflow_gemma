// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'package:flutter_md/flutter_md.dart' as md;

class MarkdownWidget extends StatefulWidget {
  const MarkdownWidget({
    Key? key,
    this.width,
    this.height,
    required this.mdcolor,
    required this.data,
    required this.fontFamily,
    required this.fontSize,
    this.onLinkTap, // Optional Future callback for link handling
  }) : super(key: key);

  final double? width;
  final double? height;
  final String data;
  final Color mdcolor;
  final String fontFamily;
  final double fontSize;
  final Future Function(String? title, String? url)? onLinkTap;

  @override
  _MarkdownWidgetState createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  late md.Markdown _markdown;

  @override
  void initState() {
    super.initState();
    // Parse markdown once during initialization for better performance
    _markdown = md.Markdown.fromString(widget.data);
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-parse if data changes
    if (oldWidget.data != widget.data) {
      _markdown = md.Markdown.fromString(widget.data);
    }
  }

  // Default link handler if none provided
  Future<void> _defaultLinkHandler(String? title, String? url) async {
    if (url != null) {
      print('Link tapped: $url (title: $title)');
      // You could add default URL launcher logic here
      try {
        // Example: await launchUrl(Uri.parse(url));
      } catch (e) {
        print('Error opening link: $e');
      }
    }
  }

  // Handle link tap with Future callback
  Future<void> _handleLinkTap(String? title, String? url) async {
    try {
      if (widget.onLinkTap != null) {
        await widget.onLinkTap!(title, url);
      } else {
        await _defaultLinkHandler(title, url);
      }
    } catch (e) {
      print('Error handling link tap: $e');
      // Could show a snackbar or error dialog here
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only wrap in SingleChildScrollView if a specific height is provided.
    // Otherwise, let the widget expand naturally (e.g., in a ListView).
    final content = md.MarkdownTheme(
      data: md.MarkdownThemeData(
        // Base text style
        textStyle: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
        ),
        // Header styles
        h1Style: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize * 2,
          fontWeight: FontWeight.bold,
        ),
        h2Style: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize * 1.75,
          fontWeight: FontWeight.bold,
        ),
        h3Style: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize * 1.5,
          fontWeight: FontWeight.bold,
        ),
        h4Style: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize * 1.25,
          fontWeight: FontWeight.bold,
        ),
        h5Style: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize * 1.1,
          fontWeight: FontWeight.bold,
        ),
        h6Style: TextStyle(
          color: widget.mdcolor,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
        ),
        // Quote style
        quoteStyle: TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          fontStyle: FontStyle.italic,
          color: widget.mdcolor.withOpacity(0.8),
        ),
        // Future callback link handler
        onLinkTap: (title, url) => _handleLinkTap(title, url),
      ),
      child: RepaintBoundary(
        child: md.MarkdownWidget(
          markdown: _markdown,
        ),
      ),
    );

    return Container(
      width: widget.width,
      height: widget.height,
      child: widget.height != null
          ? SingleChildScrollView(
              child: content,
            )
          : content,
    );
  }
}
