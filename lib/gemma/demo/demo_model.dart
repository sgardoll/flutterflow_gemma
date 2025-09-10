import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/flutter_gemma_library.dart';
import '/custom_code/model_file_manager.dart';
import 'demo_widget.dart' show DemoWidget;
import 'package:flutter/material.dart';

class DemoModel extends FlutterFlowModel<DemoWidget> {
  ///  Local state fields for this page.

  FlutterGemmaLibrary? flutterGemmaLibrary;

  ModelFileManager? modelManager;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - downloadModelAction] action in Demo widget.
  String? downloadAction;
  // Stores action output result for [Custom Action - setModelAction] action in Demo widget.
  bool? setAction;
  // Stores action output result for [Custom Action - initializeModelAction] action in Demo widget.
  bool? initAction;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
