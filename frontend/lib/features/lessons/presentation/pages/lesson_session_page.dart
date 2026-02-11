import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/exercise.dart';
import '../controllers/lesson_session_controller.dart';
import '../widgets/exercises/arrange_words_widget.dart';
import '../widgets/exercises/translate_exercise_widget.dart';
import '../widgets/exercises/multiple_choice_widget.dart';

class LessonSessionPage extends ConsumerWidget {
  final Lesson lesson;

  const LessonSessionPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonSessionControllerProvider(lesson));
    final controller = ref.read(lessonSessionControllerProvider(lesson).notifier);

    // Handle lesson completion
    if (state.isCompleted) {
      return _LessonCompletedScreen(
        lesson: lesson,
        streak: state.streak,
        heartsRemaining: state.hearts,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: X | progress | hearts ──
            _DuolingoAppBar(
              progress: state.progress,
              hearts: state.hearts,
              streak: state.streak,
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),

            // ── Exercise content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCurrentExercise(state.currentExercise, controller),
              ),
            ),

            // ── Bottom: feedback bar OR check button ──
            if (state.isAnswerCorrect != null)
              _FeedbackBar(
                isCorrect: state.isAnswerCorrect!,
                message: state.feedbackMessage ?? '',
                onContinue: () => controller.continueToNext(),
              )
            else
              _CheckButton(
                canCheck: _canCheck(state),
                isLoading: state.isCheckButtonLoading,
                onCheck: controller.checkAnswer,
              ),
          ],
        ),
      ),
    );
  }

  bool _canCheck(LessonSessionState state) {
    final answer = state.userAnswer;
    if (answer == null) return false;
    if (answer is List && answer.isEmpty) return false;
    if (answer is int) return true; // MultipleChoice selection
    return true;
  }

  Widget _buildCurrentExercise(Exercise exercise, LessonSessionController controller) {
    if (exercise is TranslateExercise) {
      return TranslateExerciseWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onAnswerChanged: (order) => controller.updateUserAnswer(order),
        onSpeakerTap: () => controller.speakWord(exercise.foreignPhrase),
      );
    }
    if (exercise is ArrangeWordsExercise) {
      return ArrangeWordsWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onAnswerChanged: (order) => controller.updateUserAnswer(order),
        onSpeakerTap: exercise.foreignPhrase != null
            ? () => controller.speakWord(exercise.foreignPhrase!)
            : null,
      );
    }
    if (exercise is MultipleChoiceExercise) {
      return MultipleChoiceWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onAnswerChanged: (index) => controller.updateUserAnswer(index),
        onOptionSpeakerTap: (label) => controller.speakWord(label),
      );
    }
    return Center(child: Text('Unknown exercise type', style: TextStyle(color: Colors.white)));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DUOLINGO APP BAR
// ═══════════════════════════════════════════════════════════════════
class _DuolingoAppBar extends StatelessWidget {
  final double progress;
  final int hearts;
  final int streak;
  final VoidCallback onClose;

  const _DuolingoAppBar({
    required this.progress,
    required this.hearts,
    required this.streak,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Column(
        children: [
          // Streak label
          if (streak >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$streak IN A ROW',
                style: TextStyle(
                  color: AppColors.streakGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          Row(
            children: [
              // Close button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 28),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),

              // Progress bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: AppColors.surfaceElevated,
                    color: AppColors.correctGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Hearts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '$hearts',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FEEDBACK BAR (inline, NOT bottom sheet)
// ═══════════════════════════════════════════════════════════════════
class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final VoidCallback onContinue;

  const _FeedbackBar({
    required this.isCorrect,
    required this.message,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect ? AppColors.correctGreen : AppColors.incorrectRed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        border: Border(top: BorderSide(color: bgColor, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: bgColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: TextStyle(
                  color: bgColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                isCorrect ? 'CONTINUE' : 'GOT IT',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CHECK BUTTON
// ═══════════════════════════════════════════════════════════════════
class _CheckButton extends StatelessWidget {
  final bool canCheck;
  final bool isLoading;
  final VoidCallback onCheck;

  const _CheckButton({
    required this.canCheck,
    required this.isLoading,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canCheck ? onCheck : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canCheck ? AppColors.correctGreen : AppColors.surfaceElevated,
            disabledBackgroundColor: AppColors.surfaceElevated,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'CHECK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: canCheck ? Colors.white : Colors.white38,
                  ),
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LESSON COMPLETED SCREEN
// ═══════════════════════════════════════════════════════════════════
class _LessonCompletedScreen extends StatelessWidget {
  final Lesson lesson;
  final int streak;
  final int heartsRemaining;

  const _LessonCompletedScreen({
    required this.lesson,
    required this.streak,
    required this.heartsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.correctGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: AppColors.streakGold, size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lesson Complete!',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.title,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatCard(icon: Icons.bolt, value: '+${lesson.xpReward}', label: 'XP', color: AppColors.streakGold),
                    const SizedBox(width: 24),
                    _StatCard(icon: Icons.favorite, value: '$heartsRemaining', label: 'Hearts', color: Colors.red),
                    if (streak > 0) ...[
                      const SizedBox(width: 24),
                      _StatCard(icon: Icons.local_fire_department, value: '$streak', label: 'Streak', color: Colors.orange),
                    ],
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.correctGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }
}
