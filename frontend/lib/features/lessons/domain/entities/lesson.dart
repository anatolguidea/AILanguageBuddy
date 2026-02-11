import 'package:equatable/equatable.dart';
import 'exercise.dart';

enum LessonStatus { locked, available, completed }

class Lesson extends Equatable {
  final String id;
  final String title;
  final String description;
  final LessonStatus status;
  final int orderIndex;
  final String languageCode;
  final int xpReward;
  final String estimatedTime;
  final List<Exercise> exercises;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.orderIndex,
    required this.languageCode,
    this.xpReward = 10,
    this.estimatedTime = '5 min',
    this.exercises = const [],
  });

  // Factory/parsing logic will be moved to a Mapper in Data layer to keep Domain pure
  
  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    LessonStatus? status,
    int? orderIndex,
    String? languageCode,
    int? xpReward,
    String? estimatedTime,
    List<Exercise>? exercises,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
      languageCode: languageCode ?? this.languageCode,
      xpReward: xpReward ?? this.xpReward,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      exercises: exercises ?? this.exercises,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    orderIndex,
    languageCode,
    xpReward,
    estimatedTime,
    exercises,
  ];
}
