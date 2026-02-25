import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../settings/presentation/providers/language_provider.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../domain/entities/topic.dart';
import 'topic_translations.dart';

abstract class TopicRepository {
  /// [languageCodeForTitles] = UI locale; [targetLanguageCode] = conversation/TTS (en, ro, fr).
  Future<List<Topic>> getTopics(String languageCodeForTitles, String targetLanguageCode);
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
  (id: 'fitness', icon: FontAwesomeIcons.dumbbell),
  (id: 'pets', icon: FontAwesomeIcons.paw),
  (id: 'movies', icon: FontAwesomeIcons.film),
  (id: 'music', icon: FontAwesomeIcons.music),
  (id: 'family', icon: FontAwesomeIcons.peopleGroup),
  (id: 'work_meeting', icon: FontAwesomeIcons.video),
];

class MockTopicRepository implements TopicRepository {
  @override
  Future<List<Topic>> getTopics(String languageCodeForTitles, String targetLanguageCode) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final lang = languageCodeForTitles.toLowerCase().split('-').first;
    final code = _normalizeTargetCode(targetLanguageCode);
    return kTopicConfigs.map((config) {
      final translations = kTopicTranslations[config.id];
      final title = translations?[lang] ?? translations?['en'] ?? config.id;
      return Topic(
        id: config.id,
        title: title,
        icon: config.icon,
        route: '/chat/${config.id}',
        languageCode: code,
      );
    }).toList();
  }

  static String _normalizeTargetCode(String v) {
    final c = v.trim().toLowerCase();
    if (c.isEmpty || c == 'e') return 'en';
    if (c.length == 1) {
      switch (c) {
        case 'f': return 'fr';
        case 's': return 'es';
        case 'r': return 'ro';
        case 'd': return 'de';
        default: return 'en';
      }
    }
    return c.split('-').first;
  }
}

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return MockTopicRepository();
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repository = ref.watch(topicRepositoryProvider);
  final locale = ref.watch(appLocaleProvider);
  final targetCode = ref.watch(languageProvider).code;
  return repository.getTopics(locale, targetCode);
});
