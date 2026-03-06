import '/components/gemma_model_selector_component_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
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
      } else {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (dialogContext) {
            return Dialog(
              elevation: 0,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              alignment: AlignmentDirectional(0.0, 0.0)
                  .resolve(Directionality.of(context)),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(dialogContext).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: GemmaModelSelectorComponentWidget(),
              ),
            );
          },
        );
      }

      if (!(FFAppState().isModelInitialized &&
          (FFAppState().hfToken != '') &&
          (FFAppState().downloadUrl != ''))) {
        _model.init = await actions.aiInitialize(
          FFAppState().downloadUrl,
          FFAppState().hfToken,
          '',
          'gpu',
          0.8,
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

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          appBar: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).accent4,
            iconTheme:
                IconThemeData(color: FlutterFlowTheme.of(context).primary),
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
                'On-Device AI Demo',
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
            child: Builder(
              builder: (context) {
                if (FFAppState().isModelInitialized) {
                  return Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    child: custom_widgets.GemmaChatRuntimeWidget(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      placeholder: 'Type your prompt here',
                      showImageButton: null,
                      onMessageSent: (message, response) async {},
                      onError: (errorMessage) async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMessage,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.lato(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            duration: Duration(milliseconds: 4000),
                            backgroundColor:
                                FlutterFlowTheme.of(context).secondary,
                          ),
                        );
                      },
                      onChangeModel: () async {},
                    ),
                  );
                } else {
                  return Builder(
                    builder: (context) => Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 300.0,
                      child: custom_widgets.GemmaSetupStatusWidget(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        height: 300.0,
                        onRetry: () async {
                          _model.initRetry = await actions.aiInitialize(
                            FFAppState().downloadUrl,
                            FFAppState().hfToken,
                            '',
                            'gpu',
                            0.8,
                          );

                          safeSetState(() {});
                        },
                        onSelectModel: () async {
                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return Dialog(
                                elevation: 0,
                                insetPadding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                alignment: AlignmentDirectional(0.0, 0.0)
                                    .resolve(Directionality.of(context)),
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  child: GemmaModelSelectorComponentWidget(),
                                ),
                              );
                            },
                          );

                          _model.reInit = await actions.aiInitialize(
                            FFAppState().downloadUrl,
                            FFAppState().hfToken,
                            '',
                            'gpu',
                            0.8,
                          );

                          safeSetState(() {});
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
