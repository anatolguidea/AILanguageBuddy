import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';
import '../../../settings/domain/entities/language.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/current_topic_language_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String scenarioId;

  const ChatPage({super.key, required this.scenarioId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static const Color _stitchPrimary = AppColors.primary;
  static const Color _stitchLightBackground = Color(0xFFF7F5F8);
  static const Color _stitchDarkBackground = Color(0xFF000000);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _translatedMessages = {};
  final Set<String> _translatingKeys = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(chatProvider.notifier);
      notifier.clearMessages();
      final code =
          ref.read(currentTopicLanguageProvider) ??
          ref.read(languageProvider).code;
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
    final code =
        ref.read(currentTopicLanguageProvider) ??
        ref.read(languageProvider).code;
    final lang = _languageFromCode(code);
    final sessionMode = '${widget.scenarioId}_${lang.code}';
    ref
        .read(chatProvider.notifier)
        .sendMessage(_messageController.text, sessionMode, lang.name);
    _messageController.clear();
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

  String _previousUserText(List<Map<String, dynamic>> messages, int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (messages[i]['role'] == 'user') {
        return messages[i]['content']?.toString() ?? '';
      }
    }
    return '';
  }

  String _messageKey(int index, Map<String, dynamic> msg) {
    return '$index-${msg['role']}-${msg['content']}';
  }

  Future<void> _translateAiMessage(int index, Map<String, dynamic> msg) async {
    final key = _messageKey(index, msg);
    if (_translatingKeys.contains(key)) return;
    final sourceText = msg['content']?.toString() ?? '';
    if (sourceText.trim().isEmpty) return;
    final localeCode = ref.read(appLocaleProvider).toLowerCase();
    final targetLanguage = localeCode.startsWith('ro') ? 'Romanian' : 'English';

    setState(() {
      _translatingKeys.add(key);
    });
    try {
      final translated = await ref
          .read(chatProvider.notifier)
          .translateMessage(
            text: sourceText,
            scenarioId: widget.scenarioId,
            targetLanguage: targetLanguage,
          );
      if (!mounted) return;
      setState(() {
        _translatedMessages[key] = translated;
      });
    } catch (_) {
      if (!mounted) return;
      final locale = ref.read(appLocaleProvider);
      final s = AppStrings.forLocale(locale);
      final currentError = ref.read(chatProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.error}: ${currentError ?? 'Translation failed'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _translatingKeys.remove(key);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);

    ref.listen(chatProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    final messages = chatState.messages;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? _stitchDarkBackground : _stitchLightBackground;

    final baseTheme = Theme.of(context);
    final screenTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: _stitchPrimary),
      scaffoldBackgroundColor: pageBg,
      textTheme: GoogleFonts.lexendTextTheme(baseTheme.textTheme),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: isDark
            ? _stitchDarkBackground.withValues(alpha: 0.85)
            : Colors.white,
      ),
    );

    return Theme(
      data: screenTheme,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 8,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Tutor: ${s.sarah}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ONLINE',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: s.startOver,
              onPressed: chatState.isLoading
                  ? null
                  : () async {
                      final notifier = ref.read(chatProvider.notifier);
                      final code =
                          ref.read(currentTopicLanguageProvider) ??
                          ref.read(languageProvider).code;
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
                          ),
                        );
                      }
                    },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
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
                  final key = _messageKey(index, msg);
                  final cachedTranslation = _translatedMessages[key];
                  final messageTranslation = msg['translation']?.toString();
                  return ChatBubble(
                    key: ValueKey(
                      'msg-$index-${msg['role']}-${msg['content']}',
                    ),
                    content: msg['content'] ?? '',
                    isUser: msg['role'] == 'user',
                    correction: msg['correction']?.toString(),
                    tips: msg['tips']?.toString(),
                    incorrectText: _previousUserText(messages, index),
                    sarahLabel: s.sarah,
                    listenLabel: s.listen,
                    feedbackLabel: s.feedback,
                    correctionLabel: s.correction,
                    tipLabel: s.tip,
                    translation: cachedTranslation ?? messageTranslation,
                    isTranslating: _translatingKeys.contains(key),
                    translateLabel: s.translateThisSentenceLabel,
                    onPlay: msg['role'] == 'user'
                        ? null
                        : () => ref
                              .read(chatProvider.notifier)
                              .speak(msg['content'] ?? ''),
                    onTranslate: msg['role'] == 'user'
                        ? null
                        : () => _translateAiMessage(index, msg),
                  );
                },
              ),
            ),
            if (chatState.error != null)
              Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${s.error}: ${chatState.error}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: 0.1, end: 0, duration: 200.ms),
            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.secondary.withValues(alpha: 0.14)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _stitchPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.sarahIsTyping,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.75),
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
              isListening: chatState.isListening,
              typeAMessageHint: s.typeAMessage,
              listeningHint: s.listening,
              onSend: _sendMessage,
              onMicTap: () => _toggleListening(chatState.isListening),
            ),
          ],
        ),
      ),
    );
  }
}
