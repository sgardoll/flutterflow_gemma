import '/flutter_flow/flutter_flow_util.dart';
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
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: MediaQuery.sizeOf(context).height * 1.0,
      child: custom_widgets.GemmaModelSelectorWidget(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        onConfigSaved: (modelUrl, authToken) async {
          FFAppState().downloadUrl = modelUrl;
          FFAppState().hfToken = modelUrl;
          safeSetState(() {});
        },
      ),
    );
  }
}
