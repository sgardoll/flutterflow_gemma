// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../ai_rust_api.dart';
import '../ai_types.dart';
import '../ai_state_helpers.dart';

/// Polling-based chat shell for Gemma on-device AI.
///
/// This widget is intentionally thin. It renders messages, accepts input,
/// and polls [AiRustApi] for updates. It contains **no** inference logic,
/// prompt construction, model management, or runtime mapping.
///
/// ## FlutterFlow usage
/// 1. Initialize the engine with [aiInitialize] action.
/// 2. Drop this widget onto a page.
/// 3. Chatting works.
class GemmaChatRuntimeWidget extends StatefulWidget {
  const GemmaChatRuntimeWidget({
    super.key,
    this.width,
    this.height,
    this.placeholder,
    this.onMessageSent,
    this.showImageButton,
    this.onError,
    this.onChangeModel,
  });

  final double? width;
  final double? height;
  final String? placeholder;

  /// Called after a complete exchange (user message + assistant response).
  final Future Function(String message, String response)? onMessageSent;

  /// Override image-button visibility. `null` = auto-detect from model caps.
  final bool? showImageButton;

  /// Called when an error occurs during generation.
  final Future Function(String errorMessage)? onError;

  /// Called when the user taps "Go Back" in an error bubble.
  final Future Function()? onChangeModel;

  @override
  State<GemmaChatRuntimeWidget> createState() => _GemmaChatRuntimeWidgetState();
}

class _GemmaChatRuntimeWidgetState extends State<GemmaChatRuntimeWidget> {
  // -----------------------------------------------------------------------
  // Controllers & pickers
  // -----------------------------------------------------------------------

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  // -----------------------------------------------------------------------
  // Local state
  // -----------------------------------------------------------------------

  List<AiMessageRecord> _messages = [];
  Timer? _pollTimer;
  bool _isSending = false;
  FFUploadedFile? _selectedImage;

  /// Text of the last user message — kept for the [onMessageSent] callback.
  String? _lastUserText;

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Seed the list with whatever the API already has (e.g. resumed session).
    _refreshMessages();

    // If the engine is mid-generation (widget re-mounted), resume polling.
    if (AiRustApi.instance.isGenerating) {
      _isSending = true;
      _startPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Polling
  // -----------------------------------------------------------------------

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _onPollTick();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _onPollTick() {
    if (!mounted) {
      _stopPolling();
      return;
    }

    _refreshMessages();

    final api = AiRustApi.instance;

    if (!api.isGenerating) {
      _stopPolling();
      setState(() => _isSending = false);

      // Fire the callback with the final assistant response.
      _fireOnMessageSent();

      // Check if the latest message is an error.
      if (AiStateHelpers.hasRecentError(_messages) && widget.onError != null) {
        final last = AiStateHelpers.latestAssistantMessage(_messages);
        if (last != null) widget.onError!(last.text);
      }
    }

    _scrollToBottom();
  }

  void _refreshMessages() {
    final fresh = AiRustApi.instance.getSessionMessages();
    if (mounted) setState(() => _messages = fresh);
  }

  // -----------------------------------------------------------------------
  // Sending
  // -----------------------------------------------------------------------

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    final image = _selectedImage;

    if ((text.isEmpty && image == null) || _isSending) return;

    final api = AiRustApi.instance;
    if (!api.isInitialized) return;

    final prompt = text.isNotEmpty ? text : 'Analyze this image';

    _inputController.clear();
    _clearImage();
    setState(() => _isSending = true);

    _lastUserText = prompt;

    bool accepted;
    if (image != null && image.bytes != null && api.supportsVision) {
      accepted = await api.sendImageMessage(prompt, image.bytes!);
    } else {
      accepted = await api.sendTextMessage(prompt);
    }

    if (accepted) {
      _refreshMessages();
      _scrollToBottom();
      _startPolling();
    } else {
      setState(() => _isSending = false);
    }
  }

