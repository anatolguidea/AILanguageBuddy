import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Topic extends Equatable {
  final String id;
  final String title;
  final IconData icon;
  final String route;
  /// ISO 2-letter code (en, ro, fr) for this topic's conversation and TTS.
  final String languageCode;

  const Topic({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
    this.languageCode = 'en',
  });

  @override
  List<Object?> get props => [id, title, icon, route, languageCode];
}
