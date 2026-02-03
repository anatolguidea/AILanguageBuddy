import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_banner.dart';
import '../../auth/presentation/auth_state.dart';
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
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadHistory,
            tooltip: 'Refresh history',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoadingHistory)
            const LinearProgressIndicator(minHeight: 2),
          if (state.error != null)
            AppErrorBanner(
              message: state.error!,
              onDismiss: () => controller.clearError(),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? const AppEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Start a conversation',
                    subtitle: 'Message your AI language coach to practice.',
                  )
                : MessageList(messages: state.messages),
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
