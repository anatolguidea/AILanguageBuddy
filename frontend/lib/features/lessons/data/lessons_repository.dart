import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config.dart';
import '../domain/entities/lesson.dart';

final lessonsRepositoryProvider = Provider((ref) => LessonsRepository());

class LessonsRepository {
  Future<List<Lesson>> getLessons(String languageCode) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return [];

    final url = Uri.parse('${defaultBackendBaseUrl}/api/v1/lessons?language=$languageCode');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
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

    final url = Uri.parse('${defaultBackendBaseUrl}/api/v1/lessons/$lessonId/complete');
    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
}
