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
/// Returns the model's response (or function call details if not auto-executing)
Future<FunctionGemmaResponse> sendFunctionGemmaMessage(
  String message, {
  List<FunctionDefinition>? functions,
  FunctionCallHandler? functionHandler,
  bool autoExecuteFunctions = true,
}) async {
  try {
    final gemma = FlutterGemmaLibrary.instance;

    if (!gemma.isInitialized) {
      print('sendFunctionGemmaMessage: Model not initialized');
      return FunctionGemmaResponse(
        text: 'Model not initialized. Please initialize the model first.',
        isError: true,
      );
    }

    // Check if this is a FunctionGemma model
    final isFunctionModel =
        ModelUtils.isFunctionCallingModel(gemma.currentModelType ?? '');

    if (!isFunctionModel) {
      print(
          'sendFunctionGemmaMessage: Warning - Model may not support function calling');
    }

    // Build the FunctionGemma helper with registered functions
    final helper = FunctionGemmaHelper(functions: functions ?? []);

    // Build the formatted prompt with function declarations
    final formattedPrompt = helper.buildFormattedPrompt(message);

    print('sendFunctionGemmaMessage: Sending formatted prompt');
    print('sendFunctionGemmaMessage: Functions registered: ${functions?.length ?? 0}');

    // Send the message to the model
    final response = await gemma.sendMessage(formattedPrompt);

    if (response == null || response.isEmpty) {
      return FunctionGemmaResponse(
        text: 'No response received from the model.',
        isError: true,
      );
    }

    print('sendFunctionGemmaMessage: Received response: $response');

    // Check if the response contains a function call
    if (helper.containsFunctionCall(response)) {
      final parsedCall = helper.parseFunctionCall(response);

      if (parsedCall != null) {
        print('sendFunctionGemmaMessage: Parsed function call: ${parsedCall.functionName}');
        print('sendFunctionGemmaMessage: Arguments: ${parsedCall.arguments}');

        // If auto-execute is enabled and we have a handler, execute the function
        if (autoExecuteFunctions && functionHandler != null) {
          try {
            final result = await functionHandler(
              parsedCall.functionName,
              parsedCall.arguments,
            );

            print('sendFunctionGemmaMessage: Function executed, result: $result');

            // Build follow-up prompt with the function result
            final followUpPrompt = helper.buildFollowUpPrompt(
              formattedPrompt,
              response,
              parsedCall.functionName,
              result,
            );

            // Get the final response from the model
            final finalResponse = await gemma.sendMessage(followUpPrompt);

            return FunctionGemmaResponse(
              text: finalResponse ?? 'Function executed successfully.',
              functionCall: parsedCall,
              functionResult: result,
              wasAutoExecuted: true,
            );
          } catch (e) {
            print('sendFunctionGemmaMessage: Error executing function: $e');
            return FunctionGemmaResponse(
              text: 'Error executing function ${parsedCall.functionName}: $e',
              functionCall: parsedCall,
              isError: true,
            );
          }
        }

        // Return the function call for manual handling
        return FunctionGemmaResponse(
          text: response,
          functionCall: parsedCall,
          wasAutoExecuted: false,
        );
      }
    }

    // No function call, return the text response
    final cleanResponse = helper.extractFinalResponse(response) ?? response;

    return FunctionGemmaResponse(
      text: cleanResponse,
    );
  } catch (e) {
    print('sendFunctionGemmaMessage: Error: $e');
    return FunctionGemmaResponse(
      text: 'Error processing message: $e',
      isError: true,
    );
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
Future<FunctionGemmaResponse> continueFunctionGemmaConversation(
  String previousPrompt,
  String functionCallResponse,
  String functionName,
  dynamic functionResult,
) async {
  try {
    final gemma = FlutterGemmaLibrary.instance;

    if (!gemma.isInitialized) {
      return FunctionGemmaResponse(
        text: 'Model not initialized.',
        isError: true,
      );
    }

    final helper = FunctionGemmaHelper();

    // Build the follow-up prompt
    final followUpPrompt = helper.buildFollowUpPrompt(
      previousPrompt,
      functionCallResponse,
      functionName,
      functionResult,
    );

    // Get the final response
    final response = await gemma.sendMessage(followUpPrompt);

    if (response == null) {
      return FunctionGemmaResponse(
        text: 'No response received.',
        isError: true,
      );
    }

    // Check if model wants to call another function (chained calls)
    if (helper.containsFunctionCall(response)) {
      final parsedCall = helper.parseFunctionCall(response);
      return FunctionGemmaResponse(
        text: response,
        functionCall: parsedCall,
        wasAutoExecuted: false,
      );
    }

    return FunctionGemmaResponse(
      text: helper.extractFinalResponse(response) ?? response,
    );
  } catch (e) {
    print('continueFunctionGemmaConversation: Error: $e');
    return FunctionGemmaResponse(
      text: 'Error continuing conversation: $e',
      isError: true,
    );
  }
}

/// Response from FunctionGemma message
class FunctionGemmaResponse {
  /// The text response from the model
  final String text;

  /// Parsed function call (if the model requested one)
  final ParsedFunctionCall? functionCall;

  /// Result of function execution (if auto-executed)
  final dynamic functionResult;

  /// Whether the function was automatically executed
  final bool wasAutoExecuted;

  /// Whether an error occurred
  final bool isError;

  FunctionGemmaResponse({
    required this.text,
    this.functionCall,
    this.functionResult,
    this.wasAutoExecuted = false,
    this.isError = false,
  });

  /// Check if the response contains a function call request
  bool get hasFunctionCall => functionCall != null;

  /// Get the function name if a function call was requested
  String? get functionName => functionCall?.functionName;

  /// Get the function arguments if a function call was requested
  Map<String, dynamic>? get functionArguments => functionCall?.arguments;

  @override
  String toString() {
    if (hasFunctionCall) {
      return 'FunctionGemmaResponse(functionCall: ${functionCall!.functionName}, '
          'autoExecuted: $wasAutoExecuted, error: $isError)';
    }
    return 'FunctionGemmaResponse(text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., error: $isError)';
  }
}
