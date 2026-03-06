import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'gemma_model_selector_component_model.dart';
export 'gemma_model_selector_component_model.dart';

class GemmaModelSelectorComponentWidget extends StatefulWidget {
  const GemmaModelSelectorComponentWidget({super.key});

  @override
  State<GemmaModelSelectorComponentWidget> createState() =>
      _GemmaModelSelectorComponentWidgetState();
}

class _GemmaModelSelectorComponentWidgetState
    extends State<GemmaModelSelectorComponentWidget> {
  late GemmaModelSelectorComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GemmaModelSelectorComponentModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
        padding: EdgeInsets.all(24.0),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.GemmaModelSelectorWidget(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            onConfigSaved: (modelUrl, authToken) async {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
