import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:gemma/custom_code/GemmaManager.dart';
import 'setup_widget.dart' show SetupWidget;
import 'package:flutter/material.dart';

class SetupModel extends FlutterFlowModel<SetupWidget> {
  ///  Local state fields for this page.

  GemmaManager? classSupport;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - getDownloadedModels] action in Setup widget.
  List<dynamic>? downloadedModels;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
