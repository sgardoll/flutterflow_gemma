# Migration Guide: Old API → New Architecture

This document is for updating FlutterFlow pages and action blocks to use
the new boundary-based architecture. Keep it open while editing in FlutterFlow.

---

## One-Line Principle

> **FlutterFlow handles the interface. `custom_code/` handles the contract.
> The runtime handles the intelligence.**

---

## Architecture Overview

```
FlutterFlow Pages
  ↓  (call)
Custom Actions (ai_*.dart)
  ↓  (delegate to)
AiRustApi singleton  ←── The only file that touches flutter_gemma
  ↓
flutter_gemma 0.12.5 (today)  →  Rust engine (future)
```

---

## Action Reference (New API)

All new actions are in `lib/custom_code/actions/ai_*.dart` and are
exported from `lib/custom_code/actions/index.dart`.

### Initialization & Lifecycle

#### `aiInitialize`
```
Signature: Future<bool> aiInitialize(
  String modelUrl,
  String? authToken,
  String? modelType,   // leave empty — auto-detected
  String backend,      // 'gpu' recommended
  double temperature,  // 0.8 recommended
)
Returns: true = ready, false = failed
Side-effects: Updates FFAppState.isModelInitialized, isDownloading,
              downloadProgress, downloadPercentage, modelSupportsVision
```
**Replaces:** `initializeGemmaModelAction`, `downloadModelAction` +
             `setModelAction` + `initializeModelAction` (3-step sequence)

---

#### `aiCreateSession`
```
Signature: Future<String?> aiCreateSession()
Returns: session ID string, or null if engine not ready
Side-effects: Clears message history for the session
```
**Note:** `aiInitialize` calls this automatically on success.
Only call explicitly if you need a fresh session mid-app.

---

### Sending Messages

#### `aiSendTextMessage`
```
Signature: Future<bool> aiSendTextMessage(String message)
Returns: true = generation started, false = not ready or already busy
```
**Generation is async.** After calling this, poll `aiGetSessionMessages`
or rely on `GemmaChatRuntimeWidget` (which polls internally).

**Replaces:** `sendMessageAction` (text path)

---

#### `aiSendImageMessage`
```
Signature: Future<bool> aiSendImageMessage(
  String message,
  FFUploadedFile? image,
)
Returns: true = accepted, false = failed
```
Falls back to text-only if the model doesn't support vision or image is null.

**Replaces:** `sendMessageAction` (image path) + `sanitizeImageForGemma`

---

#### `aiCancelGeneration`
```
Signature: Future<bool> aiCancelGeneration()
Returns: true = cancelled, false = nothing was generating
```
Commits partial tokens as a cancelled message visible in the chat.

---

### Reading Messages

#### `aiGetSessionMessages`
```
Signature: Future<List<dynamic>> aiGetSessionMessages()
Returns: list of message maps (newest last)
```

Each map has these keys:
```
id           String   unique message ID
sessionId    String   current session ID
text         String   message content
isUser       bool     true = user, false = assistant
isPartial    bool     true while generation is in progress
timestamp    int      millisecondsSinceEpoch
status       String   'pending' | 'generating' | 'complete' | 'error' | 'cancelled'
```

**Polling pattern:**
```
Timer → aiGetSessionMessages → update page state → rebuild list
Stop when status != 'generating'
```

**Note:** `GemmaChatRuntimeWidget` handles polling internally.
Only call this from FlutterFlow pages if you're building a custom UI.

---

### Model Management

#### `aiListModels`
```
Signature: Future<List<dynamic>> aiListModels()
Returns: list of installed model maps
```

Each map has:
```
id                    String   e.g. 'gemma-3n-e2b-it'
displayName           String   e.g. 'Gemma 3n E2B (2B, Vision)'
filePath              String?  local file path
fileSizeBytes         int?
fileSizeFormatted     String   e.g. '2.4 GB'
supportsVision        bool
supportsFunctionCalling bool
isInstalled           bool     always true (only installed models returned)
downloadUrl           String?
installedAt           int?     millisecondsSinceEpoch
```

---

