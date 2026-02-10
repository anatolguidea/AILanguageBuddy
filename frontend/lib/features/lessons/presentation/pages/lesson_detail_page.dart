import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/lesson.dart';
import '../providers/lessons_provider.dart';
import '../../data/lessons_repository.dart';

class LessonDetailPage extends ConsumerStatefulWidget {
  final Lesson lesson;

  const LessonDetailPage({super.key, required this.lesson});

  @override
  ConsumerState<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends ConsumerState<LessonDetailPage> {
  bool _isLoading = false;

  Future<void> _completeLesson() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(lessonsRepositoryProvider).completeLesson(widget.lesson.id);
      // Refresh the list to update status
      ref.invalidate(lessonsProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic content rendering - assume simplistic JSON structure for demo
    final sections = (widget.lesson.content['sections'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index] as Map;
                final type = section['type'];
                final content = section['content'];

                if (type == 'text') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      content.toString(),
                      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    ),
                  );
                }
                // Add more types here (image, audio, quiz)
                return const SizedBox.shrink();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || widget.lesson.status == LessonStatus.completed 
                    ? null 
                    : _completeLesson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      widget.lesson.status == LessonStatus.completed ? 'Completed' : 'Complete Lesson',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
