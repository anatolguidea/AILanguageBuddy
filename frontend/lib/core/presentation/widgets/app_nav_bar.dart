import 'package:flutter/material.dart';

import '../../theme/app_tailwind.dart';

class AppNavBarItem {
  const AppNavBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// Bottom navigation bar matching the dashboard/profile HTML designs.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTailwind.surfaceDarkProfile.withOpacity(0.95) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                  isDark: isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final AppNavBarItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeColor = AppTailwind.primary;
    final inactiveColor =
        isDark ? AppTailwind.textSecondary : AppTailwind.textCharcoalMuted;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTailwind.roundedFull),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withOpacity(isDark ? 0.24 : 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTailwind.roundedFull),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

