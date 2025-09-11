import '/components/initialzing_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/flutter_gemma_library.dart';
import '/custom_code/model_file_manager.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'demo_widget.dart' show DemoWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DemoModel extends FlutterFlowModel<DemoWidget> {
  ///  Local state fields for this page.

  FlutterGemmaLibrary? flutterGemmaLibrary;

  ModelFileManager? modelManager;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - downloadNetworkPath] action in Demo widget.
  String? fileDownloaded;
  // Stores action output result for [Custom Action - setModelAction] action in Demo widget.
  bool? setActionAndroid;
  // Stores action output result for [Custom Action - downloadModelAction] action in Demo widget.
  String? downloadAction;
  // Stores action output result for [Custom Action - setModelAction] action in Demo widget.
  bool? setAction;
  // Stores action output result for [Custom Action - initializeModelAction] action in Demo widget.
  bool? initAction;
  // Model for Initialzing component.
  late InitialzingModel initialzingModel;

  @override
  void initState(BuildContext context) {
    initialzingModel = createModel(context, () => InitialzingModel());
  }

  @override
  void dispose() {
    initialzingModel.dispose();
  }
}
