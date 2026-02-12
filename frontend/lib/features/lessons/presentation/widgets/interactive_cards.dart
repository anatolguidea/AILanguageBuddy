import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

typedef PlayAudioCallback = Future<void> Function(String text);
typedef OnSolvedCallback = Future<void> Function();

class ImageChoiceWidget extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final bool isSolved;
  final PlayAudioCallback onPlayAudio;
  final OnSolvedCallback onSolved;

  const ImageChoiceWidget({
    super.key,
    required this.cardData,
    required this.isSolved,
    required this.onPlayAudio,
    required this.onSolved,
  });

  @override
  Widget build(BuildContext context) {
    final options = (cardData['options'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cardData['question']?.toString() ?? '',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...options.map((optionRaw) {
          final option = (optionRaw as Map).cast<String, dynamic>();
          final label = option['text']?.toString() ?? '';
          final isCorrect = option['correct'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(
                  color: isSolved && isCorrect
                      ? Colors.green
                      : AppColors.primary.withOpacity(0.5),
                ),
              ),
              onPressed: isSolved
                  ? null
                  : () async {
                      await onPlayAudio(label);
                      if (isCorrect) {
                        await onSolved();
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    const SizedBox(width: 8),
                    if (option['emoji'] != null)
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundBlack.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          option['emoji']!.toString(),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class TranslatePickerWidget extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final bool isSolved;
  final PlayAudioCallback onPlayAudio;
  final OnSolvedCallback onSolved;

  const TranslatePickerWidget({
    super.key,
    required this.cardData,
    required this.isSolved,
    required this.onPlayAudio,
    required this.onSolved,
  });

  @override
  Widget build(BuildContext context) {
    final options = ((cardData['options'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final correctAnswer = cardData['correct_answer']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cardData['question']?.toString() ?? 'Select the correct translation',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isCorrect = option == correctAnswer;
            return ChoiceChip(
              label: Text(option),
              selected: isSolved && isCorrect,
              selectedColor: Colors.green.withOpacity(0.2),
              labelStyle: TextStyle(
                  color: isSolved && isCorrect ? Colors.green : AppColors.textPrimary),
              onSelected: isSolved
                  ? null
                  : (selected) async {
                      if (selected) {
                         await onPlayAudio(option);
                         if (isCorrect) {
                           await onSolved();
                         }
                      }
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SentenceBuilderWidget extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isSolved;
  final PlayAudioCallback onPlayAudio;
  final OnSolvedCallback onSolved;

  const SentenceBuilderWidget({
    super.key,
    required this.cardData,
    required this.isSolved,
    required this.onPlayAudio,
    required this.onSolved,
  });

  @override
  State<SentenceBuilderWidget> createState() => _SentenceBuilderWidgetState();
}

class _SentenceBuilderWidgetState extends State<SentenceBuilderWidget> {
  List<String> selectedWords = [];
  
  @override
  void didUpdateWidget(covariant SentenceBuilderWidget oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (oldWidget.cardData != widget.cardData) {
          selectedWords = [];
      }
  }

  @override
  Widget build(BuildContext context) {
    final sentenceToTranslate = widget.cardData['sentence_to_translate']?.toString() ?? '';
    final wordBank = ((widget.cardData['word_bank'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final correctOrder = ((widget.cardData['correct_order'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.cardData['question']?.toString() ?? 'Translate this sentence',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
           sentenceToTranslate,
           style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        // Selected Area
        Container(
            constraints: const BoxConstraints(minHeight: 50),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3))
            ),
            child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedWords.map((word) {
                    return ActionChip(
                        label: Text(word),
                        onPressed: widget.isSolved ? null : () {
                            setState(() {
                                selectedWords.remove(word);
                            });
                        },
                    );
                }).toList(),
            ),
        ),
        
        const SizedBox(height: 20),
        
        // Word Bank
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wordBank.map((word) {
                // Determine usage count to disable if already used max times
                // Or just if used once. Assuming words are unique in bank or handle duplicates logic? 
                // Simple logic: if word is in selected, don't show or disable. 
                // But duplicate words might exist.
                // Let's count occurrences.
                final totalInBank = wordBank.where((w) => w == word).length;
                final usedCount = selectedWords.where((w) => w == word).length;
                final isAvailable = usedCount < totalInBank;

                return ActionChip(
                    label: Text(word),
                    backgroundColor: isAvailable ? AppColors.surfaceElevated : Colors.transparent,
                    side: BorderSide(color: isAvailable ? AppColors.primary : Colors.grey.withOpacity(0.3)),
                    labelStyle: TextStyle(color: isAvailable ? AppColors.textPrimary : Colors.grey),
                    onPressed: (widget.isSolved || !isAvailable) ? null : () async {
                         await widget.onPlayAudio(word);
                         setState(() {
                             selectedWords.add(word);
                         });
                         _checkSolution(correctOrder);
                    },
                );
            }).toList(),
        )

      ],
    );
  }

  void _checkSolution(List<String> correctOrder) {
      if (selectedWords.length == correctOrder.length) {
          bool isCorrect = true;
          for (int i=0; i<correctOrder.length; i++) {
              if (selectedWords[i] != correctOrder[i]) {
                  isCorrect = false;
                  break;
              }
          }
          
          if (isCorrect) {
              widget.onSolved();
          } else {
              // Maybe shake or show error? For now, we strip user logic:
              // User has to remove words to try again.
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Not quite right, try again!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent, duration: Duration(milliseconds: 1000)),
              );
              setState(() {
                  selectedWords.clear();
              });
          }
      }
  }
}
