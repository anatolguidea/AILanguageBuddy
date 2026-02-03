class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        role: json['role'] ?? 'assistant',
        text: json['content'] ?? json['text'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': text,
        'createdAt': createdAt.toIso8601String(),
      };
}
