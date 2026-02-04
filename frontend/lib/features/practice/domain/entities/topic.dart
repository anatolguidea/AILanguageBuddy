import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Topic extends Equatable {
  final String id;
  final String title;
  final IconData icon;
  final String route;

  const Topic({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  List<Object?> get props => [id, title, icon, route];
}
