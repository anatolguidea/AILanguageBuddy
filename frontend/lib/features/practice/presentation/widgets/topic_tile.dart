import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

class TopicTile extends StatelessWidget {
  final String title;
  final String? topicId;
  final IconData icon;
  final VoidCallback onTap;

  const TopicTile({
    super.key,
    required this.title,
    this.topicId,
    required this.icon,
    required this.onTap,
  });

  String _emojiForTopic(String? id, String rawTitle) {
    switch (id) {
      case 'chef':
        return '🧑‍🍳';
      case 'recipe':
        return '🥘';
      case 'interview':
        return '🎤';
      case 'culinary_trends':
        return '💬';
      case 'gastronomic_event':
        return '🎉';
      case 'professional_skills':
        return '💼';
      case 'cooking_project':
        return '📈';
      case 'food_supplier':
        return '📦';
      case 'international_cuisine':
        return '🌍';
      case 'cover_letter':
        return '📝';
      case 'restaurant_complaint':
        return '⚠️';
      case 'ordering_food':
        return '🍽️';
      case 'travel_airport':
        return '✈️';
      case 'doctor_visit':
        return '🩺';
      case 'cafe_order':
        return '☕';
      case 'market_shopping':
        return '🛍️';
      case 'casual_friend':
        return '💬';
      case 'hotel_checkin':
        return '🏨';
      case 'directions':
        return '🗺️';
      case 'hobbies':
        return '🎨';
      case 'weather':
        return '🌤️';
      case 'booking':
        return '🗓️';
      case 'small_talk':
        return '💬';
      case 'fitness':
        return '🏋️';
      case 'pets':
        return '🐶';
      case 'movies':
        return '🎬';
      case 'music':
        return '🎸';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'work_meeting':
        return '📹';
      default:
        break;
    }

    final t = rawTitle.toLowerCase().trim();
    if (t.contains('hobby') || t.contains('art')) return '🎨';
    if (t.contains('family') || t.contains('familie')) return '👨‍👩‍👧‍👦';
    if (t.contains('music') || t.contains('muzică')) return '🎸';
    if (t.contains('movie') || t.contains('filme')) return '🎬';
    if (t.contains('fitness')) return '🏋️';
    if (t.contains('pet') || t.contains('animale')) return '🐶';
    if (t.contains('meeting') || t.contains('întâlnire')) return '📹';
    if (t.contains('friend') || t.contains('social')) return '💬';
    return '💡';
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiForTopic(topicId, title);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Text(
                      emoji,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoColorEmoji(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.surfaceElevated, height: 16),
      ],
    );
  }
}
