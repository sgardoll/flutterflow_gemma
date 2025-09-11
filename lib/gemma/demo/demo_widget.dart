import '/components/initialzing_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/flutter_gemma_library.dart';
import '/custom_code/model_file_manager.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
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
      if (isAndroid) {
        _model.fileDownloaded = await actions.downloadNetworkPath(
          'http://10.0.2.2:8000/gemma-3n-E2B-it-int4.task',
        );
        _model.setActionAndroid = await actions.setModelAction(
          _model.fileDownloaded!,
        );
      } else {
        _model.downloadAction = await actions.downloadModelAction(
          FFLibraryValues().huggingFaceToken,
          FFLibraryValues().modelDownloadUrl,
          (downloadProgress) async {
            FFAppState().downloadProgress = downloadProgress;
            safeSetState(() {});
          },
        );
        _model.setAction = await actions.setModelAction(
          _model.downloadAction!,
        );
      }

      _model.initAction = await actions.initializeModelAction(
        null,
        'gpu',
        1024,
        0.8,
        1,
        1,
      );
      if (_model.initAction!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Initialized Successfully',
              style: GoogleFonts.interTight(
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            duration: Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Initialization Error',
              style: GoogleFonts.interTight(
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            duration: Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );
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
          actions: [],
          flexibleSpace: FlexibleSpaceBar(
            title: AutoSizeText(
              'Gemma 3n Demo',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.interTight(
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
                  width: double.infinity,
                  height: double.infinity,
                  child: custom_widgets.GemmaChatWidget(
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: 'Enter text here...',
                    onMessageSent: (message, response) async {},
                  ),
                ),
              ),
              wrapWithModel(
                model: _model.initialzingModel,
                updateCallback: () => safeSetState(() {}),
                child: InitialzingWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
