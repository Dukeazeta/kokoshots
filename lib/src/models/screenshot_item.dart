import 'dart:convert';

class ScreenshotItem {
  const ScreenshotItem({
    required this.id,
    required this.assetId,
    required this.filePath,
    required this.thumbnailPath,
    required this.description,
    required this.tags,
    required this.dateTaken,
    required this.dateIndexed,
    required this.isProcessed,
    required this.status,
    this.errorMessage,
  });

  final String id;
  final String assetId;
  final String filePath;
  final String thumbnailPath;
  final String description;
  final List<String> tags;
  final DateTime dateTaken;
  final DateTime dateIndexed;
  final bool isProcessed;
  final String status;
  final String? errorMessage;

  ScreenshotItem copyWith({
    String? description,
    List<String>? tags,
    DateTime? dateIndexed,
    bool? isProcessed,
    String? status,
    String? errorMessage,
    String? filePath,
    String? thumbnailPath,
  }) {
    return ScreenshotItem(
      id: id,
      assetId: assetId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      dateTaken: dateTaken,
      dateIndexed: dateIndexed ?? this.dateIndexed,
      isProcessed: isProcessed ?? this.isProcessed,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'description': description,
      'tags': jsonEncode(tags),
      'date_taken': dateTaken.toIso8601String(),
      'date_indexed': dateIndexed.toIso8601String(),
      'is_processed': isProcessed ? 1 : 0,
      'status': status,
      'error_message': errorMessage,
    };
  }

  factory ScreenshotItem.fromMap(Map<String, Object?> map) {
    return ScreenshotItem(
      id: map['id'] as String,
      assetId: map['asset_id'] as String? ?? '',
      filePath: map['file_path'] as String? ?? '',
      thumbnailPath: map['thumbnail_path'] as String? ?? '',
      description: map['description'] as String? ?? '',
      tags: _decodeTags(map['tags'] as String?),
      dateTaken:
          DateTime.tryParse(map['date_taken'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dateIndexed:
          DateTime.tryParse(map['date_indexed'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isProcessed: (map['is_processed'] as int? ?? 0) == 1,
      status: map['status'] as String? ?? 'pending',
      errorMessage: map['error_message'] as String?,
    );
  }

  bool matches(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return true;
    final haystack = [
      description,
      filePath,
      status,
      ...tags,
    ].join(' ').toLowerCase();
    return normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .every(haystack.contains);
  }

  static List<String> _decodeTags(String? value) {
    if (value == null || value.isEmpty) return const [];
    final decoded = jsonDecode(value);
    if (decoded is! List) return const [];
    return decoded.map((tag) => tag.toString()).toList(growable: false);
  }
}
