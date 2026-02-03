import 'package:flutter/material.dart';

import '../../domain/chat_message.dart';
import 'chat_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) => ChatBubble(message: messages[index]),
    );
  }
}
