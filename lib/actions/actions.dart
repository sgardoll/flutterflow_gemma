import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/flutter_gemma_library.dart';
import 'package:flutter/material.dart';

Future loadSetInitialiseModel(
  BuildContext context, {
  String? downloadUrl,
  String? hfToken,
}) async {
  String? loadAction;
  bool? setAction;
  bool? initAction;

  loadAction = await actions.downloadModelAction(
    hfToken,
    downloadUrl!,
    (downloadProgress) async {
      FFAppState().downloadProgress = downloadProgress;
    },
  );
  setAction = await actions.setModelAction(
    loadAction!,
  );
  initAction = await actions.initializeModelAction(
    FlutterGemmaLibrary.instance.currentModelType,
    FlutterGemmaLibrary.instance.currentBackend!,
    FlutterGemmaLibrary.instance.plugin.initializedModel?.maxTokens,
    1.0,
    0,
    1,
  );
}
