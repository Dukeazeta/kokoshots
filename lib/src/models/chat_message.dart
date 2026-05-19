class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: map['role'] as String? ?? 'assistant',
      text: map['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
