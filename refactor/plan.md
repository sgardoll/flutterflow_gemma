# Refactor Plan: flutterflow_gemma → FlutterFlow-Safe Architecture

**Session ID:** refactor_2025_03_06  
**Goal:** Reshape the project into a FlutterFlow-safe architecture that can gradually introduce a Rust-powered AI core without breaking the current app.

---

## Current State Analysis

### Critical Problem: The God File

**`lib/custom_code/flutter_gemma_library.dart`** (1101 lines) is doing WAY too much:
- FlutterGemmaLibrary singleton with plugin access
- Model lifecycle management (download, init, session, chat)
- Inference orchestration with 5+ fallback strategies
- Vision capability detection
- Model type parsing and auto-detection
- Error handling and recovery
- CPU/GPU fallback logic
- Session/chat management

**This is the single point of failure and the primary target for refactoring.**

### Direct Plugin Coupling

Currently, code throughout the project directly imports and uses `flutter_gemma`:
- `flutter_gemma_library.dart` imports `flutter_gemma` directly
- Actions call methods on `FlutterGemmaLibrary.instance` which then calls plugin
- Widgets check `FlutterGemmaLibrary.instance.supportsVision` etc.

**This makes switching to Rust later nearly impossible without a full rewrite.**

### Widget Responsibility Bloat

**`gemma_chat_widget.dart`** (795 lines) handles:
- UI rendering (messages, input, buttons)
- Image selection and management
- Message state and history
- Progress polling from app state
- Error handling with action buttons
- Model capability detection
- Integration with actions for sending

**This widget is too smart. It should be dumber.**

### Duplicated/Fragmented Actions

Multiple actions do similar things:
- `initialize_model_action.dart` - legacy initialization
- `initialize_gemma_model_action.dart` - newer "complete" initialization
- Both exist, both get called in some flows

This creates confusion about which path to use.

### Missing Abstraction Layers

No clean separation between:
- Data models (what a message IS)
- Runtime API (how to talk to the engine)
- Mapping (converting runtime responses to app types)
- State helpers (coordinating FlutterFlow state)

---

## Target Architecture

### Desired Shape

```
FlutterFlow Pages (generated)
  ↓
Custom Widgets (thin, UI-only)
  ↓
Custom Actions (one-shot async)
  ↓
Shared files in lib/custom_code/ (root level)
  ↓
AI Runtime Boundary (ai_rust_api.dart)
  ↓
flutter_gemma now → Rust-backed engine later
```

### Phase 0: Create Boundaries (This Refactor)

**Do NOT rewrite in Rust yet.** Instead:
1. Hide current `flutter_gemma` behind a façade (`ai_rust_api.dart`)
2. Create clean data models (`ai_types.dart`)
3. Extract mapping logic (`ai_mapper.dart`)
4. Make widgets thin
5. Make actions predictable

**Phase 1:** Once Dart-side is stable, introduce Rust behind the same façade.

---

## Target File Layout

```
lib/custom_code/
  # Shared boundary files (NEW)
  ai_types.dart                    # Data models only
  ai_rust_api.dart                 # Runtime façade
  ai_mapper.dart                   # Response mapping
  ai_state_helpers.dart            # State coordination helpers
  
  # Actions (reorganized/refactored)
  actions/
    ai_initialize.dart             # Initialize engine
    ai_list_models.dart            # List available models
    ai_create_session.dart         # Create chat session
    ai_get_session_messages.dart   # Fetch messages (polling)
    ai_send_text_message.dart      # Send text prompt
    ai_send_image_message.dart     # Send vision prompt
    ai_cancel_generation.dart      # Cancel in-flight gen
    ai_install_model.dart          # Download/install model
    ai_delete_model.dart           # Delete model
    ai_get_device_capabilities.dart # Device capability check
    
  # Widgets (reorganized/refactored)
  widgets/
    gemma_chat_runtime_widget.dart     # Main chat UI (thin)
    gemma_model_selector_widget.dart   # Model selection UI
    gemma_setup_status_widget.dart     # Setup progress UI
    
  # DEPRECATED (to be removed)
  flutter_gemma_library.dart     # REPLACED by ai_rust_api.dart
  model_file_manager.dart        # MERGED into ai_rust_api.dart
  function_gemma_helper.dart     # MOVED to separate feature
  function_chat_message.dart     # REPLACED by ai_types.dart
  actions/
    (old action files)           # REPLACED by new ai_* actions
  widgets/
    (old widget files)           # REPLACED by new gemma_* widgets
```

