import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Reusable elevated/surface card with consistent radius and padding.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation = 0,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double elevation;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = color ?? theme.colorScheme.surfaceContainerHighest;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}
