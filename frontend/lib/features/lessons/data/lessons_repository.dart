import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/lesson.dart';
import 'local_lessons_catalog.dart';
import 'datasources/local_lesson_datasource.dart';


final lessonsRepositoryProvider = Provider((ref) {
  final localDataSource = ref.watch(localLessonDataSourceProvider);
  return LessonsRepository(localDataSource);
});

class LessonsRepository {
  final LocalLessonDataSource _localDataSource;

  LessonsRepository(this._localDataSource);

  Future<List<Lesson>> getLessons(String languageCode) async {
    // 1. Get static content
    final bluePrints = LocalLessonsCatalog.forLanguage(languageCode);
    if (bluePrints.isEmpty) return [];

    // 2. Get user progress from SQLite
    // Returns List<LessonProgressTableData>
    final progressList = await _localDataSource.getProgressForLanguage(languageCode);
    final completedIds = progressList
        .where((p) => p.isCompleted)
        .map((p) => p.id)
        .toSet();

    // 3. Merge and determine status
    final merged = <Lesson>[];
    var isPreviousCompleted = true; // First lesson is always unlocked if previous (null) is "completed"

    for (final lesson in bluePrints) {
      final isCompleted = completedIds.contains(lesson.id);
      
      LessonStatus status;
      if (isCompleted) {
        status = LessonStatus.completed;
      } else if (isPreviousCompleted) {
        status = LessonStatus.available;
      } else {
        status = LessonStatus.locked;
      }

      merged.add(lesson.copyWith(status: status));
      
      // Update for next iteration
      isPreviousCompleted = isCompleted;
    }

    return merged;
  }

  Future<void> completeLesson(Lesson lesson) async {
    // Save to local DB
    await _localDataSource.saveLessonProgress(
      lesson.id,
      lesson.languageCode,
      true, // isCompleted
      3,    // Stars (hardcoded for now, can be dynamic later)
    );
    
    // TODO: Sync to backend in background
  }
}
