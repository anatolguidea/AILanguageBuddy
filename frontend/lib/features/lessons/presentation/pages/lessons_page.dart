import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../domain/entities/lesson.dart';
import '../providers/lessons_provider.dart';
import '../widgets/lessons_header.dart';
import '../widgets/lessons_topic_card.dart';
import '../widgets/lesson_step_circle.dart';
import 'lesson_detail_page.dart';
import '../../data/lessons_repository.dart';
import '../../../settings/presentation/providers/language_provider.dart';

class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final lessonsAsync = ref.watch(lessonsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: lessonsAsync.when(
            data: (lessons) {
              final firstLesson = lessons.isNotEmpty ? lessons.first : null;
              final level = firstLesson?.content['level']?.toString() ?? 'B2';

              return RefreshIndicator(
                onRefresh: () => ref.refresh(lessonsProvider.future),
                color: scheme.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          LessonsHeader(
                            streakCount: 0,
                            upgradeLabel: s.upgrade,
                            onUpgrade: null,
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 20),
                          if (firstLesson != null) ...[
                            LessonsTopicCard(
                              level: level,
                              topicIndex: 1,
                              title: firstLesson.title,
                              subtitle: firstLesson.description.isNotEmpty
                                  ? firstLesson.description
                                  : null,
                              onFilterTap: () {
                                // TODO: filter/settings for topic
                              },
                            ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
                            const SizedBox(height: 24),
                          ],
                        ]),
                      ),
                    ),
                    if (lessons.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyState(message: s.noLessonsYet),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(lessons.length, (index) {
                                  final lesson = lessons[index];
                                  return LessonStepCircle(
                                    lesson: lesson,
                                    isLast: index == lessons.length - 1,
                                    onTap: () async {
                                      if (lesson.status == LessonStatus.locked) return;
                                      try {
                                        final repo = ref.read(lessonsRepositoryProvider);
                                        final language = ref.read(languageProvider).code;
                                        final fullLesson = await repo.getLessonDetails(
                                          lessonId: lesson.id,
                                          languageCode: language,
                                        );
                                        if (!context.mounted) return;
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => LessonDetailPage(lesson: fullLesson),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${s.error}: $e')),
                                        );
                                      }
                                    },
                                  )
                                      .animate(
                                        delay: Duration(milliseconds: 100 + index * 40),
                                      )
                                      .fadeIn(duration: 300.ms)
                                      .slideY(begin: 0.08, end: 0, duration: 300.ms);
                                }),
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => _LessonsShimmer(isDark: isDark),
            error: (err, _) => _ErrorState(
              message: s.errorLoadingLessons,
              retryLabel: s.retry,
              onRetry: () => ref.refresh(lessonsProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonsShimmer extends StatelessWidget {
  final bool isDark;

  const _LessonsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.surfaceDark : const Color(0xFFF4F4F5);
    final highlight = isDark ? AppColors.surfaceElevated : const Color(0xFFE4E4E7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              _Bone(width: 48, height: 48, radius: 24, color: base),
              const Spacer(),
              _Bone(width: 80, height: 32, radius: 16, color: base),
              const SizedBox(width: 8),
              _Bone(width: 56, height: 32, radius: 16, color: base),
            ],
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 1200.ms, color: highlight),
          const SizedBox(height: 20),
          // Topic card skeleton
          _Bone(width: double.infinity, height: 100, radius: 20, color: base)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 1200.ms, delay: 200.ms, color: highlight),
          const SizedBox(height: 32),
          // Step circles skeleton
          Center(
            child: Column(
              children: List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _Bone(width: 64, height: 64, radius: 32, color: base)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: 1200.ms,
                      delay: Duration(milliseconds: 100 + i * 80),
                      color: highlight,
                    ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school_rounded, size: 36, color: scheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
