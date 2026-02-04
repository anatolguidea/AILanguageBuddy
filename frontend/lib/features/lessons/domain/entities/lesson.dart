import 'package:equatable/equatable.dart';

enum LessonStatus { locked, available, completed }

class Lesson extends Equatable {
  final String id;
  final String title;
  final String description;
  final LessonStatus status;
  final int level;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    this.status = LessonStatus.locked,
    this.level = 0,
  });

  @override
  List<Object?> get props => [id, title, description, status, level];
}
