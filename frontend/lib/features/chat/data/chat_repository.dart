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

  Future<ChatMessage> sendMessage(
    String text, {
    String? accessToken,
    String? targetLanguage,
  }) async {
    final url = ApiRoutes.chatAsk();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
    };
    late final http.Response response;
    try {
      final body = {
        'message': text,
        if (targetLanguage != null) 'targetLanguage': targetLanguage,
      };
      
      response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    } on SocketException catch (e) {
      throw Exception(_wrapConnectionError(e, url));
    } on OSError catch (e) {
      throw Exception(_wrapConnectionError(e, url));
    }

    if (response.statusCode == 401) {
      throw Exception('Please sign in again.');
    }
    if (response.statusCode != 200) {
      throw Exception(_tryReadApiError(response.body) ?? 'Server responded with ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final replyText = decoded is Map<String, dynamic> ? (decoded['replyText'] ?? '').toString() : '';
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      text: replyText.isEmpty ? 'No reply received.' : replyText,
      createdAt: DateTime.now(),
    );
  }

  Future<List<ChatMessage>> fetchHistory({
    int limit = 50,
    String? accessToken,
  }) async {
    final uri = Uri.parse(ApiRoutes.chatHistory(limit: limit));
    final headers = <String, String>{
      if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
    };
    final response = await _client.get(uri, headers: headers.isEmpty ? null : headers);
    if (response.statusCode == 401) {
      throw Exception('Please sign in again.');
    }
    if (response.statusCode != 200) {
      throw Exception(_tryReadApiError(response.body) ?? 'Failed to load history');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      // Legacy shape; keep for safety.
      return decoded.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) {
        return items.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  static String? _tryReadApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return null;
  }
}
