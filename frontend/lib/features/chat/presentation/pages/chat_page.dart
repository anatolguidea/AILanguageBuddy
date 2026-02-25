import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/app_strings.dart';
import '../widgets/avatar_display.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../providers/chat_provider.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import '../providers/current_topic_language_provider.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../../settings/domain/entities/language.dart';

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
      notifier.clearMessages();
      final code = ref.read(currentTopicLanguageProvider) ?? ref.read(languageProvider).code;
      final lang = _languageFromCode(code);
      final sessionMode = '${widget.scenarioId}_${lang.code}';
      notifier.loadHistory(sessionMode, targetLanguage: lang.name);
    });
  }

  static Language _languageFromCode(String? code) {
    final c = (code ?? 'en').trim().toLowerCase();
    final normalized = c == 'e' || c.isEmpty
        ? 'en'
        : c == 'f'
            ? 'fr'
            : c.length >= 2
                ? c.split('-').first
                : 'en';
    return Language.supported.firstWhere(
      (l) => l.code == normalized,
      orElse: () => Language.supported.first,
    );
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
    final code = ref.read(currentTopicLanguageProvider) ?? ref.read(languageProvider).code;
    final lang = _languageFromCode(code);
    final sessionMode = '${widget.scenarioId}_${lang.code}';
    ref.read(chatProvider.notifier).sendMessage(
      _messageController.text,
      sessionMode,
      lang.name,
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
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          s.practiceSession,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: s.startOver,
            onPressed: chatState.isLoading
                ? null
                : () async {
                    final notifier = ref.read(chatProvider.notifier);
                    final code = ref.read(currentTopicLanguageProvider) ?? ref.read(languageProvider).code;
                    final lang = _languageFromCode(code);
                    final sessionMode = '${widget.scenarioId}_${lang.code}';
                    await notifier.deleteHistoryAndRestart(
                      sessionMode,
                      targetLanguage: lang.name,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.conversationCleared),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          action: SnackBarAction(
                            label: s.ok,
                            textColor: Theme.of(context).colorScheme.primary,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          // Avatar Area (fixed height so chat has more space)
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: AvatarDisplay(
              status: avatarStatus,
              size: 90,
            ),
          ),

          // Chat Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.md,
                        AppDimensions.lg,
                        AppDimensions.md,
                        AppDimensions.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                      return ChatBubble(
                        content: msg['content'] ?? '',
                        isUser: msg['role'] == 'user',
                        correction: msg['correction']?.toString(),
                        tips: msg['tips']?.toString(),
                        sarahLabel: s.sarah,
                        listenLabel: s.listen,
                        feedbackLabel: s.feedback,
                        correctionLabel: s.correction,
                        tipLabel: s.tip,
                        onPlay: msg['role'] == 'user'
                              ? null
                              : () => ref.read(chatProvider.notifier).speak(msg['content'] ?? ''),
                        );
                      },
                    ),
                  ),

                  if (chatState.error != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${s.error}: ${chatState.error}',
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  s.sarahIsTyping,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                ChatInputBar(
                  controller: _messageController,
                  isListening: isListening,
                  typeAMessageHint: s.typeAMessage,
                  listeningHint: s.listening,
                  onSend: _sendMessage,
                  onMicTap: () => _toggleListening(isListening),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
