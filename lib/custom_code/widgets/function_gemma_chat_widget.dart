// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import '../flutter_gemma_library.dart';
import '../flutter_gemma_helper.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

/// FunctionGemma Chat Widget for FlutterFlow
///
/// This widget provides a chat interface specifically designed for
/// FunctionGemma models with function calling capabilities.
///
/// It includes: - Visual display of function calls and their results -
/// Support for custom function handlers - Built-in common function
/// definitions - Tool execution status indicators
///
/// ## Usage: 1. Download and initialize a FunctionGemma model
/// (functiongemma-270m-it) 2. Add this widget to your FlutterFlow page 3.
/// Optionally provide custom functions via onFunctionCall callback
class FunctionGemmaChatWidget extends StatefulWidget {
  const FunctionGemmaChatWidget({
    super.key,
    this.width,
    this.height,
    this.placeholder,
    this.onMessageSent,
    this.onFunctionCall,
    this.enableCommonFunctions,
    this.customFunctions,
    this.showFunctionDetails,
  });

  final double? width;
  final double? height;
  final String? placeholder;

  /// Callback when a message is sent and response received
  final Future Function(String message, String response)? onMessageSent;

  /// Callback when FunctionGemma requests a function call
  /// Return the result of executing the function
  /// If null, function calls will be displayed but not executed
  final Future<dynamic> Function(
      String functionName, Map<String, dynamic> args)? onFunctionCall;

  /// Enable built-in common function definitions (calendar, weather, etc.)
  final bool? enableCommonFunctions;

  /// Custom function definitions to register with the model
  /// Use FunctionDefinition from function_gemma_helper.dart
  final List<Map<String, dynamic>>? customFunctions;

  /// Show detailed function call information in the chat
  final bool? showFunctionDetails;

  @override
  State<FunctionGemmaChatWidget> createState() =>
      _FunctionGemmaChatWidgetState();
}

