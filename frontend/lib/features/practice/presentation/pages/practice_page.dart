import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import '../../data/topic_repository.dart';
import '../../domain/entities/custom_topic.dart';
import '../providers/custom_topics_provider.dart';
import '../widgets/practice_header.dart';
import '../widgets/practice_banner.dart';
import '../../../chat/presentation/providers/current_topic_language_provider.dart';
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
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final topicsAsync = ref.watch(topicsProvider);
    final customTopicsAsync = ref.watch(customTopicsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(topicsProvider.future);
                  ref.read(customTopicsProvider.notifier).load();
                },
                color: Theme.of(context).colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PracticeHeader(
                        streakCount: 0,
                        title: s.practice,
                        upgradeLabel: s.upgrade,
                        onUpgrade: () {
                          // TODO: Navigate to upgrade / paywall
                        },
                      ),
                      const SizedBox(height: 24),
                      // All topics / Custom segmented control
                      Row(
                        children: [
                          _SegmentChip(
                            label: s.allTopics,
                            selected: _showAllTopics,
                            onTap: () => setState(() => _showAllTopics = true),
                          ),
                          const SizedBox(width: 12),
                          _SegmentChip(
                            label: s.custom,
                            selected: !_showAllTopics,
                            onTap: () => setState(() => _showAllTopics = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PracticeBanner(
                        title: s.wordOfTheDay,
                        subtitle: s.checkTodays,
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
                                topicId: topic.id,
                                title: topic.title,
                                icon: topic.icon,
                                onTap: () {
                                  ref
                                      .read(
                                        currentTopicLanguageProvider.notifier,
                                      )
                                      .state = topic
                                      .languageCode;
                                  context.push(topic.route);
                                },
                              );
                            },
                          ),
                          loading: () => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          error: (err, stack) => Center(
                            child: Text(
                              s.errorLoadingTopics,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        customTopicsAsync.when(
                          data: (customTopics) {
                            if (customTopics.isEmpty) {
                              return _CustomEmptyState(
                                message: s.noCustomTopicsYet,
                                addLabel: s.createTopic,
                                onAddTap: () =>
                                    context.push('/practice/custom/create'),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        context.push('/practice/custom/create'),
                                    icon: const Icon(
                                      Icons.add,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    label: Text(s.addTopic),
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
                                      topicId: 'custom',
                                      title: topic.title,
                                      icon: FontAwesomeIcons.lightbulb,
                                      onTap: () {
                                        ref
                                            .read(
                                              currentTopicLanguageProvider
                                                  .notifier,
                                            )
                                            .state = ref
                                            .read(languageProvider)
                                            .code;
                                        context.push(topic.route);
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          error: (e, st) => Center(
                            child: Text(
                              s.errorLoadingCustomTopics,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
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
                    icon: Icon(
                      Icons.mic,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                    label: Text(s.startFreeTalk),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(color: scheme.surfaceContainerHighest),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomEmptyState extends StatelessWidget {
  final String message;
  final String addLabel;
  final VoidCallback onAddTap;

  const _CustomEmptyState({
    required this.message,
    required this.addLabel,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddTap,
            icon: Icon(Icons.add, color: scheme.primary, size: 20),
            label: Text(addLabel),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
          ),
        ],
      ),
    );
  }
}