---

## Implementation Order

### Step 1: Create Shared Boundary Files

Create these FIRST - everything else depends on them:

1. **`ai_types.dart`** - Define the shared language
   - `AiModelInfo` - Model metadata
   - `AiMessageRecord` - Chat message structure
   - `AiCapabilityInfo` - Device/model capabilities
   - `AiEngineStatus` - Runtime status
   - Polling/stream result structures

2. **`ai_rust_api.dart`** - The single façade
   - Wrap `flutter_gemma` for now
   - Expose boring methods:
     - `initializeEngine()`
     - `listModels()`
     - `createSession()`
     - `getSessionMessages(sessionId)`
     - `sendTextMessage(...)`
     - `sendImageMessage(...)`
     - `cancelGeneration(...)`
   - NO direct plugin access outside this file

3. **`ai_mapper.dart`** - Conversion layer
   - Convert raw plugin responses → `AiModelInfo`
   - Convert raw message payloads → `AiMessageRecord`
   - Convert errors → display-safe messages
   - NO widget state, NO page logic

4. **`ai_state_helpers.dart`** - Coordination helpers
   - Sort messages
   - Merge message lists
   - Find draft/pending messages
   - Normalize partial updates
   - Keep it small and dumb

### Step 2: Create Core Actions

Create actions that prove the boundary works:

1. **`actions/ai_initialize.dart`**
   - Call `AiRustApi.initializeEngine()`
   - Return simple status/boolean
   - Update `FFAppState`

2. **`actions/ai_create_session.dart`**
   - Create session in runtime
   - Return session ID
   - Persist session reference in app state

3. **`actions/ai_get_session_messages.dart`**
   - Fetch messages from runtime
   - Map to `AiMessageRecord`
   - Return UI-safe list

### Step 3: Create Main Chat Widget

**`widgets/gemma_chat_runtime_widget.dart`**
- Render message list
- Handle input submission
- Handle image attachment flows
- Show loading/generation state
- Poll for message updates
- Show errors

**Should NOT:**
- Build prompts
- Do session trimming
- Check model compatibility
- Orchestrate inference
- Map runtime responses

### Step 4: Add Message Sending

1. **`actions/ai_send_text_message.dart`**
   - Pass session ID + text to runtime
   - Return acknowledgement
   - Widget handles polling

2. **`actions/ai_send_image_message.dart`**
   - Pass session ID + text + image path
   - Validate input before handoff
   - Return acknowledgement

### Step 5: Add Model Management

1. **`actions/ai_list_models.dart`**
   - Fetch model metadata
   - Filter unsupported if needed
   - Return clean list

2. **`actions/ai_get_device_capabilities.dart`**
   - Expose device/runtime capabilities
   - Surface compatibility info

3. **`widgets/gemma_model_selector_widget.dart`**
   - Display models
   - Show install status
   - Allow selection

### Step 6: Add Install/Delete Flows

1. **`actions/ai_install_model.dart`**
   - Trigger download/install
   - Report result
   - Return updated state

2. **`actions/ai_delete_model.dart`**
   - Remove model files
   - Return updated state

3. **`widgets/gemma_setup_status_widget.dart`**
   - Show initialization state
   - Show download/install progress
   - Show recoverable errors

### Step 7: Add Cancellation

**`actions/ai_cancel_generation.dart`**
- Call runtime cancel
- Return success/failure

---

## Streaming Strategy

### Recommendation: Start with Polling

Instead of forcing streaming integration immediately:

```
1. Submit prompt with ai_send_text_message
2. Runtime starts generation
3. Chat widget polls ai_get_session_messages
4. UI updates progressively
5. Stop polling when message complete
```

**Benefits:**
- Works within FlutterFlow constraints
- Easier to debug
- Easier recovery from failures
- Keeps runtime contract simple

**Later:** Add direct streaming behind same façade once stable.

---

## What Stays Out of Widgets

Widgets should NOT own:
- Prompt construction
- Runtime-specific message mapping
- Model compatibility rules
- Image preprocessing
- Storage heuristics
- Session pruning
- Inference orchestration

## What Stays Out of Actions

