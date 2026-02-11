import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/exercise.dart';

/// Duolingo-style arrange-words widget.
/// Optional foreign-phrase speaker bubble, ghost words in word bank,
/// sentence slot area with bottom underline.
class ArrangeWordsWidget extends StatefulWidget {
  final ArrangeWordsExercise exercise;
  final ValueChanged<List<String>> onAnswerChanged;
  final VoidCallback? onSpeakerTap;

  const ArrangeWordsWidget({
    super.key,
    required this.exercise,
    required this.onAnswerChanged,
    this.onSpeakerTap,
  });

  @override
  State<ArrangeWordsWidget> createState() => _ArrangeWordsWidgetState();
}

class _ArrangeWordsWidgetState extends State<ArrangeWordsWidget> {
  late List<String> _bank;
  final List<String> _sentence = [];
  final Set<int> _usedIndices = {};

  @override
  void initState() {
    super.initState();
    _bank = List.of(widget.exercise.words)..shuffle();
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
    setState(() {
      _sentence.removeAt(sentenceIndex);
      for (int i = 0; i < _bank.length; i++) {
        if (_bank[i] == word && _usedIndices.contains(i)) {
          _usedIndices.remove(i);
          break;
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
              width: 10, height: 10,
              decoration: const BoxDecoration(color: AppColors.newWordPurple, shape: BoxShape.circle),
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
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ── Optional: Foreign phrase speaker bubble ──
        if (widget.exercise.foreignPhrase != null && widget.exercise.foreignPhrase!.isNotEmpty) ...[
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
                      widget.exercise.foreignPhrase!,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (widget.exercise.hint.isNotEmpty) ...[
          Text(
            'Hint: ${widget.exercise.hint}',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
        ],

        // ── Sentence area ──
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 2)),
          ),
          child: _sentence.isEmpty
              ? Text('  ', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_sentence.length, (i) {
                    return _WordChip(word: _sentence[i], isSelected: true, onTap: () => _onWordTapInSentence(i));
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

class _WordChip extends StatelessWidget {
  final String word;
  final bool isSelected;
  final bool isGhost;
  final VoidCallback? onTap;

  const _WordChip({required this.word, this.isSelected = false, this.isGhost = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isGhost) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(word, style: const TextStyle(color: Colors.transparent, fontSize: 15)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2), blurRadius: 0),
          ],
        ),
        child: Text(
          word,
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
        ),
      ),
    );
  }
}