#### `aiInstallModel`
```
Signature: Future<dynamic> aiInstallModel(
  String downloadUrl,
  String? authToken,
)
Returns: map with keys: success (bool), filePath (String?), errorMessage (String?)
Side-effects: Updates FFAppState download progress fields
```
**Replaces:** `downloadModelAction`

---

#### `aiDeleteModel`
```
Signature: Future<bool> aiDeleteModel(String modelPath)
Returns: true = deleted
```
Closes the engine first if the model is currently loaded.

**Replaces:** No direct equivalent (was inline in widgets)

---

#### `aiGetDeviceCapabilities`
```
Signature: Future<dynamic> aiGetDeviceCapabilities()
Returns: map with keys:
  supportsGpu           bool
  supportsCpu           bool
  supportsTpu           bool
  recommendedBackend    String?  'gpu' | 'cpu' | 'npu'
  platform              String   'ios' | 'android' | 'web' | 'other'
```

---

## Widget Reference (New)

### `GemmaChatRuntimeWidget`
Drop-in replacement for `GemmaChatWidget`.

**Parameters:**
```
width             double?
height            double?
placeholder       String?        input hint text
showImageButton   bool?          null = auto-detect from model caps
onMessageSent     Future Function(String message, String response)?
onError           Future Function(String errorMessage)?
onChangeModel     Future Function()?   called when user taps "Go Back" on error
```

**How it works:**
1. On mount: reads existing messages from `AiRustApi`
2. On send: calls `AiRustApi.sendTextMessage` or `sendImageMessage`
3. Polls every 400 ms while `AiRustApi.isGenerating == true`
4. Stops polling and fires `onMessageSent` when generation completes
5. Respects `FFAppState.isModelInitialized` — input disabled when not ready

**Does NOT:** contain inference logic, build prompts, manage sessions,
map runtime responses, or check model compatibility.

---

### `GemmaModelSelectorWidget`
Replacement for `ModelConfigurationWidget`.

**Parameters:**
```
width             double?
height            double?
onConfigSaved     Future Function(String modelUrl, String authToken)?
```

**Behaviour:**
- Shows installed models (via `AiRustApi.listModels`) + 3 well-known
  downloadable models + custom URL option
- On save: writes `FFAppState.downloadUrl` and `FFAppState.hfToken`,
  then calls `onConfigSaved` callback
- The page/action block should call `aiInitialize` after `onConfigSaved`

---

### `GemmaSetupStatusWidget`
Replacement for `InitialzingWidget` + `ErrorRecoveryWidget`.

**Parameters:**
```
width             double?
height            double?
onRetry           Future Function()?   called when user taps "Try Again"
onSelectModel     Future Function()?   called when user taps "Change Model"
```

**Reads from `FFAppState`:**
- `isDownloading`, `isInitializing`, `isModelInitialized`
- `downloadProgress`, `downloadPercentage`, `fileName`

**Does NOT** call any actions itself — all logic flows through callbacks.

---

## FlutterFlow Page Wiring: Minimal Chat Setup

Replace the existing `Demo` page logic with this pattern:

### On Page Load action block:
```
1. Check: if (FFAppState.hfToken == '' || FFAppState.downloadUrl == '')
     → Show GemmaModelSelectorWidget (hide chat)
   else
     → Call aiInitialize(
         FFAppState.downloadUrl,
         FFAppState.hfToken,
         '',         ← modelType (auto-detect)
         'gpu',      ← backend
         0.8,        ← temperature
       )
     → If result == true: hide setup overlay, show GemmaChatRuntimeWidget
     → If result == false: show GemmaSetupStatusWidget
```

### Page body layout (Stack):
```
Layer 1 (always): GemmaChatRuntimeWidget (full size)
  onChangeModel: navigate back / show model selector

Layer 2 (conditional): GemmaSetupStatusWidget
  visible when: !FFAppState.isModelInitialized && busy
  onRetry: call aiInitialize again
  onSelectModel: show model selector

Layer 3 (conditional): GemmaModelSelectorWidget
  visible when: hfToken == '' && downloadUrl == ''
  onConfigSaved: trigger page load action
```

---

## Old → New Action Mapping

