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
import 'package:url_launcher/url_launcher.dart';
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
      // Check if library values are configured
      final modelUrl = FFLibraryValues().modelDownloadUrl;
      final hfToken = FFLibraryValues().huggingFaceToken;

      final needsModelUrl = modelUrl.isEmpty;
      final needsToken = hfToken == null || hfToken.isEmpty;

      // If values are missing, show configuration modal
      if (needsModelUrl || needsToken) {
        final result = await _showConfigurationModal(
          context,
          needsModelUrl: needsModelUrl,
          needsToken: needsToken,
          currentModelUrl: modelUrl,
          currentToken: hfToken,
        );

        if (result == null) {
          // User cancelled - go back
          if (mounted) {
            context.safePop();
          }
          return;
        }

        // Update library values with user input
        if (result['modelUrl'] != null && result['modelUrl']!.isNotEmpty) {
          FFLibraryValues().modelDownloadUrl = result['modelUrl']!;
        }
        if (result['token'] != null && result['token']!.isNotEmpty) {
          FFLibraryValues().huggingFaceToken = result['token']!;
        }
      }

      // Now proceed with initialization
      FFAppState().hfToken = FFLibraryValues().huggingFaceToken ?? '';
      FFAppState().downloadUrl = FFLibraryValues().modelDownloadUrl;
      safeSetState(() {});
      _model.initAction = await actions.initializeGemmaModelAction(
        FFLibraryValues().modelDownloadUrl,
        FFLibraryValues().huggingFaceToken,
        '',
        'gpu',
        0.8,
      );
      if (_model.initAction!) {
        safeSetState(() {});
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

  /// Show configuration modal for missing library values
  Future<Map<String, String>?> _showConfigurationModal(
    BuildContext context, {
    required bool needsModelUrl,
    required bool needsToken,
    String? currentModelUrl,
    String? currentToken,
  }) async {
    final modelUrlController = TextEditingController(text: currentModelUrl ?? '');
    final tokenController = TextEditingController(text: currentToken ?? '');
    String? selectedModel;

    // Default models from README
    final defaultModels = {
      'Gemma 3n E4B (4B, Vision)': 'https://huggingface.co/google/gemma-3n-E4B-it-litert-lm/resolve/main/gemma-3n-E4B-it-int4.litertlm',
      'Gemma 3n E2B (2B, Vision)': 'https://huggingface.co/google/gemma-3n-E2B-it-litert-lm/resolve/main/gemma-3n-E2B-it-int4.litertlm',
      'Gemma 3 1B (Text-only)': 'https://huggingface.co/google/gemma-3-1b-it-litert-lm/resolve/main/gemma-3-1b-it-int4.litertlm',
      'FunctionGemma 270M': 'https://huggingface.co/nickschu/functiongemma-270m-it-litert/resolve/main/functiongemma-270m-it-int4.litertlm',
    };

    return showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Configure Gemma Model',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (needsModelUrl) ...[
                      Text(
                        'Select a model or enter a custom URL:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Default model selection
                      ...defaultModels.entries.map((entry) {
                        final isSelected = selectedModel == entry.key;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedModel = entry.key;
                                modelUrlController.text = entry.value;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? FlutterFlowTheme.of(context).primary.withAlpha(25)
                                    : FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? FlutterFlowTheme.of(context).primary
                                      : FlutterFlowTheme.of(context).alternate,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected
                                        ? FlutterFlowTheme.of(context).primary
                                        : FlutterFlowTheme.of(context).secondaryText,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 8),
                      // Custom URL option
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedModel = 'custom';
                            modelUrlController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedModel == 'custom'
                                ? FlutterFlowTheme.of(context).primary.withAlpha(25)
                                : FlutterFlowTheme.of(context).secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedModel == 'custom'
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).alternate,
                              width: selectedModel == 'custom' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedModel == 'custom' ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: selectedModel == 'custom'
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).secondaryText,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Custom URL',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: selectedModel == 'custom' ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (selectedModel == 'custom') ...[
                        SizedBox(height: 12),
                        TextField(
                          controller: modelUrlController,
                          decoration: InputDecoration(
                            labelText: 'Model URL',
                            hintText: 'https://huggingface.co/...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ],
                      SizedBox(height: 16),
                    ],
                    if (needsToken) ...[
                      Text(
                        'HuggingFace Token (required for download):',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: tokenController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'HuggingFace Token',
                          hintText: 'hf_...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.open_in_new, size: 20),
                            onPressed: () {
                              launchUrl(Uri.parse('https://huggingface.co/settings/tokens'));
                            },
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Get your token at huggingface.co/settings/tokens',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final modelUrl = modelUrlController.text.trim();
                    final token = tokenController.text.trim();

                    // Validate required fields
                    if (needsModelUrl && modelUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select or enter a model URL')),
                      );
                      return;
                    }
                    if (needsToken && token.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your HuggingFace token')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop({
                      'modelUrl': modelUrl,
                      'token': token,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  child: custom_widgets.GemmaChatWidget(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    showImageButton:
                        FlutterGemmaLibrary.instance.supportsVision,
                    onMessageSent: (message, response) async {},
                  ),
                ),
              ),
              if (!valueOrDefault<bool>(
                FFAppState().isModelInitialized,
                true,
              ))
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
