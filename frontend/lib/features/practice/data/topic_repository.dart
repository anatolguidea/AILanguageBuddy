import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../domain/entities/topic.dart';

abstract class TopicRepository {
  Future<List<Topic>> getTopics();
}

class MockTopicRepository implements TopicRepository {
  @override
  Future<List<Topic>> getTopics() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      Topic(
        id: '1',
        title: 'Parler du métier de chef',
        icon: FontAwesomeIcons.utensils,
        route: '/chat/chef',
      ),
      Topic(
        id: '2',
        title: 'Décrire une recette favorite',
        icon: FontAwesomeIcons.fireBurner,
        route: '/chat/recipe',
      ),
      Topic(
        id: '3',
        title: "Simulation d'entretien",
        icon: FontAwesomeIcons.microphone,
        route: '/chat/interview',
      ),
    ];
  }
}

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return MockTopicRepository();
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repository = ref.watch(topicRepositoryProvider);
  return repository.getTopics();
});
