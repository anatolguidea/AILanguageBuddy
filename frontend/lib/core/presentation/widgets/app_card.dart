import 'package:flutter/material.dart';

import '../../theme/app_tailwind.dart';

/// Bordered, rounded card that can host emoji, icons, or content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.showCheck = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = selected
        ? AppTailwind.primary.withOpacity(isDark ? 0.10 : 0.05)
        : (isDark ? AppTailwind.cardBgDark : Colors.white);

    final borderColor = selected
        ? AppTailwind.primary
        : (isDark ? const Color(0xFF52453D) : Colors.transparent);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppTailwind.p5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTailwind.rounded2xl),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: !isDark && !selected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: child),
          if (showCheck) ...[
            const SizedBox(width: AppTailwind.gap4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTailwind.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

