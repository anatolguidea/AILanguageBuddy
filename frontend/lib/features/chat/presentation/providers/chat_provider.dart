import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/models/chat_models.dart';
import '../../../../core/config.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import 'current_topic_language_provider.dart';
import 'session_topic_tracker.dart';

// Constants
String get kBaseUrl => '$defaultBackendBaseUrl/api/v1/chat';

// Provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

// State
class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;
  final bool isSpeaking;
  final bool isListening;

  ChatState({
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

// Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  FlutterSoundPlayer? _backendTtsPlayer;
  static bool _backendPlayerOpened = false;

  ChatNotifier(this._ref) : super(ChatState()) {
    _initTts();
    _initStt();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    
    _flutterTts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true);
    });

    _flutterTts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });

    _flutterTts.setErrorHandler((msg) {
      state = state.copyWith(isSpeaking: false, error: "TTS Error: $msg");
    });
  }

  Future<void> _initStt() async {
    // Basic initialization, permission request happens on startListening
  }

  Future<void> startListening(Function(String) onResult) async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
        onError: (errorNotification) {
          state = state.copyWith(isListening: false, error: "STT Error: ${errorNotification.errorMsg}");
        },
      );

      if (available) {
        state = state.copyWith(isListening: true);
        _speechToText.listen(
          onResult: (result) {
             onResult(result.recognizedWords);
          },
        );
      } else {
        state = state.copyWith(error: "Speech recognition not available");
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to initialize STT: $e");
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  /// Speaks [text] via backend TTS. Only pass the AI reply content (not correction/tips).
  /// Uses current topic language code so voice accent matches the conversation.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isSpeaking: true);
    try {
      final code = _ref.read(currentTopicLanguageProvider) ?? _ref.read(languageProvider).code;
      final played = await _playBackendTts(text, code);
      if (!played) await _flutterTts.speak(text);
    } catch (_) {
      await _flutterTts.speak(text);
    } finally {
      state = state.copyWith(isSpeaking: false);
    }
  }

  /// POST to backend TTS. [languageCode] must be 2-letter (en, ro, es) for correct accent.
  Future<bool> _playBackendTts(String text, String languageCode) async {
    // Ensure we never send shorthand "e" (backend maps it, but send "en" for consistency)
    final lang = languageCode.trim().toLowerCase();
    final code = (lang == 'e' || lang.isEmpty) ? 'en' : lang;
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return false;
      final uri = Uri.parse('$defaultBackendBaseUrl/api/v1/tts/speak');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'language': code,
          'languageCode': code,
        }),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return false;
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return false;
      final codecStr = (response.headers['x-audio-codec'] ?? 'pcm16').toLowerCase();
      final codec = codecStr == 'mp3' ? Codec.mp3 : Codec.pcm16;
      final sampleRate = int.tryParse(response.headers['x-audio-sample-rate'] ?? '') ?? 24000;
      _backendTtsPlayer ??= FlutterSoundPlayer();
      if (!_backendPlayerOpened) {
        await _backendTtsPlayer!.openPlayer();
        _backendPlayerOpened = true;
      }
      if (_backendTtsPlayer!.isPlaying) await _backendTtsPlayer!.stopPlayer();
      await _backendTtsPlayer!.startPlayer(
        fromDataBuffer: Uint8List.fromList(bytes),
        codec: codec,
        sampleRate: sampleRate,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    if (_backendTtsPlayer != null && _backendTtsPlayer!.isPlaying) {
      await _backendTtsPlayer!.stopPlayer();
    }
  }

  Future<void> loadHistory(String scenarioId, {String? targetLanguage}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$kBaseUrl/history/v2?limit=50&mode=$scenarioId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final historyResponse = ChatHistoryResponse.fromJson(data);

        final loadedMessages = historyResponse.messages.map((m) {
          final role = m.role == 'assistant' ? 'ai' : m.role;
          final map = <String, dynamic>{
            'role': role,
            'content': m.content,
          };
          if (m.correction != null) map['correction'] = m.correction;
          if (m.tips != null) map['tips'] = m.tips;
          return map;
        }).toList();

        state = state.copyWith(
          messages: loadedMessages,
          isLoading: false,
        );

        // Session topic tracker: if no history and we haven't sent initial for this topic, fetch it.
        final tracker = _ref.read(sessionTopicTrackerProvider.notifier);
        if (loadedMessages.isEmpty && !tracker.hasReceivedInitial(scenarioId)) {
          final instructionLocale = _ref.read(appLocaleProvider);
          await _fetchInitialMessage(scenarioId, token, headers, targetLanguage ?? 'English', instructionLocale);
        }
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load history');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error loading history');
    }
  }

  Future<void> _fetchInitialMessage(String scenarioId, String token, Map<String, String> headers, String targetLanguage, String instructionLocale) async {
    try {
      final uri = Uri.parse('$kBaseUrl/initial?mode=${Uri.encodeComponent(scenarioId)}&targetLanguage=${Uri.encodeComponent(targetLanguage)}&instructionLocale=${Uri.encodeComponent(instructionLocale)}');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = ChatAskResponse.fromJson(data);
        final map = <String, dynamic>{
          'role': 'ai',
          'content': chatResponse.replyText,
        };
        if (chatResponse.correction != null) map['correction'] = chatResponse.correction;
        if (chatResponse.tips != null) map['tips'] = chatResponse.tips;
        state = state.copyWith(messages: [...state.messages, map]);
        _ref.read(sessionTopicTrackerProvider.notifier).markInitialSent(scenarioId);
      }
    } catch (_) {
      // Non-fatal: user can still type
    }
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  /// Deletes server history for this topic, clears local messages, and reloads so user gets a fresh initial message.
  Future<void> deleteHistoryAndRestart(String scenarioId, {String? targetLanguage}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse('$kBaseUrl/history?mode=${Uri.encodeComponent(scenarioId)}');
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 204 || response.statusCode == 200) {
        state = state.copyWith(messages: []);
        _ref.read(sessionTopicTrackerProvider.notifier).clearInitialForTopic(scenarioId);
        await loadHistory(scenarioId, targetLanguage: targetLanguage);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to clear history');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to clear history');
    }
  }

  Future<void> sendMessage(String text, String scenarioId, String targetLanguage) async {
    if (text.trim().isEmpty) return;

    // Optimistic Update
    final userMessage = {'role': 'user', 'content': text};
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = ChatAskRequest(
        message: text,
        mode: scenarioId,
        targetLanguage: targetLanguage,
        instructionLocale: _ref.read(appLocaleProvider),
      ).toJson();

      final response = await http.post(
        Uri.parse('$kBaseUrl/ask'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = ChatAskResponse.fromJson(data);
        final aiMap = <String, dynamic>{
          'role': 'ai',
          'content': chatResponse.replyText,
        };
        if (chatResponse.correction != null) aiMap['correction'] = chatResponse.correction;
        if (chatResponse.tips != null) aiMap['tips'] = chatResponse.tips;

        state = state.copyWith(
          messages: [...state.messages, aiMap],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
           messages: [...state.messages, {'role': 'ai', 'content': 'Error: ${response.statusCode}'}],
           isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        messages: [...state.messages, {'role': 'ai', 'content': 'Network/Connection Error'}],
        isLoading: false,
      );
    }
  }
}
