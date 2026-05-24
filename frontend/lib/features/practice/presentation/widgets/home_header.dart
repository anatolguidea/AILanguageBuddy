import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../home/presentation/widgets/language_selector.dart';

class HomeHeader extends StatelessWidget {
  final String title;
  final int streakCount;

  const HomeHeader({
    super.key,
    required this.title,
    this.streakCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.displayMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LanguageSelector(),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F3F46), // Zinc 700
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: AppColors.accent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$streakCount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
