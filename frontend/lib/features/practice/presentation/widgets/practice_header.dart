import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class PracticeHeader extends StatelessWidget {
  final int streakCount;
  final VoidCallback? onUpgrade;
  final String title;
  final String upgradeLabel;

  const PracticeHeader({
    super.key,
    this.streakCount = 0,
    this.onUpgrade,
    this.title = 'Practice',
    this.upgradeLabel = 'Upgrade',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onUpgrade != null) ...[
              _UpgradeChip(label: upgradeLabel, onTap: onUpgrade!),
              const SizedBox(width: 8),
            ],
            _StreakBadge(count: streakCount),
          ],
        ),
      ],
    );
  }
}

class _UpgradeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _UpgradeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int count;

  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 16),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}
