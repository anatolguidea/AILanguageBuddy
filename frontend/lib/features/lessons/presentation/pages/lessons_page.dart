import 'package:flutter/material.dart';
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

class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(locale);
    final lessonsAsync = ref.watch(lessonsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: lessonsAsync.when(
          data: (lessons) {
            final firstLesson = lessons.isNotEmpty ? lessons.first : null;
            final level = firstLesson?.content['level']?.toString() ?? 'B2';

            return RefreshIndicator(
              onRefresh: () => ref.refresh(lessonsProvider.future),
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LessonsHeader(
                      streakCount: 0,
                      upgradeLabel: s.upgrade,
                      onUpgrade: null,
                    ),
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
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (lessons.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            s.noLessonsYet,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(lessons.length, (index) {
                            final lesson = lessons[index];
                            return LessonStepCircle(
                              lesson: lesson,
                              isLast: index == lessons.length - 1,
                              onTap: () {
                                if (lesson.status == LessonStatus.locked) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => LessonDetailPage(lesson: lesson),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.errorLoadingLessons,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.refresh(lessonsProvider),
                    child: Text(s.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
