import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

enum AvatarStatus { idle, listening, speaking }

class AvatarDisplay extends StatelessWidget {
  final AvatarStatus status;
  final double size;

  const AvatarDisplay({
    super.key,
    this.status = AvatarStatus.idle,
    this.size = 200,
  });

  Color get _glowColor {
    switch (status) {
      case AvatarStatus.listening:
        return AppColors.avatarListening;
      case AvatarStatus.speaking:
        return AppColors.avatarSpeaking;
      case AvatarStatus.idle:
      default:
        return AppColors.avatarIdle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _glowColor.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 2000.ms,
            curve: Curves.easeInOut,
          ),

          // Inner Circle / Placeholder Avatar
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
              border: Border.all(color: _glowColor, width: 2),
              image: const DecorationImage(
                image: NetworkImage("https://img.freepik.com/free-psd/3d-illustration-person-with-sunglasses_23-2149436188.jpg"), // Placeholder 3D Avatar
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Status Indicator Ring
          if (status == AvatarStatus.speaking)
             Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).effect(
              duration: 1000.ms,
            ).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)).fadeOut(),
        ],
      ),
    );
  }
}
