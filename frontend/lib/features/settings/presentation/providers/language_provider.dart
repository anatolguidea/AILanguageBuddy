import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/language.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Language> {
  LanguageNotifier() : super(Language.supported.firstWhere((l) => l.code == 'es', orElse: () => Language.supported.first));

  void setLanguage(Language language) {
    state = language;
  }
}
