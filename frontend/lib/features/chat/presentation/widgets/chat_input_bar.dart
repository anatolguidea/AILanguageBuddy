import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final bool isListening;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMicTap,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isListening ? 'Listening...' : 'Type a message...',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening ? AppColors.error : AppColors.surfaceElevated,
            ),
            child: IconButton(
              icon: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: isListening ? Colors.white : AppColors.textPrimary,
              ),
              onPressed: onMicTap,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
