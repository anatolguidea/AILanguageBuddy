import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../core/constants/app_dimensions.dart';

/// Original design: violet primary, dark surfaces in dark mode.
/// Light mode: same violet brand, light backgrounds, dark text.
class AppTheme {
  // Light mode — same violet primary, light surfaces
  static const Color _lightBackground = Color(0xFFFAFAFA);
  static const Color _lightSurface = Color(0xFFF4F4F5);       // Zinc 100
  static const Color _lightSurfaceVariant = Color(0xFFE4E4E7); // Zinc 200
  static const Color _lightText = Color(0xFF18181B);          // Zinc 900
  static const Color _lightTextSecondary = Color(0xFF71717A); // Zinc 500

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: _lightSurface,
        onSurface: _lightText,
        onSurfaceVariant: _lightTextSecondary,
        surfaceContainerHighest: _lightSurfaceVariant,
        background: _lightBackground,
        onBackground: _lightText,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: _textTheme(_lightText, _lightTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _lightText),
        titleTextStyle: GoogleFonts.outfit(
          color: _lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary, AppColors.onPrimary),
      inputDecorationTheme: _inputDecorationTheme(_lightSurfaceVariant, _lightText, AppColors.primary),
      cardTheme: _cardTheme(_lightSurface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return _lightSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withOpacity(0.5);
          return _lightSurfaceVariant;
        }),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundBlack,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        surfaceContainerHighest: AppColors.surfaceElevated,
        background: AppColors.backgroundBlack,
        onBackground: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundBlack,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary, AppColors.onPrimary),
      inputDecorationTheme: _inputDecorationTheme(AppColors.surfaceElevated, AppColors.textPrimary, AppColors.primary),
      cardTheme: _cardTheme(AppColors.surfaceDark),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceElevated;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withOpacity(0.5);
          return AppColors.surfaceElevated;
        }),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return GoogleFonts.outfitTextTheme().apply(
      bodyColor: primary,
      displayColor: primary,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
      displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
      titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      titleMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.outfit(fontSize: 16, color: primary),
      bodyMedium: GoogleFonts.outfit(fontSize: 14, color: secondary),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bgColor, Color fgColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Color fillColor, Color textColor, Color focusColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
    );
  }

  static CardThemeData _cardTheme(Color color) {
    return CardThemeData(
      color: color,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );
  }
}
