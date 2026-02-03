import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_controller.dart';
import 'widgets/message_composer.dart';
import 'widgets/message_list.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Language Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoadingHistory)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyState()
                : MessageList(messages: state.messages),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          MessageComposer(
            onSend: controller.send,
            isSending: state.isSending,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Start a conversation with your AI language coach.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
