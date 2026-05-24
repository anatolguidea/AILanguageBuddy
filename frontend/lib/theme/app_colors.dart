import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6D28D9);
  static const Color primaryLight = Color(0xFF7C3AED);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFF59E0B);

  // Dark mode surfaces (Zinc scale)
  static const Color backgroundDark = Color(0xFF09090B); // Zinc 950
  static const Color surfaceDark = Color(0xFF18181B);    // Zinc 900
  static const Color surfaceElevated = Color(0xFF27272A); // Zinc 800
  static const Color surfaceHighest = Color(0xFF3F3F46);  // Zinc 700

  // Light mode surfaces
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF4F4F5); // Zinc 100
  static const Color surfaceHighestLight = Color(0xFFE4E4E7); // Zinc 200

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textTertiary = Color(0xFF71717A);  // Zinc 500
  static const Color textMuted = Color(0xFF52525B);     // Zinc 600

  // Voice avatar status
  static const Color avatarIdle = Color(0xFF8B5CF6);
  static const Color avatarListening = Color(0xFFF472B6);
  static const Color avatarSpeaking = Color(0xFF6D28D9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient practiceCardGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration get cardDecorationDark => BoxDecoration(
    color: surfaceDark,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: primary.withValues(alpha: 0.12)),
  );

  static BoxDecoration get cardDecorationLight => BoxDecoration(
    color: surfaceLight,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE4E4E7)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