Actions should NOT own:
- Duplicated data models
- Repeated mapping logic
- Chat rendering state
- Device heuristics
- Session storage policy
- Hidden business logic

## What Stays Out of Shared Root Files

Shared files should NOT become:
- A giant singleton
- A UI framework
- A second app state system
- A dumping ground for helpers

---

## Non-Goals for First Refactor

**Do NOT do these yet:**
- Full Rust-native inference rewrite
- Generic plugin abstraction system
- Perfect token-by-token streaming
- Abstracting every AI backend
- Full local retrieval/RAG
- Overdesigned session framework

**Focus on:** Clean boundaries, thin APIs, gradual improvement.

---

## Definition of Success

The refactor is successful when:

- [ ] All AI runtime calls route through `ai_rust_api.dart`
- [ ] Widgets contain no inference logic
- [ ] Actions are thin and predictable
- [ ] Shared models live in `custom_code/` root
- [ ] Chat widget works with polling-based updates
- [ ] Switching from current runtime to Rust feels plausible

---

## Copy-Paste Checklist

### Shared root files
- [ ] `lib/custom_code/ai_types.dart`
- [ ] `lib/custom_code/ai_rust_api.dart`
- [ ] `lib/custom_code/ai_mapper.dart`
- [ ] `lib/custom_code/ai_state_helpers.dart`

### Actions
- [ ] `lib/custom_code/actions/ai_initialize.dart`
- [ ] `lib/custom_code/actions/ai_list_models.dart`
- [ ] `lib/custom_code/actions/ai_create_session.dart`
- [ ] `lib/custom_code/actions/ai_get_session_messages.dart`
- [ ] `lib/custom_code/actions/ai_send_text_message.dart`
- [ ] `lib/custom_code/actions/ai_send_image_message.dart`
- [ ] `lib/custom_code/actions/ai_cancel_generation.dart`
- [ ] `lib/custom_code/actions/ai_install_model.dart`
- [ ] `lib/custom_code/actions/ai_delete_model.dart`
- [ ] `lib/custom_code/actions/ai_get_device_capabilities.dart`

### Widgets
- [ ] `lib/custom_code/widgets/gemma_chat_runtime_widget.dart`
- [ ] `lib/custom_code/widgets/gemma_model_selector_widget.dart`
- [ ] `lib/custom_code/widgets/gemma_setup_status_widget.dart`

### Deprecation/Cleanup
- [ ] Mark old files as deprecated
- [ ] Update action/widget index files
- [ ] Update imports in generated code (if needed)
- [ ] Document migration path

---

## Milestone Plan

### Milestone 1: Boundary and Session
**Files:** ai_types.dart, ai_rust_api.dart, ai_mapper.dart, ai_initialize.dart, ai_create_session.dart, ai_get_session_messages.dart

**Success:** App can initialize, create session, fetch and render messages through clean boundaries.

### Milestone 2: Usable Chat Shell
**Files:** gemma_chat_runtime_widget.dart, ai_send_text_message.dart

**Success:** User can send prompt, widget refreshes, prompt/response loop works, no business logic in widget.

### Milestone 3: Multimodal Support
**Files:** ai_send_image_message.dart

**Success:** Image + prompt flow works, no multimodal logic in page code.

### Milestone 4: Model Setup
**Files:** ai_list_models.dart, ai_get_device_capabilities.dart, gemma_model_selector_widget.dart

**Success:** Model choices explicit, incompatible options handled honestly.

### Milestone 5: Lifecycle Management
**Files:** ai_install_model.dart, ai_delete_model.dart, gemma_setup_status_widget.dart, ai_cancel_generation.dart

**Success:** Installation, deletion, cancellation manageable. App feels like a product.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| FlutterFlow regeneration breaks imports | High | High | Keep all shared files in custom_code/ root, use relative imports |
| Plugin API changes | Medium | High | Isolate in ai_rust_api.dart, stable signatures |
| Breaking existing flows | Medium | Medium | Keep old files during transition, deprecate gradually |
| Performance regression | Low | Medium | Test polling vs streaming, optimize later |

---

## One-Line Principle

> **FlutterFlow handles the interface. `custom_code/` handles the contract. The runtime handles the intelligence.**

---

*Plan created: 2025-03-06*  
*Ready to execute: Run `/refactor execute` to begin*
