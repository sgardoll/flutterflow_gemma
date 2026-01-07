/// FunctionGemma Helper for FlutterFlow
///
/// This helper provides utilities for working with FunctionGemma models,
/// which are specialized for function calling. It handles:
/// - Function/tool definitions using JSON schema format
/// - Parsing function call responses from the model
/// - Formatting function results for the model
/// - Building proper prompts with function declarations
///
/// Based on FunctionGemma documentation:
/// https://ai.google.dev/gemma/docs/functiongemma

import 'dart:convert';

/// Special tokens used by FunctionGemma for structured output
class FunctionGemmaTokens {
  static const String startFunctionCall = '<start_function_call>';
  static const String endFunctionCall = '<end_function_call>';
  static const String startFunctionResponse = '<start_function_response>';
  static const String endFunctionResponse = '<end_function_response>';
  static const String startFunctionDeclaration = '<start_function_declaration>';
  static const String endFunctionDeclaration = '<end_function_declaration>';
  static const String escape = '<escape>';
  static const String escapeEnd = '</escape>';
  static const String startOfTurn = '<start_of_turn>';
  static const String endOfTurn = '<end_of_turn>';
  static const String bos = '<bos>';
}

/// Represents a function/tool definition for FunctionGemma
class FunctionDefinition {
  final String name;
  final String description;
  final Map<String, ParameterDefinition> parameters;
  final List<String> required;

  const FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
    this.required = const [],
  });

  /// Convert to JSON schema format expected by FunctionGemma
  Map<String, dynamic> toJsonSchema() {
    return {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': parameters.map(
          (key, value) => MapEntry(key, value.toJsonSchema()),
        ),
        'required': required,
      },
    };
  }

  /// Build the function declaration string for the prompt
  String toDeclarationString() {
    final params = parameters.entries.map((e) {
      final param = e.value;
      String paramStr = '${e.key}:{type:${_escapeValue(param.type)}';
      if (param.description != null) {
        paramStr += ',description:${_escapeValue(param.description!)}';
      }
      if (param.enumValues != null && param.enumValues!.isNotEmpty) {
        paramStr += ',enum:[${param.enumValues!.map(_escapeValue).join(',')}]';
      }
      paramStr += '}';
      return paramStr;
    }).join(',');

    return 'declaration:$name{description:${_escapeValue(description)},parameters:{type:${_escapeValue('OBJECT')},properties:{$params}${required.isNotEmpty ? ',required:[${required.join(',')}]' : ''}}}';
  }

  String _escapeValue(String value) {
    return '${FunctionGemmaTokens.escape}$value${FunctionGemmaTokens.escapeEnd}';
  }
}

/// Represents a parameter definition for a function
class ParameterDefinition {
  final String type; // STRING, INTEGER, NUMBER, BOOLEAN, ARRAY, OBJECT
  final String? description;
  final List<String>? enumValues;
  final dynamic defaultValue;

  const ParameterDefinition({
    required this.type,
    this.description,
    this.enumValues,
    this.defaultValue,
  });

  Map<String, dynamic> toJsonSchema() {
    final schema = <String, dynamic>{'type': type.toLowerCase()};
    if (description != null) schema['description'] = description;
    if (enumValues != null) schema['enum'] = enumValues;
    if (defaultValue != null) schema['default'] = defaultValue;
    return schema;
  }
}

/// Represents a parsed function call from FunctionGemma's response
class ParsedFunctionCall {
  final String functionName;
  final Map<String, dynamic> arguments;
  final String rawOutput;

  const ParsedFunctionCall({
    required this.functionName,
    required this.arguments,
    required this.rawOutput,
  });

  @override
  String toString() {
    return 'ParsedFunctionCall(name: $functionName, args: $arguments)';
  }
}

/// Main helper class for FunctionGemma operations
class FunctionGemmaHelper {
  final List<FunctionDefinition> _functions;

  FunctionGemmaHelper({List<FunctionDefinition>? functions})
      : _functions = functions ?? [];

