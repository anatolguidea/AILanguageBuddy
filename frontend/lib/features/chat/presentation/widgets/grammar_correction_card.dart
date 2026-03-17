import 'package:flutter/material.dart';

class GrammarCorrectionCard extends StatelessWidget {
  final String incorrectText;
  final String correctedText;
  final String? explanation;
  final VoidCallback? onExplainWhy;

  const GrammarCorrectionCard({
    super.key,
    required this.incorrectText,
    required this.correctedText,
    this.explanation,
    this.onExplainWhy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final incorrect = incorrectText.trim().isEmpty ? '—' : incorrectText.trim();
    final corrected = correctedText.trim().isEmpty ? '—' : correctedText.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                'Grammar Correction',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            incorrect,
            style: TextStyle(
              fontSize: 12,
              color: Colors.redAccent.withValues(alpha: 0.8),
              decoration: TextDecoration.lineThrough,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            corrected,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onExplainWhy,
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text(
              'Explain why',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          if (explanation != null && explanation!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                explanation!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
