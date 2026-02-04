import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/lesson.dart';
import '../widgets/lesson_node.dart';

class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key});

  static const List<Lesson> mockLessons = [
    Lesson(id: '1', title: 'Basics 1', description: 'Hello and goodbye', status: LessonStatus.completed),
    Lesson(id: '2', title: 'Basics 2', description: 'Common phrases', status: LessonStatus.completed),
    Lesson(id: '3', title: 'Food', description: 'Ordering at a restaurant', status: LessonStatus.available),
    Lesson(id: '4', title: 'Travel', description: 'At the airport', status: LessonStatus.locked),
    Lesson(id: '5', title: 'Shopping', description: 'Buying clothes', status: LessonStatus.locked),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Learning Path'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: List.generate(mockLessons.length, (index) {
              final lesson = mockLessons[index];
              return LessonNode(
                lesson: lesson,
                isLast: index == mockLessons.length - 1,
                onTap: () {
                  // TODO: Open lesson details/start lesson
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
