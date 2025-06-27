# Gemma Flutter - On-Device AI Chat Application

A sophisticated FlutterFlow application that integrates Google's Gemma 3 AI models for offline, on-device AI capabilities. This project provides a complete solution for downloading, managing, and interacting with Gemma models directly on mobile devices.

## 🌟 Features

### Core Capabilities

- **On-Device AI Processing**: Run Gemma models locally without internet connectivity
- **Authenticated Model Downloads**: Secure model downloads from HuggingFace with token authentication
- **Multiple Model Support**: Choose from various Gemma models including:
  - Gemma 3 4B Instruct (Multimodal with vision support)
  - Gemma 3 Nano Edge models (2B/4B with vision support)
  - Gemma 3 2B/1B Instruct (Text-only models)
  - Custom model URLs from HuggingFace
- **Real-time Chat Interface**: Interactive chat widget for conversing with AI models
- **Model Management**: Download, store, and manage multiple models locally
- **Cross-platform**: Supports iOS and Android devices

### Technical Features

- **FlutterFlow Integration**: Built with FlutterFlow's visual development platform
- **Custom Widgets & Actions**: Extensive custom code for model handling
- **Secure Token Storage**: HuggingFace tokens stored securely using Flutter Secure Storage
- **Progress Tracking**: Real-time download progress with file size information
- **Error Handling**: Comprehensive error handling and user feedback
- **GPU/CPU Backend Support**: Flexible backend selection for optimal performance

## 📋 Prerequisites

- Flutter SDK (stable release)
- FlutterFlow account (for visual editing)
- HuggingFace account and API token (for model downloads)
- Xcode (for iOS development)
- Android Studio (for Android development)
- Minimum iOS 13.0 / Android API level 21

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone [repository-url]
cd gemma-6hs3o0
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Platform-specific Setup

#### iOS Setup

```bash
cd ios
pod install
cd ..
```

#### Android Setup

Ensure your `android/app/build.gradle` has:

- minSdkVersion 21 or higher
- Proper memory allocation for larger models

### 4. Get HuggingFace Token

1. Create an account at [HuggingFace](https://huggingface.co)
2. Go to Settings → Access Tokens
3. Create a new token with read permissions
4. Copy the token for use in the app

### 5. Run the Application

```bash
flutter run
```

## 📱 Usage

### Initial Setup

1. Launch the app - you'll see the Gemma setup screen
2. Enter your HuggingFace token
3. Select a model from the dropdown:
   - Choose a multimodal model for vision capabilities
   - Select text-only models for faster performance
   - Use "Other" to specify custom model URLs
4. Tap "Download & Setup Model"
5. Wait for download and initialization to complete

### Using Existing Models

- Previously downloaded models appear in the "Use Existing Model" section
- Simply tap on a model to initialize it without re-downloading

### Chat Interface

- After setup, you'll be redirected to the chat interface
- Type your message and tap Send
- The AI will process your query locally and respond
- For multimodal models, you can include images in your queries

## 🛠️ Project Structure

```
lib/
├── app_state.dart              # Global state management
├── main.dart                   # App entry point
├── flutter_flow/               # FlutterFlow framework files
├── pages/                      # App screens
│   ├── home_page/             # Chat interface
│   └── setup/                 # Model setup screen
└── custom_code/               # Custom implementations
    ├── GemmaManager.dart      # Core model management
    ├── actions/               # Custom actions for FlutterFlow
    │   ├── initialize_gemma_model.dart
    │   ├── download_authenticated_model.dart
    │   ├── send_gemma_message.dart
    │   └── ...
    └── widgets/               # Custom widgets
        ├── gemma_chat_widget.dart
        └── gemma_authenticated_setup_widget.dart
```

## 🔧 Custom Actions

### Model Management

- `initializeGemmaModel` - Initialize a model with configuration
- `initializeLocalGemmaModel` - Initialize from local file
- `downloadAuthenticatedModel` - Download models from HuggingFace
- `installLocalModelFile` - Install model from device storage
- `manageDownloadedModels` - List and manage local models

### Chat Operations

- `createGemmaSession` - Create a chat session
- `sendGemmaMessage` - Send messages and receive responses
- `closeGemmaModel` - Clean up model resources

### Utilities

- `getHuggingfaceModelInfo` - Fetch model metadata
- `debugModelPaths` - Debug model file locations

## 🎨 Customization

### Modifying the Chat Interface

Edit `lib/custom_code/widgets/gemma_chat_widget.dart` to customize:

- Chat bubble styling
- Message formatting
- Input field appearance
- Animation effects

### Adding New Models

1. Update model options in `gemma_authenticated_setup_widget.dart`
2. Add model metadata to the `_modelOptions` list
3. Ensure proper model type detection in `_isMultimodalModel()`

### Backend Configuration

Modify backend preferences in the setup widget:

- `gpu` - For devices with GPU support
- `cpu` - For CPU-only processing
- Adjust thread count and memory allocation

## 🐛 Troubleshooting

### Common Issues

1. **Model Download Fails**

   - Verify HuggingFace token is valid
   - Check internet connection
   - Ensure sufficient storage space

2. **Model Initialization Error**

   - Verify model file integrity
   - Check device compatibility
   - Try CPU backend if GPU fails

3. **App Crashes on Large Models**
   - Increase memory allocation in platform configs
   - Use smaller model variants
   - Enable memory optimization flags

### Debug Tools

- Use `debugModelPaths()` action to inspect model locations
- Check Flutter logs for detailed error messages
- Monitor memory usage during model loading

## 📦 Dependencies

Key packages used:

- `flutter_gemma: ^0.1.7` - Core Gemma integration
- `http: ^1.2.2` - Network requests
- `path_provider: ^2.1.5` - File system access
- `flutter_secure_storage: ^9.2.2` - Secure token storage
- `percent_indicator: ^4.2.3` - Progress indicators

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow FlutterFlow custom code guidelines
4. Test thoroughly on both platforms
5. Submit a pull request

## 📄 License

This project is built with FlutterFlow and uses Google's Gemma models. Please refer to:

- [FlutterFlow Terms](https://flutterflow.io/terms)
- [Gemma Model License](https://ai.google.dev/gemma/terms)
- [HuggingFace Terms](https://huggingface.co/terms-of-service)

## 🙏 Acknowledgments

- Google for the Gemma AI models
- FlutterFlow team for the development platform
- HuggingFace for model hosting
- Flutter community for packages and support

---

For more information or support, please open an issue in the repository.
