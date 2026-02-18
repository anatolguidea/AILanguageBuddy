import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../theme/app_tailwind.dart';

/// Primary CTA button used across the redesigned screens.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = AppTailwind.primary;
    final hoverBg = isDark ? const Color(0xFFE65F00) : const Color(0xFFE65F00);

    final button = ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: height),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: onPressed == null ? bg.withOpacity(0.4) : bg,
          borderRadius: BorderRadius.circular(AppTailwind.roundedXl),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTailwind.roundedXl),
            onTap: onPressed,
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.06),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOut,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
                child: Text(label.toUpperCase()),
              ),
            ),
          ),
        ),
      ),
    );

    if (!expanded) return button;

    return MouseRegion(
      cursor: onPressed == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          begin: bg,
          end: onPressed == null ? bg.withOpacity(0.4) : hoverBg,
        ),
        duration: const Duration(milliseconds: 0),
        builder: (context, color, _) {
          // Color tween is only used to match design; actual hover handled by InkWell.
          return button;
        },
      ),
    );
  }
}

