# Gemma 3n FlutterFlow Integration

<img width="1248" height="832" alt="MP" src="https://github.com/user-attachments/assets/5246b3a6-5c57-442f-99e7-184c13ec5f08" />

An integration of Google's Gemma 3n AI models, providing offline/local on-device multimodel AI capabilities with authenticated model downloads and real-time chat functionality.

For Flutter and FlutterFlow developers inspecting or adapting the exported source. The feature and model overview below records the original project goals; it is not evidence of current build, device, memory or performance results. Use the source setup and current action contracts below rather than older selector/download examples.

## ✨ Features

### 🤖 AI Model Support
- **Gemma 3 Text Models**: 1B parameters (text-only)
- **Gemma 3 Nano Models**: 2B, 4B parameters (vision + text)
- **On-device Processing**: Complete offline AI capabilities
- **Mobile Optimized**: iOS & Android Support (Web coming soon)

### 🎨 User Interface
- **Visual Model Selector**: Expandable card interface for intuitive model selection
- **Real-time Chat**: Interactive chat interface with typing indicators
- **Markdown Support**: Rich text rendering for AI responses with syntax highlighting
- **Image Processing**: Camera and gallery integration for vision models
- **Responsive Design**: Adaptive UI that works across all screen sizes

### 🚀 Performance & Storage
- **50% Storage Reduction**: Optimized model storage prevents duplication
- **Smart Caching**: Efficient model file management
- **Memory Optimization**: Automatic CPU/GPU fallback for device compatibility
- **Background Processing**: Async image processing prevents UI blocking

## 🏗️ Architecture

### Core Components

#### AiRustApi (Singleton)
- [AiRustApi](lib/custom_code/ai_rust_api.dart) is the current runtime boundary. Despite its name, this checkout wraps `flutter_gemma`; it does not establish a working Rust engine.
- Actions and widgets call this boundary for model initialization, session management, messages and storage.

#### Custom Widgets
- [GemmaModelSelectorWidget](lib/custom_code/widgets/gemma_model_selector_widget.dart): saves model URL/token configuration; saving alone does not initialize or download a model.
- [GemmaChatRuntimeWidget](lib/custom_code/widgets/gemma_chat_runtime_widget.dart): renders and polls the active session after initialization.
- [ModelConfigurationWidget](lib/custom_code/widgets/model_configuration_widget.dart), [GemmaSetupStatusWidget](lib/custom_code/widgets/gemma_setup_status_widget.dart) and [MarkdownWidget](lib/custom_code/widgets/markdown_widget.dart) provide configuration, status and rendering UI.

#### Custom Actions
- [aiInitialize](lib/custom_code/actions/ai_initialize.dart): locates/downloads a model, initializes the engine and creates a session.
- [aiInstallModel](lib/custom_code/actions/ai_install_model.dart): storage-only model download; does not initialize the engine.
- [aiSendTextMessage](lib/custom_code/actions/ai_send_text_message.dart) and [aiGetSessionMessages](lib/custom_code/actions/ai_get_session_messages.dart): start generation and retrieve session messages.

## 📱 Supported Models

### Text-Only Models (Gemma 3)
| Model | Parameters | Memory | Use Case |
|-------|------------|--------|----------|
| gemma3-1b-it | 1B | 800MB | Mobile efficiency |

### Vision + Text Models (Gemma 3 Nano)
| Model | Parameters | Memory | Capabilities |
|-------|------------|--------|--------------|
| gemma-3n-e2b-it | 2B | 2GB | Vision + text |
| gemma-3n-e4b-it | 4B | 3GB | Advanced vision |

## 🛠️ Installation & Setup

### Get the exported source

```bash
git clone https://github.com/sgardoll/flutterflow_gemma.git
cd flutterflow_gemma
```

This repository is an exported Flutter project with FlutterFlow custom code. Cloning it downloads source; it does not import a library into the FlutterFlow editor. No verified Marketplace link or editor library ID is supplied here.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/install), with Dart matching the root [pubspec.yaml](pubspec.yaml) constraint `>=3.0.0 <4.0.0`.
- A compatible model file URL and enough device storage/memory for that model. Bundled model choices are examples, not live availability checks.
- For a gated/private Hugging Face model, an account with access to that repository and a token permitted to read it. Public unauthenticated URLs can use a null token.

### Dependencies
Use the checked-in manifest rather than copying an older dependency list. It pins `flutter_gemma: 0.11.16`; this README does not upgrade it. From the cloned root:

```bash
flutter pub get
```

