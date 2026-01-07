// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import '../flutter_gemma_library.dart';

/// Recover from initialization errors and reset state for retry
///
/// This action provides error recovery by:
/// 1. Cleaning up any partially initialized model resources
/// 2. Resetting the application state to a clean state
/// 3. Clearing error messages and progress indicators
/// 4. Allowing the user to try initialization again with different parameters
///
/// ## Usage in FlutterFlow:
/// - Call this action when initialization fails
/// - Use it to allow users to "try again" or select a different model
/// - Can be triggered by a "Reset" or "Try Again" button
///
/// ## Returns:
/// - Future<void>: Completes when cleanup and reset are done
///
/// ## Example:
/// ```dart
/// // In your error handling flow
/// await recoverFromInitializationError();
/// // Now user can try again with different model/parameters
/// ```
Future<void> recoverFromInitializationError() async {
  try {
    print('recoverFromInitializationError: Starting error recovery...');

    final appState = FFAppState();
    final gemmaLibrary = FlutterGemmaLibrary.instance;

    // Step 1: Close any partially initialized model
    print('recoverFromInitializationError: Cleaning up model resources...');
    try {
      await gemmaLibrary.closeModel();
      print('recoverFromInitializationError: Model resources cleaned up');
    } catch (cleanupError) {
      print(
          'recoverFromInitializationError: Error during model cleanup: $cleanupError');
      // Continue with state reset even if cleanup fails
    }

    // Step 2: Reset application state to clean state
    print('recoverFromInitializationError: Resetting application state...');
    appState.update(() {
      // Reset initialization flags
      appState.isInitializing = false;
      appState.isDownloading = false;
      appState.isModelInitialized = false;

      // Reset progress indicators
      appState.downloadProgress = '';
      appState.downloadPercentage = 0.0;
      appState.fileName = '';

      // Reset model capabilities
      appState.modelSupportsVision = false;
    });

    print(
        'recoverFromInitializationError: Error recovery completed successfully');
    print(
        'recoverFromInitializationError: User can now try initialization again');
  } catch (e) {
    print('recoverFromInitializationError: Error during recovery: $e');
    // Even recovery can fail, but we should still try to reset basic state
    try {
      final appState = FFAppState();
      appState.update(() {
        appState.isInitializing = false;
        appState.isDownloading = false;
        appState.downloadProgress = 'Recovery failed. Please restart the app.';
      });
    } catch (stateError) {
      print(
          'recoverFromInitializationError: Critical error - could not reset state: $stateError');
    }
  }
}

/// Check if the system is in an error state that needs recovery
///
/// This helper function can be used to determine if error recovery
/// should be offered to the user.
///
/// ## Returns:
/// - true: System is in error state and needs recovery
/// - false: System is in normal state
///
/// ## Example:
/// ```dart
/// final needsRecovery = await isInErrorState();
/// if (needsRecovery) {
///   // Show "Try Again" button
/// }
/// ```
Future<bool> isInErrorState() async {
  try {
    final appState = FFAppState();

    // Check for various error conditions
    final hasErrorProgress =
        appState.downloadProgress.toLowerCase().contains('error') ||
            appState.downloadProgress.toLowerCase().contains('failed');

    final isStuckInitializing = appState.isInitializing &&
        !appState.isDownloading &&
        !appState.isModelInitialized;

    final hasPartialState =
        (appState.isDownloading || appState.isInitializing) &&
            appState.downloadPercentage == 0.0 &&
            appState.downloadProgress.isEmpty;

    return hasErrorProgress || isStuckInitializing || hasPartialState;
  } catch (e) {
    print('isInErrorState: Error checking state: $e');
    return true; // Assume error state if we can't check
  }
}
