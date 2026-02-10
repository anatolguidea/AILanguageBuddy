import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/avatar_display.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../providers/chat_provider.dart';
import '../../../settings/presentation/providers/language_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String scenarioId;

  const ChatPage({super.key, required this.scenarioId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(chatProvider.notifier);
      notifier.clearMessages(); // Clear previous chat
      notifier.loadHistory(widget.scenarioId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentLanguage = ref.read(languageProvider);
    ref.read(chatProvider.notifier).sendMessage(
      _messageController.text, 
      widget.scenarioId,
      currentLanguage.name, 
    );
    _messageController.clear();
    // Scroll will be handled by listener or post-build
  }

  void _toggleListening(bool isListening) {
    if (isListening) {
      ref.read(chatProvider.notifier).stopListening();
    } else {
      ref.read(chatProvider.notifier).startListening((text) {
        setState(() {
          _messageController.text = text;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    
    // Auto-scroll when messages change
    ref.listen(chatProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        // Wait for list to render
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final isListening = chatState.isListening;
    final isSpeaking = chatState.isSpeaking;

    // Determine Avatar Status
    AvatarStatus avatarStatus = AvatarStatus.idle;
    if (isSpeaking) {
      avatarStatus = AvatarStatus.speaking;
    } else if (isListening) {
      avatarStatus = AvatarStatus.listening;
    } else if (isLoading) {
      avatarStatus = AvatarStatus.listening; 
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Practice Session'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Avatar Area
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundBlack,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: AvatarDisplay(
                status: avatarStatus,
              ),
            ),
          ),

          // Chat Area
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimensions.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        content: msg['content'] ?? '',
                        isUser: msg['role'] == 'user',
                        onPlay: msg['role'] == 'user' 
                            ? null 
                            : () => ref.read(chatProvider.notifier).speak(msg['content'] ?? ''),
                      );
                    },
                  ),
                ),
                
                if (chatState.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Error: ${chatState.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(color: AppColors.primary),
                  ),

                ChatInputBar(
                  controller: _messageController,
                  isListening: isListening,
                  onSend: _sendMessage,
                  onMicTap: () => _toggleListening(isListening),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