  void _fireOnMessageSent() {
    if (widget.onMessageSent == null || _lastUserText == null) return;

    final lastAssistant = AiStateHelpers.latestAssistantMessage(_messages);
    if (lastAssistant != null &&
        lastAssistant.status == AiMessageStatus.complete) {
      widget.onMessageSent!(_lastUserText!, lastAssistant.text);
      _lastUserText = null;
    }
  }

  // -----------------------------------------------------------------------
  // Image selection
  // -----------------------------------------------------------------------

  Future<void> _selectImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = FFUploadedFile(name: picked.name, bytes: bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _clearImage() => setState(() => _selectedImage = null);

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  bool get _showImageButton {
    if (widget.showImageButton != null) return widget.showImageButton!;
    return AiRustApi.instance.supportsVision;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final isReady = appState.isModelInitialized;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          // Message list
          Expanded(
            child: _messages.isEmpty && isReady
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(context, _messages[i]),
                  ),
          ),

          // Generating indicator
          if (_isSending) _buildGeneratingBar(context),

          // Image preview
          if (_selectedImage != null) _buildImagePreview(context),

          // Input row
          _buildInputArea(context, isReady),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Sub-builders (UI only — no logic)
  // -----------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    final vision = AiRustApi.instance.supportsVision;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          vision
              ? 'Ready to chat. You can send text and images.'
              : 'Ready to chat. Send a message to get started.',
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontStyle: FontStyle.italic,
              ),
        ),
      ),
    );
  }

  Widget _buildGeneratingBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Thinking...'),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          if (_selectedImage?.bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _selectedImage!.bytes!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedImage?.name ?? 'Selected Image',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
          ),
          IconButton(
            onPressed: _clearImage,
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isReady) {
    final enabled = isReady && !_isSending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FlutterFlowTheme.of(context).primary.withAlpha(51),
          ),
        ),
      ),
      child: Row(
        children: [
          // Image button
          if (_showImageButton) ...[
            IconButton(
              onPressed: enabled ? _selectImage : null,
              icon: Icon(
                Icons.image,
                color: enabled
                    ? FlutterFlowTheme.of(context).primary
                    : Colors.grey,
              ),
              tooltip: 'Add Image',
            ),
            const SizedBox(width: 8),
          ],

          // Text field
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: enabled,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => enabled ? _sendMessage() : null,
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          ElevatedButton(
            onPressed: enabled ? _sendMessage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Message bubble
  // -----------------------------------------------------------------------

  Widget _buildBubble(BuildContext context, AiMessageRecord msg) {
    // Error messages get a special treatment.
    if (msg.status == AiMessageStatus.error) {
      return _buildErrorBubble(context, msg);
    }

    final isUser = msg.isUser;
    final isPartial = msg.isPartial;

    Widget bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attached image
            if (msg.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  msg.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              if (msg.text.isNotEmpty) const SizedBox(height: 8),
            ],

            // Text / markdown
            if (msg.text.isNotEmpty)
              isUser
                  ? Text(msg.text, style: const TextStyle(color: Colors.white))
                  : isPartial
                      ? Text(
                          '${msg.text} ...',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : MarkdownWidget(
                          data: msg.text,
                          mdcolor: FlutterFlowTheme.of(context).primaryText,
                          fontFamily: 'Readex Pro',
                          fontSize: 14.0,
                        ),
          ],
        ),
      ),
    );

    // Long-press to copy assistant messages.
    if (!isUser && msg.text.isNotEmpty && !isPartial) {
      bubble = GestureDetector(
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: msg.text));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: bubble,
      );
    }

    return bubble;
  }

  Widget _buildErrorBubble(BuildContext context, AiMessageRecord msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).error.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).error.withAlpha(76),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  color: FlutterFlowTheme.of(context).error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (widget.onChangeModel != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.onChangeModel!();
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
