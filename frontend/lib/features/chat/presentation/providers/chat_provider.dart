import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../settings/presentation/providers/app_locale_provider.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../../domain/services/chat_audio_service.dart';
import 'session_topic_tracker.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref: ref,
    repository: ref.read(chatRepositoryProvider),
    audioService: ref.read(chatAudioServiceProvider),
  );
});

class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;
  final bool isSpeaking;
  final bool isListening;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isSpeaking = false,
    this.isListening = false,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? error,
    bool? isSpeaking,
    bool? isListening,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required Ref ref,
    required ChatRepository repository,
    required ChatAudioService audioService,
  }) : _ref = ref,
       _repository = repository,
       _audioService = audioService,
       super(const ChatState()) {
    unawaited(_initializeAudio());
  }

  final Ref _ref;
  final ChatRepository _repository;
  final ChatAudioService _audioService;

  Future<void> _initializeAudio() async {
    try {
      await _audioService.initialize(
        onSpeakingChanged: (isSpeaking) {
          state = state.copyWith(isSpeaking: isSpeaking);
        },
        onError: _setError,
      );
    } on AppFailure catch (failure) {
      _setError(failure.message);
    }
  }

  Future<void> startListening(void Function(String text) onResult) async {
    try {
      await _audioService.startListening(
        onResult: onResult,
        onListeningChanged: (isListening) {
          state = state.copyWith(isListening: isListening);
        },
        onError: _setError,
      );
    } on AppFailure catch (failure) {
      _setError(failure.message);
    }
  }

  Future<void> stopListening() async {
    try {
      await _audioService.stopListening();
      state = state.copyWith(isListening: false);
    } on AppFailure catch (failure) {
      _setError(failure.message);
    }
  }

  Future<void> speak(String text) async {
    try {
      await _audioService.speak(
        text,
        onSpeakingChanged: (isSpeaking) {
          state = state.copyWith(isSpeaking: isSpeaking);
        },
      );
    } on AppFailure catch (failure) {
      _setError(failure.message);
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _audioService.stopSpeaking();
      state = state.copyWith(isSpeaking: false);
    } on AppFailure catch (failure) {
      _setError(failure.message);
    }
  }

  Future<void> loadHistory(String scenarioId, {String? targetLanguage}) async {
    final token = _currentAccessToken();
    if (token == null) {
      _setError('Not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repository.fetchHistory(
        accessToken: token,
        mode: scenarioId,
        limit: 50,
      );

      final loadedMessages = history.messages
          .map(_toUiMessageFromApi)
          .toList(growable: false);
      state = state.copyWith(messages: loadedMessages, isLoading: false);

      final tracker = _ref.read(sessionTopicTrackerProvider.notifier);
      if (loadedMessages.isEmpty && !tracker.hasReceivedInitial(scenarioId)) {
        await _loadInitialMessage(
          scenarioId: scenarioId,
          token: token,
          targetLanguage: targetLanguage ?? 'English',
          instructionLocale: _ref.read(appLocaleProvider),
        );
      }
    } on AppFailure catch (failure) {
      state = state.copyWith(isLoading: false);
      _setError(failure.message);
    }
  }

  Future<void> deleteHistoryAndRestart(
    String scenarioId, {
    String? targetLanguage,
  }) async {
    final token = _currentAccessToken();
    if (token == null) {
      _setError('Not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteHistory(accessToken: token, mode: scenarioId);
      _ref
          .read(sessionTopicTrackerProvider.notifier)
          .clearInitialForTopic(scenarioId);
      state = state.copyWith(messages: [], isLoading: false);
      await loadHistory(scenarioId, targetLanguage: targetLanguage);
    } on AppFailure catch (failure) {
      state = state.copyWith(isLoading: false);
      _setError(failure.message);
    }
  }

  static const int _maxMessageLength = 2000;

  Future<void> sendMessage(
    String text,
    String scenarioId,
    String targetLanguage,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > _maxMessageLength) {
      _setError('Message is too long (max $_maxMessageLength characters).');
      return;
    }
    final token = _currentAccessToken();
    if (token == null) {
      _setError('Not authenticated');
      return;
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        {'role': 'user', 'content': trimmed},
      ],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _repository.ask(
        accessToken: token,
        request: ChatAskRequest(
          message: trimmed,
          mode: scenarioId,
          targetLanguage: targetLanguage,
          instructionLocale: _ref.read(appLocaleProvider),
        ),
      );
      final aiMap = <String, dynamic>{
        'role': 'ai',
        'content': response.replyText,
      };
      if (response.translation != null) {
        aiMap['translation'] = response.translation;
      }
      if (response.correction != null) {
        aiMap['correction'] = response.correction;
      }
      if (response.tips != null) {
        aiMap['tips'] = response.tips;
      }
      state = state.copyWith(
        messages: [...state.messages, aiMap],
        isLoading: false,
      );
    } on AppFailure catch (failure) {
      state = state.copyWith(isLoading: false);
      _setError(failure.message);
    }
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  String? _currentAccessToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  Future<void> _loadInitialMessage({
    required String scenarioId,
    required String token,
    required String targetLanguage,
    required String instructionLocale,
  }) async {
    final initial = await _repository.fetchInitialMessage(
      accessToken: token,
      mode: scenarioId,
      targetLanguage: targetLanguage,
      instructionLocale: instructionLocale,
    );
    final message = <String, dynamic>{
      'role': 'ai',
      'content': initial.replyText,
    };
    if (initial.translation != null) {
      message['translation'] = initial.translation;
    }
    if (initial.correction != null) {
      message['correction'] = initial.correction;
    }
    if (initial.tips != null) {
      message['tips'] = initial.tips;
    }
    state = state.copyWith(messages: [...state.messages, message]);
    _ref.read(sessionTopicTrackerProvider.notifier).markInitialSent(scenarioId);
  }

  Map<String, dynamic> _toUiMessageFromApi(ChatMessage message) {
    final role = message.role == 'assistant' ? 'ai' : message.role;
    final map = <String, dynamic>{'role': role, 'content': message.content};
    if (message.correction != null) {
      map['correction'] = message.correction;
    }
    if (message.tips != null) {
      map['tips'] = message.tips;
    }
    return map;
  }

  void _setError(String message) {
    state = state.copyWith(error: message);
  }

  Future<String> translateMessage({
    required String text,
    required String scenarioId,
    required String targetLanguage,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final token = _currentAccessToken();
    if (token == null) {
      _setError('Not authenticated');
      throw const AppFailure(
        message: 'Not authenticated',
        code: 'auth_unauthorized',
      );
    }

    try {
      final response = await _repository.ask(
        accessToken: token,
        request: ChatAskRequest(
          message:
              'Translate the following text to $targetLanguage. '
              'Return only the translated text with no extra commentary.\n\n$trimmed',
          mode: '${scenarioId}_translation',
          targetLanguage: targetLanguage,
          instructionLocale: _ref.read(appLocaleProvider),
        ),
      );
      final translation = (response.translation ?? response.replyText).trim();
      return translation;
    } on AppFailure catch (failure) {
      _setError(failure.message);
      rethrow;
    }
  }

  @override
  void dispose() {
    unawaited(_audioService.dispose());
    super.dispose();
  }
}
