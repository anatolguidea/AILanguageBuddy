import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/models/chat_models.dart';

// Constants
const String kBaseUrl = 'http://192.168.107.166:8080/api/v1/chat';

// Provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
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
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  
  ChatNotifier() : super(ChatState()) {
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

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> loadHistory(String scenarioId) async {
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
        
        final loadedMessages = historyResponse.messages.map((m) => {
          'role': m.role == 'assistant' ? 'ai' : m.role, 
          'content': m.content,
        }).toList();

        state = state.copyWith(
          messages: loadedMessages,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load history');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error loading history');
    }
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
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
      ).toJson();

      final response = await http.post(
        Uri.parse('$kBaseUrl/ask'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = ChatAskResponse.fromJson(data);
        final aiReply = chatResponse.replyText;
        
        state = state.copyWith(
          messages: [...state.messages, {'role': 'ai', 'content': aiReply}],
          isLoading: false,
        );
        
        // Auto-speak disabled for Orchestrator phase
        // speak(aiReply); 
        
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
