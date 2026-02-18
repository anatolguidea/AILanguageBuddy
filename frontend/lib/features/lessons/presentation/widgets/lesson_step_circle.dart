import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/lesson.dart';

/// Single lesson as a circular step (design: dumbbell, presentation, abc, trophy icons).
class LessonStepCircle extends StatelessWidget {
  final Lesson lesson;
  final bool isLast;
  final VoidCallback? onTap;

  const LessonStepCircle({
    super.key,
    required this.lesson,
    this.isLast = false,
    required this.onTap,
  });

  static IconData _iconForIndex(int index) {
    switch (index % 4) {
      case 0:
        return Icons.fitness_center; // dumbbell / practice
      case 1:
        return Icons.slideshow_outlined; // presentation
      case 2:
        return Icons.abc; // vocabulary
      case 3:
        return Icons.emoji_events_outlined; // trophy
      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.status == LessonStatus.completed;
    final isAvailable = lesson.status == LessonStatus.available;
    final isLocked = lesson.status == LessonStatus.locked;
    final canTap = isAvailable || isCompleted;

    return Column(
      children: [
        GestureDetector(
          onTap: isLocked
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete previous lessons to unlock this one.'),
                    ),
                  );
                }
              : (canTap ? onTap : null),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primary
                  : isAvailable
                      ? AppColors.primary
                      : AppColors.surfaceElevated,
              border: isAvailable && !isCompleted
                  ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: isAvailable || isCompleted
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : _iconForIndex(lesson.orderIndex),
              color: isCompleted || isAvailable ? Colors.white : AppColors.textTertiary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isAvailable || isCompleted ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: isAvailable && !isCompleted ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
