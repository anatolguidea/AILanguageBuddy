// Legacy page — fully replaced by LessonSessionPage.
// Kept as a redirect to avoid any stale deep-links.

import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_session_page.dart';

class LessonDetailPage extends StatelessWidget {
  final Lesson lesson;
  const LessonDetailPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to the new session page
    return LessonSessionPage(lesson: lesson);
  }
}