  /// Get the list of registered functions
  List<FunctionDefinition> get functions => List.unmodifiable(_functions);

  /// Add a function definition
  void addFunction(FunctionDefinition function) {
    _functions.add(function);
  }

  /// Remove a function by name
  void removeFunction(String name) {
    _functions.removeWhere((f) => f.name == name);
  }

  /// Clear all registered functions
  void clearFunctions() {
    _functions.clear();
  }

  /// Build the system prompt with function declarations
  ///
  /// FunctionGemma requires a specific system message format:
  /// "You are a model that can do function calling with the following functions"
  String buildSystemPrompt() {
    if (_functions.isEmpty) {
      return 'You are a helpful assistant.';
    }

    final declarations = _functions.map((f) {
      return '${FunctionGemmaTokens.startFunctionDeclaration}${f.toDeclarationString()}${FunctionGemmaTokens.endFunctionDeclaration}';
    }).join('\n');

    return 'You are a model that can do function calling with the following functions\n$declarations';
  }

  /// Build the complete formatted prompt for FunctionGemma
  ///
  /// Format:
  /// <bos><start_of_turn>developer
  /// {system_prompt}
  /// <end_of_turn>
  /// <start_of_turn>user
  /// {user_message}
  /// <end_of_turn>
  /// <start_of_turn>model
  String buildFormattedPrompt(String userMessage) {
    final systemPrompt = buildSystemPrompt();
    return '${FunctionGemmaTokens.bos}${FunctionGemmaTokens.startOfTurn}developer\n'
        '$systemPrompt${FunctionGemmaTokens.endOfTurn}\n'
        '${FunctionGemmaTokens.startOfTurn}user\n'
        '$userMessage${FunctionGemmaTokens.endOfTurn}\n'
        '${FunctionGemmaTokens.startOfTurn}model\n';
  }

