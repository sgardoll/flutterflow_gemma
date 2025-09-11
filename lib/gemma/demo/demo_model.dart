import '/components/initialzing_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'demo_widget.dart' show DemoWidget;
import 'package:flutter/material.dart';

class DemoModel extends FlutterFlowModel<DemoWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - initializeGemmaModelAction] action in Demo widget.
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
