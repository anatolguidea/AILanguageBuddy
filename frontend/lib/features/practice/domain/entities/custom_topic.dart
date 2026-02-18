import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CustomTopic extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;

  const CustomTopic({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
  });

  /// Route to open chat for this custom topic (use id as scenario/mode).
  String get route => '/chat/custom_$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomTopic.fromJson(Map<String, dynamic> json) {
    return CustomTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CustomTopic copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
  }) {
    return CustomTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, createdAt];
}
