// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../actions/send_message_action.dart';
import '../flutter_gemma_library.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'markdown_widget.dart';

/// Simplified Gemma chat widget for FlutterFlow integration This widget
/// provides a clean chat interface for interacting with Gemma models.
///
/// It assumes the model has already been downloaded, set, and initialized
/// using the corresponding custom actions.
///
/// ## Features: - Text-based conversations - Image support for vision-capable
/// models (auto-detected) - Markdown rendering for model responses -
/// Copy-to-clipboard functionality for responses - Responsive design with
/// FlutterFlow theming
///
/// ## Usage: 1. Use downloadModelAction to get your model 2. Use
/// setModelAction to register the model 3. Use initializeModelAction to
/// prepare the model 4. Add this widget to your FlutterFlow page 5. Start
/// chatting!
class GemmaChatWidget extends StatefulWidget {
  const GemmaChatWidget({
    super.key,
    this.width,
    this.height,
    this.placeholder,
    this.onMessageSent,
    this.showImageButton,
  });

  final double? width;
  final double? height;
  final String? placeholder;
  final Future Function(String message, String response)? onMessageSent;
  final bool? showImageButton; // Override image button visibility

  @override
  State<GemmaChatWidget> createState() => _GemmaChatWidgetState();
}

class _GemmaChatWidgetState extends State<GemmaChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  FFUploadedFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  /// Check if the model is ready and show appropriate status message
  void _checkModelStatus() {
    final gemma = FlutterGemmaLibrary.instance;

    if (!gemma.isInitialized) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Please initialize the model first using the initializeModelAction.',
          isUser: false,
          isSystemMessage: true,
        ));
      });
    } else if (!gemma.hasSession) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Model initialized but no session available. This should not happen - please check your setup.',
          isUser: false,
          isSystemMessage: true,
        ));
      });
    } else {
      // Model is ready
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Hello! I\'m ready to chat. ${gemma.supportsVision ? "You can send me text and images." : "Send me a message to get started."}',
          isUser: false,
          isSystemMessage: true,
        ));
      });
    }
  }

  /// Get whether to show the image button
  bool get _shouldShowImageButton {
    if (widget.showImageButton != null) {
      return widget.showImageButton!;
    }

    // Auto-detect based on model capabilities
    return FlutterGemmaLibrary.instance.supportsVision;
  }

  /// Select image from gallery or camera
  Future<void> _selectImage() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = FFUploadedFile(
          name: pickedFile.name,
          bytes: imageBytes,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${pickedFile.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show dialog to choose image source
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Clear selected image
  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// Send message to the model
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final imageFile = _selectedImage;

    // Validate input
    if ((messageText.isEmpty && imageFile == null) || _isLoading) {
      return;
    }

    final displayMessage =
        messageText.isNotEmpty ? messageText : 'Analyze this image';

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(
        text: displayMessage,
        isUser: true,
        imageBytes: imageFile?.bytes,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _clearImage();
    _scrollToBottom();

    try {
      // Send message using the action (this uses the new library)
      final response = await sendMessageAction(
        displayMessage,
        imageFile,
      );

      // Add model response
      setState(() {
        _messages.add(ChatMessage(
          text: response ?? 'Sorry, I could not generate a response.',
          isUser: false,
        ));
      });

      // Call callback if provided
      if (widget.onMessageSent != null && response != null) {
        try {
          await widget.onMessageSent!(displayMessage, response);
        } catch (e) {
          print('GemmaChatWidget: Error in callback: $e');
        }
      }
    } catch (e) {
      print('GemmaChatWidget: Error sending message: $e');

      // Add error message
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Sorry, an error occurred while processing your message. Please try again.',
          isUser: false,
          isSystemMessage: true,
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Scroll to bottom of chat
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

  @override
  Widget build(BuildContext context) {
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
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
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
            ),

          // Selected image preview
          if (_selectedImage != null) _buildImagePreview(),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  /// Build image preview widget
  Widget _buildImagePreview() {
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
              _selectedImage!.name ?? 'Selected Image',
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

  /// Build input area widget
  Widget _buildInputArea() {
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
          // Image button (conditionally shown)
          if (_shouldShowImageButton) ...[
            IconButton(
              onPressed: _isLoading ? null : _selectImage,
              icon: Icon(
                Icons.image,
                color: _isLoading
                    ? Colors.grey
                    : FlutterFlowTheme.of(context).primary,
              ),
              tooltip: 'Add Image',
            ),
            const SizedBox(width: 8),
          ],

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isLoading,
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          ElevatedButton(
            onPressed: _isLoading ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build message bubble widget
  Widget _buildMessageBubble(ChatMessage message) {
    Widget bubble = Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isSystemMessage
              ? FlutterFlowTheme.of(context).warning.withAlpha(25)
              : message.isUser
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: message.isSystemMessage
              ? Border.all(
                  color: FlutterFlowTheme.of(context).warning.withAlpha(76),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if present
            if (message.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  message.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],

            // Text message
            if (message.text.isNotEmpty)
              message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    )
                  : message.isSystemMessage
                      ? Text(
                          message.text,
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : MarkdownWidget(
                          data: message.text,
                          mdcolor: FlutterFlowTheme.of(context).primaryText,
                          fontFamily: 'Readex Pro',
                          fontSize: 14.0,
                        ),
          ],
        ),
      ),
    );

    // Add copy functionality for non-user messages
    if (!message.isUser &&
        !message.isSystemMessage &&
        message.text.isNotEmpty) {
      bubble = GestureDetector(
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: message.text));
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Simple message class for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final bool isSystemMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imageBytes,
    this.isSystemMessage = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
