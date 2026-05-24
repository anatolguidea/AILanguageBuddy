import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:ailanguageapp/core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/chat/presentation/pages/live_speech_page.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import 'package:ailanguageapp/theme/app_colors.dart';

class ShellPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ShellPage({required this.navigationShell, super.key});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(voiceReconnectOnLanguageChangeProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        isDark: isDark,
        s: s,
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final bool isDark;
  final AppStringsData s;

  const _AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.surfaceElevated
                : const Color(0xFFE4E4E7),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: FontAwesomeIcons.chalkboard,
                activeIcon: FontAwesomeIcons.chalkboardUser,
                label: s.lessons,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
                activeColor: scheme.primary,
                inactiveColor: scheme.onSurfaceVariant,
              ),
              _NavItem(
                icon: FontAwesomeIcons.dumbbell,
                activeIcon: FontAwesomeIcons.dumbbell,
                label: s.practice,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
                activeColor: scheme.primary,
                inactiveColor: scheme.onSurfaceVariant,
              ),
              _NavItem(
                icon: FontAwesomeIcons.user,
                activeIcon: FontAwesomeIcons.solidUser,
                label: s.profile,
                selected: currentIndex == 2,
                onTap: () => onTap(2),
                activeColor: scheme.primary,
                inactiveColor: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          highlightColor: Colors.transparent,
          splashColor: activeColor.withValues(alpha: 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FaIcon(
                  selected ? activeIcon : icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  fontFamily: 'Outfit',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
