import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  final VoidCallback? onPlay;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? Radius.zero : null,
            bottomLeft: isUser ? null : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isUser ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            if (!isUser && onPlay != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: onPlay,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
