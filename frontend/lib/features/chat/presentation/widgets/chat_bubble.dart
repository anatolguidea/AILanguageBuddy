import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ChatBubble extends StatefulWidget {
  final String content;
  final bool isUser;
  final String? correction;
  final String? tips;
  final String? sarahLabel;
  final String? listenLabel;
  final String? feedbackLabel;
  final String? correctionLabel;
  final String? tipLabel;
  final VoidCallback? onPlay;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.correction,
    this.tips,
    this.sarahLabel,
    this.listenLabel,
    this.feedbackLabel,
    this.correctionLabel,
    this.tipLabel,
    this.onPlay,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _feedbackExpanded = false;

  bool get _hasFeedback =>
      (widget.correction != null && widget.correction!.isNotEmpty) ||
      (widget.tips != null && widget.tips!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment:
                widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!widget.isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    widget.sarahLabel ?? 'Sarah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.isUser
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: widget.isUser ? const Radius.circular(6) : null,
                    bottomLeft: widget.isUser ? null : const Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content,
                      style: TextStyle(
                        color: widget.isUser
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    if (!widget.isUser && widget.onPlay != null) ...[
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onPlay,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.listenLabel ?? 'Listen',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!widget.isUser && _hasFeedback) _buildFeedbackCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _feedbackExpanded = !_feedbackExpanded),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: _feedbackExpanded ? 14 : 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.feedbackLabel ?? 'Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _feedbackExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                if (_feedbackExpanded) ...[
                  const SizedBox(height: 12),
                  if (widget.correction != null &&
                      widget.correction!.isNotEmpty) ...[
                    Text(
                      widget.correctionLabel ?? 'Correction',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.correction!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.tips != null && widget.tips!.isNotEmpty) ...[
                    Text(
                      widget.tipLabel ?? 'Tip',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tips!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
