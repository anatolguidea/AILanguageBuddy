import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'sign_in_screen.dart';
import 'welcome_screen.dart';
import '../../shell/presentation/splash_screen.dart';

/// Shows SignInScreen when not authenticated.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const WelcomeScreen();
        // GoRouter redirect logic in app_router.dart will handle moving
        // the user to /practice if they are logged in.
        return child ?? const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () => const SplashScreen(),
      error: (err, _) => const WelcomeScreen(),
    );
  }
}
