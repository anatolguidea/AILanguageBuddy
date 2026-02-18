import 'package:flutter/material.dart';

import '../../theme/app_tailwind.dart';

/// Horizontal progress bar with fixed height 12 and rounded-full ends.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Progress value between 0 and 1.
  final double value;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final track = backgroundColor ??
        (isDark ? AppTailwind.progressTrackDark : AppTailwind.progressTrackLight);
    final fill = foregroundColor ?? AppTailwind.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTailwind.roundedFull),
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: track),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppTailwind.roundedFull),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

