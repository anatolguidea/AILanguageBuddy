import 'package:equatable/equatable.dart';

enum LessonStatus { locked, available, completed }

class Lesson extends Equatable {
  final String id;
  final String title;
  final String description;
  final LessonStatus status;
  final int orderIndex;
  final Map<String, dynamic> content;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.orderIndex,
    required this.content,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: _parseStatus(json['status']),
      orderIndex: json['orderIndex'] ?? 0,
      content: json['content'] ?? {},
    );
  }

  static LessonStatus _parseStatus(String? status) {
    switch (status) {
      case 'available':
        return LessonStatus.available;
      case 'completed':
        return LessonStatus.completed;
      default:
        return LessonStatus.locked;
    }
  }

  @override
  List<Object?> get props => [id, title, description, status, orderIndex, content];
}
