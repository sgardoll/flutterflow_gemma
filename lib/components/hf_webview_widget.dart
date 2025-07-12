import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_web_view.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'hf_webview_model.dart';
export 'hf_webview_model.dart';

/// a small popup where a user can enter their Hugging Face Token.
///
/// Should be coloured like the Hugging Face logo and include their logo
class HfWebviewWidget extends StatefulWidget {
  const HfWebviewWidget({super.key});

  @override
  State<HfWebviewWidget> createState() => _HfWebviewWidgetState();
}

class _HfWebviewWidgetState extends State<HfWebviewWidget> {
  late HfWebviewModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HfWebviewModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 2.0,
        sigmaY: 2.0,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
        child: Container(
          width: 320.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: [
              BoxShadow(
                blurRadius: 24.0,
                color: FlutterFlowTheme.of(context).secondaryText,
                offset: Offset(
                  0.0,
                  0.0,
                ),
                spreadRadius: 12.0,
              )
            ],
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Align(
                alignment: AlignmentDirectional(-1.0, -1.0),
                child: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 8.0,
                  borderWidth: 1.0,
                  buttonSize: 40.0,
                  fillColor: Color(0xFFFF9D00),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.0,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ),
              Flexible(
                child: FlutterFlowWebView(
                  content: 'https://huggingface.co/settings/tokens',
                  bypass: false,
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: 500.0,
                  verticalScroll: false,
                  horizontalScroll: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
