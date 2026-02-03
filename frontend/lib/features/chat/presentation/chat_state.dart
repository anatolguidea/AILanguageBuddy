import '../domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final bool isLoadingHistory;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.isLoadingHistory = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isLoadingHistory,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
    );
  }
}
