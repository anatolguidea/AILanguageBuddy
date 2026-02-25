import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/language.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((
  ref,
) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Language> {
  LanguageNotifier()
    : super(
        Language.supported.firstWhere(
          (l) => l.code == 'es',
          orElse: () => Language.supported.first,
        ),
      ) {
    unawaited(_loadFromProfile());
  }

  void setLanguage(Language language) {
    state = language;
    unawaited(_persistToProfile(language.code));
  }

  Future<void> _loadFromProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('target_language')
          .eq('id', userId)
          .maybeSingle();
      final raw = (data?['target_language'] as String?)?.toLowerCase().trim();
      if (raw == null || raw.isEmpty) return;
      final code = _normalizeLanguageCode(raw);
      final matching = Language.supported.where((l) => l.code == code);
      if (matching.isNotEmpty) {
        state = matching.first;
      }
    } catch (_) {
      // keep current language if profile data is unavailable
    }
  }

  static String _normalizeLanguageCode(String v) {
    if (v == 'e') return 'en';
    if (v == 'f') return 'fr';
    if (v.length >= 2) return v.split('-').first;
    return v;
  }

  Future<void> _persistToProfile(String code) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'target_language': code,
      });
    } catch (_) {}
  }
}
