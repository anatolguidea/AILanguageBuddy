import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:ailanguageapp/core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';

class ShellPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ShellPage({
    required this.navigationShell,
    super.key,
  });

  void _goBranch(StatefulNavigationShell navigationShell, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorScheme.surfaceContainerHighest, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _goBranch(navigationShell, index),
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.surfaceContainerHighest,
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.chalkboard, size: 20, color: colorScheme.onSurfaceVariant),
              selectedIcon: FaIcon(FontAwesomeIcons.chalkboardUser, size: 20, color: colorScheme.primary),
              label: s.lessons,
            ),
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.dumbbell, size: 20, color: colorScheme.onSurfaceVariant),
              selectedIcon: FaIcon(FontAwesomeIcons.dumbbell, size: 20, color: colorScheme.primary),
              label: s.practice,
            ),
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.user, size: 20, color: colorScheme.onSurfaceVariant),
              selectedIcon: FaIcon(FontAwesomeIcons.solidUser, size: 20, color: colorScheme.primary),
              label: s.profile,
            ),
          ],
        ),
      ),
    );
  }
}
