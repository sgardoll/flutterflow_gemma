// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../GemmaManager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// FlutterFlow Action Flow Editor Callbacks:
// - onMessageSent: Triggered when user sends a text message (use for: logging, analytics, app state updates)
// - onResponseReceived: Triggered when AI responds (use for: notifications, saving to database, UI updates)
// - onImageMessageSent: Triggered when user sends image + text (use for: image processing, storage, special handling)
// - onModelCapabilitiesCheck: Triggered on init to check if model supports multimodal (should return bool to App State)

class GemmaChatWidget extends StatefulWidget {
  const GemmaChatWidget({
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12.0,
    this.paddingHorizontal = 16.0,
    this.paddingVertical = 12.0,
    this.placeholder = 'Type your message...',
    this.sendButtonText = 'Send',
    this.imageButtonColor,
    this.maxImageSize = 1024,
    required this.onMessageSent,
    this.onResponseReceived,
    this.onImageMessageSent,
    this.onModelCapabilitiesCheck,
  });

  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double paddingHorizontal;
  final double paddingVertical;
  final String placeholder;
  final String sendButtonText;
  final Color? imageButtonColor;
  final int maxImageSize;
  final Future Function(String message) onMessageSent;
  final Future Function(String response)? onResponseReceived;
  final Future Function(String message, FFUploadedFile imageFile)?
      onImageMessageSent;
  final Future Function()? onModelCapabilitiesCheck;

  @override
  State<GemmaChatWidget> createState() => _GemmaChatWidgetState();
}

class _GemmaChatWidgetState extends State<GemmaChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isMultimodalAvailable =
      false; // Tracks if model actually supports multimodal
  FFUploadedFile? _selectedImage;
  final GemmaManager _gemmaManager = GemmaManager();

  @override
  void initState() {
    super.initState();
    // Don't initialize here - rely on the model being already initialized

    // Check model capabilities and auto-enable multimodal if supported
    _checkModelCapabilities();
  }

  Future<void> _checkModelCapabilities() async {
    try {
      // Check if the GemmaManager has a multimodal-capable model loaded
      bool modelSupportsMultimodal = false;

      // Get the current model type from GemmaManager
      if (_gemmaManager.isInitialized &&
          _gemmaManager.currentModelType != null) {
        // Use the same logic as GemmaManager to detect multimodal models
        final modelType = _gemmaManager.currentModelType!;
        final multimodalModels = [
          'gemma-3-4b-it',
          'gemma-3-12b-it',
          'gemma-3-27b-it',
          'gemma-3-nano-e4b-it',
          'gemma-3-nano-e2b-it',
        ];

        // Also check for display names used in the UI
        final multimodalDisplayNames = [
          'gemma 3 4b edge',
          'gemma 3 12b edge',
          'gemma 3 27b edge',
          'gemma 3 nano',
        ];

        modelSupportsMultimodal = multimodalModels.any((model) =>
                modelType.toLowerCase().contains(model.toLowerCase())) ||
            multimodalDisplayNames.any((displayName) =>
                modelType.toLowerCase().contains(displayName.toLowerCase())) ||
            modelType.toLowerCase().contains('nano') ||
            modelType.toLowerCase().contains('vision') ||
            modelType.toLowerCase().contains('multimodal');

        print(
            'GemmaChatWidget: Model type: "$modelType", Supports multimodal: $modelSupportsMultimodal');
        print(
            'GemmaChatWidget: Model type contains "gemma 3 4b edge": ${modelType.toLowerCase().contains('gemma 3 4b edge')}');
      } else {
        print('GemmaChatWidget: No model initialized or model type unknown');
        modelSupportsMultimodal = false;
      }

      // Call FlutterFlow action to check/store capabilities
      if (widget.onModelCapabilitiesCheck != null) {
        await widget.onModelCapabilitiesCheck!();
        // The FlutterFlow action should set an App State variable with the result
      }

      setState(() {
        _isMultimodalAvailable = modelSupportsMultimodal;
      });

      print('Multimodal capabilities detected: $_isMultimodalAvailable');
    } catch (e) {
      print('Error checking model capabilities: $e');
      setState(() {
        _isMultimodalAvailable = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: widget.maxImageSize.toDouble(),
        maxHeight: widget.maxImageSize.toDouble(),
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = FFUploadedFile(
            name: pickedFile.name,
            bytes: bytes,
          );
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future _sendMessage() async {
    final message = _messageController.text.trim();
    if ((message.isEmpty && _selectedImage == null) || _isLoading) return;

    final messageText =
        message.isNotEmpty ? message : "Please analyze this image";
    final imageFile = _selectedImage;

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        imageBytes: imageFile?.bytes,
      ));
      _isLoading = true;
      _selectedImage = null; // Clear selected image after sending
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String? response;

      // Call the FlutterFlow action callback (for FlutterFlow state management)
      if (imageFile != null && widget.onImageMessageSent != null) {
        await widget.onImageMessageSent!(messageText, imageFile);
      } else {
        await widget.onMessageSent(messageText);
      }

      // Directly call the Gemma actions to get the response
      if (imageFile != null) {
        response = await _gemmaManager.sendMessage(messageText,
            imageBytes: imageFile.bytes);
      } else {
        response = await _gemmaManager.sendMessage(messageText);
      }

      if (response != null && response.toString().isNotEmpty) {
        final responseText = response.toString();
        setState(() {
          _messages.add(ChatMessage(text: responseText, isUser: false));
        });

        // Call the FlutterFlow callback if provided
        if (widget.onResponseReceived != null) {
          await widget.onResponseReceived!(responseText);
        }
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I couldn\'t generate a response. Please try again.',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print('GemmaChatWidget Error: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: ${e.toString()}',
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: widget.paddingHorizontal,
                vertical: widget.paddingVertical,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: widget.paddingVertical / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ],
              ),
            ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              margin: EdgeInsets.all(widget.paddingHorizontal),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).alternate,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImage!.bytes!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedImage!.name ?? 'Selected Image',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearSelectedImage,
                    icon: Icon(
                      Icons.close,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.all(widget.paddingHorizontal),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: FlutterFlowTheme.of(context).alternate,
                  width: 1,
                ),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Image picker button (only show if multimodal is enabled)
                  if (_isMultimodalAvailable) ...[
                    IconButton(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: Icon(
                        Icons.image,
                        color: widget.imageButtonColor ??
                            FlutterFlowTheme.of(context).primary,
                      ),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(widget.paddingVertical),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Text input
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 120, // Limit max height of text field
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius),
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: widget.paddingHorizontal,
                            vertical: widget.paddingVertical,
                          ),
                        ),
                        style: TextStyle(
                          color: widget.textColor ??
                              FlutterFlowTheme.of(context).primaryText,
                        ),
                        maxLines: 5, // Limit to 5 lines max
                        minLines: 1,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.paddingHorizontal,
                        vertical: widget.paddingVertical,
                      ),
                    ),
                    child: Text(
                      widget.sendButtonText,
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: widget.paddingHorizontal,
          vertical: widget.paddingVertical,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image if present
            if (message.imageBytes != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  maxHeight: 200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    message.imageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],

            // Display text if present
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? FlutterFlowTheme.of(context).primaryBackground
                      : FlutterFlowTheme.of(context).primaryText,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imageBytes,
  }) : timestamp = timestamp ?? DateTime.now();
}