[Version-specific plugin documentation](https://pub.dev/packages/flutter_gemma/versions/0.11.16) describes platform setup. As checked on 7 October 2026, the [package page](https://pub.dev/packages/flutter_gemma) marks `flutter_gemma` discontinued and replaced by `flutter_edge_ai`. That does not migrate this checkout or prove compatibility with a newer package.

### Current checkout limitations

Acquisition and source contracts are documented here; a successful demo build is not established. The current [action export file](lib/custom_code/actions/index.dart) still exports absent legacy files, including `close_model.dart`. The [selector component wrapper](lib/components/gemma_model_selector_component_widget.dart) assigns `hfToken = modelUrl` in its callback, overwriting the supplied token. Runtime/export repairs need separate work; the explicit action inputs below describe the API without promising that the existing page wiring works.

### Setup Steps

1. **Choose a model URL and access**
   - Supply a direct model file URL compatible with the pinned runtime. Inspect the bundled selector choices and [AiMapper](lib/custom_code/ai_mapper.dart); model names alone are not download URLs.
   - For gated models, request access on the model page using [Hugging Face's access instructions](https://huggingface.co/docs/hub/models-gated), then use your own [read-capable token](https://huggingface.co/docs/hub/security-tokens). Do not commit token values.
2. **Save configuration**
   - `GemmaModelSelectorWidget` saves the URL to `FFAppState().downloadUrl` and the token to `FFAppState().hfToken`, then calls `onConfigSaved(modelUrl, authToken)` if supplied. It does not automatically download or initialize.
   - [library_values.dart](lib/library_values.dart) declares `modelDownloadUrl` and `huggingFaceToken`; those names are not substitutes for passing the current action's arguments.
3. **Initialize before chatting**
   - Call `aiInitialize(modelUrl, authToken, modelType, backend, temperature)`. All five arguments must be supplied; nullable token/modelType can be null. For example, `'cpu'` and `0.8` are explicit values, not defaults on the action signature.
   - Check its Boolean result. On success the action marks initialization state and calls `createSession`; on failure it returns false and updates progress/error state. The model type is inferred from the URL when no override is supplied.
   - `aiInstallModel(downloadUrl, authToken)` is optional storage-only preparation. Inspect `success`, `filePath` and `errorMessage`; installation alone does not make a chat session ready. Initialize afterward using the model URL.
4. **Use the initialized session**
   - `GemmaChatRuntimeWidget` polls messages from `AiRustApi`. Text generation is asynchronous; an accepted send is not a completed response. Vision use additionally depends on the model and the created session's capabilities.

## 🎯 Usage

### Basic Chat
```dart
// After successful aiInitialize, in a Flutter widget tree:
GemmaChatRuntimeWidget(
  width: double.infinity,
  height: double.infinity,
  placeholder: 'Ask me anything...',
  onMessageSent: (message, response) async {
    // Optional callback after a complete exchange
  },
)
```

### Model Selection
```dart
// Configuration only; initialize explicitly after saving:
GemmaModelSelectorWidget(
  onConfigSaved: (modelUrl, authToken) async {
    final ready = await aiInitialize(modelUrl, authToken, null, 'cpu', 0.8);
    // Only show the chat UI when ready is true.
  },
)
```

### Custom Actions
```dart
// Contract example inside an async handler, with modelUrl and authToken
// supplied by the caller. This does not certify the checkout's build.
final ready = await aiInitialize(modelUrl, authToken, null, 'cpu', 0.8);
if (ready) {
  final accepted = await aiSendTextMessage('Hello');
  // accepted means generation started; poll aiGetSessionMessages()
  // for progress and the final response.
}
```

These snippets reference the current classes/actions in the exported source. Inspect their imports and generated dependencies before adapting them; the absent legacy exports noted above prevent treating them as a verified runnable quickstart. `AiRustApi.instance.closeEngine()` is the current cleanup method; no existing `closeModel` action file is supplied in this checkout.

## 📁 Project Structure

```
lib/
├── custom_code/
│   ├── actions/
│   │   ├── ai_initialize.dart
│   │   ├── ai_install_model.dart
│   │   ├── ai_send_text_message.dart
│   │   └── ai_get_session_messages.dart
│   ├── widgets/
│   │   ├── gemma_model_selector_widget.dart
│   │   ├── gemma_chat_runtime_widget.dart
│   │   └── markdown_widget.dart
│   └── ai_rust_api.dart
├── pages/
│   └── home_page/
│       └── home_page_widget.dart
└── flutter_flow/
    └── flutter_flow_theme.dart
```

## 🔧 Development Notes

### FlutterFlow Integration
- All widgets follow FlutterFlow conventions
- Current action/widget files use generated imports; the action export file also contains missing legacy entries, as noted above.
- Theme integration with FlutterFlowTheme
- Responsive design patterns

### Platform Considerations
The source attempts the requested backend and may fall back to CPU. This is a source strategy, not proof of device support. Consult the pinned plugin's platform setup and validate on the intended device; Android, iOS and web results are not established by this documentation change.

### Performance Optimizations
- Image compression and resizing before processing
- Async processing with isolates
- Memory-efficient model loading
- Smart caching strategies

## 🐛 Troubleshooting

### Common Issues
1. **Model Not Found**: Check HuggingFace token permissions
2. **Memory Errors**: Try CPU backend or smaller model
3. **iOS Crashes**: Disable vision features for CPU-only devices
4. **Storage Issues**: Use optimized model variants

### Debug Tips
- Check console logs for detailed error messages
- Use smaller models for testing
- Verify file permissions and storage space
- Test on different devices for compatibility

## 🤝 Contributing

This project is built for FlutterFlow integration. When contributing:
- Follow FlutterFlow widget patterns
- Maintain theme consistency
- Add proper error handling
- Update documentation

## 📄 License

This project integrates with Google's Gemma models. Please review the Gemma license terms and ensure compliance with usage policies.

## 🔗 Resources

- [FlutterFlow Documentation](https://docs.flutterflow.io)
- [Gemma Models](https://huggingface.co/collections/google/gemma-3-665f2f5b4b0a10a9e5d6be9d)
- [Flutter Gemma Plugin](https://pub.dev/packages/flutter_gemma)
- [HuggingFace Tokens](https://huggingface.co/settings/tokens)
