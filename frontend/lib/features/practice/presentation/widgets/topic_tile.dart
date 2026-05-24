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
      case 'chef': return '🧑‍🍳';
      case 'recipe': return '🥘';
      case 'interview': return '🎤';
      case 'culinary_trends': return '💬';
      case 'gastronomic_event': return '🎉';
      case 'professional_skills': return '💼';
      case 'cooking_project': return '📈';
      case 'food_supplier': return '📦';
      case 'international_cuisine': return '🌍';
      case 'cover_letter': return '📝';
      case 'restaurant_complaint': return '⚠️';
      case 'ordering_food': return '🍽️';
      case 'travel_airport': return '✈️';
      case 'doctor_visit': return '🩺';
      case 'cafe_order': return '☕';
      case 'market_shopping': return '🛍️';
      case 'casual_friend': return '💬';
      case 'hotel_checkin': return '🏨';
      case 'directions': return '🗺️';
      case 'hobbies': return '🎨';
      case 'weather': return '🌤️';
      case 'booking': return '🗓️';
      case 'small_talk': return '💬';
      case 'fitness': return '🏋️';
      case 'pets': return '🐶';
      case 'movies': return '🎬';
      case 'music': return '🎸';
      case 'family': return '👨‍👩‍👧‍👦';
      case 'work_meeting': return '📹';
      default: break;
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: scheme.primary.withValues(alpha: 0.06),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.surfaceElevated
                    : const Color(0xFFE4E4E7),
              ),
            ),
            child: Row(
              children: [
                // Emoji badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: GoogleFonts.notoColorEmoji(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Arrow
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
