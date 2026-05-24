import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import '../../data/topic_repository.dart';
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
  bool _showAllTopics = true;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final topicsAsync = ref.watch(topicsProvider);
    final customTopicsAsync = ref.watch(customTopicsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(topicsProvider.future);
                  ref.read(customTopicsProvider.notifier).load();
                },
                color: scheme.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          PracticeHeader(
                            streakCount: 0,
                            title: s.practice,
                            upgradeLabel: s.upgrade,
                            onUpgrade: () {
                              // TODO: Navigate to upgrade / paywall
                            },
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 20),

                          // Segment control
                          _SegmentedControl(
                            labels: [s.allTopics, s.custom],
                            selectedIndex: _showAllTopics ? 0 : 1,
                            onChanged: (i) => setState(() => _showAllTopics = i == 0),
                          ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
                          const SizedBox(height: 16),

                          // Banner
                          PracticeBanner(
                            title: s.wordOfTheDay,
                            subtitle: s.checkTodays,
                            onTap: () {
                              // TODO: Implement word of the day modal
                            },
                          ),
                          const SizedBox(height: 20),
                        ]),
                      ),
                    ),

                    // Topic list
                    if (_showAllTopics)
                      topicsAsync.when(
                        data: (topics) => SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          sliver: SliverList.builder(
                            itemCount: topics.length,
                            itemBuilder: (context, index) => TopicTile(
                              topicId: topics[index].id,
                              title: topics[index].title,
                              icon: topics[index].icon,
                              onTap: () {
                                ref
                                    .read(currentTopicLanguageProvider.notifier)
                                    .state = topics[index].languageCode;
                                context.push(topics[index].route);
                              },
                            )
                                .animate(delay: Duration(milliseconds: 50 + index * 30))
                                .fadeIn(duration: 250.ms)
                                .slideY(begin: 0.08, end: 0, duration: 250.ms),
                          ),
                        ),
                        loading: () => SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.builder(
                            itemCount: 6,
                            itemBuilder: (_, i) => _TopicSkeleton(isDark: isDark)
                                .animate(delay: Duration(milliseconds: i * 40))
                                .fadeIn(duration: 300.ms),
                          ),
                        ),
                        error: (err, _) => SliverToBoxAdapter(
                          child: _ErrorState(
                            message: s.errorLoadingTopics,
                            onRetry: () => ref.refresh(topicsProvider.future),
                            retryLabel: s.retry,
                          ),
                        ),
                      )
                    else
                      customTopicsAsync.when(
                        data: (customTopics) {
                          if (customTopics.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                                child: _CustomEmptyState(
                                  message: s.noCustomTopicsYet,
                                  addLabel: s.createTopic,
                                  onAddTap: () => context.push('/practice/custom/create'),
                                ),
                              ),
                            );
                          }
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => context.push('/practice/custom/create'),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: Text(s.addTopic),
                                  ),
                                ),
                                ...customTopics.asMap().entries.map((entry) {
                                  final topic = entry.value;
                                  return TopicTile(
                                    topicId: 'custom',
                                    title: topic.title,
                                    icon: FontAwesomeIcons.lightbulb,
                                    onTap: () {
                                      ref
                                          .read(currentTopicLanguageProvider.notifier)
                                          .state = ref.read(languageProvider).code;
                                      context.push(topic.route);
                                    },
                                  )
                                      .animate(
                                        delay: Duration(milliseconds: entry.key * 30),
                                      )
                                      .fadeIn(duration: 250.ms);
                                }),
                              ]),
                            ),
                          );
                        },
                        loading: () => SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.builder(
                            itemCount: 4,
                            itemBuilder: (_, i) => _TopicSkeleton(isDark: isDark),
                          ),
                        ),
                        error: (e, _) => SliverToBoxAdapter(
                          child: _ErrorState(
                            message: s.errorLoadingCustomTopics,
                            onRetry: () => ref.read(customTopicsProvider.notifier).load(),
                            retryLabel: s.retry,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Floating free talk CTA
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _FreeTalkButton(label: s.startFreeTalk)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final selected = entry.key == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? AppColors.surfaceDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FreeTalkButton extends StatelessWidget {
  final String label;

  const _FreeTalkButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/live'),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicSkeleton extends StatelessWidget {
  final bool isDark;

  const _TopicSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.surfaceDark : const Color(0xFFF4F4F5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevated : const Color(0xFFE4E4E7),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : const Color(0xFFE4E4E7),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: scheme.error, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, color: scheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onAddTap,
            child: Text(addLabel),
          ),
        ],
      ),
    );
  }
}
