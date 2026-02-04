import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../scenario/presentation/scenario_screen.dart';
import '../../lessons/presentation/lessons_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Language Buddy'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you want to practice today?',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _HomeTile(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Chat with your coach',
                      subtitle: 'Free-form conversation in your target language.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      ),
                    ),
                    _HomeTile(
                      icon: Icons.theater_comedy_rounded,
                      title: 'Scenario mode',
                      subtitle: 'Role-play real-life situations.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScenarioScreen()),
                      ),
                    ),
                    _HomeTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Lessons & tracks',
                      subtitle: 'Structured lessons based on your mistakes.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LessonsScreen()),
                      ),
                    ),
                    _HomeTile(
                      icon: Icons.person_rounded,
                      title: 'Profile & progress',
                      subtitle: 'Level, streak, and XP.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Quick chat',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon.'),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

