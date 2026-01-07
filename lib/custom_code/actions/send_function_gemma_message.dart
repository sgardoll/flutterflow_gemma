// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '../flutter_gemma_library.dart';
import '../function_gemma_helper.dart';
import 'dart:convert';

/// Callback type for when FunctionGemma requests a function call
/// Return the result of executing the function
typedef FunctionCallHandler = Future<dynamic> Function(
  String functionName,
  Map<String, dynamic> arguments,
);

/// Send a message to a FunctionGemma model with function calling support
///
/// This action handles the complete FunctionGemma workflow:
/// 1. Formats the message with function declarations
/// 2. Sends to the model
/// 3. Parses any function call responses
/// 4. Optionally executes functions via the handler callback
/// 5. Returns the final response
///
/// [message] - The user's message/query
/// [functions] - List of function definitions (use CommonFunctionDefinitions helpers)
/// [functionHandler] - Optional callback to execute function calls
/// [autoExecuteFunctions] - If true and handler provided, automatically executes functions
///
/// Returns JSON string with response data: {"text":"...","isError":false,"hasFunctionCall":false,"functionName":null,"functionResult":null,"wasAutoExecuted":false}
Future<String> sendFunctionGemmaMessage(
  String message, {
  List<FunctionDefinition>? functions,
  FunctionCallHandler? functionHandler,
  bool autoExecuteFunctions = true,
}) async {
  try {
    final gemma = FlutterGemmaLibrary.instance;

    if (!gemma.isInitialized) {
      print('sendFunctionGemmaMessage: Model not initialized');
      return jsonEncode({
        'text': 'Model not initialized. Please initialize the model first.',
        'isError': true,
        'hasFunctionCall': false,
        'functionName': null,
        'functionResult': null,
        'wasAutoExecuted': false,
      });
    }

    final helper = FunctionGemmaHelper(functions: functions ?? []);
    final formattedPrompt = helper.buildFormattedPrompt(message);

    print('sendFunctionGemmaMessage: Sending formatted prompt');
    print(
        'sendFunctionGemmaMessage: Functions registered: ${functions?.length ?? 0}');

    final response = await gemma.sendMessage(formattedPrompt);

    if (response == null || response.isEmpty) {
      return jsonEncode({
        'text': 'No response received from the model.',
        'isError': true,
        'hasFunctionCall': false,
        'functionName': null,
        'functionResult': null,
        'wasAutoExecuted': false,
      });
    }

    print('sendFunctionGemmaMessage: Received response: $response');

    if (helper.containsFunctionCall(response)) {
      final parsedCall = helper.parseFunctionCall(response);

      if (parsedCall != null) {
        print(
            'sendFunctionGemmaMessage: Parsed function call: ${parsedCall.functionName}');
        print('sendFunctionGemmaMessage: Arguments: ${parsedCall.arguments}');

        if (autoExecuteFunctions && functionHandler != null) {
          try {
            final result = await functionHandler(
              parsedCall.functionName,
              parsedCall.arguments,
            );

            print(
                'sendFunctionGemmaMessage: Function executed, result: $result');

            final followUpPrompt = helper.buildFollowUpPrompt(
              formattedPrompt,
              response,
              parsedCall.functionName,
              result,
            );

            final finalResponse = await gemma.sendMessage(followUpPrompt);

            return jsonEncode({
              'text': finalResponse ?? 'Function executed successfully.',
              'isError': false,
              'hasFunctionCall': true,
              'functionName': parsedCall.functionName,
              'functionResult': result,
              'wasAutoExecuted': true,
            });
          } catch (e) {
            print('sendFunctionGemmaMessage: Error executing function: $e');
            return jsonEncode({
              'text': 'Error executing function ${parsedCall.functionName}: $e',
              'isError': true,
              'hasFunctionCall': true,
              'functionName': parsedCall.functionName,
              'functionResult': null,
              'wasAutoExecuted': false,
            });
          }
        }

        return jsonEncode({
          'text': response,
          'isError': false,
          'hasFunctionCall': true,
          'functionName': parsedCall.functionName,
          'functionResult': null,
          'wasAutoExecuted': false,
        });
      }
    }

    final cleanResponse = helper.extractFinalResponse(response) ?? response;

    return jsonEncode({
      'text': cleanResponse,
      'isError': false,
      'hasFunctionCall': false,
      'functionName': null,
      'functionResult': null,
      'wasAutoExecuted': false,
    });
  } catch (e) {
    print('sendFunctionGemmaMessage: Error: $e');
    return jsonEncode({
      'text': 'Error processing message: $e',
      'isError': true,
      'hasFunctionCall': false,
      'functionName': null,
      'functionResult': null,
      'wasAutoExecuted': false,
    });
  }
}

/// Continue a FunctionGemma conversation after manually executing a function
///
/// Use this when autoExecuteFunctions is false and you've manually executed
/// the function call returned by sendFunctionGemmaMessage
///
/// [previousPrompt] - The original formatted prompt
/// [functionCallResponse] - The model's response containing the function call
/// [functionName] - Name of the executed function
/// [functionResult] - Result of the function execution
Future<String> continueFunctionGemmaConversation(
  String previousPrompt,
  String functionCallResponse,
  String functionName,
  String functionResultJson,
) async {
  try {
    final gemma = FlutterGemmaLibrary.instance;

    if (!gemma.isInitialized) {
      return jsonEncode({
        'text': 'Model not initialized.',
        'isError': true,
        'hasFunctionCall': false,
        'functionName': null,
        'functionResult': null,
        'wasAutoExecuted': false,
      });
    }

    final helper = FunctionGemmaHelper();
    final functionResult = jsonDecode(functionResultJson);

    final followUpPrompt = helper.buildFollowUpPrompt(
      previousPrompt,
      functionCallResponse,
      functionName,
      functionResult,
    );

    final response = await gemma.sendMessage(followUpPrompt);

    if (response == null) {
      return jsonEncode({
        'text': 'No response received.',
        'isError': true,
        'hasFunctionCall': false,
        'functionName': null,
        'functionResult': null,
        'wasAutoExecuted': false,
      });
    }

    if (helper.containsFunctionCall(response)) {
      final parsedCall = helper.parseFunctionCall(response);
      return jsonEncode({
        'text': response,
        'isError': false,
        'hasFunctionCall': true,
        'functionName': parsedCall?.functionName,
        'functionResult': null,
        'wasAutoExecuted': false,
      });
    }

    return jsonEncode({
      'text': helper.extractFinalResponse(response) ?? response,
      'isError': false,
      'hasFunctionCall': false,
      'functionName': null,
      'functionResult': null,
      'wasAutoExecuted': false,
    });
  } catch (e) {
    print('continueFunctionGemmaConversation: Error: $e');
    return jsonEncode({
      'text': 'Error continuing conversation: $e',
      'isError': true,
      'hasFunctionCall': false,
      'functionName': null,
      'functionResult': null,
      'wasAutoExecuted': false,
    });
  }
}
