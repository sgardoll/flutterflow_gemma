import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'license_model.dart';
export 'license_model.dart';

class LicenseWidget extends StatefulWidget {
  const LicenseWidget({super.key});

  static String routeName = 'LICENSE';
  static String routePath = '/license';

  @override
  State<LicenseWidget> createState() => _LicenseWidgetState();
}

class _LicenseWidgetState extends State<LicenseWidget>
    with TickerProviderStateMixin {
  late LicenseModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LicenseModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment(0.0, 0),
                            child: FlutterFlowButtonTabBar(
                              useToggleButtonStyle: true,
                              labelStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
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
                              unselectedLabelStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                              labelColor:
                                  FlutterFlowTheme.of(context).primaryText,
                              unselectedLabelColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).accent1,
                              unselectedBackgroundColor:
                                  FlutterFlowTheme.of(context).accent4,
                              borderColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              unselectedBorderColor:
                                  FlutterFlowTheme.of(context).alternate,
                              borderWidth: 2.0,
                              borderRadius: 8.0,
                              elevation: 0.0,
                              buttonMargin: EdgeInsetsDirectional.fromSTEB(
                                  8.0, 0.0, 8.0, 0.0),
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  56.0, 0.0, 0.0, 0.0),
                              tabs: [
                                Tab(
                                  text: 'Terms of Use',
                                ),
                                Tab(
                                  text: 'Prohibited\nUse Policy',
                                ),
                                Tab(
                                  text: 'Intended Use \n  Statement',
                                ),
                              ],
                              controller: _model.tabBarController,
                              onTap: (i) async {
                                [() async {}, () async {}, () async {}][i]();
                              },
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _model.tabBarController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Flex(
                                    direction: Axis.vertical,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 8.0, 0.0, 0.0),
                                        child: Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              1.0,
                                          child: custom_widgets.MarkdownWidget(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: MediaQuery.sizeOf(context)
                                                    .height *
                                                1.0,
                                            mdcolor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            data:
                                                'Gemma Terms of Use\n\nLast modified: March 24, 2025\n\nBy using, reproducing, modifying, distributing, performing or displaying any portion or element of Gemma, Model Derivatives including via any Hosted Service, (each as defined below) (collectively, the \"**Gemma Services**\") or otherwise accepting the terms of this Agreement, you agree to be bound by this Agreement.\n\n## Section 1: DEFINITIONS\n\n### 1.1 Definitions\n\n(a) \"**Agreement**\" or \"**Gemma Terms of Use**\" means these terms and conditions that govern the use, reproduction, Distribution or modification of the Gemma Services and any terms and conditions incorporated by reference.\n\n(b) \"**Distribution**\" or \"**Distribute**\" means any transmission, publication, or other sharing of Gemma or Model Derivatives to a third party, including by providing or making Gemma or its functionality available as a hosted service via API, web access, or any other electronic or remote means (\"**Hosted Service**\").\n\n(c) \"**Gemma**\" means the set of machine learning language models, trained model weights and parameters identified in the [Appendix](https://ai.google.dev/gemma/terms#appendix), regardless of the source that you obtained it from.\n\n(d) \"**Google**\" means Google LLC.\n\n(e) \"**Model Derivatives**\" means all (i) modifications to Gemma, (ii) works based on Gemma, or (iii) any other machine learning model which is created by transfer of patterns of the weights, parameters, operations, or Output of Gemma, to that model in order to cause that model to perform similarly to Gemma, including distillation methods that use intermediate data representations or methods based on the generation of synthetic data Outputs by Gemma for training that model. For clarity, Outputs are not deemed Model Derivatives.\n\n(f) \"**Output**\" means the information content output of Gemma or a Model Derivative that results from operating or otherwise using Gemma or the Model Derivative, including via a Hosted Service.\n\n### 1.2\n\nAs used in this Agreement, \"**including**\" means \"**including without limitation**\".\n\n## Section 2: ELIGIBILITY AND USAGE\n\n### 2.1 Eligibility\n\nYou represent and warrant that you have the legal capacity to enter into this Agreement (including being of sufficient age of consent). If you are accessing or using any of the Gemma Services for or on behalf of a legal entity, (a) you are entering into this Agreement on behalf of yourself and that legal entity, (b) you represent and warrant that you have the authority to act on behalf of and bind that entity to this Agreement and (c) references to \"**you**\" or \"**your**\" in the remainder of this Agreement refers to both you (as an individual) and that entity.\n\n### 2.2 Use\n\nYou may use, reproduce, modify, Distribute, perform or display any of the Gemma Services only in accordance with the terms of this Agreement, and must not violate (or encourage or permit anyone else to violate) any term of this Agreement.\n\n## Section 3: DISTRIBUTION AND RESTRICTIONS\n\n### 3.1 Distribution and Redistribution\n\nYou may reproduce or Distribute copies of Gemma or Model Derivatives if you meet all of the following conditions:\n\n1. You must include the use restrictions referenced in Section 3.2 as an enforceable provision in any agreement (e.g., license agreement, terms of use, etc.) governing the use and/or distribution of Gemma or Model Derivatives and you must provide notice to subsequent users you Distribute to that Gemma or Model Derivatives are subject to the use restrictions in Section 3.2.  \n2. You must provide all third party recipients of Gemma or Model Derivatives a copy of this Agreement.  \n3. You must cause any modified files to carry prominent notices stating that you modified the files.  \n4. All Distributions (other than through a Hosted Service) must be accompanied by a \"**Notice**\" text file that contains the following notice: \"**Gemma is provided under and subject to the Gemma Terms of Use found at ai.google.dev/gemma/terms**\".\n\nYou may add your own intellectual property statement to your modifications and, except as set forth in this Section, may provide additional or different terms and conditions for use, reproduction, or Distribution of your modifications, or for any such Model Derivatives as a whole, provided your use, reproduction, modification, Distribution, performance, and display of Gemma otherwise complies with the terms and conditions of this Agreement. Any additional or different terms and conditions you impose must not conflict with the terms of this Agreement.\n\n### 3.2 Use Restrictions\n\nYou must not use any of the Gemma Services:\n\n1. for the restricted uses set forth in the Gemma Prohibited Use Policy at [ai.google.dev/gemma/prohibited\\_use\\_policy](https://ai.google.dev/gemma/prohibited_use_policy) (\"**Prohibited Use Policy**\"), which is hereby incorporated by reference into this Agreement; or  \n2. in violation of applicable laws and regulations.\n\nTo the maximum extent permitted by law, Google reserves the right to restrict (remotely or otherwise) usage of any of the Gemma Services that Google reasonably believes are in violation of this Agreement.\n\n### 3.3 Generated Output\n\nGoogle claims no rights in Outputs you generate using Gemma. You and your users are solely responsible for Outputs and their subsequent uses.\n\n## Section 4: ADDITIONAL PROVISIONS\n\n### 4.1 Updates\n\nGoogle may update Gemma from time to time.\n\n### 4.2 Trademarks\n\nNothing in this Agreement grants you any rights to use Google\'s trademarks, trade names, logos or to otherwise suggest endorsement or misrepresent the relationship between you and Google. Google reserves any rights not expressly granted herein.\n\n### 4.3 DISCLAIMER OF WARRANTY\n\nUNLESS REQUIRED BY APPLICABLE LAW, THE GEMMA SERVICES, AND OUTPUTS, ARE PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. YOU ARE SOLELY RESPONSIBLE FOR DETERMINING THE APPROPRIATENESS OF USING, REPRODUCING, MODIFYING, PERFORMING, DISPLAYING OR DISTRIBUTING ANY OF THE GEMMA SERVICES OR OUTPUTS AND ASSUME ANY AND ALL RISKS ASSOCIATED WITH YOUR USE OR DISTRIBUTION OF ANY OF THE GEMMA SERVICES OR OUTPUTS AND YOUR EXERCISE OF RIGHTS AND PERMISSIONS UNDER THIS AGREEMENT.\n\n### 4.4 LIMITATION OF LIABILITY\n\nTO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT AND UNDER NO LEGAL THEORY, WHETHER IN TORT (INCLUDING NEGLIGENCE), PRODUCT LIABILITY, CONTRACT, OR OTHERWISE, UNLESS REQUIRED BY APPLICABLE LAW, SHALL GOOGLE OR ITS AFFILIATES BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, EXEMPLARY, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR LOST PROFITS OF ANY KIND ARISING FROM THIS AGREEMENT OR RELATED TO, ANY OF THE GEMMA SERVICES OR OUTPUTS EVEN IF GOOGLE OR ITS AFFILIATES HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.\n\n### 4.5 Term, Termination, and Survival\n\nThe term of this Agreement will commence upon your acceptance of this Agreement (including acceptance by your use, modification, or Distribution, reproduction, performance or display of any portion or element of the Gemma Services) and will continue in full force and effect until terminated in accordance with the terms of this Agreement. Google may terminate this Agreement if you are in breach of any term of this Agreement. Upon termination of this Agreement, you must delete and cease use and Distribution of all copies of Gemma and Model Derivatives in your possession or control. Sections 1, 2.1, 3.3, 4.2 to 4.9 shall survive the termination of this Agreement.\n\n### 4.6 Governing Law and Jurisdiction\n\nThis Agreement will be governed by the laws of the State of California without regard to choice of law principles. The UN Convention on Contracts for the International Sale of Goods does not apply to this Agreement. The state and federal courts of Santa Clara County, California shall have exclusive jurisdiction of any dispute arising out of this Agreement.\n\n### 4.7 Severability\n\nIf any provision of this Agreement is held to be invalid, illegal or unenforceable, the remaining provisions shall be unaffected thereby and remain valid as if such provision had not been set forth herein.\n\n### 4.8 Entire Agreement\n\nThis Agreement states all the terms agreed between the parties and supersedes all other agreements between the parties as of the date of acceptance relating to its subject matter.\n\n### 4.9 No Waiver\n\nGoogle will not be treated as having waived any rights by not exercising (or delaying the exercise of) any rights under this Agreement.\n\n## Appendix\n\n* [Gemma 1](https://ai.google.dev/gemma/docs/core/model_card)  \n* [Gemma 1.1](https://ai.google.dev/gemma/docs/core/model_card)  \n* [Gemma 2](https://ai.google.dev/gemma/docs/core/model_card_2)  \n* [Gemma 3](https://ai.google.dev/gemma/docs/core/model_card_3)  \n* [Gemma 3n](https://ai.google.dev/gemma/docs/3n)  \n* [EmbeddingGemma](https://ai.google.dev/gemma/docs/embeddinggemma)  \n* [PaliGemma](https://ai.google.dev/gemma/docs/paligemma/model-card)  \n* [PaliGemma 2](https://ai.google.dev/gemma/docs/paligemma/model-card-2)  \n* [ShieldGemma](https://ai.google.dev/gemma/docs/shieldgemma/model_card)  \n* [ShieldGemma 2](https://ai.google.dev/gemma/docs/shieldgemma/model_card_2)  \n* [CodeGemma](https://ai.google.dev/gemma/docs/codegemma/model_card)  \n* [CodeGemma 1.1](https://ai.google.dev/gemma/docs/codegemma/model_card)  \n* [Gemma 2 JPN](https://huggingface.co/google/gemma-2-2b-jpn-it)  \n* [DataGemma RIG](https://www.kaggle.com/models/google/datagemma-rig)  \n* [DataGemma RAG](https://www.kaggle.com/models/google/datagemma-rag)  \n* [RecurrentGemma](https://ai.google.dev/gemma/docs/recurrentgemma/model_card)  \n* [Gemma Scope](https://ai.google.dev/gemma/docs/gemma_scope)  \n* [Gemma-APS](https://ai.google.dev/gemma/docs/gemma-aps)  \n* [T5Gemma](https://www.kaggle.com/models/google/t5gemma)\n\n',
                                            fontFamily: 'Inter',
                                            fontSize: 14.0,
                                            onLinkTap: (title, url) async {},
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Flex(
                                    direction: Axis.vertical,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              1.0,
                                          child: custom_widgets.MarkdownWidget(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: MediaQuery.sizeOf(context)
                                                    .height *
                                                1.0,
                                            mdcolor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            data:
                                                'Gemma Prohibited Use Policy\n\nGoogle reserves the right to update this Gemma Prohibited Use Policy from time to time.\n\nLast modified: February 21, 2024\n\nYou **may not** use nor allow others to use Gemma or Model Derivatives to:\n\n1. Generate any content, including the outputs or results generated by Gemma or Model Derivatives, that infringes, misappropriates, or otherwise violates any individual\'s or entity\'s rights (including, but not limited to rights in copyrighted content).  \n2. Perform or facilitate dangerous, illegal, or malicious activities, including:  \n   1. Facilitation or promotion of illegal activities or violations of law, such as:  \n      1. Promoting or generating content related to child sexual abuse or exploitation;  \n      2. Promoting or facilitating sale of, or providing instructions for synthesizing or accessing, illegal substances, goods, or services;  \n      3. Facilitating or encouraging users to commit any type of crimes; or  \n      4. Promoting or generating violent extremism or terrorist content.  \n   2. Engagement in the illegal or unlicensed practice of any vocation or profession including, but not limited to, legal, medical, accounting, or financial professional practices.  \n   3. Abuse, harm, interference, or disruption of services (or enable others to do the same), such as:  \n      1. Promoting or facilitating the generation or distribution of spam; or  \n      2. Generating content for deceptive or fraudulent activities, scams, phishing, or malware.  \n   4. Attempts to override or circumvent safety filters or intentionally drive Gemma or Model Derivatives to act in a manner that contravenes this Gemma Prohibited Use Policy.  \n   5. Generation of content that may harm or promote the harm of individuals or a group, such as:  \n      1. Generating content that promotes or encourages hatred;  \n      2. Facilitating methods of harassment or bullying to intimidate, abuse, or insult others;  \n      3. Generating content that facilitates, promotes, or incites violence;  \n      4. Generating content that facilitates, promotes, or encourages self harm;  \n      5. Generating personally identifying information for distribution or other harms;  \n      6. Tracking or monitoring people without their consent;  \n      7. Generating content that may have unfair or adverse impacts on people, particularly impacts related to sensitive or protected characteristics; or  \n      8. Generating, gathering, processing, or inferring sensitive personal or private information about individuals without obtaining all rights, authorizations, and consents required by applicable laws.  \n3. Generate and distribute content intended to misinform, misrepresent or mislead, including:  \n   1. Misrepresentation of the provenance of generated content by claiming content was created by a human, or represent generated content as original works, in order to deceive;  \n   2. Generation of content that impersonates an individual (living or dead) without explicit disclosure, in order to deceive;  \n   3. Misleading claims of expertise or capability made particularly in sensitive areas (e.g. health, finance, government services, or legal);  \n   4. Making automated decisions in domains that affect material or individual rights or well-being (e.g., finance, legal, employment, healthcare, housing, insurance, and social welfare);  \n   5. Generation of defamatory content, including defamatory statements, images, or audio content; or  \n   6. Engaging in the unauthorized or unlicensed practice of any profession including, but not limited to, financial, legal, medical/health, or related professional practices.  \n4. Generate sexually explicit content, including content created for the purposes of pornography or sexual gratification (e.g. sexual chatbots). Note that this does not include content created for scientific, educational, documentary, or artistic purposes.\n\n',
                                            fontFamily: 'Inter',
                                            fontSize: 14.0,
                                            onLinkTap: (title, url) async {},
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Flex(
                                    direction: Axis.vertical,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              1.0,
                                          child: custom_widgets.MarkdownWidget(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: MediaQuery.sizeOf(context)
                                                    .height *
                                                1.0,
                                            mdcolor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            data:
                                                '# Intended Use Statement\n\nGemma is a family of cutting-edge open models, intended to be used by developers and researchers as a starting point for building and customizing their own model-based solutions across a variety of domains.\n\n**Note**: Gemma itself is not a finished product and does not perform specific tasks directly. It is a tool for building applications, and users are responsible for training and adapting Gemma to their specific intended use. Gemma is **not intended for any specific use case and is a general purpose starting point, for use by developers and/or researchers for their specific applications and use cases. Users are responsible for complying with all legal and regulatory requirements applicable to their specific applications and use cases.**\n\n**Product Description:**\n\nGemma is a family of cutting-edge AI models that provide a base architecture and a set of pre-trained weights for a wide variety of AI-related tasks. Gemma empowers developers and researchers to create bespoke solutions by training and fine-tuning models with their own data, controls, and domain-specific knowledge. This allows developers and researchers to create customized AI solutions tailored to specific tasks and industries.\n\nFor example, users could potentially build products using Gemma to:\n\n- Tutor K-12 students in mathematics.\n- Create personalized trip planning applications.\n- Analyze, label, or caption images.\n- Generate reports based on medical data.\n- Assist with administrative tasks in healthcare settings, such as summarizing notes or scheduling appointments.\n- Develop tools for home finance management and analysis.\n- Build applications for summarizing and analyzing text, such as books or articles.\n- Create systems for code development and evaluation.\n- Provide and adapt dialog applications for specific languages or cultures.\n- Develop systems for assisting with writing tasks, such as essay composition.\n',
                                            fontFamily: 'Inter',
                                            fontSize: 14.0,
                                            onLinkTap: (title, url) async {},
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                      child: FlutterFlowIconButton(
                        borderRadius: 8.0,
                        buttonSize: 40.0,
                        icon: Icon(
                          Icons.arrow_back,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 24.0,
                        ),
                        onPressed: () async {
                          context.safePop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
