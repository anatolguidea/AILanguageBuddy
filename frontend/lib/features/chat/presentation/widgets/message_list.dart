import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/chat_message.dart';
import 'chat_bubble.dart';

/// Scrollable list of chat bubbles; reversed so latest is at bottom.
class MessageList extends StatelessWidget {
  const MessageList({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return ChatBubble(message: message);
      },
    );
  }
}
