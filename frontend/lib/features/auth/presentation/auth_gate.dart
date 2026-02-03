import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/chat_screen.dart';
import 'auth_state.dart';
import 'sign_in_screen.dart';

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
        return child ?? const ChatScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SignInScreen(),
    );
  }
}
