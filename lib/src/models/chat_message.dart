import 'dart:convert';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.matchedAssetIds,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  /// Asset IDs of screenshots that matched the user's query.
  /// Only populated on assistant messages that return search results.
  final List<String>? matchedAssetIds;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'matched_asset_ids': matchedAssetIds != null
          ? jsonEncode(matchedAssetIds)
          : null,
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
      matchedAssetIds: _decodeAssetIds(map['matched_asset_ids'] as String?),
    );
  }

  static List<String>? _decodeAssetIds(String? value) {
    if (value == null || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is! List) return null;
    return decoded.map((id) => id.toString()).toList(growable: false);
  }
}
