import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config.dart';
import '../domain/entities/lesson.dart';

final lessonsRepositoryProvider = Provider((ref) => LessonsRepository());

class LessonsRepository {
  final Map<String, Lesson> _lessonCache = {};

  Future<List<Lesson>> getLessons({String? languageCode}) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return [];

    final params = <String, String>{};
    if (languageCode != null && languageCode.isNotEmpty) {
      params['language'] = languageCode;
    }
    // Use lightweight metadata endpoint for fast initial loading.
    final url = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/lessons/summary',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Parse on a background isolate to avoid jank for larger payloads.
      return compute(_parseLessonsList, response.body);
    } else {
      throw Exception('Failed to load lessons');
    }
  }

  Future<Lesson> getLessonDetails({
    required String lessonId,
    String? languageCode,
  }) async {
    // Serve from in-memory cache if available.
    final cached = _lessonCache[lessonId];
    if (cached != null && cached.content.isNotEmpty) {
      return cached;
    }

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final params = <String, String>{};
    if (languageCode != null && languageCode.isNotEmpty) {
      params['language'] = languageCode;
    }

    final url = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/lessons/$lessonId',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load lesson details');
    }

    final lesson = await compute(_parseSingleLesson, response.body);
    _lessonCache[lessonId] = lesson;
    return lesson;
  }

  Future<void> completeLesson(String lessonId) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return;

    final url = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/lessons/$lessonId/complete',
    );
    await http.post(url, headers: {'Authorization': 'Bearer $token'});
  }

  Future<LessonSpeechAudio> synthesizeSpeech({
    required String text,
    required String languageCode,
  }) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final url = Uri.parse('$defaultBackendBaseUrl/api/v1/tts/speak');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'language': languageCode,
        'languageCode': languageCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to synthesize speech');
    }

    return LessonSpeechAudio(
      bytes: response.bodyBytes,
      codec: response.headers['x-audio-codec'] ?? 'pcm16',
      sampleRate:
          int.tryParse(response.headers['x-audio-sample-rate'] ?? '') ?? 24000,
    );
  }
}

List<Lesson> _parseLessonsList(String body) {
  final List<dynamic> data = jsonDecode(body);
  return data.map((json) => Lesson.fromJson(json as Map<String, dynamic>)).toList();
}

Lesson _parseSingleLesson(String body) {
  final Map<String, dynamic> json = jsonDecode(body);
  return Lesson.fromJson(json);
}

class LessonSpeechAudio {
  final List<int> bytes;
  final String codec;
  final int sampleRate;

  LessonSpeechAudio({
    required this.bytes,
    required this.codec,
    required this.sampleRate,
  });
}
