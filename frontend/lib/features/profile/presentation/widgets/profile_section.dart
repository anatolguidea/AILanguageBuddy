import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFE4E4E7),
            ),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((entry) {
                  final isLast = entry.key == children.length - 1;
                  return Column(
                    children: [
                      entry.value,
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 52,
                          color: isDark
                              ? AppColors.surfaceElevated
                              : const Color(0xFFF4F4F5),
                        ),
                    ],
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }
}
