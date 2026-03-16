import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/presentation/auth_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & progress')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: userAsync.when(
            data: (user) {
              return FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Your account',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: Semantics(
                          container: true,
                          label: 'Profile details',
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? 'Anonymous',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'We\'ll soon show your level, streaks, and XP here.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
                        child: Semantics(
                          button: true,
                          label: 'Sign out',
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: AppButton(
                              label: 'Sign out',
                              primary: false,
                              onPressed: () async {
                                await ref
                                    .read(authRepositoryProvider)
                                    .signOut();
                                if (context.mounted) {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Could not load profile.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
