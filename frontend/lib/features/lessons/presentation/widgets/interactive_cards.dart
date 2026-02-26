import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ailanguageapp/core/l10n/app_strings.dart';
import 'package:ailanguageapp/features/settings/presentation/providers/app_locale_provider.dart';
import '../../../../theme/app_colors.dart';

typedef PlayAudioCallback = Future<void> Function(String text);
typedef OnSolvedCallback = Future<void> Function();

String _localizeQuestion(
  String raw,
  AppStringsData s,
  bool isRo, {
  String? genericFallback,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return genericFallback ?? '';
  if (!isRo) return trimmed;

  // Map known English templates to Romanian (or app language) sentences.
  if (trimmed == 'Which one is \"hello\"?') {
    return s.whichOneIsHello;
  }
  if (trimmed == 'How do you say \"hello\"?') {
    return s.howDoYouSayHello;
  }
  if (trimmed == 'Translate this sentence') {
    return s.translateThisSentenceLabel;
  }

  // Fallback: use a generic localized prompt if provided, otherwise original text.
  return genericFallback ?? trimmed;
}

String _baseLocaleCode(String localeCode) {
  final lower = localeCode.toLowerCase();
  final separatorIndex = lower.indexOf(RegExp(r'[-_]'));
  if (separatorIndex == -1) return lower;
  return lower.substring(0, separatorIndex);
}

/// Prefer a structured localization map from the backend (e.g. {'en': '...', 'ro': '...'})
/// and fall back to a plain string or a provided fallback.
String _resolveLocalizedFromBackend(
  Object? value,
  String localeCode, {
  String? fallback,
  bool allowEnglishFallbackForAnyLocale = false,
}) {
  if (value is Map) {
    // Normalize the incoming locale (e.g. 'ro_RO' -> 'ro').
    final base = _baseLocaleCode(localeCode);

    // Normalize keys coming from the backend as well so that:
    // - 'ro_RO' or 'ro-RO' maps correctly to 'ro'
    // - case differences don't matter.
    final normalized = <String, String>{};
    value.forEach((key, val) {
      if (val == null) return;
      final keyStr = key.toString().toLowerCase();
      final valStr = val.toString();

      // Original key as-is (lowercased).
      normalized[keyStr] = valStr;

      // Also store the base locale version of the key so that
      // 'ro_RO' will be reachable via 'ro'.
      final keyBase = _baseLocaleCode(keyStr);
      normalized.putIfAbsent(keyBase, () => valStr);
    });

    final byBase = normalized[base];
    if (byBase != null && byBase.trim().isNotEmpty) {
      return byBase;
    }

    // English fallback strategy:
    // - For content like prompts/lexemes we *do* want to always fall back to
    //   English if the localized entry is missing (so that users at least see
    //   the base content instead of nothing).
    // - For content like *instructions/questions*, we usually want to let the
    //   frontend/localization layer handle the phrasing in the user's
    //   language, so we only fall back to English when the app locale itself
    //   is English.
    final byEn = normalized['en'];
    if (byEn != null && byEn.trim().isNotEmpty) {
      if (allowEnglishFallbackForAnyLocale || base == 'en') {
        return byEn;
      }
    }
    return fallback ?? '';
  }

  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return fallback ?? '';
}

class ImageChoiceWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final localeCode = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(localeCode);

    // Diagnostic logging to see exactly what arrives from the backend.
    // This is intentionally verbose for debugging the missing prompt issue.
    // Example output:
    // [ImageChoiceWidget] locale=ro_RO, prompt_native={...}, prompt_en=..., sentence_to_translate=..., text=...
    // You can filter by "[ImageChoiceWidget]" in the console.
    // ignore: avoid_print
    print(
      '[ImageChoiceWidget] locale=$localeCode '
      'prompt_native=${cardData['prompt_native']} '
      'prompt_en=${cardData['prompt_en']} '
      'sentence_to_translate=${cardData['sentence_to_translate']} '
      'text=${cardData['text']}',
    );

    // Triple-fallback prompt resolution:
    //
    // 1. Prefer `prompt_native` for the current locale.
    // 2. If empty, fall back to `prompt_en`.
    // 3. If still empty, use `sentence_to_translate` or `text`.
    // 4. As a last resort, fall back to the raw question or a generic label.
    String promptNative = _resolveLocalizedFromBackend(
      cardData['prompt_native'],
      localeCode,
      fallback: '',
      // For lexeme/prompt content we *do* want an English fallback so that
      // we always show something even if only {en: ...} exists.
      allowEnglishFallbackForAnyLocale: true,
    ).trim();

    String promptEn = '';
    if (promptNative.isEmpty) {
      promptEn = _resolveLocalizedFromBackend(
        cardData['prompt_en'],
        localeCode,
        fallback: '',
      ).trim();
    }

    String safetyNet = '';
    if (promptNative.isEmpty && promptEn.isEmpty) {
      final sentenceToTranslate =
          cardData['sentence_to_translate']?.toString().trim();
      final baseText = cardData['text']?.toString().trim();
      safetyNet = (sentenceToTranslate?.isNotEmpty ?? false)
          ? sentenceToTranslate!
          : ((baseText?.isNotEmpty ?? false) ? baseText! : '');
    }

    String promptText = promptNative;
    if (promptText.isEmpty) {
      promptText = promptEn;
    }
    if (promptText.isEmpty) {
      promptText = safetyNet;
    }
    if (promptText.isEmpty) {
      // Absolute safety net so we never render an empty string.
      promptText = s.selectCorrectTranslation;
    }

    // Always use a local, fully localized instruction for this card type.
    // We deliberately ignore any backend-provided "instruction" to avoid
    // inconsistencies and missing text.
    final question = s.selectCorrectTranslation;
    final options = (cardData['options'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(color: scheme.onSurface, fontSize: 16),
        ),
        if (promptText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    promptText,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...options.map((optionRaw) {
          final option = (optionRaw as Map).cast<String, dynamic>();
          final label = option['text']?.toString() ?? '';
          final isCorrect = option['correct'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 180),
              tween: Tween<double>(begin: 1, end: isSolved && isCorrect ? 1.02 : 1),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  backgroundColor: isSolved && isCorrect
                      ? Colors.green.withOpacity(0.12)
                      : scheme.surface,
                  side: BorderSide(
                    color: isSolved && isCorrect
                        ? Colors.green
                        : scheme.primary.withOpacity(0.4),
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onPressed: isSolved
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        await onPlayAudio(label);
                        if (isCorrect) {
                          await onSolved();
                        }
                      },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (option['emoji'] != null)
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          option['emoji']!.toString(),
                          style: const TextStyle(fontSize: 28),
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

class TranslatePickerWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final localeCode = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(localeCode);

    // Diagnostic logging for translate-picker cards.
    // ignore: avoid_print
    print(
      '[TranslatePickerWidget] locale=$localeCode '
      'prompt_native=${cardData['prompt_native']} '
      'prompt_en=${cardData['prompt_en']} '
      'sentence_to_translate=${cardData['sentence_to_translate']} '
      'text=${cardData['text']}',
    );

    final options = ((cardData['options'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final correctAnswer = cardData['correct_answer']?.toString() ?? '';

    // Simplified, hard-fallback prompt/content resolution for TRANSLATE_PICKER:
    // 1) Prefer prompt_native (with English fallback for any locale).
    // 2) If missing, fall back to `text`.
    // 3) If still missing, fall back to `sentence_to_translate`.
    String promptText = _resolveLocalizedFromBackend(
      cardData['prompt_native'],
      localeCode,
      fallback: '',
      allowEnglishFallbackForAnyLocale: true,
    ).trim();

    if (promptText.isEmpty) {
      final textValue = cardData['text']?.toString().trim();
      if (textValue != null && textValue.isNotEmpty) {
        promptText = textValue;
      } else {
        final sentenceToTranslate =
            cardData['sentence_to_translate']?.toString().trim();
        if (sentenceToTranslate != null && sentenceToTranslate.isNotEmpty) {
          promptText = sentenceToTranslate;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // For TRANSLATE_PICKER we always use the local app string, not
          // backend-provided instructions, to avoid missing/inconsistent text.
          s.translateThisSentenceLabel,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (promptText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    promptText,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isCorrect = option == correctAnswer;
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 160),
              tween: Tween<double>(
                begin: 1,
                end: isSolved && isCorrect ? 1.05 : 1,
              ),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: ChoiceChip(
                label: Text(option),
                selected: isSolved && isCorrect,
                selectedColor: Colors.green.withOpacity(0.18),
                backgroundColor: scheme.surface,
                labelStyle: TextStyle(
                  color: isSolved && isCorrect ? Colors.green : scheme.onSurface,
                  fontWeight:
                      isSolved && isCorrect ? FontWeight.w600 : FontWeight.w500,
                ),
                onSelected: isSolved
                    ? null
                    : (selected) async {
                        if (selected) {
                          HapticFeedback.lightImpact();
                          await onPlayAudio(option);
                          if (isCorrect) {
                            await onSolved();
                          }
                        }
                      },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSolved && isCorrect
                        ? Colors.green
                        : scheme.outlineVariant.withOpacity(0.7),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SentenceBuilderWidget extends ConsumerStatefulWidget {
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
  ConsumerState<SentenceBuilderWidget> createState() => _SentenceBuilderWidgetState();
}

class _SentenceBuilderWidgetState extends ConsumerState<SentenceBuilderWidget> {
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
    final scheme = Theme.of(context).colorScheme;
    final localeCode = ref.watch(appLocaleProvider);
    final s = AppStrings.forLocale(localeCode);
    final isRo = localeCode.toLowerCase().startsWith('ro');
    final sentenceNative = _resolveLocalizedFromBackend(
      widget.cardData['sentence_native'],
      localeCode,
      fallback: null,
      allowEnglishFallbackForAnyLocale: true,
    );
    final sentenceToTranslate =
        (sentenceNative.isNotEmpty ? sentenceNative : widget.cardData['sentence_to_translate']?.toString() ?? '');
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
          // Sentence builder cards always use a local, fully localized
          // instruction instead of backend-provided strings.
          s.translateThisSentenceLabel,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
           sentenceToTranslate,
           style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        // Selected Area
        Container(
            constraints: const BoxConstraints(minHeight: 50),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withOpacity(0.3))
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
                    backgroundColor: isAvailable ? scheme.surfaceContainerHighest : Colors.transparent,
                    side: BorderSide(color: isAvailable ? scheme.primary : Colors.grey.withOpacity(0.3)),
                    labelStyle: TextStyle(color: isAvailable ? scheme.onSurface : Colors.grey),
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
