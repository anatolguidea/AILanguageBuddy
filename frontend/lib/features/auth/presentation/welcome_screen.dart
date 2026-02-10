import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_button.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2), // Push content down slightly
              // Illustration Placeholder
              Center(
                child: Icon(
                  FontAwesomeIcons.robot,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Welcome to\nAI Language Buddy',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'The most immersive language learning app in the world.\nBuilt so you stick with it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(flex: 3),
              
              // Apple Sign In (Placeholder)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Apple Sign In
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apple Sign In coming soon!')),
                  );
                },
                icon: const Icon(FontAwesomeIcons.apple, color: Colors.white),
                label: const Text('Continue with Apple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              
              // Google Sign In
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signInWithGoogle();
                },
                icon: const Icon(FontAwesomeIcons.google, color: Colors.red), // Brand color
                label: Text(
                  'Continue with Google',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: theme.colorScheme.outline),
                  backgroundColor: isDark ? Colors.transparent : Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Email Sign In (Used AppButton for primary style)
              AppButton(
                label: 'Continue with Email',
                onPressed: () {
                  // Navigate to Register or specialized Email entry
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                primary: true,
              ),

              const SizedBox(height: 24),
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    child: const Text('Log in'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
