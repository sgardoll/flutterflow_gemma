import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';

Future loadSetInitialiseModel(
  BuildContext context, {
  String? downloadUrl,
  String? hfToken,
}) async {
  await actions.aiInitialize(
    downloadUrl ?? '',
    hfToken,
    '',
    'gpu',
    0.8,
  );
}
