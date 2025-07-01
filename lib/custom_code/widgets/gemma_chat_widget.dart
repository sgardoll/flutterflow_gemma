// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import '../GemmaManager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'dart:math' as Math;

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

  @override
  State<GemmaChatWidget> createState() => _GemmaChatWidgetState();
}

class _GemmaChatWidgetState extends State<GemmaChatWidget>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  final GemmaManager _gemmaManager = GemmaManager();
  FFUploadedFile? _selectedImage;
  bool _isPickingImage = false; // Track image picking state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGemma();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isPickingImage) {
      // Reset picking state when app is resumed
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future _initializeGemma() async {
    print('GemmaChatWidget: Checking model and session status...');
    print('Model initialized: ${_gemmaManager.isInitialized}');
    print('Has session: ${_gemmaManager.hasSession}');

    // Check if we have both model and session ready
    if (_gemmaManager.isInitialized && _gemmaManager.hasSession) {
      print(
          'GemmaChatWidget: Model and session ready, no initialization needed');
      return;
    }

    // If model isn't initialized, we can't proceed
    // The user needs to complete setup first
    if (!_gemmaManager.isInitialized) {
      print(
          'GemmaChatWidget: No model initialized - user needs to complete setup');
      // Don't try to initialize here with defaults, let the user know they need setup
      return;
    }

    // If model is ready but no session, try to create one
    if (!_gemmaManager.hasSession) {
      print('GemmaChatWidget: Model ready but no session, creating session...');
      final sessionSuccess = await _gemmaManager.createSession();
      if (!sessionSuccess) {
        print('GemmaChatWidget: Failed to create session');
      } else {
        print('GemmaChatWidget: Session created successfully');
      }
    }
  }

  bool get _isMultiModalModel {
    final modelType = _gemmaManager.currentModelType ?? '';
    final isMultimodal = GemmaManager.isMultimodalModel(modelType);

    // Debug logging
    print(
        'GemmaChatWidget._isMultiModalModel: modelType="$modelType", result=$isMultimodal');

    return isMultimodal;
  }

  Future _selectImage() async {
    if (_isPickingImage) {
      print('GemmaChatWidget: Image picking already in progress');
      return;
    }

    try {
      setState(() {
        _isPickingImage = true;
      });

      print('=== GemmaChatWidget._selectImage START ===');

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

      if (source == null) {
        print('GemmaChatWidget: User cancelled image source selection');
        return;
      }

      print('GemmaChatWidget: Selected source: ${source.name}');

      // Pick image from selected source with enhanced error handling
      XFile? pickedFile;
      try {
        // For camera, use more conservative settings to prevent crashes
        if (source == ImageSource.camera) {
          pickedFile = await _imagePicker.pickImage(
            source: source,
            maxWidth: 1280, // Even more conservative for camera
            maxHeight: 1280,
            imageQuality:
                75, // Lower quality for camera to prevent memory issues
            requestFullMetadata: false, // Disable metadata to save memory
          );
        } else {
          // For gallery, can use higher settings since image already exists
          pickedFile = await _imagePicker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: widget.imageQuality,
          );
        }
        print(
            'GemmaChatWidget: Image picker completed, file: ${pickedFile?.path}');
      } catch (imagePickerError) {
        print('GemmaChatWidget: Image picker error: $imagePickerError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera error: $imagePickerError'),
              backgroundColor: FlutterFlowTheme.of(context).error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (pickedFile == null) {
        print('GemmaChatWidget: No image selected');
        return;
      }

      // Convert to bytes with size validation
      Uint8List? imageBytes;
      try {
        final fileSize = await pickedFile.length();
        print(
            'GemmaChatWidget: Image file size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

        // Check file size before reading (max 50MB to prevent memory issues)
        if (fileSize > 50 * 1024 * 1024) {
          throw Exception(
              'Image file too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB. Maximum is 50MB.');
        }

        imageBytes = await pickedFile.readAsBytes();
        print(
            'GemmaChatWidget: Image bytes loaded successfully: ${imageBytes.length} bytes');
      } catch (readError) {
        print('GemmaChatWidget: Error reading image bytes: $readError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reading image: $readError'),
              backgroundColor: FlutterFlowTheme.of(context).error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Create initial FFUploadedFile
      final originalFile = FFUploadedFile(
        name: pickedFile.name,
        bytes: imageBytes,
        height: null, // Could be determined if needed
        width: null, // Could be determined if needed
      );

      FFUploadedFile? finalFile = originalFile;

      // Check if image needs processing (resizing OR format conversion)
      bool needsProcessing = imageBytes.length > widget.maxImageSize;

      // Check if image is PNG - vision models need JPEG
      bool isPNG = imageBytes.length >= 8 &&
          imageBytes[0] == 0x89 &&
          imageBytes[1] == 0x50 &&
          imageBytes[2] == 0x4E &&
          imageBytes[3] == 0x47;

      if (isPNG) {
        print(
            'Image is PNG format, converting to JPEG for vision model compatibility');
        needsProcessing = true;
      }

      if (needsProcessing) {
        // Show processing message
        String processingMsg = 'Processing image for vision model...';
        if (imageBytes.length > widget.maxImageSize) {
          processingMsg = 'Resizing and converting image...';
        } else if (isPNG) {
          processingMsg = 'Converting image to JPEG format...';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(processingMsg),
              backgroundColor: FlutterFlowTheme.of(context).primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Process image (resize and/or convert to JPEG)
        finalFile = await resizeImageToConstraints(
          originalFile,
          widget.maxImageSize,
          widget.imageQuality,
        );

        if (finalFile == null) {
          final errorMsg =
              'Could not process image for vision model compatibility';

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

      print('=== GemmaChatWidget._selectImage SUCCESS ===');
    } catch (e) {
      final errorMsg = 'Error selecting image: $e';
      print('=== GemmaChatWidget._selectImage ERROR: $errorMsg ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: FlutterFlowTheme.of(context).error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Always reset the picking state
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
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
    print('=== GemmaChatWidget._sendMessage Debug ===');
    final message = _messageController.text.trim();
    print('Message text: "$message"');
    print('Selected image: ${_selectedImage != null}');
    print('Is loading: $_isLoading');

    if ((message.isEmpty && _selectedImage == null) || _isLoading) {
      print('Aborting send: empty message and no image, or already loading');
      return;
    }

    // Defensive check: ensure model and session are ready
    if (!_gemmaManager.isInitialized) {
      print('Model not initialized - showing error message');
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Please complete the model setup first before sending messages.',
          isUser: false,
        ));
      });
      return;
    }

    if (!_gemmaManager.hasSession) {
      print('No session available - attempting to create one');
      final sessionSuccess = await _gemmaManager.createSession();
      if (!sessionSuccess) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                'Unable to start chat session. Please restart the app and complete setup.',
            isUser: false,
          ));
        });
        return;
      }
    }

    final messageText = message.isNotEmpty ? message : 'Analyze this image';
    final imageBytes = _selectedImage?.bytes;

    print('Final message text: "$messageText"');
    print('Image bytes available: ${imageBytes != null}');
    print('Image bytes length: ${imageBytes?.length ?? 0}');

    if (_selectedImage != null) {
      print('=== CHAT WIDGET: Image Debug Info ===');
      print('Selected image name: ${_selectedImage!.name}');
      print('Selected image bytes null: ${_selectedImage!.bytes == null}');
      print(
          'Selected image bytes length: ${_selectedImage!.bytes?.length ?? 0}');

      if (_selectedImage!.bytes != null) {
        // Enhanced image debugging
        final bytes = _selectedImage!.bytes!;
        print('Image bytes first 20: ${bytes.take(20).toList()}');
        print('Image bytes last 10: ${bytes.skip(bytes.length - 10).toList()}');

        // Check image format
        String format = 'unknown';
        if (bytes.length >= 8) {
          if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
            format = 'JPEG';
          } else if (bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47) {
            format = 'PNG';
          }
        }
        print('Detected format: $format');

        // Platform-specific debugging
        if (Platform.isIOS) {
          print('iOS: Processing image for vision model');
        } else if (Platform.isAndroid) {
          print('Android: Processing image for vision model');
        }

        // Check for obvious corruption
        int nullCount = 0;
        for (int i = 0; i < Math.min(100, bytes.length); i++) {
          if (bytes[i] == 0) nullCount++;
        }
        print('Null byte count in first 100 bytes: $nullCount');
        if (nullCount > 50) {
          print('WARNING: High null byte count suggests image corruption');
        }
      }
      print('=== End Chat Widget Image Debug ===');
    }

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

    try {
      // Send message through GemmaManager directly
      print('Sending message through GemmaManager...');
      String? response = await _gemmaManager.sendMessage(
        messageText,
        imageBytes: imageBytes,
      );
      print(
          'GemmaManager response: ${response != null ? "received (${response.length} chars)" : "null"}');

      // Check if we got a hallucinated or nonsensical response for vision
      if (imageBytes != null &&
          response != null &&
          _isVisionResponseProblematic(response)) {
        print('Detected problematic vision response, attempting retry...');

        // Retry with a more specific prompt
        final retryPrompt =
            '''This is a real photograph. Look carefully and describe exactly what you see.

IMPORTANT: This is NOT a pattern, design, textile, fabric, or artwork. This is a real photograph of real objects in the real world.

What do you see?
- Real objects, people, animals, plants, or things
- The actual physical setting or location
- Real lighting conditions and colors
- Any real text, signs, or writing

Do NOT describe this as a pattern, design, textile, fabric, artwork, or abstract composition.

Original question: $messageText''';

        response = await _gemmaManager.sendMessage(retryPrompt,
            imageBytes: imageBytes);
        print('Retry response: ${response != null ? "received" : "null"}');

        // If still problematic, try without the image
        if (response != null && _isVisionResponseProblematic(response)) {
          print(
              'Second attempt still problematic, trying text-only fallback...');
          response = await _gemmaManager.sendMessage(
              'I apologize, but I\'m having trouble analyzing the image you provided. Could you describe what you see in the image, and I can help you with questions about it?');
        }
      }

      if (response != null && response.isNotEmpty) {
        // Always show the response first, but check if it's problematic
        setState(() {
          _messages.add(ChatMessage(text: response!, isUser: false));
        });

        // If the response is problematic, add a helpful note
        if (imageBytes != null && _isVisionResponseProblematic(response)) {
          setState(() {
            _messages.add(ChatMessage(
                text:
                    '''ℹ️ NOTE: The response above may not be accurate for real-world photos. On-device vision models work better with text, diagrams, or simple graphics.''',
                isUser: false));
          });
        }
      } else {
        String fallbackMsg;

        if (imageBytes != null) {
          // Vision-specific error handling
          if (_gemmaManager.supportsVision) {
            fallbackMsg = '''❌ Vision analysis failed - no response generated.

This could be due to:
• Model initialization issues
• Image processing errors  
• Memory constraints

Try:
• Restarting the app
• Using a smaller image
• Checking model setup

For complex natural photos, consider describing what you see and asking text-based questions instead.''';
          } else {
            fallbackMsg =
                'The current model doesn\'t support image analysis. Please use a multimodal model like Gemma 3 for vision capabilities.';
          }
        } else {
          fallbackMsg =
              'Sorry, I couldn\'t generate a response. Please try rephrasing your question.';
        }

        setState(() {
          _messages.add(ChatMessage(
            text: fallbackMsg,
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print('Error in _sendMessage: $e');

      String errorMsg;
      if (imageBytes != null) {
        errorMsg = '''Image processing error: ${e.toString()}

This might indicate:
• Image format compatibility issues
• Memory constraints with large images  
• Model initialization problems
• Platform-specific vision processing errors

Please try with a smaller or different format image, or ask a text-only question.''';
      } else {
        errorMsg = 'Error generating response: ${e.toString()}';
      }

      setState(() {
        _messages.add(ChatMessage(
          text: errorMsg,
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
      print('=== End GemmaChatWidget._sendMessage Debug ===');
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

  // Helper method to detect problematic vision responses (like the pattern hallucination issue)
  bool _isVisionResponseProblematic(String response) {
    final lowercaseResponse = response.toLowerCase();

    // Check for the specific pattern hallucination issue (broader detection)
    if (lowercaseResponse.contains('repeating pattern') &&
        (lowercaseResponse.contains('letter') ||
            lowercaseResponse.contains('symbol') ||
            lowercaseResponse.contains('character'))) {
      // It's describing a repeating pattern of a letter/symbol, which is a common hallucination
      return true;
    }

    // Check for textile/fabric misidentification (new hallucination type)
    if (lowercaseResponse.contains('textile') ||
        lowercaseResponse.contains('fabric') ||
        lowercaseResponse.contains('woven') ||
        lowercaseResponse.contains('printed pattern') ||
        (lowercaseResponse.contains('pattern') &&
            lowercaseResponse.contains('abstract'))) {
      print('Detected textile/pattern hallucination');
      return true;
    }

    // Check for other common hallucination patterns
    final problematicPatterns = [
      'this image appears to be a **repeating pattern',
      'very simple visual, likely created for a specific purpose',
      'typographic exercise',
      'artistic exploration',
      'placeholder image',
      'code/programming',
      'repetition of the letter',
      'repetition of the character',
      'core element is the repetition',
      'a simple visual',
      'intricate detail',
      'appears to be a design',
      'somewhat abstract pattern',
      'vibrant, colorful, and somewhat abstract',
    ];

    for (final pattern in problematicPatterns) {
      if (lowercaseResponse.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    // Check for responses that are mostly about patterns when user asked a simple question
    if (lowercaseResponse.contains('pattern') &&
        lowercaseResponse.contains('repetition') &&
        response.length > 150) {
      return true;
    }

    // Check for evasive or unhelpful answers when an image is present
    if (lowercaseResponse.contains('without more context') &&
        lowercaseResponse.contains('hard to say definitively')) {
      return true;
    }

    // Check for responses that mention Greek letters (common hallucination)
    if (lowercaseResponse.contains('greek letter') ||
        lowercaseResponse.contains('greek character')) {
      return true;
    }

    // Check for design/artwork misidentification when dealing with real photos
    if ((lowercaseResponse.contains('design') ||
            lowercaseResponse.contains('artwork')) &&
        (lowercaseResponse.contains('possibly') ||
            lowercaseResponse.contains('appears to be'))) {
      print('Detected design/artwork hallucination');
      return true;
    }

    return false;
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
