import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// Topic header card: "B2 · Topic 1", main title, optional subtitle, filter icon.
class LessonsTopicCard extends StatelessWidget {
  final String level;
  final int topicIndex;
  final String title;
  final String? subtitle;
  final VoidCallback? onFilterTap;

  const LessonsTopicCard({
    super.key,
    this.level = 'B2',
    required this.topicIndex,
    required this.title,
    this.subtitle,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$level · Topic $topicIndex',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onFilterTap != null)
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(40, 40),
              ),
            ),
        ],
      ),
    );
  }
}
