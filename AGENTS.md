# AGENTS.md

This file provides guidance to agentic coding agents working with this FlutterFlow Gemma library repository.

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

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
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

## Code Style Guidelines

### File Organization
- Use clear, descriptive file names in snake_case
- Group related functionality in subdirectories
- Keep custom code in `/lib/custom_code/` for FlutterFlow sync

### Import Organization
```dart
// Dart core imports first
import 'dart:io';
import 'dart:async';

// Flutter framework imports
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports (alphabetical)
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

// Project imports (relative)
import 'model_file_manager.dart';
import '../app_state.dart';
```

### Naming Conventions
- **Classes**: UpperCamelCase (`FlutterGemmaLibrary`, `ModelFileManager`)
- **Variables**: lowerCamelCase (`modelManager`, `downloadProgress`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`, `DEFAULT_TIMEOUT`)
- **Files**: snake_case (`flutter_gemma_library.dart`, `model_file_manager.dart`)
- **Private members**: prefix with underscore (`_model`, `_session`)

### Type Annotations
- Always specify return types for public methods
- Use nullable types (`?`) where appropriate
- Prefer strong typing over `dynamic`
```dart
// Good
Future<bool> initializeModel(String modelPath) async {
  // Implementation
}

// Avoid
var result = await initializeModel(path);
```

### Error Handling
- Use try-catch blocks for async operations
- Log errors with context using `debugPrint`
- Return appropriate fallback values
- Use specific exception types where possible
```dart
try {
  final result = await riskyOperation();
  return result;
} on SocketException catch (e) {
  debugPrint('Network error in initializeModel: $e');
  return false;
} catch (e) {
  debugPrint('Unexpected error in initializeModel: $e');
  rethrow;
}
```

### Async/Await Patterns
- Always await Future returns in actions
- Use `async`/`await` instead of `.then()`
- Handle cancellation where appropriate
```dart
// Good
Future<void> sendMessage(String message) async {
  final response = await _chat.generate(message);
  _updateUI(response);
}

// Avoid
sendMessage(message).then((response) => _updateUI(response));
```

### Documentation
- Use dartdoc comments for public APIs
- Include parameter descriptions and return values
- Add usage examples for complex methods
```dart
/// Downloads a model from the specified URL.
/// 
/// [url] The HuggingFace model URL to download from.
/// [token] Authentication token for private models.
/// Returns the local file path of the downloaded model.
/// 
/// Example:
/// ```dart
/// final path = await downloadModel(url, token);
/// print('Model downloaded to: $path');
/// ```
Future<String> downloadModel(String url, String token) async {
  // Implementation
}
```

### FlutterFlow Custom Code Requirements

#### File Headers (MANDATORY)
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

#### Parameter Type Restrictions
Use ONLY these FlutterFlow-compatible types:
- `String`, `double`, `int`, `bool`, `Color?`
- `DateTime`, `LatLng`, `DocumentReference`
- `List<T>` of simple types
- `<TypeName>Struct` for custom data types
- `Future Function()` or `Future Function(T)` for action callbacks
- `Widget Function(BuildContext)` for widget builders

**Avoid:** `EdgeInsets`, `Duration`, `TextStyle`, enums (use String instead)

#### Actions Must Return Future
```dart
Future<ReturnType?> yourActionName(params) async { }
```

## Testing

### Test Structure
- Place tests in `/test/` directory
- Use descriptive test names
- Group related tests with `group()`
- Mock external dependencies where possible

### Test Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode
flutter test --watch
```

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

## Linting and Analysis

The project uses `flutter_lints` with custom exclusions for FlutterFlow-generated code. Custom code in `/lib/custom_code/` is excluded from analysis to avoid conflicts with FlutterFlow's code generation.

Run `flutter analyze` to check for issues in non-excluded files.