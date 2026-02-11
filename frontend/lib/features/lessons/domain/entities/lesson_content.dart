import 'package:equatable/equatable.dart';

class LessonContent extends Equatable {
  final List<String> sections;
  final List<ArrangeWordsExercise> exercises;

  const LessonContent({required this.sections, required this.exercises});

  @override
  List<Object?> get props => [sections, exercises];
}

class ArrangeWordsExercise extends Equatable {
  final String id;
  final String prompt;
  final String hint;
  final List<String> words;
  final List<String> solution;

  const ArrangeWordsExercise({
    required this.id,
    required this.prompt,
    required this.hint,
    required this.words,
    required this.solution,
  });

  @override
  List<Object?> get props => [id, prompt, hint, words, solution];
}
