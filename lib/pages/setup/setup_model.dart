import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'setup_widget.dart' show SetupWidget;
import 'package:flutter/material.dart';

class SetupModel extends FlutterFlowModel<SetupWidget> {
  ///  Local state fields for this page.

  double? progress = 0.0;

  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
