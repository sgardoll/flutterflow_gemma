// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import '../ai_rust_api.dart';

/// Return device/runtime capability information.
///
/// Use this to guide model selection — e.g. show GPU-only models only when
/// the device supports GPU acceleration.
///
/// ## Returns `Future<dynamic>` — a `Map<String, dynamic>` with keys: -
/// `supportsGpu` (bool) - `supportsCpu` (bool) - `supportsTpu` (bool) -
/// `recommendedBackend` (String? — 'gpu' | 'cpu' | 'npu' | null) - `platform`
/// (String — 'ios' | 'android' | 'web' | 'other')
Future<dynamic> aiGetDeviceCapabilities() async {
  return AiRustApi.instance.getDeviceCapabilities().toMap();
}
