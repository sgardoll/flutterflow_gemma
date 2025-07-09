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
import 'package:flutter/services.dart'; // For Clipboard
import 'package:image/image.dart' as img; // For image processing
import 'dart:io';
import 'dart:async'; // For TimeoutException
import 'package:flutter/foundation.dart'; // For compute

// Top-level function for async image processing
Future<Uint8List> _processImageAsync(Uint8List imageBytes) async {
  try {
    // Decode the image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Calculate target dimensions (max 512x512 for vision models)
    const maxDimension = 512;
    int targetWidth = image.width;
    int targetHeight = image.height;

    if (targetWidth > maxDimension || targetHeight > maxDimension) {
      final aspectRatio = targetWidth / targetHeight;
      if (targetWidth > targetHeight) {
        targetWidth = maxDimension;
        targetHeight = (maxDimension / aspectRatio).round();
      } else {
        targetHeight = maxDimension;
        targetWidth = (maxDimension * aspectRatio).round();
      }
    }

    // Resize the image
    final resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // Encode as JPEG with quality optimization
    final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

    return Uint8List.fromList(compressedBytes);
  } catch (e) {
    // Fallback: return original image if compression fails
    return imageBytes;
  }
}

class GemmaChatWidget extends StatefulWidget {
  const GemmaChatWidget({
    super.key,
    this.width,
    this.height,
    this.placeholder,
    this.onMessageSent,
  });

  final double? width;
  final double? height;
  final String? placeholder; // Input placeholder text
  final Future Function(String message)? onMessageSent; // Message callback

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
  String _processingStatus = '';
  bool _canCancelProcessing = false;

