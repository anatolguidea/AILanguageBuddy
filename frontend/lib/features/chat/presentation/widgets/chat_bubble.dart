import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_colors.dart';
import 'grammar_correction_card.dart';

class ChatBubble extends StatefulWidget {
  final String content;
  final bool isUser;
  final String? correction;
  final String? tips;
  final String? incorrectText;
  final String? translation;
  final bool isTranslating;
  final String? sarahLabel;
  final String? listenLabel;
  final String? translateLabel;
  final String? feedbackLabel;
  final String? correctionLabel;
  final String? tipLabel;
  final VoidCallback? onPlay;
  final VoidCallback? onTranslate;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.correction,
    this.tips,
    this.incorrectText,
    this.translation,
    this.isTranslating = false,
    this.sarahLabel,
    this.listenLabel,
    this.translateLabel,
    this.feedbackLabel,
    this.correctionLabel,
    this.tipLabel,
    this.onPlay,
    this.onTranslate,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showExplanation = false;

  bool get _hasCorrection =>
      widget.correction != null && widget.correction!.trim().isNotEmpty;

  bool get _hasTips => widget.tips != null && widget.tips!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = AppColors.primary;
    final secondary = AppColors.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = widget.isUser
        ? primary
        : (isDark ? primary.withValues(alpha: 0.1) : Colors.white);

    final bubbleTextColor = widget.isUser ? Colors.white : scheme.onSurface;

    return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: widget.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!widget.isUser) ...[
                _Avatar(isUser: false),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!widget.isUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          widget.sarahLabel ?? 'Sarah',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleBg,
                        borderRadius: widget.isUser
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(6),
                              )
                            : const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                                bottomLeft: Radius.circular(6),
                              ),
                        border: widget.isUser
                            ? null
                            : Border.all(
                                color: primary.withValues(alpha: 0.18),
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: secondary.withValues(
                              alpha: widget.isUser ? 0.24 : 0.12,
                            ),
                            blurRadius: widget.isUser ? 16 : 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.content,
                            style: TextStyle(
                              color: bubbleTextColor,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!widget.isUser &&
                              (widget.onPlay != null ||
                                  widget.onTranslate != null)) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onPlay != null)
                                  InkWell(
                                    onTap: widget.onPlay,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.volume_up_rounded,
                                            size: 16,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.listenLabel ?? 'Listen',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.onTranslate != null) ...[
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: widget.isTranslating
                                        ? null
                                        : widget.onTranslate,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (widget.isTranslating)
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primary,
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.translate_rounded,
                                              size: 16,
                                              color: primary,
                                            ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.translateLabel ??
                                                'Translate',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (!widget.isUser &&
                              widget.translation != null &&
                              widget.translation!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.translation!,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!widget.isUser && _hasCorrection) ...[
                      const SizedBox(height: 8),
                      GrammarCorrectionCard(
                            incorrectText: widget.incorrectText ?? '',
                            correctedText: widget.correction!,
                            explanation: _showExplanation ? widget.tips : null,
                            onExplainWhy: () {
                              setState(
                                () => _showExplanation = !_showExplanation,
                              );
                            },
                          )
                          .animate()
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.08, end: 0, duration: 350.ms),
                    ],
                    if (!widget.isUser && (_hasCorrection || _hasTips)) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const _FeedbackPill(
                            icon: Icons.check_circle_rounded,
                            label: 'Good effort!',
                            tint: Color(0xFF10B981),
                          ),
                          if (_hasTips)
                            _FeedbackPill(
                              icon: Icons.lightbulb_rounded,
                              label: widget.tipLabel ?? 'Past Tense Tip',
                              tint: Colors.amber,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isUser) ...[
                const SizedBox(width: 10),
                _Avatar(isUser: true),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 300.ms);
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;

  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser
            ? scheme.surfaceContainerHighest
            : AppColors.secondary.withValues(alpha: 0.14),
        border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 18,
        color: isUser ? scheme.onSurfaceVariant : primary,
      ),
    );
  }
}

class _FeedbackPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;

  const _FeedbackPill({
    required this.icon,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: tint.withValues(alpha: 0.25)),
        ),
        color: tint.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

