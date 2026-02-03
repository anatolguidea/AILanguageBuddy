import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../domain/chat_message.dart';

class ChatRepository {
  ChatRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String _wrapConnectionError(Object e, String url) {
    if (e is SocketException) {
      return 'Cannot reach backend at $url. Is the server running? (e.g. run Spring Boot on port 8080)';
    }
    if (e is OSError) {
      return 'Network error: $e';
    }
    return e.toString();
  }

  Future<ChatMessage> sendMessage(String text) async {
    final url = ApiRoutes.chatAsk();
    late final http.Response response;
    try {
      response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'text/plain'},
        body: text,
      );
    } on SocketException catch (e) {
      throw Exception(_wrapConnectionError(e, url));
    } on OSError catch (e) {
      throw Exception(_wrapConnectionError(e, url));
    }

    if (response.statusCode != 200) {
      throw Exception('Server responded with ${response.statusCode}');
    }

    // Backend currently returns plain text. Wrap it into a ChatMessage.
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      text: response.body,
      createdAt: DateTime.now(),
    );
  }

  Future<List<ChatMessage>> fetchHistory({int limit = 50}) async {
    final response = await _client.get(Uri.parse(ApiRoutes.chatHistory(limit: limit)));
    if (response.statusCode != 200) {
      throw Exception('Failed to load history');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