  final GemmaManager _gemmaManager = GemmaManager();

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  // Check if model is ready
  void _checkModelStatus() {
    if (!_gemmaManager.isInitialized) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Please complete model setup first using the setup widget.',
          isUser: false,
        ));
      });
    } else if (!_gemmaManager.hasSession) {
      // Try to create session if model is ready
      _gemmaManager.createSession().then((success) {
        if (!success) {
          setState(() {
            _messages.add(ChatMessage(
              text: 'Failed to start chat session. Please restart the app.',
              isUser: false,
            ));
          });
        }
      });
    }
  }

  // Check if current model supports images
  bool get _supportsImages => _gemmaManager.supportsVision;

  // Compress and resize image to prevent memory issues using async processing
  Future<Uint8List> _compressAndResizeImage(Uint8List imageBytes) async {
    try {
      // Use compute to run image processing in a separate isolate
      final compressedBytes = await compute(_processImageAsync, imageBytes);

      print(
          'Image compressed: ${imageBytes.length} bytes → ${compressedBytes.length} bytes');

      return compressedBytes;
    } catch (e) {
      print('Error compressing image: $e');
      // Fallback: return original image if compression fails
      return imageBytes;
    }
  }

  // Validate image format and size
  Future<String?> _validateImageFormat(File file) async {
    try {
      // Check file size (max 50MB)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        return 'Image too large. Maximum size is 50MB.';
      }

      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!validExtensions.contains(extension)) {
        return 'Unsupported image format. Please use JPG, PNG, GIF, or WebP.';
      }

      // Try to decode the image to verify it's valid
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return 'Invalid or corrupted image file.';
      }

      // Check image dimensions (max 5000x5000)
      if (image.width > 5000 || image.height > 5000) {
        return 'Image too large. Maximum dimensions are 5000x5000 pixels.';
      }

      return null; // Valid image
    } catch (e) {
      return 'Error validating image: ${e.toString()}';
    }
  }

  // Select image from gallery or camera
  Future<void> _selectImage() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Validate image format and size
      final validationError = await _validateImageFormat(File(pickedFile.path));
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final originalImageBytes = await pickedFile.readAsBytes();

      // Compress and resize image to prevent memory issues
      final compressedImageBytes =
          await _compressAndResizeImage(originalImageBytes);

      setState(() {
        _selectedImage = FFUploadedFile(
          name: pickedFile.name,
          bytes: compressedImageBytes,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${pickedFile.name}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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

  // Show dialog to choose image source
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Clear selected image
  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // Send message with comprehensive error handling
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final imageBytes = _selectedImage?.bytes;

    if ((messageText.isEmpty && imageBytes == null) || _isLoading) {
      return;
    }

    // Check if model is ready
    if (!_gemmaManager.isInitialized || !_gemmaManager.hasSession) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Model not ready. Please complete setup first.',
          isUser: false,
        ));
      });
      return;
    }

    final finalMessage =
        messageText.isNotEmpty ? messageText : 'Analyze this image';

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: finalMessage,
        isUser: true,
        imageBytes: imageBytes,
      ));
      _isLoading = true;
      _processingStatus =
          imageBytes != null ? 'Processing image...' : 'Generating response...';
      _canCancelProcessing = true;
    });

    _messageController.clear();
    _clearImage();
    _scrollToBottom();

    String? response;
    String? errorMessage;

    try {
      // Update status for vision processing
      if (imageBytes != null) {
        setState(() {
          _processingStatus = 'Analyzing image with AI...';
        });
      }

      // Send message to model with timeout
      response = await _gemmaManager
          .sendMessage(
        finalMessage,
        imageBytes: imageBytes,
      )
          .timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Processing timed out', Duration(seconds: 30));
        },
      );

      // Validate response
      if (response == null || response.isEmpty) {
        errorMessage = 'No response received from model';
      }
    } on TimeoutException catch (e) {
      errorMessage =
          'Request timed out. Please try again with a smaller image or simpler request.';
      print('Timeout error: $e');
    } catch (e) {
      // Handle different types of errors
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('memory') ||
          errorString.contains('allocation')) {
        errorMessage =
            'Memory error. Please try with a smaller image or restart the app.';
      } else if (errorString.contains('timeout') ||
          errorString.contains('deadline')) {
        errorMessage = 'Processing timed out. Please try again.';
      } else if (errorString.contains('gpu') ||
          errorString.contains('delegate')) {
        errorMessage = 'GPU processing error. Attempting CPU fallback...';
      } else if (errorString.contains('vision') ||
          errorString.contains('image')) {
        errorMessage =
            'Image processing error. Please try with a different image.';
      } else if (errorString.contains('session') ||
          errorString.contains('model')) {
        errorMessage = 'Model session error. Please restart the app.';
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }

      print('Error sending message: $e');
    }

    // Add model response or error message
    setState(() {
      _messages.add(ChatMessage(
        text: response ??
            errorMessage ??
            'Sorry, I could not generate a response.',
        isUser: false,
      ));
    });

    // Call callback if provided and response is successful
    if (widget.onMessageSent != null && response != null) {
      try {
        await widget.onMessageSent!(response);
      } catch (e) {
        print('Error in callback: $e');
      }
    }

    setState(() {
      _isLoading = false;
      _processingStatus = '';
      _canCancelProcessing = false;
    });
    _scrollToBottom();
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
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
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator with status
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(_processingStatus.isNotEmpty
                      ? _processingStatus
                      : 'Thinking...'),
                ],
              ),
            ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedImage!.name ?? 'Selected Image',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearImage,
                    icon: Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                // Image button (only show if model supports vision)
                if (_supportsImages) ...[
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
                  SizedBox(width: 8),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                SizedBox(width: 8),

                // Send button
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(12),
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isAgent = !message.isUser;
    Widget bubble = Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
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
              if (message.text.isNotEmpty) SizedBox(height: 8),
            ],

            // Text message
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : FlutterFlowTheme.of(context).primaryText,
                ),
              ),
          ],
        ),
      ),
    );

    if (isAgent && message.text.isNotEmpty) {
      // Wrap with GestureDetector for long-press copy
      bubble = GestureDetector(
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: message.text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
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

// Simple message class
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
