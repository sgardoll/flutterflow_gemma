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
    this.uploadButtonText = '📷',
    this.showImageUpload = true,
    this.maxImageSize = 5242880, // 5MB default
    this.imageQuality = 85,
    required this.onMessageSent,
    this.onResponseReceived,
    this.onImageSelected,
    this.onImageError,
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
  final String uploadButtonText;
  final bool showImageUpload;
  final int maxImageSize; // Maximum image size in bytes
  final int imageQuality; // Image quality (1-100)
  final Future Function(String message, FFUploadedFile? imageFile)
      onMessageSent;
  final Future Function(String response)? onResponseReceived;
  final Future Function(FFUploadedFile image)? onImageSelected;
  final Future Function(String error)? onImageError;

  @override
  State<GemmaChatWidget> createState() => _GemmaChatWidgetState();
}

class _GemmaChatWidgetState extends State<GemmaChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  final GemmaManager _gemmaManager = GemmaManager();
  FFUploadedFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeGemma();
  }

  Future _initializeGemma() async {
    // Initialize with default settings - user should call initializeGemmaModel action first
    if (!_gemmaManager.isInitialized) {
      await _gemmaManager.initializeModel(
        modelType: 'gemma-2b-it',
        backend: 'gpu',
        maxTokens: 1024,
        supportImage: false,
        maxNumImages: 1,
      );
    }

    if (!_gemmaManager.hasSession) {
      await _gemmaManager.createSession();
    }
  }

  bool get _isMultiModalModel {
    final modelType = _gemmaManager.currentModelType?.toLowerCase() ?? '';
    final multimodalModels = [
      'gemma-3-4b-it',
      'gemma-3-12b-it',
      'gemma-3-27b-it',
      'gemma-3-nano-e4b-it',
      'gemma-3-nano-e2b-it',
      'gemma 3 4b edge',
      'gemma 3 nano',
      'gemma-3',
      'gemma3',
    ];
    return multimodalModels.any((model) =>
        modelType.contains(model.toLowerCase()) ||
        modelType.contains('nano') ||
        modelType.contains('vision') ||
        modelType.contains('multimodal') ||
        modelType.contains('edge') ||
        modelType.contains('3'));
  }

  Future _selectImage() async {
    try {
      // Show image source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select Image Source',
              style: FlutterFlowTheme.of(context).headlineSmall,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      // Pick image from selected source
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: widget.imageQuality,
      );

      if (pickedFile == null) return;

      // Convert to bytes
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      // Create initial FFUploadedFile
      final originalFile = FFUploadedFile(
        name: pickedFile.name,
        bytes: imageBytes,
        height: null, // Could be determined if needed
        width: null, // Could be determined if needed
      );

      FFUploadedFile? finalFile = originalFile;

      // Check if image needs resizing
      if (imageBytes.length > widget.maxImageSize) {
        // Show processing message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resizing image to fit size limit...'),
              backgroundColor: FlutterFlowTheme.of(context).primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Resize image to fit constraints
        finalFile = await resizeImageToConstraints(
          originalFile,
          widget.maxImageSize,
          widget.imageQuality,
        );

        if (finalFile == null) {
          final errorMsg =
              'Could not resize image to fit size limit of ${(widget.maxImageSize / 1024).toStringAsFixed(1)}KB';

          if (widget.onImageError != null) {
            await widget.onImageError!(errorMsg);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: FlutterFlowTheme.of(context).error,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _selectedImage = finalFile;
      });

      // Call callback if provided
      if (widget.onImageSelected != null) {
        await widget.onImageSelected!(finalFile!);
      }

      if (mounted) {
        final sizeText = finalFile!.bytes!.length > 1024
            ? '${(finalFile!.bytes!.length / 1024).toStringAsFixed(1)}KB'
            : '${finalFile!.bytes!.length} bytes';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${finalFile!.name} ($sizeText)'),
            backgroundColor: FlutterFlowTheme.of(context).primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMsg = 'Error selecting image: $e';
      print(errorMsg);

      if (widget.onImageError != null) {
        await widget.onImageError!(errorMsg);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  void setSelectedImage(FFUploadedFile? image) {
    setState(() {
      _selectedImage = image;
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future _sendMessage() async {
    final message = _messageController.text.trim();
    if ((message.isEmpty && _selectedImage == null) || _isLoading) return;

    final messageText = message.isNotEmpty ? message : 'Analyze this image';
    final imageBytes = _selectedImage?.bytes;

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        imageBytes: imageBytes,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _clearImage();
    _scrollToBottom();

    // Call the FlutterFlow action
    await widget.onMessageSent(messageText, _selectedImage);

    try {
      // Get response from Gemma
      final response = await _gemmaManager.sendMessage(
        messageText,
        imageBytes: imageBytes,
      );

      if (response != null && response.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false));
        });

        // Call the FlutterFlow callback if provided
        if (widget.onResponseReceived != null) {
          await widget.onResponseReceived!(response);
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
      final errorMsg = 'Error generating response: ${e.toString()}';
      setState(() {
        _messages.add(ChatMessage(
          text: errorMsg,
          isUser: false,
        ));
      });

      if (widget.onImageError != null) {
        await widget.onImageError!(errorMsg);
      }
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
    // Debug: Print model info for troubleshooting
    print(
        'GemmaChatWidget: Current model type: ${_gemmaManager.currentModelType}');
    print('GemmaChatWidget: Is multimodal: $_isMultiModalModel');
    print('GemmaChatWidget: Show image upload: ${widget.showImageUpload}');

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

          // Image preview
          if (_selectedImage != null)
            Container(
              margin:
                  EdgeInsets.symmetric(horizontal: widget.paddingHorizontal),
              padding: const EdgeInsets.all(8),
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
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).alternate,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.broken_image,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedImage!.name ?? 'Selected Image',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _selectedImage!.bytes!.length > 1024
                              ? '${(_selectedImage!.bytes!.length / 1024).toStringAsFixed(1)} KB'
                              : '${_selectedImage!.bytes!.length} bytes',
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearImage,
                    icon: Icon(
                      Icons.close,
                      color: FlutterFlowTheme.of(context).error,
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
                  // Image upload button (show when enabled and model supports it)
                  if (widget.showImageUpload && _isMultiModalModel) ...[
                    IconButton(
                      onPressed: _isLoading ? null : _selectImage,
                      icon: Text(
                        widget.uploadButtonText,
                        style: TextStyle(
                          fontSize: 20,
                          color: _isLoading
                              ? FlutterFlowTheme.of(context).secondaryText
                              : FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _selectedImage != null
                            ? FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.1)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                        ),
                      ),
                      tooltip: 'Select Image',
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
            // Image if present
            if (message.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  message.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Image Error',
                            style: FlutterFlowTheme.of(context).bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],

            // Text message
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
