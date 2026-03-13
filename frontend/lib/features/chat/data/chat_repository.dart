import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../../../core/errors/app_failure.dart';
import 'models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

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

  Future<ChatAskResponse> ask({
    required String accessToken,
    required ChatAskRequest request,
  }) async {
    final uri = Uri.parse('$defaultBackendBaseUrl/api/v1/chat/ask');
    try {
      final response = await _client
          .post(
            uri,
            headers: _authJsonHeaders(accessToken),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw _failureFromResponse(response, fallback: 'Failed to send message');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatAskResponse.fromJson(json);
    } on SocketException catch (e) {
      throw AppFailure(
        message: _wrapConnectionError(e, uri.toString()),
        code: 'network_unreachable',
        cause: e,
      );
    } on OSError catch (e) {
      throw AppFailure(
        message: _wrapConnectionError(e, uri.toString()),
        code: 'network_os_error',
        cause: e,
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure(
        message: 'Unexpected error while sending message.',
        code: 'chat_send_unexpected',
        cause: e,
      );
    }
  }

  Future<ChatHistoryResponse> fetchHistory({
    required String accessToken,
    required String mode,
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/chat/history/v2?limit=$limit&mode=${Uri.encodeComponent(mode)}',
    );
    try {
      final response = await _client
          .get(uri, headers: _authJsonHeaders(accessToken))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw _failureFromResponse(response, fallback: 'Failed to load history');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ChatHistoryResponse.fromJson(decoded);
      }
      if (decoded is List) {
        return ChatHistoryResponse(
          messages: decoded
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      throw const AppFailure(
        message: 'Invalid history response format.',
        code: 'chat_history_invalid_format',
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure(
        message: 'Unexpected error while loading history.',
        code: 'chat_history_unexpected',
        cause: e,
      );
    }
  }

  Future<ChatAskResponse> fetchInitialMessage({
    required String accessToken,
    required String mode,
    required String targetLanguage,
    required String instructionLocale,
  }) async {
    final uri = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/chat/initial'
      '?mode=${Uri.encodeComponent(mode)}'
      '&targetLanguage=${Uri.encodeComponent(targetLanguage)}'
      '&instructionLocale=${Uri.encodeComponent(instructionLocale)}',
    );
    try {
      final response = await _client
          .get(uri, headers: _authJsonHeaders(accessToken))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw _failureFromResponse(
          response,
          fallback: 'Failed to start conversation.',
        );
      }
      return ChatAskResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure(
        message: 'Unexpected error while loading initial message.',
        code: 'chat_initial_unexpected',
        cause: e,
      );
    }
  }

  Future<void> deleteHistory({
    required String accessToken,
    required String mode,
  }) async {
    final uri = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/chat/history?mode=${Uri.encodeComponent(mode)}',
    );
    try {
      final response = await _client
          .delete(uri, headers: _authJsonHeaders(accessToken))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _failureFromResponse(response, fallback: 'Failed to clear history');
      }
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure(
        message: 'Unexpected error while clearing history.',
        code: 'chat_delete_unexpected',
        cause: e,
      );
    }
  }

  Future<ChatSpeechAudio> synthesizeSpeech({
    required String accessToken,
    required String text,
    required String languageCode,
  }) async {
    final uri = Uri.parse('$defaultBackendBaseUrl/api/v1/tts/speak');
    try {
      final response = await _client
          .post(
            uri,
            headers: _authJsonHeaders(accessToken),
            body: jsonEncode({
              'text': text,
              'language': languageCode,
              'languageCode': languageCode,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw _failureFromResponse(
          response,
          fallback: 'Failed to synthesize speech.',
        );
      }
      return ChatSpeechAudio(
        bytes: response.bodyBytes,
        codec: response.headers['x-audio-codec'] ?? 'pcm16',
        sampleRate:
            int.tryParse(response.headers['x-audio-sample-rate'] ?? '') ?? 24000,
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure(
        message: 'Unexpected error while synthesizing speech.',
        code: 'chat_tts_unexpected',
        cause: e,
      );
    }
  }

  static AppFailure _failureFromResponse(
    http.Response response, {
    required String fallback,
  }) {
    if (response.statusCode == 401) {
      return const AppFailure(
        message: 'Please sign in again.',
        code: 'auth_unauthorized',
      );
    }
    return AppFailure(
      message: _tryReadApiError(response.body) ?? fallback,
      code: 'http_${response.statusCode}',
    );
  }

  static Map<String, String> _authJsonHeaders(String accessToken) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  static String? _tryReadApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

class ChatSpeechAudio {
  final List<int> bytes;
  final String codec;
  final int sampleRate;

  const ChatSpeechAudio({
    required this.bytes,
    required this.codec,
    required this.sampleRate,
  });
}
