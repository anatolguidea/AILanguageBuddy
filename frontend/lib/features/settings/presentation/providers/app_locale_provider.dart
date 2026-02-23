import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyAppLocale = 'app_locale';

/// App UI language: 'en' (English) or 'ro' (Romanian).
/// Persisted in SharedPreferences. Use with [AppStrings.forLocale].
final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, String>((ref) {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends StateNotifier<String> {
  AppLocaleNotifier() : super('en') {
    unawaited(_load());
  }

  static const String en = 'en';
  static const String ro = 'ro';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_keyAppLocale) ?? en;
  }

  void setLocale(String code) {
    if (code != en && code != ro) return;
    state = code;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyAppLocale, code);
    });
  }
}
