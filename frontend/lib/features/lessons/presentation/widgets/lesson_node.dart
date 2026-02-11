import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/lesson.dart';

class LessonNode extends StatelessWidget {
  final Lesson lesson;
  final bool isLast;
  final VoidCallback onTap;

  const LessonNode({
    super.key,
    required this.lesson,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = lesson.status == LessonStatus.completed;
    final bool isAvailable = lesson.status == LessonStatus.available;

    return Column(
      children: [
        GestureDetector(
          onTap: isAvailable || isCompleted ? onTap : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primary
                  : isAvailable
                  ? AppColors.surfaceElevated
                  : AppColors.surfaceDark,
              border: Border.all(
                color: isAvailable ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.lock_open,
              color: isCompleted || isAvailable
                  ? Colors.white
                  : AppColors.textTertiary,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isAvailable || isCompleted
                ? AppColors.textPrimary
                : AppColors.textTertiary,
            fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
