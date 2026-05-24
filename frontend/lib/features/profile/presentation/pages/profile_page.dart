import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../auth/presentation/auth_state.dart';
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _LanguageOption(
              locale: AppLocaleNotifier.en,
              label: 'English',
              flag: '🇬🇧',
              isSelected: current == AppLocaleNotifier.en,
              onTap: () {
                notifier.setLocale(AppLocaleNotifier.en);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            _LanguageOption(
              locale: AppLocaleNotifier.ro,
              label: 'Română',
              flag: '🇷🇴',
              isSelected: current == AppLocaleNotifier.ro,
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

class _LanguageOption extends StatelessWidget {
  final String locale;
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.locale,
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Text(flag, style: const TextStyle(fontSize: 26)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? scheme.primary : scheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: scheme.primary, size: 20)
          : null,
    );
  }
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
      appBar: AppBar(
        title: Text(s.profile),
        centerTitle: false,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(s.notLoggedIn));
          }
          final email = user.email ?? s.noEmail;
          final initials = email.isNotEmpty
              ? email.substring(0, 1).toUpperCase()
              : '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Avatar
                _ProfileAvatar(initials: initials)
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 16),

                // Email
                Text(
                  email,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Free plan',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 28),

                // Stats row
                _StatsRow()
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0, duration: 300.ms),
                const SizedBox(height: 28),

                // Settings section
                ProfileSection(
                  title: s.settings,
                  children: [
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
                    _DarkThemeSwitchTile(
                      title: s.darkTheme,
                      value: isDark,
                      onChanged: (value) =>
                          ref.read(themeModeProvider.notifier).setDark(value),
                    ),
                  ],
                ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Account section
                ProfileSection(
                  title: s.account,
                  children: [
                    ProfileListTile(
                      icon: FontAwesomeIcons.arrowRightFromBracket,
                      title: s.signOut,
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () async {
                        await ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                  ],
                ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text('${s.error}: $err'),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initials;

  const _ProfileAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _StatCard(
          icon: Icons.local_fire_department_rounded,
          value: '0',
          label: 'Day streak',
          color: AppColors.accent,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.check_circle_rounded,
          value: '0',
          label: 'Lessons done',
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.mic_rounded,
          value: '0',
          label: 'Voice sessions',
          color: AppColors.secondary,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.surfaceElevated : const Color(0xFFE4E4E7),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                FontAwesomeIcons.moon,
                color: scheme.onSurface,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
