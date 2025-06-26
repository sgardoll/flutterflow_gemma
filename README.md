# FlutterFlow Gemma Integration

A complete FlutterFlow integration for Google's Gemma AI models, providing local on-device AI capabilities with authenticated model downloads and real-time chat functionality.

## 🚀 Features

- **Local AI Processing**: Run Gemma models directly on device without internet connectivity
- **Authenticated Downloads**: Secure model downloads from Hugging Face with token authentication
- **Real-time Progress**: Live download progress with file size and percentage tracking
- **Multiple Model Support**: Support for Gemma 3-4B-IT, Gemma 3-2B-IT, and Gemma 1B-IT models
- **Chat Interface**: Ready-to-use chat widget with message history and streaming responses
- **FlutterFlow Compatible**: Fully compatible with FlutterFlow's custom code requirements
- **Cross-platform**: Works on iOS and Android devices

## 📱 Supported Models

| Model | Size | Description |
|-------|------|-------------|
| `gemma-3-4b-it` | ~6.5GB | Gemma 3 4B Instruction Tuned (Best quality) |
| `gemma-3-2b-it` | ~3.1GB | Gemma 3 2B Instruction Tuned (Balanced) |
| `gemma-1b-it` | ~0.5GB | Gemma 1B Instruction Tuned (Fastest) |

## 🛠️ Setup Requirements

### Prerequisites

1. **FlutterFlow Project**: This integration is designed for FlutterFlow projects
2. **Hugging Face Account**: Required for model downloads
3. **Hugging Face Token**: Personal access token with model access permissions
4. **Device Storage**: Sufficient space for model files (0.5GB - 6.5GB depending on model)

### Hugging Face Setup

