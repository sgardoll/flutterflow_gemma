# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a FlutterFlow library for Google's Gemma 3n on-device AI models, providing offline/local AI capabilities with authenticated model downloads and real-time chat functionality. The project supports both text and vision models (Gemma 3 1B text-only, Gemma 3n 2B/4B vision+text).

## Build and Development Commands

```bash
# Get dependencies
flutter pub get

# Run the app (development)
flutter run

# Build for iOS
flutter build ios

# Build for Android
flutter build apk

# Run analyzer/lints
flutter analyze
```

## Architecture

### Core Components

**FlutterGemmaLibrary** (`lib/custom_code/flutter_gemma_library.dart`)
- Singleton pattern managing the entire model lifecycle
- Handles model initialization with GPU/CPU fallback
- Manages chat sessions with vision support detection
- Updates `FFAppState` as single source of truth for model state

**ModelFileManager** (`lib/custom_code/model_file_manager.dart`)
- Downloads models from HuggingFace with authentication
- Platform-specific storage (native file system vs web SharedPreferences)
- Manages model path registration with flutter_gemma plugin

**FFAppState** (`lib/app_state.dart`)
- Application state management using ChangeNotifier
- Persists `hfToken` and `downloadUrl` via flutter_secure_storage
- Tracks: `isModelInitialized`, `modelSupportsVision`, `isDownloading`, `downloadProgress`

### Custom Code Structure (FlutterFlow Sync)

Only files in `/lib/custom_code/` sync with FlutterFlow:
```
lib/custom_code/
├── actions/          # Custom actions (async operations)
├── widgets/          # Custom widgets
├── flutter_gemma_library.dart
└── model_file_manager.dart
```

Custom functions go in `/lib/flutter_flow/custom_functions.dart` (not in custom_code).

### Model Flow
1. User provides HuggingFace token and model URL
2. `downloadModelAction` downloads via ModelFileManager
3. `initializeGemmaModelAction` creates model + chat session
4. `sendMessageAction` handles text/image messages through FlutterGemmaLibrary
5. `closeModel` cleans up resources

## FlutterFlow Custom Code Requirements

### File Headers (MANDATORY)

**Custom Widget:**
```dart
// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!
```

**Custom Action:**
```dart
// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!
```

### Parameter Type Restrictions

Use ONLY these FlutterFlow-compatible types:
- `String`, `double`, `int`, `bool`, `Color?`
- `DateTime`, `LatLng`, `DocumentReference`
- `List<T>` of simple types
- `<TypeName>Struct` for custom data types
- `Future Function()` or `Future Function(T)` for action callbacks
- `Widget Function(BuildContext)` for widget builders

**Avoid:** `EdgeInsets`, `Duration`, `TextStyle`, enums (use String instead)

### Custom Functions Limitations
- Synchronous only (no async/await)
- Limited imports (predefined set in flutter_flow/custom_functions.dart)
- No custom package imports allowed

### Actions Must Return Future
```dart
Future<ReturnType?> yourActionName(params) async { }
```

## Supported Models

| Model | Parameters | Vision | Function Calling |
|-------|------------|--------|------------------|
| gemma3-1b-it | 1B | No | No |
| gemma-3n-e2b-it | 2B | Yes | No |
| gemma-3n-e4b-it | 4B | Yes | No |
| functiongemma-270m-it | 270M | No | Yes |

- Vision support: auto-detected via `ModelUtils.isMultimodalModel()`
- Function calling: auto-detected via `ModelUtils.isFunctionCallingModel()`

## FunctionGemma Support

FunctionGemma is a specialized 270M model for function calling, translating natural language into executable API actions.

### Key Files
- `lib/custom_code/function_gemma_helper.dart` - Token parsing, function definitions, prompt building
- `lib/custom_code/actions/send_function_gemma_message.dart` - Function calling action
- `lib/custom_code/widgets/function_gemma_chat_widget.dart` - Chat UI with tool visualization

### Function Call Format
```
<start_function_call>call:function_name{param:<escape>value<escape>}<end_function_call>
```

### Usage
```dart
// Define functions
final functions = [
  CommonFunctionDefinitions.createCalendarEvent(),
  CommonFunctionDefinitions.getCurrentWeather(),
];

// Send message with function calling
final response = await sendFunctionGemmaMessage(
  'Set a reminder for 3pm',
  functions: functions,
  functionHandler: (name, args) async {
    // Execute the function and return result
    return {'success': true, 'id': '123'};
  },
);

// Check if function was called
if (response.hasFunctionCall) {
  print('Called: ${response.functionName}');
}
```

### Built-in Functions
`CommonFunctionDefinitions` provides: `createCalendarEvent`, `setReminder`, `getCurrentWeather`, `controlSmartLight`, `sendMessage`, `getTodayDate`, `playMedia`, `setAlarm`

## State Management Pattern

```dart
// Update FFAppState (triggers UI rebuild)
FFAppState().update(() {
  FFAppState().isModelInitialized = true;
  FFAppState().modelSupportsVision = supportsVision;
});

// Read state
final isReady = FFAppState().isModelInitialized;
```

## Platform Considerations

- **iOS**: Automatic CPU fallback for compatibility
- **Android**: Full GPU acceleration support
- **Web**: Model metadata stored in SharedPreferences, URL-based streaming

## Key Dependencies

- `flutter_gemma`: Core AI inference (custom fork from sgardoll/flutter_gemma)
- `image_picker`: Camera/gallery integration for vision models
- `flutter_secure_storage`: Secure token persistence
- `path_provider`: Platform-specific file storage
