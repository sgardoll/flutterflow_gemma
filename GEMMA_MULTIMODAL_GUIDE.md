# Gemma Multimodal Implementation Guide

This guide explains how to use the enhanced multimodal functionality in the Gemma chat widget and custom actions.

## Overview

The implementation now includes complete image selection and multimodal AI capabilities using Google's Gemma 3 models. Users can:

- Select images from camera or gallery
- Send text + image combinations to multimodal Gemma models
- Receive AI responses that analyze both text and visual content
- Handle various image formats (JPEG, PNG, WebP, GIF, BMP)

## Requirements

### Dependencies Added

- `image_picker: ^1.1.2` - For image selection from camera/gallery

### Supported Models

Multimodal functionality works with Gemma 3 models:

- `gemma-3-4b-it`
- `gemma-3-12b-it`
- `gemma-3-27b-it`
- `gemma-3-nano-e4b-it`
- `gemma-3-nano-e2b-it`
- Any model containing "gemma-3", "nano", "vision", "multimodal", or "edge"

## GemmaChatWidget Enhanced Parameters

### New Parameters

```dart
final int maxImageSize; // Maximum image size in bytes (default: 5MB)
final int imageQuality; // Image quality 1-100 (default: 85)
final Future Function(FFUploadedFile image)? onImageSelected; // Callback when image selected
final Future Function(String error)? onImageError; // Callback for image errors
```

### Usage Example

```dart
GemmaChatWidget(
  width: 400,
  height: 600,
  showImageUpload: true,
  maxImageSize: 5242880, // 5MB
  imageQuality: 85,
  onMessageSent: (message) async {
    // Handle message sent
    print('Message sent: $message');
  },
  onResponseReceived: (response) async {
    // Handle AI response
    print('AI response: $response');
  },
  onImageSelected: (image) async {
    // Handle image selection
    print('Image selected: ${image.name}');
  },
  onImageError: (error) async {
    // Handle image errors
    print('Image error: $error');
  },
)
```

## Enhanced Custom Actions

### sendGemmaMessage

Enhanced with comprehensive multimodal support and validation:

```dart
Future<String?> sendGemmaMessage(
  String message,
  FFUploadedFile? imageFile,
) async
```

**Features:**

- Validates input (message or image required)
- Checks if Gemma is initialized
- Auto-creates session if needed
- Validates image size (max 10MB)
- Checks model multimodal capability
- Provides user-friendly error messages

**Usage:**

```dart
final response = await sendGemmaMessage(
  'What do you see in this image?',
  selectedImageFile,
);
```

### setChatImage

New action for programmatically setting images:

```dart
Future<bool> setChatImage(FFUploadedFile imageFile) async
```

**Features:**

- Validates image format (JPEG, PNG, WebP, GIF, BMP)
- Checks file size limits
- Returns success/failure status

## Image Selection Flow

### 1. User Interaction

- User taps the camera button (📷) in the chat widget
- Dialog appears with "Gallery" and "Camera" options

### 2. Image Processing

- Selected image is processed with quality compression
- Size validation (max 5MB by default, configurable)
- Format validation ensures compatibility

### 3. Preview

- Selected image appears in preview area above input
- Shows image thumbnail, name, and file size
- User can remove image with X button

### 4. Sending

- Image is included with message when sent
- Widget automatically detects multimodal models
- Fallback message "Analyze this image" if no text provided

## Error Handling

### Image Selection Errors

- **File too large**: Configurable size limit with user feedback
- **Invalid format**: Only common image formats supported
- **Permission denied**: Handled gracefully with error callbacks

### Model Compatibility

- **Non-multimodal model**: Clear error message explaining limitation
- **Model not initialized**: Guidance to initialize first
- **Session errors**: Automatic session recreation

### Network/Processing Errors

- **Empty response**: User-friendly retry message
- **Processing timeout**: Graceful degradation
- **Unknown errors**: Generic fallback with retry option

## Best Practices

### Image Optimization

```dart
GemmaChatWidget(
  maxImageSize: 2097152, // 2MB for faster processing
  imageQuality: 70, // Lower quality for speed
  // ... other parameters
)
```

### Error Handling

```dart
GemmaChatWidget(
  onImageError: (error) async {
    // Log errors for debugging
    print('Image error: $error');

    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image error: $error')),
    );
  },
  // ... other parameters
)
```

### Model Selection

Ensure you're using a Gemma 3 model for multimodal capabilities:

```dart
await initializeGemmaModel(
  modelType: 'gemma-3-nano-e4b-it', // Multimodal model
  supportImage: true,
  maxNumImages: 1,
  // ... other parameters
);
```

## Troubleshooting

### Image Upload Not Working

1. Check if model supports multimodal (`_isMultiModalModel` returns true)
2. Verify `showImageUpload` is set to `true`
3. Ensure proper permissions for camera/gallery access

### Large Image Processing

1. Reduce `maxImageSize` parameter
2. Lower `imageQuality` setting
3. Consider resizing images before selection

### Model Compatibility Issues

1. Verify you're using a Gemma 3 model
2. Check model initialization with `supportImage: true`
3. Ensure model is properly downloaded and accessible

## Implementation Notes

### FlutterFlow Compatibility

- All parameters use simple types (int, String, bool)
- Action callbacks use `Future Function()` pattern
- Widget builders use `Widget Function(BuildContext)` pattern
- No complex Flutter types (EdgeInsets, Duration, etc.)

### Performance Considerations

- Image compression reduces file size
- Automatic quality adjustment based on settings
- Memory management for large images
- Async processing prevents UI blocking

### Security

- File format validation prevents malicious uploads
- Size limits prevent resource exhaustion
- Error handling prevents information leakage

## Future Enhancements

### Planned Features

- Multiple image selection
- Image editing capabilities
- Advanced image preprocessing
- Batch image processing
- Custom image filters

### Integration Options

- Cloud storage integration
- Advanced AI vision features
- Real-time image processing
- Custom model support

This implementation provides a robust foundation for multimodal AI interactions while maintaining FlutterFlow compatibility and following best practices for mobile app development.
