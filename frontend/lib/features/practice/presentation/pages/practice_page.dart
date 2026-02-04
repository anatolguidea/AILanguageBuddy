import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../data/topic_repository.dart';
import '../widgets/home_header.dart';
import '../widgets/practice_banner.dart';
import '../widgets/topic_tile.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(topicsProvider.future),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeHeader(title: 'Practice', streakCount: 0),
                    const SizedBox(height: 24),
                    PracticeBanner(
                      title: 'word of the day',
                      subtitle: "Check today's",
                      onTap: () {
                        // TODO: Implement word of the day modal
                      },
                    ),
                    const SizedBox(height: 32),
                    topicsAsync.when(
                      data: (topics) => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topics.length,
                        itemBuilder: (context, index) {
                          final topic = topics[index];
                          return TopicTile(
                            title: topic.title,
                            icon: topic.icon,
                            onTap: () => context.push(topic.route),
                          );
                        },
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Error loading topics',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Space for sticky button
                  ],
                ),
              ),
            ),
            
            // Sticky Start Button
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/chat/free_talk'),
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text('Start free talk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
