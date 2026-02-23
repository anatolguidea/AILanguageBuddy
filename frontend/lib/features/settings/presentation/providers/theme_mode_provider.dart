import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'theme_mode';

/// Persisted theme mode: 'light', 'dark', or 'system'.
/// Use with [MaterialApp.themeMode].
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    unawaited(_load());
  }

  static const String _light = 'light';
  static const String _dark = 'dark';
  static const String _system = 'system';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode) ?? _dark;
    state = _themeModeFromString(value);
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value.toLowerCase()) {
      case _light:
        return ThemeMode.light;
      case _system:
        return ThemeMode.system;
      case _dark:
      default:
        return ThemeMode.dark;
    }
  }

  String _stringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _light;
      case ThemeMode.system:
        return _system;
      case ThemeMode.dark:
        return _dark;
    }
  }

  /// Sets theme and persists. [isDark] true = dark, false = light.
  void setDark(bool isDark) {
    final next = isDark ? ThemeMode.dark : ThemeMode.light;
    state = next;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyThemeMode, _stringFromThemeMode(next));
    });
  }

  /// Toggle between light and dark (ignores system).
  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setDark(next == ThemeMode.dark);
  }

  /// Direct set for system/light/dark.
  void setThemeMode(ThemeMode mode) {
    state = mode;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyThemeMode, _stringFromThemeMode(mode));
    });
  }

  bool get isDark => state == ThemeMode.dark;
  bool get isLight => state == ThemeMode.light;
}
