/// Represents a message in the FunctionGemma chat
class FunctionChatMessage {
  const FunctionChatMessage({
    required this.text,
    this.isUser = false,
    this.isSystemMessage = false,
    this.isError = false,
    this.isFunctionCall = false,
    this.isFunctionResult = false,
    this.functionName,
    this.functionArgs,
  });

  final String text;
  final bool isUser;
  final bool isSystemMessage;
  final bool isError;
  final bool isFunctionCall;
  final bool isFunctionResult;
  final String? functionName;
  final Map<String, dynamic>? functionArgs;
}
