import '/components/initialzing_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/flutter_gemma_library.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'demo_model.dart';
export 'demo_model.dart';

class DemoWidget extends StatefulWidget {
  const DemoWidget({super.key});

  static String routeName = 'Demo';
  static String routePath = '/demo';

  @override
  State<DemoWidget> createState() => _DemoWidgetState();
}

class _DemoWidgetState extends State<DemoWidget> {
  late DemoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DemoModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if ((FFLibraryValues().modelDownloadUrl != null &&
              FFLibraryValues().modelDownloadUrl != '') &&
          (FFLibraryValues().huggingFaceToken != null &&
              FFLibraryValues().huggingFaceToken != '')) {
        FFAppState().hfToken = FFLibraryValues().huggingFaceToken!;
        FFAppState().downloadUrl = FFLibraryValues().modelDownloadUrl!;
        safeSetState(() {});
      }
      _model.initAction = await actions.initializeGemmaModelAction(
        FFAppState().downloadUrl,
        FFAppState().hfToken,
        '',
        'gpu',
        0.8,
      );
      if (_model.initAction!) {
        safeSetState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
          backgroundColor: FlutterFlowTheme.of(context).accent4,
          iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
          automaticallyImplyLeading: false,
          actions: [
            FlutterFlowIconButton(
              borderRadius: 8.0,
              buttonSize: 40.0,
              icon: Icon(
                Icons.info_outlined,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 24.0,
              ),
              onPressed: () async {
                context.pushNamed(LicenseWidget.routeName);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: AutoSizeText(
              'Gemma 3n Demo',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.openSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).titleLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).titleLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    lineHeight: 0.9,
                  ),
            ),
            centerTitle: true,
            expandedTitleScale: 1.0,
          ),
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: MediaQuery.sizeOf(context).height * 1.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  child: custom_widgets.GemmaChatWidget(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    showImageButton:
                        FlutterGemmaLibrary.instance.supportsVision,
                    onMessageSent: (message, response) async {},
                    onError: (errorMessage) async {},
                    onChangeModel: () async {},
                  ),
                ),
              ),
              if (!valueOrDefault<bool>(
                    FFAppState().isModelInitialized,
                    true,
                  ) &&
                  ((FFAppState().hfToken != '') ||
                      (FFAppState().downloadUrl != '')) &&
                  (FFAppState().isModelInitialized != true))
                wrapWithModel(
                  model: _model.initialzingModel,
                  updateCallback: () => safeSetState(() {}),
                  child: InitialzingWidget(),
                ),
              if ((FFAppState().hfToken == '') &&
                  (FFAppState().downloadUrl == ''))
                Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  child: custom_widgets.ModelConfigurationWidget(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
