import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'setup_model.dart';
export 'setup_model.dart';

class SetupWidget extends StatefulWidget {
  const SetupWidget({super.key});

  static String routeName = 'Setup';
  static String routePath = '/setup';

  @override
  State<SetupWidget> createState() => _SetupWidgetState();
}

class _SetupWidgetState extends State<SetupWidget> {
  late SetupModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetupModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'Download Gemma',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            decoration: BoxDecoration(),
            child: Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: MediaQuery.sizeOf(context).height * 1.0,
              child: custom_widgets.GemmaAuthenticatedSetupWidget(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: MediaQuery.sizeOf(context).height * 1.0,
                modelName: 'gemma-3-4b-it',
                huggingFaceToken: FFAppState().hfToken,
                preferredBackend: 'gpu',
                maxTokens: 1024,
                supportImage: true,
                maxNumImages: 1,
                primaryColor: FlutterFlowTheme.of(context).primary,
                backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
                textColor: FlutterFlowTheme.of(context).primaryText,
                onSetupComplete: () async {
                  context.pushNamed(HomePageWidget.routeName);

                  await actions.installGemmaFromAsset(
                    '',
                    '',
                  );
                },
                onSetupFailed: (error) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Setup Failed',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                      duration: Duration(milliseconds: 4000),
                      backgroundColor: FlutterFlowTheme.of(context).secondary,
                    ),
                  );
                },
                onProgress: (progress) async {
                  _model.downloadProgress =
                      ((progress ?? 0) / 100.0).clamp(0.0, 1.0);
                  safeSetState(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
