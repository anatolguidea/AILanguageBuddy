import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';

/// Header for the Practice screen: title, Upgrade button, and streak (flame) badge.
class PracticeHeader extends StatelessWidget {
  final int streakCount;
  final VoidCallback? onUpgrade;

  const PracticeHeader({
    super.key,
    this.streakCount = 0,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Practice',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onUpgrade != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onUpgrade,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Upgrade',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
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
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
