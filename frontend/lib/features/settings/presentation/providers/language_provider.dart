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
      final code = (data?['target_language'] as String?)?.toLowerCase();
      if (code == null || code.isEmpty) return;
      final matching = Language.supported.where((l) => l.code == code);
      if (matching.isNotEmpty) {
        state = matching.first;
      }
    } catch (_) {
      // keep current language if profile data is unavailable
    }
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
