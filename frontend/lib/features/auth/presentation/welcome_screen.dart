import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';
import 'auth_state.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Hero
              _HeroSection(s: s, isDark: isDark),
              const SizedBox(height: 48),

              // Auth buttons
              _AuthButtons(s: s, isDark: isDark, ref: ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AppStringsData s;
  final bool isDark;

  const _HeroSection({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        // Logo mark
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(FontAwesomeIcons.robot, color: Colors.white, size: 40),
        )
            .animate()
            .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 32),

        // Headline
        Text(
          s.welcomeToApp,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          s.welcomeSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
        const SizedBox(height: 32),

        // Feature pills
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _FeaturePill(icon: Icons.translate_rounded, label: '10+ Languages'),
            _FeaturePill(icon: Icons.mic_rounded, label: 'Voice AI'),
            _FeaturePill(icon: Icons.auto_fix_high_rounded, label: 'Grammar Coach'),
          ],
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: 400.ms),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final AppStringsData s;
  final bool isDark;
  final WidgetRef ref;

  const _AuthButtons({required this.s, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Apple Sign In
        _SocialButton(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.appleSignInComing)),
          ),
          icon: FontAwesomeIcons.apple,
          label: s.continueWithApple,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          borderColor: Colors.black,
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
        const SizedBox(height: 12),

        // Google Sign In
        _SocialButton(
          onTap: () async => ref.read(authRepositoryProvider).signInWithGoogle(),
          icon: FontAwesomeIcons.google,
          label: s.continueWithGoogle,
          backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF18181B),
          borderColor: isDark ? AppColors.surfaceHighest : const Color(0xFFE4E4E7),
          iconColor: const Color(0xFFEA4335),
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
        const SizedBox(height: 20),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.or,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ],
        )
            .animate(delay: 450.ms)
            .fadeIn(duration: 300.ms),
        const SizedBox(height: 20),

        // Email CTA
        _GradientButton(
          label: s.continueWithEmail,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
        )
            .animate(delay: 500.ms)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
        const SizedBox(height: 20),

        // Sign in link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              s.alreadyHaveAccount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              ),
              child: Text(
                s.logIn,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        )
            .animate(delay: 550.ms)
            .fadeIn(duration: 300.ms),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color? iconColor;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? foregroundColor, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
