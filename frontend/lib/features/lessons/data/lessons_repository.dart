import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config.dart';
import '../domain/entities/lesson.dart';
import 'local_lessons_catalog.dart';

final lessonsRepositoryProvider = Provider((ref) => LessonsRepository());

class LessonsRepository {
  final Map<String, Set<int>> _localCompletedByLanguage = {};

  Future<List<Lesson>> getLessons(String languageCode) async {
    final localBlueprints = LocalLessonsCatalog.forLanguage(languageCode);
    if (localBlueprints.isEmpty) return const [];

    final remoteByOrder = <int, Lesson>{};
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      final url = Uri.parse(
        '$defaultBackendBaseUrl/api/v1/lessons?language=$languageCode',
      );
      try {
        final response = await http.get(
          url,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          for (final json in data.whereType<Map<String, dynamic>>()) {
            final lesson = Lesson.fromJson(json, languageCode: languageCode);
            remoteByOrder[lesson.orderIndex] = lesson;
          }
        }
      } catch (_) {
        // If backend lessons are unavailable, fall back to local curriculum.
      }
    }

    final completedLocal = _localCompletedByLanguage.putIfAbsent(
      languageCode,
      () => <int>{},
    );
    final merged = <Lesson>[];
    var previousCompleted = true;

    for (final blueprint in localBlueprints) {
      final remote = remoteByOrder[blueprint.orderIndex];
      final isRemoteCompleted = remote?.status == LessonStatus.completed;
      final isLocalCompleted = completedLocal.contains(blueprint.orderIndex);
      final isCompleted = isRemoteCompleted || isLocalCompleted;

      LessonStatus status;
      if (isCompleted) {
        status = LessonStatus.completed;
      } else if (previousCompleted) {
        status = LessonStatus.available;
      } else {
        status = LessonStatus.locked;
      }

      merged.add(
        Lesson(
          id: remote?.id ?? 'local-$languageCode-${blueprint.orderIndex}',
          title: blueprint.title,
          description: blueprint.description,
          status: status,
          orderIndex: blueprint.orderIndex,
          languageCode: languageCode,
          content: blueprint.toContentMap(),
        ),
      );

      previousCompleted = isCompleted;
    }

    return merged;
  }

  Future<void> completeLesson({
    required String lessonId,
    required String languageCode,
    required int orderIndex,
  }) async {
    if (lessonId.startsWith('local-')) {
      _localCompletedByLanguage
          .putIfAbsent(languageCode, () => <int>{})
          .add(orderIndex);
      return;
    }

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return;

    final url = Uri.parse(
      '$defaultBackendBaseUrl/api/v1/lessons/$lessonId/complete',
    );
    await http.post(url, headers: {'Authorization': 'Bearer $token'});
  }
}
