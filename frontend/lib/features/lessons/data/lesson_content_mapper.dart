import '../domain/entities/lesson_content.dart';

class LessonContentMapper {
  const LessonContentMapper._();

  static LessonContent fromMap(Map<String, dynamic> content) {
    final rawSections = (content['sections'] as List?) ?? const [];
    final sections = rawSections
        .whereType<Map>()
        .map((section) => section['content']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList(growable: false);

    final rawExercises = (content['exercises'] as List?) ?? const [];
    final exercises = rawExercises
        .whereType<Map>()
        .where((exercise) => exercise['type'] == 'arrange_words')
        .map((exercise) {
          final words = _asStringList(exercise['wordBank']);
          final solution = _asStringList(exercise['solution']);
          return ArrangeWordsExercise(
            id: exercise['id']?.toString() ?? '',
            prompt: exercise['prompt']?.toString() ?? '',
            hint: exercise['hint']?.toString() ?? '',
            words: words,
            solution: solution,
          );
        })
        .where(
          (exercise) =>
              exercise.words.isNotEmpty && exercise.solution.isNotEmpty,
        )
        .toList(growable: false);

    return LessonContent(sections: sections, exercises: exercises);
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