class _FunctionGemmaChatWidgetState extends State<FunctionGemmaChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<FunctionChatMessage> _messages = [];

  bool _isLoading = false;
  late FunctionGemmaHelper _functionHelper;

  @override
  void initState() {
    super.initState();
    _initializeFunctionHelper();
    _checkModelStatus();
  }

  void _initializeFunctionHelper() {
    _functionHelper = FunctionGemmaHelper();

    // Add common functions if enabled
    if (widget.enableCommonFunctions ?? true) {
      _functionHelper
          .addFunction(CommonFunctionDefinitions.createCalendarEvent());
      _functionHelper.addFunction(CommonFunctionDefinitions.setReminder());
      _functionHelper
          .addFunction(CommonFunctionDefinitions.getCurrentWeather());
      _functionHelper
          .addFunction(CommonFunctionDefinitions.controlSmartLight());
      _functionHelper.addFunction(CommonFunctionDefinitions.sendMessage());
      _functionHelper.addFunction(CommonFunctionDefinitions.getTodayDate());
      _functionHelper.addFunction(CommonFunctionDefinitions.playMedia());
      _functionHelper.addFunction(CommonFunctionDefinitions.setAlarm());
    }

    // Add custom functions if provided
    if (widget.customFunctions != null) {
      for (final funcMap in widget.customFunctions!) {
        try {
          final func = _parseCustomFunction(funcMap);
          if (func != null) {
            _functionHelper.addFunction(func);
          }
        } catch (e) {
          print('FunctionGemmaChatWidget: Error parsing custom function: $e');
        }
      }
    }
  }

  FunctionDefinition? _parseCustomFunction(Map<String, dynamic> funcMap) {
    try {
      final name = funcMap['name'] as String?;
      final description = funcMap['description'] as String?;
      final parameters = funcMap['parameters'] as Map<String, dynamic>?;

      if (name == null || description == null) return null;

      final params = <String, ParameterDefinition>{};
      if (parameters != null) {
        for (final entry in parameters.entries) {
          final paramData = entry.value as Map<String, dynamic>?;
          if (paramData != null) {
            params[entry.key] = ParameterDefinition(
              type: (paramData['type'] as String?) ?? 'STRING',
              description: paramData['description'] as String?,
              enumValues: (paramData['enum'] as List?)?.cast<String>(),
            );
          }
        }
      }

      final required = (funcMap['required'] as List?)?.cast<String>() ?? [];

      return FunctionDefinition(
        name: name,
        description: description,
        parameters: params,
        required: required,
      );
    } catch (e) {
      print('_parseCustomFunction error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkModelStatus() {
    final appState = Provider.of<FFAppState>(context, listen: false);

    if (appState.isModelInitialized) {
      final isFunctionModel = ModelUtils.isFunctionCallingModel(
        FlutterGemmaLibrary.instance.currentModelType ?? '',
      );

      setState(() {
        _messages.add(FunctionChatMessage(
          text: isFunctionModel
              ? 'FunctionGemma ready! I can help you with:\n'
                  '• Creating calendar events\n'
                  '• Setting reminders and alarms\n'
                  '• Checking the weather\n'
                  '• Controlling smart home devices\n'
                  '• Sending messages\n'
                  '• Playing media\n\n'
                  'Try asking me to do something!'
              : 'Model initialized, but it may not support function calling. '
                  'For best results, use FunctionGemma-270M-IT.',
          isUser: false,
          isSystemMessage: true,
        ));
      });
    } else {
      setState(() {
        _messages.add(FunctionChatMessage(
          text: 'Please initialize a FunctionGemma model to start.',
          isUser: false,
          isSystemMessage: true,
        ));
      });
    }
  }

  Future<void> _sendMessage() async {
    final appState = context.read<FFAppState>();
    if (!appState.isModelInitialized || _isLoading) return;

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(FunctionChatMessage(
        text: messageText,
        isUser: true,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Send message with function calling support
      final response = await sendFunctionGemmaMessage(
        messageText,
        functions: _functionHelper.functions,
        functionHandler: widget.onFunctionCall != null
            ? (name, args) => widget.onFunctionCall!(name, args)
            : _defaultFunctionHandler,
        autoExecuteFunctions: true,
      );

      // Add the response
      if (response.hasFunctionCall) {
        // Show function call details if enabled
        if (widget.showFunctionDetails ?? true) {
          setState(() {
            _messages.add(FunctionChatMessage(
              text: 'Calling function: ${response.functionName}',
              isUser: false,
              isSystemMessage: true,
              isFunctionCall: true,
              functionName: response.functionName,
              functionArgs: response.functionArguments,
            ));

            if (response.wasAutoExecuted && response.functionResult != null) {
              _messages.add(FunctionChatMessage(
                text: 'Function result: ${response.functionResult}',
                isUser: false,
                isSystemMessage: true,
                isFunctionResult: true,
              ));
            }
          });
        }
      }

      // Add the final text response
      setState(() {
        _messages.add(FunctionChatMessage(
          text: response.text,
          isUser: false,
          isError: response.isError,
        ));
      });

      // Call callback if provided
      if (widget.onMessageSent != null) {
        await widget.onMessageSent!(messageText, response.text);
      }
    } catch (e) {
      print('FunctionGemmaChatWidget: Error: $e');
      setState(() {
        _messages.add(FunctionChatMessage(
          text: 'Error: $e',
          isUser: false,
          isError: true,
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Default function handler for common functions
  Future<dynamic> _defaultFunctionHandler(
    String functionName,
    Map<String, dynamic> args,
  ) async {
    print('Default handler: $functionName with args: $args');

    // Simulate function execution with mock responses
    switch (functionName) {
      case 'get_today_date':
        return DateTime.now().toIso8601String().split('T')[0];

      case 'get_current_weather':
        final location = args['location'] ?? 'Unknown';
        return {
          'location': location,
          'temperature': 22,
          'condition': 'Sunny',
          'humidity': 45,
        };

      case 'create_calendar_event':
        return {
          'success': true,
          'event_id': 'evt_${DateTime.now().millisecondsSinceEpoch}',
          'title': args['title'],
          'datetime': args['datetime'],
        };

      case 'set_reminder':
        return {
          'success': true,
          'reminder_id': 'rem_${DateTime.now().millisecondsSinceEpoch}',
          'message': args['message'],
        };

      case 'set_alarm':
        return {
          'success': true,
          'alarm_id': 'alm_${DateTime.now().millisecondsSinceEpoch}',
          'time': args['time'],
        };

      case 'control_smart_light':
        return {
          'success': true,
          'room': args['room'],
          'action': args['action'],
          'status': 'completed',
        };

      case 'send_message':
        return {
          'success': true,
          'message_id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
          'recipient': args['recipient'],
          'status': 'sent',
        };

      case 'play_media':
        return {
          'success': true,
          'now_playing': args['query'],
          'media_type': args['media_type'] ?? 'music',
        };

      default:
        return {'error': 'Unknown function', 'function': functionName};
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary.withAlpha(25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.functions,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'FunctionGemma',
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Readex Pro',
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_functionHelper.functions.length} tools',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processing...',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ],
              ),
            ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final appState = context.watch<FFAppState>();
    final isInitialized = appState.isModelInitialized;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FlutterFlowTheme.of(context).primary.withAlpha(51),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: isInitialized && !_isLoading,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Try "Set a reminder for 3pm"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => isInitialized ? _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (!isInitialized || _isLoading) ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(FunctionChatMessage message) {
    // Function call indicator
    if (message.isFunctionCall) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).tertiary.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).tertiary.withAlpha(76),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: FlutterFlowTheme.of(context).tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Function Call',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Readex Pro',
                        fontWeight: FontWeight.bold,
                        color: FlutterFlowTheme.of(context).tertiary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.functionName ?? '',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (message.functionArgs != null &&
                      message.functionArgs!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message.functionArgs!.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Function result indicator
    if (message.isFunctionResult) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).success.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).success.withAlpha(76),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: FlutterFlowTheme.of(context).success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: FlutterFlowTheme.of(context).bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    // Regular message bubble
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: !message.isUser && !message.isSystemMessage
            ? () async {
                await Clipboard.setData(ClipboardData(text: message.text));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: message.isError
                ? FlutterFlowTheme.of(context).error.withAlpha(25)
                : message.isSystemMessage
                    ? FlutterFlowTheme.of(context).warning.withAlpha(25)
                    : message.isUser
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: message.isError
                ? Border.all(
                    color: FlutterFlowTheme.of(context).error.withAlpha(76),
                  )
                : message.isSystemMessage
                    ? Border.all(
                        color:
                            FlutterFlowTheme.of(context).warning.withAlpha(76),
                      )
                    : null,
          ),
          child: message.isUser || message.isSystemMessage || message.isError
              ? Text(
                  message.text,
                  style: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : FlutterFlowTheme.of(context).primaryText,
                    fontStyle:
                        message.isSystemMessage ? FontStyle.italic : null,
                  ),
                )
              : MarkdownWidget(
                  data: message.text,
                  mdcolor: FlutterFlowTheme.of(context).primaryText,
                  fontFamily: 'Readex Pro',
                  fontSize: 14.0,
                ),
        ),
      ),
    );
  }
}
