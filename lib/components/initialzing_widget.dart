import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'initialzing_model.dart';
export 'initialzing_model.dart';

/// A component showing download progress, with a progress bar and a line of
/// text
class InitialzingWidget extends StatefulWidget {
  const InitialzingWidget({super.key});

  @override
  State<InitialzingWidget> createState() => _InitialzingWidgetState();
}

class _InitialzingWidgetState extends State<InitialzingWidget>
    with TickerProviderStateMixin {
  late InitialzingModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InitialzingModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      while (true) {
        await Future.delayed(
          Duration(
            milliseconds: 2000,
          ),
        );
        safeSetState(() {});
      }
    });

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: Color(0x80FFFFFF),
            angle: 0.524,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // Check if this is an error state
    final isError =
        FFAppState().downloadProgress.toLowerCase().startsWith('error');

    // If error, show error UI with action buttons
    if (isError) {
      return _buildErrorWidget(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: [
              BoxShadow(
                blurRadius: 3.0,
                color: Color(0x33000000),
                offset: Offset(
                  0.0,
                  1.0,
                ),
                spreadRadius: 0.0,
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        () {
                          if (FFAppState().isDownloading) {
                            return 'Downloading...';
                          } else if (FFAppState().isInitializing) {
                            return 'Initializing...';
                          } else {
                            return FFAppState().downloadProgress;
                          }
                        }(),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                    ),
                    Text(
                      valueOrDefault<String>(
                        '${valueOrDefault<String>(
                          formatNumber(
                            FFAppState().downloadPercentage,
                            formatType: FormatType.custom,
                            format: '###.0',
                            locale: 'en_US',
                          ),
                          '0',
                        )}%',
                        '0%',
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primary,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ],
                ),
                Flexible(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).accent1,
                          FlutterFlowTheme.of(context).primary
                        ],
                        stops: [
                          valueOrDefault<double>(
                            FFAppState().downloadPercentage,
                            0.0,
                          ),
                          1.0
                        ],
                        begin: AlignmentDirectional(1.0, 0.0),
                        end: AlignmentDirectional(-1.0, 0),
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ).animateOnPageLoad(
                      animationsMap['containerOnPageLoadAnimation']!),
                ),
                Flexible(
                  child: Text(
                    _getModelDisplayName(FFAppState().downloadUrl),
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                  ),
                ),
              ].divide(SizedBox(height: 12.0)),
            ),
          ),
        ),
      ),
    );
  }

  /// Build error widget with action buttons
  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).error.withAlpha(25),
            boxShadow: [
              BoxShadow(
                blurRadius: 3.0,
                color: Color(0x33000000),
                offset: Offset(0.0, 1.0),
                spreadRadius: 0.0,
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).error.withAlpha(76),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error icon and message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: FlutterFlowTheme.of(context).error,
                      size: 24.0,
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        FFAppState().downloadProgress,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                              ),
                              color: FlutterFlowTheme.of(context).error,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                // Action button - only "Go Back" to navigate back
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Reset state and navigate back
                      FFAppState().update(() {
                        FFAppState().isDownloading = false;
                        FFAppState().isInitializing = false;
                        FFAppState().downloadProgress = '';
                        FFAppState().downloadPercentage = 0.0;
                      });
                      // Navigate back using FlutterFlow's safePop
                      context.safePop();
                    },
                    icon: Icon(Icons.arrow_back, size: 18.0),
                    label: Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get human-readable model name from URL
  String _getModelDisplayName(String url) {
    final urlLower = url.toLowerCase();

    if (urlLower.contains('gemma-3n-e4b') || urlLower.contains('gemma-3n_e4b')) {
      return 'Gemma 3n E4B (4B, Vision)';
    } else if (urlLower.contains('gemma-3n-e2b') || urlLower.contains('gemma-3n_e2b')) {
      return 'Gemma 3n E2B (2B, Vision)';
    } else if (urlLower.contains('gemma-3-1b') || urlLower.contains('gemma3-1b')) {
      return 'Gemma 3 1B (Text-only)';
    } else if (urlLower.contains('functiongemma')) {
      return 'FunctionGemma 270M';
    } else if (urlLower.contains('gemma')) {
      // Try to extract a readable name from the URL
      final uri = Uri.tryParse(url);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        // Get the filename without extension
        final filename = uri.pathSegments.last.split('.').first;
        return filename.replaceAll('-', ' ').replaceAll('_', ' ');
      }
      return 'Gemma Model';
    }

    return 'AI Model';
  }
}
