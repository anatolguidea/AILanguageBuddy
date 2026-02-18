import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../data/topic_repository.dart';
import '../../domain/entities/custom_topic.dart';
import '../providers/custom_topics_provider.dart';
import '../widgets/practice_header.dart';
import '../widgets/practice_banner.dart';
import '../widgets/topic_tile.dart';

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  bool _showAllTopics = true; // true = All topics, false = Custom

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final customTopicsAsync = ref.watch(customTopicsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.refresh(topicsProvider.future);
                ref.read(customTopicsProvider.notifier).load();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PracticeHeader(
                      streakCount: 0,
                      onUpgrade: () {
                        // TODO: Navigate to upgrade / paywall
                      },
                    ),
                    const SizedBox(height: 24),
                    // All topics / Custom segmented control
                    Row(
                      children: [
                        _SegmentChip(
                          label: 'All topics',
                          selected: _showAllTopics,
                          onTap: () => setState(() => _showAllTopics = true),
                        ),
                        const SizedBox(width: 12),
                        _SegmentChip(
                          label: 'Custom',
                          selected: !_showAllTopics,
                          onTap: () => setState(() => _showAllTopics = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PracticeBanner(
                      title: "word of the day",
                      subtitle: "Check today's",
                      onTap: () {
                        // TODO: Implement word of the day modal
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_showAllTopics) ...[
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
                    ] else ...[
                      customTopicsAsync.when(
                        data: (customTopics) {
                          if (customTopics.isEmpty) {
                            return _CustomEmptyState(
                              onAddTap: () => context.push('/practice/custom/create'),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextButton.icon(
                                  onPressed: () => context.push('/practice/custom/create'),
                                  icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                                  label: const Text('Add topic'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: customTopics.length,
                                itemBuilder: (context, index) {
                                  final topic = customTopics[index];
                                  return TopicTile(
                                    title: topic.title,
                                    icon: FontAwesomeIcons.lightbulb,
                                    onTap: () => context.push(topic.route),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                        error: (e, st) => Center(
                          child: Text(
                            'Error loading custom topics',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/live'),
                  icon: const Icon(Icons.mic, color: Colors.white, size: 24),
                  label: const Text('Start free talk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.5),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceElevated : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: AppColors.surfaceElevated),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _CustomEmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _CustomEmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'No custom topics yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddTap,
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            label: const Text('Create a topic'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