  /// Parse a function call from the model's response
  ///
  /// FunctionGemma outputs function calls in the format:
  /// <start_function_call>call:function_name{param:<escape>value<escape>}<end_function_call>
  ParsedFunctionCall? parseFunctionCall(String modelOutput) {
    try {
      // Check if the output contains a function call
      final startIdx =
          modelOutput.indexOf(FunctionGemmaTokens.startFunctionCall);
      final endIdx = modelOutput.indexOf(FunctionGemmaTokens.endFunctionCall);

      if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
        print('FunctionGemmaHelper: No function call found in output');
        return null;
      }

      // Extract the function call content
      final callContent = modelOutput.substring(
        startIdx + FunctionGemmaTokens.startFunctionCall.length,
        endIdx,
      );

      print('FunctionGemmaHelper: Parsing function call: $callContent');

      // Parse "call:function_name{...}"
      if (!callContent.startsWith('call:')) {
        print('FunctionGemmaHelper: Invalid function call format');
        return null;
      }

      final afterCall = callContent.substring(5); // Remove "call:"
      final braceIdx = afterCall.indexOf('{');

      if (braceIdx == -1) {
        // Function with no arguments
        return ParsedFunctionCall(
          functionName: afterCall.trim(),
          arguments: {},
          rawOutput: modelOutput,
        );
      }

      final functionName = afterCall.substring(0, braceIdx);
      final argsStr = afterCall.substring(braceIdx + 1, afterCall.length - 1);

      // Parse arguments
      final arguments = _parseArguments(argsStr);

      return ParsedFunctionCall(
        functionName: functionName,
        arguments: arguments,
        rawOutput: modelOutput,
      );
    } catch (e) {
      print('FunctionGemmaHelper: Error parsing function call: $e');
      return null;
    }
  }

  /// Parse the arguments string from a function call
  Map<String, dynamic> _parseArguments(String argsStr) {
    final args = <String, dynamic>{};

    // Regex to match key:value or key:<escape>value</escape>
    final pattern = RegExp(
      r'(\w+):(?:<escape>(.*?)</escape>|([^,}]*))',
      dotAll: true,
    );

    for (final match in pattern.allMatches(argsStr)) {
      final key = match.group(1)!;
      String? value = match.group(2) ?? match.group(3);

      if (value == null || value.isEmpty || value.toLowerCase() == 'none') {
        continue; // Skip null/empty values
      }

      // Type conversion
      args[key] = _convertValue(value.trim());
    }

    return args;
  }

  /// Convert string value to appropriate type
  dynamic _convertValue(String value) {
    // Boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Integer
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // Double
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;

    // JSON object or array
    if ((value.startsWith('{') && value.endsWith('}')) ||
        (value.startsWith('[') && value.endsWith(']'))) {
      try {
        return jsonDecode(value);
      } catch (_) {
        // Fall through to string
      }
    }

    // String (default)
    return value;
  }

  /// Format a function result to send back to the model
  ///
  /// Format:
  /// <start_function_response>response:function_name{result:<escape>value<escape>}<end_function_response>
  String formatFunctionResponse(String functionName, dynamic result) {
    String resultStr;
    if (result is Map || result is List) {
      resultStr = jsonEncode(result);
    } else {
      resultStr = result.toString();
    }

    return '${FunctionGemmaTokens.startFunctionResponse}'
        'response:$functionName{result:${FunctionGemmaTokens.escape}$resultStr${FunctionGemmaTokens.escapeEnd}}'
        '${FunctionGemmaTokens.endFunctionResponse}';
  }

  /// Build a follow-up prompt with the function response
  ///
  /// This continues the conversation after executing a function call
  String buildFollowUpPrompt(
    String originalPrompt,
    String functionCallOutput,
    String functionName,
    dynamic functionResult,
  ) {
    final functionResponse =
        formatFunctionResponse(functionName, functionResult);

    return '$originalPrompt'
        '$functionCallOutput${FunctionGemmaTokens.endOfTurn}\n'
        '${FunctionGemmaTokens.startOfTurn}tool\n'
        '$functionResponse${FunctionGemmaTokens.endOfTurn}\n'
        '${FunctionGemmaTokens.startOfTurn}model\n';
  }

  /// Check if a model response contains a function call
  bool containsFunctionCall(String response) {
    return response.contains(FunctionGemmaTokens.startFunctionCall) &&
        response.contains(FunctionGemmaTokens.endFunctionCall);
  }

  /// Extract the final text response (after function execution)
  String? extractFinalResponse(String response) {
    // If no function call tokens, return the whole response
    if (!containsFunctionCall(response)) {
      return response.trim();
    }

    // Look for text after the last end_function_call or end_function_response
    final lastFuncEnd =
        response.lastIndexOf(FunctionGemmaTokens.endFunctionResponse);
    final lastCallEnd =
        response.lastIndexOf(FunctionGemmaTokens.endFunctionCall);

    final lastEnd = lastFuncEnd > lastCallEnd ? lastFuncEnd : lastCallEnd;

    if (lastEnd == -1) {
      return null;
    }

    final afterFunctionEnd = lastEnd == lastFuncEnd
        ? lastEnd + FunctionGemmaTokens.endFunctionResponse.length
        : lastEnd + FunctionGemmaTokens.endFunctionCall.length;

    if (afterFunctionEnd < response.length) {
      final remaining = response.substring(afterFunctionEnd).trim();
      // Remove any trailing model tags
      return remaining
          .replaceAll(FunctionGemmaTokens.endOfTurn, '')
          .replaceAll(FunctionGemmaTokens.startOfTurn, '')
          .replaceAll('model', '')
          .trim();
    }

    return null;
  }
}

