import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? imageSelected;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - sendGemmaMessage] action in GemmaChatWidget widget.
  String? sendMessageOutput;
  // Stores action output result for [Custom Action - sendGemmaMessageWithImage] action in GemmaChatWidget widget.
  String? sendMessageWithImageOutput;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
