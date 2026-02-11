import 'package:flutter/material.dart';

class AppColors {
  // Primary "Praktika" Brand Colors
  static const Color primary = Color(0xFF6D28D9); // Deep Violet
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF8B5CF6); // Lighter Violet
  static const Color accent = Color(0xFFF59E0B); // Amber/Orange (Streak)

  // Backgrounds
  static const Color backgroundBlack = Color(0xFF000000); // Pure Black
  static const Color surfaceDark = Color(0xFF18181B); // Zinc 900
  static const Color surfaceElevated = Color(0xFF27272A); // Zinc 800
  
  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // Avatar Status
  static const Color avatarIdle = Color(0xFF8B5CF6);
  static const Color avatarListening = Color(0xFFF472B6);
  static const Color avatarSpeaking = Color(0xFF6D28D9);

  // Duolingo-style Lesson Colors
  static const Color correctGreen = Color(0xFF58CC02);
  static const Color incorrectRed = Color(0xFFFF4B4B);
  static const Color streakGold = Color(0xFFFFC800);
  static const Color newWordPurple = Color(0xFFCE82FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textTertiary = Color(0xFF52525B); // Zinc 600

  // Gradients
  static const LinearGradient practiceCardGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFC026D3)], // Violet to Fuchsia
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