/// Pre-built common function definitions for mobile/smart home use cases
class CommonFunctionDefinitions {
  /// Create a calendar event function
  static FunctionDefinition createCalendarEvent() {
    return FunctionDefinition(
      name: 'create_calendar_event',
      description: 'Creates a new calendar event with the specified details',
      parameters: {
        'title': ParameterDefinition(
          type: 'STRING',
          description: 'The title or name of the event',
        ),
        'datetime': ParameterDefinition(
          type: 'STRING',
          description: 'The date and time of the event in ISO 8601 format',
        ),
        'description': ParameterDefinition(
          type: 'STRING',
          description: 'Optional description of the event',
        ),
      },
      required: ['title', 'datetime'],
    );
  }

  /// Set a reminder function
  static FunctionDefinition setReminder() {
    return FunctionDefinition(
      name: 'set_reminder',
      description: 'Sets a reminder for a specific time',
      parameters: {
        'message': ParameterDefinition(
          type: 'STRING',
          description: 'The reminder message',
        ),
        'datetime': ParameterDefinition(
          type: 'STRING',
          description: 'When to trigger the reminder',
        ),
      },
      required: ['message', 'datetime'],
    );
  }

  /// Get current weather function
  static FunctionDefinition getCurrentWeather() {
    return FunctionDefinition(
      name: 'get_current_weather',
      description: 'Gets the current weather for a location',
      parameters: {
        'location': ParameterDefinition(
          type: 'STRING',
          description: 'City name or location',
        ),
        'unit': ParameterDefinition(
          type: 'STRING',
          description: 'Temperature unit',
          enumValues: ['celsius', 'fahrenheit'],
          defaultValue: 'celsius',
        ),
      },
      required: ['location'],
    );
  }

  /// Control smart light function
  static FunctionDefinition controlSmartLight() {
    return FunctionDefinition(
      name: 'control_smart_light',
      description: 'Controls a smart light in the home',
      parameters: {
        'room': ParameterDefinition(
          type: 'STRING',
          description: 'The room where the light is located',
        ),
        'action': ParameterDefinition(
          type: 'STRING',
          description: 'Action to perform',
          enumValues: ['on', 'off', 'dim', 'brighten'],
        ),
        'brightness': ParameterDefinition(
          type: 'INTEGER',
          description: 'Brightness level (0-100)',
        ),
      },
      required: ['room', 'action'],
    );
  }

  /// Send message function
  static FunctionDefinition sendMessage() {
    return FunctionDefinition(
      name: 'send_message',
      description: 'Sends a message to a contact',
      parameters: {
        'recipient': ParameterDefinition(
          type: 'STRING',
          description: 'Name or phone number of the recipient',
        ),
        'message': ParameterDefinition(
          type: 'STRING',
          description: 'The message content',
        ),
      },
      required: ['recipient', 'message'],
    );
  }

  /// Get today's date function (simple, no parameters)
  static FunctionDefinition getTodayDate() {
    return FunctionDefinition(
      name: 'get_today_date',
      description: 'Gets today\'s date',
      parameters: {},
    );
  }

  /// Play media function
  static FunctionDefinition playMedia() {
    return FunctionDefinition(
      name: 'play_media',
      description: 'Plays music, podcast, or other media',
      parameters: {
        'query': ParameterDefinition(
          type: 'STRING',
          description: 'What to play (song name, artist, podcast, etc.)',
        ),
        'media_type': ParameterDefinition(
          type: 'STRING',
          description: 'Type of media',
          enumValues: ['music', 'podcast', 'audiobook', 'radio'],
        ),
      },
      required: ['query'],
    );
  }

  /// Set alarm function
  static FunctionDefinition setAlarm() {
    return FunctionDefinition(
      name: 'set_alarm',
      description: 'Sets an alarm for a specific time',
      parameters: {
        'time': ParameterDefinition(
          type: 'STRING',
          description: 'Time for the alarm (HH:MM format)',
        ),
        'label': ParameterDefinition(
          type: 'STRING',
          description: 'Optional label for the alarm',
        ),
        'repeat': ParameterDefinition(
          type: 'STRING',
          description: 'Repeat pattern',
          enumValues: ['once', 'daily', 'weekdays', 'weekends'],
          defaultValue: 'once',
        ),
      },
      required: ['time'],
    );
  }
}
