class ChatAskRequest {
  final String message;
  final String targetLanguage;
  final String nativeLanguage;
  final String level;
  final String mode;
  final String? instructionLocale;

  ChatAskRequest({
    required this.message,
    required this.targetLanguage,
    this.nativeLanguage = 'English',
    this.level = 'Intermediate',
    this.mode = 'General',
    this.instructionLocale,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'targetLanguage': targetLanguage,
    'nativeLanguage': nativeLanguage,
    'level': level,
    'mode': mode,
    if (instructionLocale != null) 'instructionLocale': instructionLocale,
  };
}

class ChatAskResponse {
  final String replyText;
  final String? correction;
  final String? tips;
  final List<Correction> corrections;
  final List<Vocabulary> vocabulary;

  ChatAskResponse({
    required this.replyText,
    this.correction,
    this.tips,
    this.corrections = const [],
    this.vocabulary = const [],
  });

  factory ChatAskResponse.fromJson(Map<String, dynamic> json) {
    return ChatAskResponse(
      replyText: json['replyText'] ?? '',
      correction: _optStr(json['correction']),
      tips: _optStr(json['tips']),
      corrections: (json['corrections'] as List?)?.map((e) => Correction.fromJson(e)).toList() ?? [],
      vocabulary: (json['vocabulary'] as List?)?.map((e) => Vocabulary.fromJson(e)).toList() ?? [],
    );
  }
}

String? _optStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

class Correction {
  final String original;
  final String corrected;
  final String explanation;

  Correction({required this.original, required this.corrected, required this.explanation});

  factory Correction.fromJson(Map<String, dynamic> json) {
    return Correction(
      original: json['original'] ?? '',
      corrected: json['corrected'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}

class Vocabulary {
  final String term;
  final String translation;
  final String note;

  Vocabulary({required this.term, required this.translation, required this.note});

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      term: json['term'] ?? '',
      translation: json['translation'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class ChatHistoryResponse {
  final List<ChatMessage> messages;
  final String? nextCursor;

  ChatHistoryResponse({required this.messages, this.nextCursor});

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ChatHistoryResponse(
      messages: (json['items'] as List?)?.map((e) => ChatMessage.fromJson(e)).toList() ?? [],
      nextCursor: json['nextCursor'],
    );
  }
}

class ChatMessage {
  final int id;
  final String content;
  final String role;
  final String createdAt;
  final String userId;
  final String? correction;
  final String? tips;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    required this.userId,
    this.correction,
    this.tips,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] : 0,
      content: json['content'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] ?? '',
      userId: json['userId'] ?? '',
      correction: _optStr(json['correction']),
      tips: _optStr(json['tips']),
    );
  }
}
