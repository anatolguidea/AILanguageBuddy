class Language {
  final String code;
  final String name;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const List<Language> supported = [
    Language(code: 'en', name: 'English', flag: '🇺🇸'),
    Language(code: 'ro', name: 'Română', flag: '🇷🇴'),
    Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    Language(code: 'fr', name: 'French', flag: '🇫🇷'),
    Language(code: 'de', name: 'German', flag: '🇩🇪'),
    Language(code: 'it', name: 'Italian', flag: '🇮🇹'),
    Language(code: 'pt', name: 'Portuguese', flag: '🇵🇹'),
    Language(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    Language(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    Language(code: 'zh', name: 'Chinese', flag: '🇨🇳'),
  ];
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
