import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/lesson.dart';

final localLessonDataSourceProvider = Provider<LocalLessonDataSource>((ref) {
  return LocalLessonDataSource(AppDatabase()); // In real app, provide DB instance globally
});

class LocalLessonDataSource {
  final AppDatabase _db;

  LocalLessonDataSource(this._db);

  Future<void> saveLessonProgress(String lessonId, String languageCode, bool isCompleted, int stars) async {
    await _db.into(_db.lessonProgressTable).insertOnConflictUpdate(
      LessonProgressTableCompanion(
        id: Value(lessonId),
        languageCode: Value(languageCode),
        isCompleted: Value(isCompleted),
        stars: Value(stars),
        completionDate: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LessonProgressTableData>> getProgressForLanguage(String languageCode) async {
    return (_db.select(_db.lessonProgressTable)
      ..where((tbl) => tbl.languageCode.equals(languageCode)))
      .get();
  }

  Future<void> updateWordStrength(String word, String languageCode, bool isCorrect) async {
    final existingStats = await (_db.select(_db.wordStrengthTable)
      ..where((tbl) => tbl.word.equals(word) & tbl.languageCode.equals(languageCode)))
      .getSingleOrNull();

    double currentStrength = existingStats?.strength ?? 0.0;
    
    // Simple SRS Algorithm
    if (isCorrect) {
      currentStrength = (currentStrength + 0.1).clamp(0.0, 1.0);
    } else {
      currentStrength = (currentStrength - 0.2).clamp(0.0, 1.0);
    }

    await _db.into(_db.wordStrengthTable).insertOnConflictUpdate(
      WordStrengthTableCompanion(
        word: Value(word),
        languageCode: Value(languageCode),
        strength: Value(currentStrength),
        lastReviewDate: Value(DateTime.now()),
      ),
    );
  }
}
