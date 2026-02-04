import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_screen.dart';
import 'auth_state.dart';
import 'sign_in_screen.dart';
import '../../shell/presentation/splash_screen.dart';

/// Shows SignInScreen when not authenticated, otherwise [child] (e.g. ChatScreen).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const SignInScreen();
        return child ?? const HomeScreen();
      },
      loading: () => const SplashScreen(),
      error: (err, _) => const SignInScreen(),
    );
  }
}
