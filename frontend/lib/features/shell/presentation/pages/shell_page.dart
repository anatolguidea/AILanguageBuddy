import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';

class ShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellPage({
    required this.navigationShell,
    super.key,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceElevated, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          backgroundColor: AppColors.backgroundBlack,
          indicatorColor: AppColors.surfaceElevated,
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.chalkboard, size: 20, color: AppColors.textSecondary),
              selectedIcon: FaIcon(FontAwesomeIcons.chalkboardUser, size: 20, color: AppColors.primary),
              label: 'Lessons',
            ),
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.dumbbell, size: 20, color: AppColors.textSecondary),
              selectedIcon: FaIcon(FontAwesomeIcons.dumbbell, size: 20, color: AppColors.primary),
              label: 'Practice',
            ),
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.microphoneLines, size: 20, color: AppColors.textSecondary),
              selectedIcon: FaIcon(FontAwesomeIcons.microphoneLines, size: 20, color: AppColors.primary),
              label: 'Live',
            ),
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.user, size: 20, color: AppColors.textSecondary),
              selectedIcon: FaIcon(FontAwesomeIcons.solidUser, size: 20, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
