import '/flutter_flow/flutter_flow_util.dart';
import 'hf_token_widget.dart' show HfTokenWidget;
import 'package:flutter/material.dart';

class HfTokenModel extends FlutterFlowModel<HfTokenWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Token widget.
  final tokenKey = GlobalKey();
  FocusNode? tokenFocusNode;
  TextEditingController? tokenTextController;
  String? tokenSelectedOption;
  late bool tokenVisibility;
  String? Function(BuildContext, String?)? tokenTextControllerValidator;

  @override
  void initState(BuildContext context) {
    tokenVisibility = false;
  }

  @override
  void dispose() {
    tokenFocusNode?.dispose();
  }
}
