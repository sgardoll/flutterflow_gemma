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

##### **`downloadAuthenticatedModel`**
Downloads models from Hugging Face with authentication and progress tracking.

**Parameters:**
- `modelIdentifier` (String): Model name or custom URL
- `huggingFaceToken` (String): Your HF authentication token
- `onProgress` (Function): Progress callback with downloaded bytes, total bytes, and percentage

**Returns:** `Future<String?>` - Path to downloaded model file

**Example Usage:**
```dart
String? modelPath = await downloadAuthenticatedModel(
  'gemma-3-2b-it',
  'your_hf_token_here',
  (downloaded, total, percentage) {
    print('Download progress: $percentage%');
    setState(() {
      downloadProgress = percentage;
    });
  },
);
```

##### **`initializeLocalGemmaModel`**
Initializes a downloaded model for inference.

**Parameters:**
- `localModelPath` (String): Path to the model file
- `modelType` (String): Model identifier for configuration
- `preferredBackend` (String): 'gpu' or 'cpu'
- `maxTokens` (int): Maximum response length (512-8192)
- `supportImage` (bool): Enable image processing (if supported)
- `numOfThreads` (int): CPU threads (1-8)
- `temperature` (double): Creativity level (0.0-2.0)
- `topK` (double): Response diversity (1.0-40.0)
- `topP` (double): Nucleus sampling (0.0-1.0)
- `randomSeed` (int): Reproducibility seed

**Returns:** `Future<bool>` - Success status

**Example Usage:**
```dart
bool success = await initializeLocalGemmaModel(
  modelPath,
  'gemma-3-2b-it',
  'gpu',
  4096,
  false,
  4,
  0.8,
  1.0,
  1.0,
  42,
);
```

##### **`createGemmaSession`**
Creates a new chat session with specified parameters.

**Parameters:**
- `temperature` (double): Response creativity (0.0-2.0)
- `randomSeed` (int): Seed for reproducible responses
- `topK` (int): Top-K sampling parameter (1-40)

**Returns:** `Future<bool>` - Success status

**Example Usage:**
```dart
bool sessionCreated = await createGemmaSession(
  0.7,  // Slightly creative responses
  123,  // Reproducible seed
  5,    // Moderate diversity
);
```

##### **`sendGemmaMessage`**
Sends a message to the AI and gets a response.

**Parameters:**
- `message` (String): User's message text
- `imageBytes` (Uint8List?, optional): Image data for multimodal models

**Returns:** `Future<String?>` - AI response text

**Example Usage:**
```dart
String? response = await sendGemmaMessage(
  'Explain quantum computing in simple terms',
  null, // No image
);

// With image (for supported models)
String? response = await sendGemmaMessage(
  'What do you see in this image?',
  imageBytes,
);
```

##### **`closeGemmaModel`**
Properly closes the model and frees resources.

**Parameters:** None

**Returns:** `Future<void>`

**Example Usage:**
```dart
await closeGemmaModel(); // Call when done or switching models
```

##### **Additional Actions**

- **`downloadGemmaModel`**: Basic model download without authentication
- **`initializeGemmaModel`**: Initialize model from asset bundle
- **`installGemmaFromAsset`**: Install pre-bundled model files
- **`manageDownloadedModels`**: List, delete, or manage downloaded models
- **`getHuggingfaceModelInfo`**: Get model metadata before download
- **`debugModelPaths`**: Debug model file locations and status

#### Example Action Flows

##### **Complete Setup Flow**
```dart
// 1. Download Model with Progress
onPressed: () async {
  setState(() { isDownloading = true; });
  
  String? modelPath = await downloadAuthenticatedModel(
    selectedModel,
    hfToken,
    (downloaded, total, percentage) {
      setState(() {
        downloadProgress = percentage;
      });
    },
  );
  
  if (modelPath != null) {
    // 2. Initialize Model
    bool initialized = await initializeLocalGemmaModel(
      modelPath,
      selectedModel,
      'gpu',
      4096,
      false,
      4,
      0.8,
      1.0,
      1.0,
      1,
    );
    
    if (initialized) {
      // 3. Create Session
      bool sessionReady = await createGemmaSession(0.8, 1, 1);
      
      if (sessionReady) {
        // 4. Navigate to Chat
        context.pushNamed('ChatPage');
      }
    }
  }
  
  setState(() { isDownloading = false; });
}
```

##### **Chat Message Flow**
```dart
// Send message and handle response
onSendMessage: (String userMessage) async {
  // Add user message to chat
  setState(() {
    messages.add(ChatMessage(text: userMessage, isUser: true));
    isLoading = true;
  });
  
  // Get AI response
  String? aiResponse = await sendGemmaMessage(userMessage, null);
  
  // Add AI response to chat
  setState(() {
    if (aiResponse != null) {
      messages.add(ChatMessage(text: aiResponse, isUser: false));
    } else {
      messages.add(ChatMessage(text: 'Sorry, I couldn\'t respond.', isUser: false));
    }
    isLoading = false;
  });
}
```

##### **Model Management Flow**
```dart
// List and manage downloaded models
onManageModels: () async {
  // Get list of downloaded models
  List<dynamic> models = await manageDownloadedModels(null, null);
  
  // Display models in UI
  for (var model in models) {
    print('Model: ${model['modelType']}');
    print('Size: ${model['sizeFormatted']}');
    print('Path: ${model['filePath']}');
  }
  
  // Delete specific model
  if (shouldDelete) {
    await manageDownloadedModels('delete', modelPath);
  }
}
```

##### **Error Handling Flow**
```dart
// Robust error handling
try {
  String? modelPath = await downloadAuthenticatedModel(
    modelId, 
    token, 
    progressCallback
  );
  
  if (modelPath == null) {
    throw Exception('Download failed');
  }
  
  bool initialized = await initializeLocalGemmaModel(/* params */);
  if (!initialized) {
    throw Exception('Model initialization failed');
  }
  
  bool sessionReady = await createGemmaSession(0.8, 1, 1);
  if (!sessionReady) {
    throw Exception('Session creation failed');
  }
  
} catch (e) {
  // Handle different error types
  if (e.toString().contains('Authentication')) {
    showError('Invalid Hugging Face token');
  } else if (e.toString().contains('Storage')) {
    showError('Insufficient storage space');
  } else if (e.toString().contains('Memory')) {
    showError('Not enough RAM for this model');
  } else {
    showError('Setup failed: ${e.toString()}');
  }
}

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
