import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../core/constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: Color(0xFFEDE9FE), // Violet 100
      onPrimaryContainer: Color(0xFF4C1D95),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      surface: AppColors.surfaceLight,
      surfaceContainerLow: AppColors.backgroundLight,
      surfaceContainer: AppColors.surfaceVariantLight,
      surfaceContainerHigh: AppColors.surfaceVariantLight,
      surfaceContainerHighest: AppColors.surfaceHighestLight,
      onSurface: Color(0xFF18181B),
      onSurfaceVariant: Color(0xFF71717A),
      outline: Color(0xFFD4D4D8),
      outlineVariant: Color(0xFFE4E4E7),
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: AppColors.primary,
      colorScheme: scheme,
      textTheme: _textTheme(const Color(0xFF18181B), const Color(0xFF71717A)),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF18181B)),
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF18181B),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : const Color(0xFF71717A),
          );
        }),
        height: 64,
      ),
      filledButtonTheme: _filledButtonTheme(AppColors.primary, Colors.white),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary, Colors.white),
      outlinedButtonTheme: _outlinedButtonTheme(AppColors.primary),
      textButtonTheme: _textButtonTheme(AppColors.primary),
      inputDecorationTheme: _inputDecorationTheme(
        AppColors.surfaceVariantLight,
        const Color(0xFF18181B),
        AppColors.primary,
      ),
      cardTheme: _cardTheme(AppColors.surfaceLight, const Color(0xFFE4E4E7)),
      chipTheme: _chipTheme(scheme),
      switchTheme: _switchTheme(AppColors.primary, AppColors.surfaceHighestLight),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4E4E7),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 14,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: Color(0xFF3B0764),
      onPrimaryContainer: Color(0xFFEDE9FE),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      surface: AppColors.surfaceDark,
      surfaceContainerLow: AppColors.backgroundDark,
      surfaceContainer: AppColors.surfaceElevated,
      surfaceContainerHigh: AppColors.surfaceElevated,
      surfaceContainerHighest: AppColors.surfaceHighest,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.surfaceHighest,
      outlineVariant: AppColors.surfaceElevated,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primary,
      colorScheme: scheme,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        height: 64,
      ),
      filledButtonTheme: _filledButtonTheme(AppColors.primary, Colors.white),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary, Colors.white),
      outlinedButtonTheme: _outlinedButtonTheme(AppColors.secondary),
      textButtonTheme: _textButtonTheme(AppColors.secondary),
      inputDecorationTheme: _inputDecorationTheme(
        AppColors.surfaceElevated,
        AppColors.textPrimary,
        AppColors.secondary,
      ),
      cardTheme: _cardTheme(AppColors.surfaceDark, AppColors.surfaceElevated),
      chipTheme: _chipTheme(scheme),
      switchTheme: _switchTheme(AppColors.primary, AppColors.surfaceElevated),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceElevated,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 14,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 36, fontWeight: FontWeight.w800, color: primary, letterSpacing: -0.5, height: 1.1,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3, height: 1.2,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.2, height: 1.2,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 22, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.2,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.1,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600, color: primary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 17, fontWeight: FontWeight.w600, color: primary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 15, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.1,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 13, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondary, height: 1.5,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.4,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 0.5,
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(Color bg, Color fg) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg, Color fg) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Color primary) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: primary.withValues(alpha: 0.35), width: 1.5),
        textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(Color primary) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(48, 48),
        textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    Color fill, Color text, Color focus,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: TextStyle(color: text.withValues(alpha: 0.65)),
      hintStyle: GoogleFonts.outfit(
        color: text.withValues(alpha: 0.4),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: TextStyle(color: focus, fontWeight: FontWeight.w600),
    );
  }

  static CardThemeData _cardTheme(Color color, Color border) {
    return CardThemeData(
      color: color,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: border),
      ),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme scheme) {
    return ChipThemeData(
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  static SwitchThemeData _switchTheme(Color active, Color inactive) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? active : inactive;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? active.withValues(alpha: 0.45)
            : inactive;
      }),
    );
  }
}
