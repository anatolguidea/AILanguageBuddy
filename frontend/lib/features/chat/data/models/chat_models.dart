class ChatAskRequest {
  final String message;
  final String targetLanguage;
  final String nativeLanguage;
  final String level;
  final String mode;

  ChatAskRequest({
    required this.message,
    this.targetLanguage = 'Spanish', // Default for now
    this.nativeLanguage = 'English',
    this.level = 'Intermediate',
    this.mode = 'General',
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'targetLanguage': targetLanguage,
    'nativeLanguage': nativeLanguage,
    'level': level,
    'mode': mode,
  };
}

class ChatAskResponse {
  final String replyText;
  final List<Correction> corrections;
  final List<Vocabulary> vocabulary;

  ChatAskResponse({
    required this.replyText,
    required this.corrections,
    required this.vocabulary,
  });

  factory ChatAskResponse.fromJson(Map<String, dynamic> json) {
    return ChatAskResponse(
      replyText: json['replyText'] ?? '',
      corrections: (json['corrections'] as List?)?.map((e) => Correction.fromJson(e)).toList() ?? [],
      vocabulary: (json['vocabulary'] as List?)?.map((e) => Vocabulary.fromJson(e)).toList() ?? [],
    );
  }
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

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    required this.userId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] : 0, 
      content: json['content'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] ?? '',
      userId: json['userId'] ?? '',
    );
  }
}
