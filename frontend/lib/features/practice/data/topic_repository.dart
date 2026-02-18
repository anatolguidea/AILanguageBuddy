import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../settings/presentation/providers/language_provider.dart';
import '../domain/entities/topic.dart';
import 'topic_translations.dart';

abstract class TopicRepository {
  Future<List<Topic>> getTopics(String languageCode);
}

/// Topic id -> icon and route. Title comes from topic_translations.
const List<({String id, IconData icon})> kTopicConfigs = [
  (id: 'chef', icon: FontAwesomeIcons.utensils),
  (id: 'recipe', icon: FontAwesomeIcons.fireBurner),
  (id: 'interview', icon: FontAwesomeIcons.microphone),
  (id: 'culinary_trends', icon: FontAwesomeIcons.plateWheat),
  (id: 'gastronomic_event', icon: FontAwesomeIcons.calendarDays),
  (id: 'professional_skills', icon: FontAwesomeIcons.briefcase),
  (id: 'cooking_project', icon: FontAwesomeIcons.chartLine),
  (id: 'food_supplier', icon: FontAwesomeIcons.phone),
  (id: 'international_cuisine', icon: FontAwesomeIcons.globe),
  (id: 'cover_letter', icon: FontAwesomeIcons.penToSquare),
  (id: 'restaurant_complaint', icon: FontAwesomeIcons.commentDots),
  (id: 'ordering_food', icon: FontAwesomeIcons.utensils),
  (id: 'travel_airport', icon: FontAwesomeIcons.plane),
  (id: 'doctor_visit', icon: FontAwesomeIcons.stethoscope),
  (id: 'cafe_order', icon: FontAwesomeIcons.mugSaucer),
  (id: 'market_shopping', icon: FontAwesomeIcons.basketShopping),
  (id: 'casual_friend', icon: FontAwesomeIcons.hand),
  (id: 'hotel_checkin', icon: FontAwesomeIcons.hotel),
  (id: 'directions', icon: FontAwesomeIcons.locationDot),
  (id: 'hobbies', icon: FontAwesomeIcons.palette),
  (id: 'weather', icon: FontAwesomeIcons.cloudSun),
  (id: 'booking', icon: FontAwesomeIcons.calendarCheck),
  (id: 'small_talk', icon: FontAwesomeIcons.comments),
];

class MockTopicRepository implements TopicRepository {
  @override
  Future<List<Topic>> getTopics(String languageCode) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final lang = languageCode.toLowerCase().split('-').first;
    return kTopicConfigs.map((config) {
      final translations = kTopicTranslations[config.id];
      final title = translations?[lang] ?? translations?['en'] ?? config.id;
      return Topic(
        id: config.id,
        title: title,
        icon: config.icon,
        route: '/chat/${config.id}',
      );
    }).toList();
  }
}

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return MockTopicRepository();
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repository = ref.watch(topicRepositoryProvider);
  final language = ref.watch(languageProvider);
  return repository.getTopics(language.code);
});
