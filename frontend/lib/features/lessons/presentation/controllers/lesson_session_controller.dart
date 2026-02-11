import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/exercise.dart';
import '../../data/lessons_repository.dart';
import '../../data/services/tts_service.dart';

// ─── State ────────────────────────────────────────────────────────
class LessonSessionState extends Equatable {
  final Lesson lesson;
  final int currentIndex;
  final int hearts;
  final int streak;          // Consecutive correct answers
  final bool isCompleted;
  final bool isCheckButtonLoading;
  final String? feedbackMessage;
  final bool? isAnswerCorrect;
  final dynamic userAnswer;

  const LessonSessionState({
    required this.lesson,
    this.currentIndex = 0,
    this.hearts = 5,
    this.streak = 0,
    this.isCompleted = false,
    this.isCheckButtonLoading = false,
    this.feedbackMessage,
    this.isAnswerCorrect,
    this.userAnswer,
  });

  Exercise get currentExercise => lesson.exercises[currentIndex];
  double get progress => (currentIndex) / lesson.exercises.length;

  LessonSessionState copyWith({
    Lesson? lesson,
    int? currentIndex,
    int? hearts,
    int? streak,
    bool? isCompleted,
    bool? isCheckButtonLoading,
    String? feedbackMessage,
    bool? isAnswerCorrect,
    dynamic userAnswer,
    bool clearFeedback = false,
    bool clearUserAnswer = false,
  }) {
    return LessonSessionState(
      lesson: lesson ?? this.lesson,
      currentIndex: currentIndex ?? this.currentIndex,
      hearts: hearts ?? this.hearts,
      streak: streak ?? this.streak,
      isCompleted: isCompleted ?? this.isCompleted,
      isCheckButtonLoading: isCheckButtonLoading ?? this.isCheckButtonLoading,
      feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isAnswerCorrect: clearFeedback ? null : (isAnswerCorrect ?? this.isAnswerCorrect),
      userAnswer: clearUserAnswer ? null : (userAnswer ?? this.userAnswer),
    );
  }

  @override
  List<Object?> get props => [
    lesson, currentIndex, hearts, streak,
    isCompleted, isCheckButtonLoading,
    feedbackMessage, isAnswerCorrect, userAnswer,
  ];
}

// ─── Controller ───────────────────────────────────────────────────
class LessonSessionController extends StateNotifier<LessonSessionState> {
  final LessonsRepository _repository;
  final LessonTtsService _ttsService;

  LessonSessionController(Lesson lesson, this._repository, this._ttsService)
      : super(LessonSessionState(lesson: lesson));

  void updateUserAnswer(dynamic answer) {
    state = state.copyWith(userAnswer: answer);
  }

  /// Play TTS for a word or phrase using the lesson's language code.
  void speakWord(String text) {
    _ttsService.speak(text, state.lesson.languageCode);
  }

  void checkAnswer() {
    if (state.isCompleted) return;

    final exercise = state.currentExercise;
    bool isCorrect = false;

    if (exercise is ArrangeWordsExercise) {
      final currentOrder = state.userAnswer as List<String>? ?? [];
      isCorrect = _listEquals(currentOrder, exercise.solution);
    } else if (exercise is TranslateExercise) {
      final currentOrder = state.userAnswer as List<String>? ?? [];
      isCorrect = _listEquals(currentOrder, exercise.solution);
    } else if (exercise is MultipleChoiceExercise) {
      final selected = state.userAnswer as int?;
      isCorrect = selected != null && selected == exercise.correctOptionIndex;
    }

    if (isCorrect) {
      state = state.copyWith(
        isAnswerCorrect: true,
        feedbackMessage: _correctFeedback(),
        streak: state.streak + 1,
      );
    } else {
      state = state.copyWith(
        isAnswerCorrect: false,
        feedbackMessage: 'Incorrect. Try again.',
        hearts: state.hearts - 1,
        streak: 0,
      );
    }
  }

  Future<void> continueToNext() async {
    if (state.isAnswerCorrect == true) {
      if (state.currentIndex >= state.lesson.exercises.length - 1) {
        // Lesson complete
        state = state.copyWith(isCheckButtonLoading: true);
        await _repository.completeLesson(state.lesson);
        state = state.copyWith(isCompleted: true, isCheckButtonLoading: false);
      } else {
        state = state.copyWith(
          currentIndex: state.currentIndex + 1,
          clearFeedback: true,
          clearUserAnswer: true,
        );
      }
    } else {
      // Incorrect — just clear feedback so they can retry
      state = state.copyWith(clearFeedback: true, clearUserAnswer: true);
    }
  }

  String _correctFeedback() {
    if (state.streak >= 3) return 'Amazing! ${state.streak + 1} in a row!';
    final messages = ['Nice!', 'Great job!', 'Correct!', 'Well done!'];
    return messages[state.currentIndex % messages.length];
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─── Provider ─────────────────────────────────────────────────────
final lessonSessionControllerProvider = StateNotifierProvider.family<
    LessonSessionController, LessonSessionState, Lesson>((ref, lesson) {
  final repo = ref.watch(lessonsRepositoryProvider);
  final tts = ref.watch(lessonTtsServiceProvider);
  return LessonSessionController(lesson, repo, tts);
});
