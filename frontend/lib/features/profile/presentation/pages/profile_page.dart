import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../auth/presentation/auth_state.dart';
import '../../../auth/data/auth_repository.dart';
import '../widgets/profile_list_tile.dart';
import '../widgets/profile_section.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/theme_mode_provider.dart';

void _showAppLanguagePicker(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(appLocaleProvider.notifier);
  final current = ref.read(appLocaleProvider);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                current == AppLocaleNotifier.en ? Icons.check_circle : Icons.circle_outlined,
                color: current == AppLocaleNotifier.en ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                size: 22,
              ),
              title: const Text('English'),
              onTap: () {
                notifier.setLocale(AppLocaleNotifier.en);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                current == AppLocaleNotifier.ro ? Icons.check_circle : Icons.circle_outlined,
                color: current == AppLocaleNotifier.ro ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                size: 22,
              ),
              title: const Text('Română'),
              onTap: () {
                notifier.setLocale(AppLocaleNotifier.ro);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final s = AppStrings.forLocale(locale);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(s.profile)),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(s.notLoggedIn));
          }
          final email = user.email ?? s.noEmail;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(FontAwesomeIcons.userAstronaut, size: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                
                ProfileSection(title: s.settings, children: [
                  ProfileListTile(
                    icon: FontAwesomeIcons.globe,
                    title: s.appLanguage,
                    subtitle: locale.startsWith('ro') ? 'Română' : 'English',
                    onTap: () => _showAppLanguagePicker(context, ref),
                  ),
                  ProfileListTile(
                    icon: FontAwesomeIcons.language,
                    title: s.languagePreferences,
                    onTap: () {},
                  ),
                  ProfileListTile(
                    icon: FontAwesomeIcons.bell,
                    title: s.notifications,
                    onTap: () {},
                  ),
                  ProfileListTile(
                    icon: FontAwesomeIcons.bell,
                    title: s.notifications,
                    onTap: () {},
                  ),
                  _DarkThemeSwitchTile(
                    title: s.darkTheme,
                    value: isDark,
                    onChanged: (value) => ref.read(themeModeProvider.notifier).setDark(value),
                  ),
                ]),

                const SizedBox(height: 24),
                
                ProfileSection(title: s.account, children: [
                  ProfileListTile(
                    icon: FontAwesomeIcons.arrowRightFromBracket,
                    title: s.signOut,
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () async {
                       await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ]),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${s.error}: $err')),
      ),
    );
  }
}

class _DarkThemeSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DarkThemeSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(FontAwesomeIcons.moon, color: Theme.of(context).colorScheme.onSurface, size: 20),
      title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