1. Create a [Hugging Face account](https://huggingface.co/join)
2. Generate a [personal access token](https://huggingface.co/settings/tokens)
3. Request access to Gemma models:
   - [Gemma 3-4B-IT](https://huggingface.co/google/gemma-3n-E4B-it-litert-preview)
   - [Gemma 3-2B-IT](https://huggingface.co/google/gemma-3n-E2B-it-litert-preview)
   - [Gemma 1B-IT](https://huggingface.co/litert-community/Gemma3-1B-IT)

## 📦 Installation

### 1. Add to pubspec.yaml

Add these dependencies to your FlutterFlow project's `pubspec.yaml`:

```yaml
dependencies:
  flutter_gemma: ^0.2.4
  http: ^1.1.0
  path_provider: ^2.1.1
  path: ^1.8.3
```

### 2. Copy Custom Code Files

Copy all files from the `lib/custom_code/` directory to your FlutterFlow project:

```
lib/custom_code/
├── actions/
│   ├── close_gemma_model.dart
│   ├── create_gemma_session.dart
│   ├── download_authenticated_model.dart
│   ├── download_gemma_model.dart
│   ├── initialize_gemma_model.dart
│   ├── initialize_local_gemma_model.dart
│   ├── install_gemma_from_asset.dart
│   ├── send_gemma_message.dart
│   └── index.dart
├── widgets/
│   ├── gemma_authenticated_setup_widget.dart
│   ├── gemma_chat_widget.dart
│   ├── gemma_model_setup_widget.dart
│   └── index.dart
└── GemmaManager.dart
```

### 3. Sync with FlutterFlow

Use the FlutterFlow VS Code extension to sync the custom code with your FlutterFlow project.

## 🎯 Usage

### Basic Implementation

#### 1. Model Setup Page

Create a setup page using the `GemmaAuthenticatedSetupWidget`:

```dart
GemmaAuthenticatedSetupWidget(
  modelName: 'gemma-1b-it', // Start with smallest model
  huggingFaceToken: 'your_hf_token_here',
  preferredBackend: 'gpu',
  maxTokens: 4096,
  onSetupComplete: () async {
    // Navigate to chat page
    context.pushNamed('ChatPage');
  },
  onSetupFailed: (error) async {
    // Handle setup failure
    print('Setup failed: $error');
  },
)
```

#### 2. Chat Interface

Use the `GemmaChatWidget` for AI conversations:

```dart
GemmaChatWidget(
  width: MediaQuery.of(context).size.width,
  height: MediaQuery.of(context).size.height * 0.8,
  onMessageSent: (message) async {
    print('User sent: $message');
  },
  onResponseReceived: (response) async {
    print('AI responded: $response');
  },
)
```

### Advanced Usage

#### Custom Actions

The integration provides several custom actions you can use in FlutterFlow Action Flows:

- **`downloadAuthenticatedModel`**: Download models with progress tracking
- **`initializeLocalGemmaModel`**: Initialize downloaded models
- **`createGemmaSession`**: Create new chat sessions
- **`sendGemmaMessage`**: Send messages and get AI responses
- **`closeGemmaModel`**: Clean up resources

#### Example Action Flow

1. **Download Model**: Use `downloadAuthenticatedModel` with progress callback
2. **Initialize Model**: Call `initializeLocalGemmaModel` with model path
3. **Create Session**: Use `createGemmaSession` to start conversations
4. **Send Messages**: Call `sendGemmaMessage` for AI interactions

## 🎨 Customization

### Widget Styling

Both widgets support extensive customization:

```dart
GemmaAuthenticatedSetupWidget(
  primaryColor: Colors.blue,
  backgroundColor: Colors.white,
  textColor: Colors.black,
  // ... other parameters
)

GemmaChatWidget(
  primaryColor: Colors.green,
  backgroundColor: Colors.grey[100],
  userMessageColor: Colors.blue,
  aiMessageColor: Colors.white,
  // ... other parameters
)
```

### Model Configuration

Configure model behavior:

```dart
// GPU acceleration (recommended)
preferredBackend: 'gpu'

// CPU only (more compatible)
preferredBackend: 'cpu'

// Adjust response length
maxTokens: 2048 // or 4096, 8192

// Enable image support (if model supports it)
supportImage: true
maxNumImages: 1
```

## 📊 Performance Tips

### Model Selection

- **Development/Testing**: Use `gemma-1b-it` (500MB) for faster downloads and testing
- **Production**: Use `gemma-3-2b-it` (3.1GB) for balanced performance and quality
- **High-end devices**: Use `gemma-3-4b-it` (6.5GB) for best quality responses

### Device Requirements

- **RAM**: Minimum 4GB, recommended 6GB+ for larger models
- **Storage**: Reserve 1-8GB for model files
- **CPU**: ARM64 architecture recommended for optimal performance

### Optimization

- Enable GPU acceleration when available
- Close models when not in use to free memory
- Use appropriate `maxTokens` for your use case
- Consider model caching for faster subsequent loads

## 🔧 Troubleshooting

### Common Issues

#### Download Fails
- Verify Hugging Face token has model access permissions
- Check internet connectivity
- Ensure sufficient device storage

#### Model Won't Initialize
- Confirm model file downloaded completely
- Check device RAM availability
- Try CPU backend if GPU fails

#### Poor Performance
- Reduce `maxTokens` for faster responses
- Close other apps to free RAM
- Consider using a smaller model

### Error Messages

| Error | Solution |
|-------|----------|
| `Authentication failed` | Check Hugging Face token validity |
| `Model file not found` | Re-download the model |
| `Insufficient memory` | Close apps or use smaller model |
| `GPU not supported` | Switch to CPU backend |

## 📱 Platform Considerations

### iOS
- Requires iOS 12.0+
- Benefits from Metal GPU acceleration
- May require additional memory optimization

### Android
- Requires Android API 21+
- GPU acceleration varies by device
- Consider ARM64 vs ARM32 compatibility

## 🔒 Security & Privacy

- **Local Processing**: All AI processing happens on-device
- **No Data Transmission**: Conversations never leave the device
- **Token Security**: Store Hugging Face tokens securely
- **Model Integrity**: Downloads include automatic verification

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review FlutterFlow custom code documentation
3. Open an issue on GitHub
4. Consult the flutter_gemma package documentation
