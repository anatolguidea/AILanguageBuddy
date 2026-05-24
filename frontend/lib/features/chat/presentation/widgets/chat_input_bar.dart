import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final VoidCallback? onAddTap;
  final bool isListening;
  final String? typeAMessageHint;
  final String? listeningHint;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMicTap,
    this.onAddTap,
    this.isListening = false,
    this.typeAMessageHint,
    this.listeningHint,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _sendHovered = false;
  bool _sendPressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = AppColors.primary;
    final secondary = AppColors.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          top: BorderSide(color: secondary.withValues(alpha: 0.24)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? secondary.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: widget.onAddTap,
              ),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: isDark
                      ? secondary.withValues(alpha: 0.1)
                      : const Color(0xFFF3F0F6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: secondary.withValues(alpha: 0.24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        style: TextStyle(color: scheme.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: widget.isListening
                              ? (widget.listeningHint ?? 'Listening...')
                              : (widget.typeAMessageHint ??
                                    'Type your response...'),
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            12,
                            6,
                            12,
                          ),
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                            null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => widget.onSend(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isListening
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                        color: widget.isListening
                            ? Colors.redAccent
                            : scheme.onSurfaceVariant,
                      ),
                      onPressed: widget.onMicTap,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            MouseRegion(
              onEnter: (_) => setState(() => _sendHovered = true),
              onExit: (_) => setState(() => _sendHovered = false),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _sendPressed = true),
                onTapCancel: () => setState(() => _sendPressed = false),
                onTapUp: (_) => setState(() => _sendPressed = false),
                onTap: widget.onSend,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: _sendPressed ? 0.94 : (_sendHovered ? 1.06 : 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(
                            alpha: _sendHovered ? 0.5 : 0.36,
                          ),
                          blurRadius: _sendHovered ? 16 : 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
