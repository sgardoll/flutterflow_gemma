import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'hf_token_widget.dart' show HfTokenWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HfTokenModel extends FlutterFlowModel<HfTokenWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Token widget.
  FocusNode? tokenFocusNode;
  TextEditingController? tokenTextController;
  late bool tokenVisibility;
  String? Function(BuildContext, String?)? tokenTextControllerValidator;

  @override
  void initState(BuildContext context) {
    tokenVisibility = false;
  }

  @override
  void dispose() {
    tokenFocusNode?.dispose();
    tokenTextController?.dispose();
  }
}
