import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/create_gemma_session.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'setup_widget.dart' show SetupWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SetupModel extends FlutterFlowModel<SetupWidget> {
  ///  Local state fields for this page.

  double? downloadProgress = 0.0;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - createGemmaSession] action in GemmaAuthenticatedSetupWidget widget.
  bool? createSessionOutput;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
