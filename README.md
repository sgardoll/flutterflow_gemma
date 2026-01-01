# Gemma 3n FlutterFlow Integration

An integration of Google's Gemma 3n AI models, providing offline/local on-device multimodel AI capabilities with authenticated model downloads and real-time chat functionality.

## ✨ Features

### 🤖 AI Model Support
- **Gemma 3 Text Models**: 1B parameters (text-only)
- **Gemma 3 Nano Models**: 2B, 4B parameters (vision + text)
- **FunctionGemma**: 270M parameters (function calling for smart actions)
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

#### GemmaManager (Singleton)
- **Model Lifecycle**: Initialize, create sessions, send messages, cleanup
- **Platform Compatibility**: iOS/Android-specific optimizations
- **Error Handling**: Comprehensive fallback mechanisms
- **Vision Support**: Automatic detection and handling of multimodal models

#### Custom Widgets
- **GemmaSimpleSetupWidget**: Complete setup wizard with progress tracking
- **GemmaChatWidget**: Real-time chat interface with image support
- **FunctionGemmaChatWidget**: Chat interface with function calling visualization
- **GemmaVisualModelSelector**: Visual model selection with expandable categories
- **MarkdownDisplayWidget**: Rich text rendering for AI responses

#### Custom Actions
- **downloadAuthenticatedModel**: Secure model downloads with progress tracking
- **installLocalModelFile**: Optimized model installation with validation
- **validateAndRepairModel**: File integrity checking and repair
- **sendFunctionGemmaMessage**: Function calling with tool definitions
- **closeModel**: Proper cleanup and state reset

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

### Function Calling Models (FunctionGemma)
| Model | Parameters | Memory | Capabilities |
|-------|------------|--------|--------------|
| functiongemma-270m-it (Tiny Garden) | 270M | 288MB | Function calling, tool use |

#### FunctionGemma Use Cases

**Tiny Garden**: A model fine-tuned to power a voice-controlled interactive game. It handles game logic to manage a virtual plot of land, decomposing commands like "Plant sunflowers in the top row" and "Water the flowers in plots 1 and 2" into app-specific functions (e.g., `plant_seed`, `water_plots`) and coordinate targets. This demonstrates the model's capacity to drive custom app mechanics without server connectivity.

**Mobile Actions**: To empower developers to build their own expert agents, Google has published a dataset and fine-tuning recipe. It translates user inputs (e.g., "Create a calendar event for lunch," "Turn on the flashlight") into function calls that trigger Android OS system tools. This use case demonstrates the model's ability to act as an offline, private agent for personal device tasks.

#### FunctionGemma Specifications
- **Input**: Text string (question, prompt, or document) - 32K token context
- **Output**: Generated function calls or text responses - up to 32K tokens

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK (stable channel)
- FlutterFlow project setup
- HuggingFace account with API token

### Dependencies
```yaml
dependencies:
  flutter_gemma: ^0.9.0
  image_picker: ^1.1.2
  markdown_widget: ^2.3.2+8
  path_provider: ^2.1.4
  url_launcher: ^6.3.1
```

### Setup Steps

1. **Get HuggingFace Token**
   - Visit [HuggingFace](https://huggingface.co/settings/tokens)
   - Create a new token with read permissions
   - Keep token secure for model downloads

2. **Model Setup**
   - Use the visual model selector to choose your preferred model
   - Download will begin automatically with progress tracking
   - Models are validated and installed locally

3. **Start Chatting**
   - Text-only models: Type messages and get AI responses
   - Vision models: Attach images from camera or gallery
   - Responses are rendered in rich markdown format

## 🎯 Usage

### Basic Chat
```dart
// The chat widget handles all AI interactions
GemmaChatWidget(
  width: double.infinity,
  height: double.infinity,
  placeholder: 'Ask me anything...',
  onMessageSent: (message) async {
    // Optional callback for message events
  },
)
```

### Model Selection
```dart
// Visual model selector with expandable categories
GemmaVisualModelSelector(
  selectedModelId: 'gemma-3n-e2b-it',
  onModelSelected: (modelId) async {
    // Handle model selection
  },
)
```

### Custom Actions
```dart
// Download and install models
await downloadAuthenticatedModel('gemma-3n-e2b-it', token, onProgress);
await installLocalModelFile(modelPath, null);

// Proper cleanup
await closeModel();
```

### FunctionGemma (Function Calling)
```dart
// Use FunctionGemmaChatWidget for automatic tool execution
FunctionGemmaChatWidget(
  width: double.infinity,
  height: double.infinity,
  enableCommonFunctions: true, // Calendar, weather, reminders, etc.
  onFunctionCall: (functionName, args) async {
    // Handle function execution
    if (functionName == 'create_calendar_event') {
      // Create the event...
      return {'success': true, 'event_id': '123'};
    }
    return null;
  },
)

// Or use the action directly for custom implementations
final response = await sendFunctionGemmaMessage(
  'Set a reminder for my meeting at 3pm',
  functions: [
    CommonFunctionDefinitions.setReminder(),
    CommonFunctionDefinitions.createCalendarEvent(),
  ],
  functionHandler: myFunctionHandler,
);
```

## 📁 Project Structure

```
lib/
├── custom_code/
│   ├── actions/
│   │   ├── download_authenticated_model.dart
│   │   ├── install_local_model_file.dart
│   │   ├── validate_and_repair_model.dart
│   │   ├── close_model.dart
│   │   └── get_downloaded_models.dart
│   ├── widgets/
│   │   ├── gemma_simple_setup_widget.dart
│   │   ├── gemma_chat_widget.dart
│   │   ├── gemma_visual_model_selector.dart
│   │   └── markdown_display_widget.dart
│   └── GemmaManager.dart
├── pages/
│   └── home_page/
│       └── home_page_widget.dart
└── flutter_flow/
    └── flutter_flow_theme.dart
```

## 🔧 Development Notes

### FlutterFlow Integration
- All widgets follow FlutterFlow conventions
- Custom actions are properly exported
- Theme integration with FlutterFlowTheme
- Responsive design patterns

### Platform Considerations
- **iOS**: Automatic CPU fallback for compatibility
- **Android**: Full GPU acceleration support
- **Web**: Optimized model variants available

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
- [FunctionGemma Model](https://huggingface.co/google/functiongemma-270m-it)
- [FunctionGemma Documentation](https://ai.google.dev/gemma/docs/functiongemma)
- [Flutter Gemma Plugin](https://pub.dev/packages/flutter_gemma)
- [HuggingFace Tokens](https://huggingface.co/settings/tokens)

