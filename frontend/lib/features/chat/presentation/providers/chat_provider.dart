import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/chat_models.dart';

// Constants
const String kBaseUrl = 'http://localhost:8080/api/v1/chat';

// Provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

// State
class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: [])); // Initial empty state

  Future<void> loadHistory() async {
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
        Uri.parse('$kBaseUrl/history/v2?limit=50'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('History Status: ${response.statusCode}');
      print('History Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final historyResponse = ChatHistoryResponse.fromJson(data);
          print('Parsed ${historyResponse.messages.length} messages');
          
          final loadedMessages = historyResponse.messages.map((m) => {
            'role': m.role == 'assistant' ? 'ai' : m.role, 
            'content': m.content,
          }).toList();

          state = state.copyWith(
            messages: loadedMessages,
            isLoading: false,
          );
        } catch (e, stack) {
          print('JSON Parse Error: $e');
          print(stack);
          state = state.copyWith(isLoading: false, error: 'Parse Error: $e');
        }
      } else {
        print('History Error: ${response.statusCode} - ${response.body}');
        state = state.copyWith(isLoading: false, error: 'Failed to load history');
      }
    } catch (e) {
      print('Network Error loading history: $e');
      state = state.copyWith(isLoading: false, error: 'Network error loading history');
    }
  }

  Future<void> sendMessage(String text, String scenarioId) async {
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

      final body = ChatAskRequest(message: text, mode: scenarioId).toJson();

      final response = await http.post(
        Uri.parse('$kBaseUrl/ask'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = ChatAskResponse.fromJson(data);
        
        state = state.copyWith(
          messages: [...state.messages, {'role': 'ai', 'content': chatResponse.replyText}],
          isLoading: false,
        );
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        state = state.copyWith(
           messages: [...state.messages, {'role': 'ai', 'content': 'Error: ${response.statusCode}'}],
           isLoading: false,
        );
      }
    } catch (e) {
      print('Network Error: $e');
      state = state.copyWith(
        messages: [...state.messages, {'role': 'ai', 'content': 'Network/Connection Error'}],
        isLoading: false,
      );
    }
  }
}
