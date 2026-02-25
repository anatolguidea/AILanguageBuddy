import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config.dart';
import '../domain/entities/lesson.dart';

final lessonsRepositoryProvider = Provider((ref) => LessonsRepository());

class LessonsRepository {
  Future<List<Lesson>> getLessons({String? languageCode}) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return [];

    final params = <String, String>{};
    if (languageCode != null && languageCode.isNotEmpty) {
      params['language'] = languageCode;
    }
    final url = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/lessons',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Lesson.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load lessons');
    }
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