| Old | New | Notes |
|-----|-----|-------|
| `initializeGemmaModelAction` | `aiInitialize` | Single call replaces 3-step sequence |
| `downloadModelAction` | `aiInstallModel` | Same; updates FFAppState progress |
| `setModelAction` | *(removed)* | Handled inside `aiInitialize` |
| `initializeModelAction` | *(removed)* | Handled inside `aiInitialize` |
| `sendMessageAction` | `aiSendTextMessage` / `aiSendImageMessage` | Split by type |
| `sanitizeImageForGemma` | *(removed)* | Handled inside `aiSendImageMessage` |
| `closeModel` | *(direct)* | `AiRustApi.instance.closeEngine()` from Dart |
| `recoverFromInitializationError` | `aiInitialize` again | Re-call with same params |
| — | `aiCreateSession` | New: explicit session reset |
| — | `aiGetSessionMessages` | New: polling from page-level |
| — | `aiListModels` | New: enumerate installed |
| — | `aiGetDeviceCapabilities` | New: check device support |
| — | `aiDeleteModel` | New: lifecycle management |
| — | `aiCancelGeneration` | New: stop in-flight generation |

---

## Old → New Widget Mapping

| Old | New | Notes |
|-----|-----|-------|
| `GemmaChatWidget` | `GemmaChatRuntimeWidget` | Same UX, polling-based, no inference logic |
| `ModelConfigurationWidget` | `GemmaModelSelectorWidget` | Shows installed models too |
| `ErrorRecoveryWidget` + `InitialzingWidget` | `GemmaSetupStatusWidget` | Unified setup/error UI |
| `MarkdownWidget` | `MarkdownWidget` | Unchanged — still exported |

---

## FFAppState Fields Used by New Actions

| Field | Type | Used by |
|-------|------|---------|
| `isModelInitialized` | bool | `aiInitialize`, `GemmaChatRuntimeWidget` |
| `isDownloading` | bool | `aiInitialize`, `aiInstallModel`, `GemmaSetupStatusWidget` |
| `isInitializing` | bool | `aiInitialize`, `GemmaSetupStatusWidget` |
| `downloadProgress` | String | `aiInitialize`, `aiInstallModel`, `GemmaSetupStatusWidget` |
| `downloadPercentage` | double | `aiInitialize`, `aiInstallModel`, `GemmaSetupStatusWidget` |
| `fileName` | String | `aiInstallModel`, `GemmaSetupStatusWidget` |
| `modelSupportsVision` | bool | `aiInitialize`, `GemmaChatRuntimeWidget` |
| `downloadUrl` | String | persisted — read by `GemmaModelSelectorWidget` |
| `hfToken` | String | persisted — read by `GemmaModelSelectorWidget` |

---

## Rust Migration Path (Future)

When you're ready to swap flutter_gemma for a Rust engine:

1. Edit **only** `lib/custom_code/ai_rust_api.dart`
2. Replace the `flutter_gemma` imports with `flutter_rust_bridge` bindings
3. Re-implement the private methods (`_createModelWithFallback`,
   `_createChatWithFallback`, `_runGeneration`) using the Rust API
4. All Actions, Widgets, and FlutterFlow pages remain unchanged

The boundary is clean. The swap is localised to one file.

---

## Files That Are Deprecated (Do Not Modify)

These files still exist for backward compatibility while FlutterFlow pages
are being updated. Once all pages use the new API, they can be removed.

```
lib/custom_code/flutter_gemma_library.dart   ← superseded by ai_rust_api.dart
lib/custom_code/model_file_manager.dart      ← still used by ai_rust_api.dart internally
lib/custom_code/function_gemma_helper.dart   ← separate feature, not migrated
lib/custom_code/function_chat_message.dart   ← superseded by ai_types.dart
lib/custom_code/actions/initialize_model_action.dart
lib/custom_code/actions/initialize_gemma_model_action.dart
lib/custom_code/actions/set_model_action.dart
lib/custom_code/actions/send_message_action.dart
lib/custom_code/actions/close_model.dart
lib/custom_code/actions/download_model_action.dart
lib/custom_code/actions/recover_from_initialization_error.dart
lib/custom_code/actions/sanitize_image_for_gemma.dart
lib/custom_code/widgets/gemma_chat_widget.dart
lib/custom_code/widgets/error_recovery_widget.dart
lib/custom_code/widgets/model_configuration_widget.dart
```
