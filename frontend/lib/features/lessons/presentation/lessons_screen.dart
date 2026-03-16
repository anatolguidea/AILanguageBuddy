import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(title: const Text('Lessons & tracks')),
        body: SafeArea(
          child: FocusTraversalGroup(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Personalized lessons from your mistakes.',
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
                        label: 'Lessons availability',
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coming soon',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We\'ll generate bite-sized lessons and review tracks from your chat history.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(3),
                      child: Semantics(
                        button: true,
                        label: 'Back to home',
                        child: SizedBox(
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: AppButton(
                              label: 'Back to home',
                              primary: false,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
