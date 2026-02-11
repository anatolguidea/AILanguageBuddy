import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/exercise.dart';

/// Duolingo-style "Write this in English" widget.
/// Shows a speaker bubble with the foreign phrase and a word bank below.
class TranslateExerciseWidget extends StatefulWidget {
  final TranslateExercise exercise;
  final ValueChanged<List<String>> onAnswerChanged;
  final VoidCallback? onSpeakerTap;

  const TranslateExerciseWidget({
    super.key,
    required this.exercise,
    required this.onAnswerChanged,
    this.onSpeakerTap,
  });

  @override
  State<TranslateExerciseWidget> createState() => _TranslateExerciseWidgetState();
}

class _TranslateExerciseWidgetState extends State<TranslateExerciseWidget> {
  late List<String> _bank;
  final List<String> _sentence = [];
  // Track which indices in the bank have been used (ghost effect)
  final Set<int> _usedIndices = {};

  @override
  void initState() {
    super.initState();
    _bank = List.of(widget.exercise.wordBank)..shuffle();
  }

  void _onWordTapInBank(int index) {
    if (_usedIndices.contains(index)) return;
    setState(() {
      _usedIndices.add(index);
      _sentence.add(_bank[index]);
    });
    widget.onAnswerChanged(List.of(_sentence));
  }

  void _onWordTapInSentence(int sentenceIndex) {
    final word = _sentence[sentenceIndex];
    // Find the original bank index
    final bankIndex = _bank.indexWhere(
      (w) => w == word && _usedIndices.contains(_bank.indexOf(w)),
    );
    setState(() {
      _sentence.removeAt(sentenceIndex);
      if (bankIndex != -1) {
        _usedIndices.remove(_bank.indexOf(word));
      } else {
        // Fallback: find first used index with this word
        for (int i = 0; i < _bank.length; i++) {
          if (_bank[i] == word && _usedIndices.contains(i)) {
            _usedIndices.remove(i);
            break;
          }
        }
      }
    });
    widget.onAnswerChanged(List.of(_sentence));
  }

  @override
  Widget build(BuildContext context) {
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

        // ── Prompt ("Write this in English") ──
        Text(
          widget.exercise.prompt,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // ── Speaker + foreign phrase bubble ──
        GestureDetector(
          onTap: widget.onSpeakerTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    widget.exercise.foreignPhrase,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Sentence area (slots) ──
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
            ),
          ),
          child: _sentence.isEmpty
              ? Text(
                  '  ',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_sentence.length, (i) {
                    return _WordChip(
                      word: _sentence[i],
                      isSelected: true,
                      onTap: () => _onWordTapInSentence(i),
                    );
                  }),
                ),
        ),

        const Spacer(),

        // ── Word bank ──
        Wrap(
          spacing: 8,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(_bank.length, (i) {
            final isUsed = _usedIndices.contains(i);
            return _WordChip(
              word: _bank[i],
              isGhost: isUsed,
              onTap: isUsed ? null : () => _onWordTapInBank(i),
            );
          }),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Reusable word chip used by both Translate and Arrange exercises.
class _WordChip extends StatelessWidget {
  final String word;
  final bool isSelected;
  final bool isGhost;
  final VoidCallback? onTap;

  const _WordChip({
    required this.word,
    this.isSelected = false,
    this.isGhost = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isGhost) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          word,
          style: TextStyle(color: Colors.transparent, fontSize: 15),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          word,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
