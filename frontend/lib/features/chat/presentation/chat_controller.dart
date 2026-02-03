import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_state.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';
import 'chat_state.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) => ChatController(ref));

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState()) {
    loadHistory();
  }

  final Ref _ref;

  String? get _userId => _ref.read(authUserProvider).value?.id;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final history = await _ref.read(chatRepositoryProvider).fetchHistory(userId: _userId);
      state = state.copyWith(messages: history, isLoadingHistory: false);
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: _errorMessage(e));
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      error: null,
    );

    try {
      final reply = await _ref.read(chatRepositoryProvider).sendMessage(text, userId: _userId);
      state = state.copyWith(
        messages: [...state.messages, reply],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: _errorMessage(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  static String _errorMessage(Object e) {
    final s = e.toString();
    if (s.startsWith('Instance of ')) {
      return 'Something went wrong. Check that the backend is running.';
    }
    if (e is Exception && e.toString().startsWith('Exception: ')) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return s;
  }
}
