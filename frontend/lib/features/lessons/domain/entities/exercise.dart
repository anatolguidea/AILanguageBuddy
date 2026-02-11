import 'package:equatable/equatable.dart';

enum ExerciseType {
  arrangeWords,
  translateSentence,
  multipleChoice,
  listening,
  speaking,
}

/// Base class for all exercise types.
abstract class Exercise extends Equatable {
  final String id;
  final ExerciseType type;
  final String prompt;

  const Exercise({
    required this.id,
    required this.type,
    required this.prompt,
  });

  @override
  List<Object?> get props => [id, type, prompt];
}

/// User arranges shuffled words into the correct sentence.
class ArrangeWordsExercise extends Exercise {
  final List<String> words;
  final List<String> solution;
  final String hint;
  /// The sentence in the foreign language (shown in a speech bubble).
  final String? foreignPhrase;

  const ArrangeWordsExercise({
    required super.id,
    required super.prompt,
    required this.words,
    required this.solution,
    required this.hint,
    this.foreignPhrase,
  }) : super(type: ExerciseType.arrangeWords);

  @override
  List<Object?> get props => [...super.props, words, solution, hint, foreignPhrase];
}

/// "Write this in English" — user hears/sees a foreign phrase and picks
/// target-language words to form the translation.
class TranslateExercise extends Exercise {
  /// The foreign sentence displayed in a speech bubble.
  final String foreignPhrase;
  /// Word bank in the target language (shuffled for display).
  final List<String> wordBank;
  /// Correct ordered answer in the target language.
  final List<String> solution;

  const TranslateExercise({
    required super.id,
    required super.prompt,
    required this.foreignPhrase,
    required this.wordBank,
    required this.solution,
  }) : super(type: ExerciseType.translateSentence);

  @override
  List<Object?> get props => [...super.props, foreignPhrase, wordBank, solution];
}

/// "Which one of these is X?" — pick the correct option.
class MultipleChoiceExercise extends Exercise {
  final List<ChoiceOption> options;
  final int correctOptionIndex;

  const MultipleChoiceExercise({
    required super.id,
    required super.prompt,
    required this.options,
    required this.correctOptionIndex,
  }) : super(type: ExerciseType.multipleChoice);

  @override
  List<Object?> get props => [...super.props, options, correctOptionIndex];
}

/// A single option in a multiple-choice exercise.
class ChoiceOption extends Equatable {
  final String label; // Foreign-language label shown on card
  final String emoji; // Emoji used as visual (e.g. ☕, 🥐)

  const ChoiceOption({required this.label, required this.emoji});

  @override
  List<Object?> get props => [label, emoji];
}

/// Listening comprehension — play audio, user types or picks the text.
class ListeningExercise extends Exercise {
  final String textToSynthesize;
  final String correctText;

  const ListeningExercise({
    required super.id,
    required super.prompt,
    required this.textToSynthesize,
    required this.correctText,
  }) : super(type: ExerciseType.listening);

  @override
  List<Object?> get props => [...super.props, textToSynthesize, correctText];
}
