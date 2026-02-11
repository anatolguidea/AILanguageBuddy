import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/exercise.dart';

/// Duolingo-style "Which one of these is X?" widget.
/// Shows a grid of emoji+label cards. Tapping selects; optional TTS on tap.
class MultipleChoiceWidget extends StatefulWidget {
  final MultipleChoiceExercise exercise;
  final ValueChanged<int> onAnswerChanged;
  final void Function(String label)? onOptionSpeakerTap;

  const MultipleChoiceWidget({
    super.key,
    required this.exercise,
    required this.onAnswerChanged,
    this.onOptionSpeakerTap,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  int? _selectedIndex;

  void _onOptionTap(int index) {
    setState(() => _selectedIndex = index);
    widget.onAnswerChanged(index);
    // Also play TTS for the tapped option
    widget.onOptionSpeakerTap?.call(widget.exercise.options[index].label);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── "NEW WORD" badge ──
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.newWordPurple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'NEW WORD',
              style: TextStyle(
                color: AppColors.newWordPurple,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Prompt ──
        Text(
          widget.exercise.prompt,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),

        // ── Options grid ──
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: options.length <= 3 ? 2 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = _selectedIndex == index;
              return _OptionCard(
                emoji: option.emoji,
                label: option.label,
                isSelected: isSelected,
                onTap: () => _onOptionTap(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.15),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
