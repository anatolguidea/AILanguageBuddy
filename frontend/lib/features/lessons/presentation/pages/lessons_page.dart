import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/lesson.dart';
import '../widgets/lesson_node.dart';
import '../providers/lessons_provider.dart';
import 'lesson_detail_page.dart';

class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Learning Path'),
        centerTitle: true,
      ),
      body: lessonsAsync.when(
        data: (lessons) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: List.generate(lessons.length, (index) {
                final lesson = lessons[index];
                return LessonNode(
                  lesson: lesson,
                  isLast: index == lessons.length - 1,
                  onTap: () {
                    if (lesson.status == LessonStatus.locked) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Complete previous lessons to unlock this one.')),
                       );
                       return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LessonDetailPage(lesson: lesson)),
                    );
                  },
                );
              }),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
