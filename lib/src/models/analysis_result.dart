import 'dart:convert';

class AnalysisResult {
  const AnalysisResult({required this.description, required this.tags});

  final String description;
  final List<String> tags;

  /// Parses a JSON array response from a batched multi-image Gemini call.
  ///
  /// Expected format:
  /// ```json
  /// [
  ///   {"index": 0, "description": "...", "tags": ["...", "..."]},
  ///   {"index": 1, "description": "...", "tags": ["...", "..."]}
  /// ]
  /// ```
  ///
  /// Returns a list where each element corresponds to an image by index.
  /// If [batchSize] is provided, the list is guaranteed to have exactly that
  /// length, filling gaps with a default result.
  static List<AnalysisResult> parseMultiple(String rawText, {int? batchSize}) {
    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Find the outermost JSON array
    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start == -1 || end <= start) {
      return _fillDefaults([], batchSize);
    }

    final decoded = jsonDecode(cleaned.substring(start, end + 1));
    if (decoded is! List) {
      return _fillDefaults([], batchSize);
    }

    // Parse into a map keyed by index for safe ordering
    final indexed = <int, AnalysisResult>{};
    for (var i = 0; i < decoded.length; i++) {
      final entry = decoded[i];
      if (entry is! Map<String, dynamic>) continue;

      final idx = entry['index'] is int ? entry['index'] as int : i;
      final tags = entry['tags'];
      indexed[idx] = AnalysisResult(
        description: entry['description']?.toString().trim() ??
            'Screenshot analyzed.',
        tags: tags is List
            ? tags.map((tag) => tag.toString().toLowerCase()).toList()
            : const ['screenshot'],
      );
    }

    // Build ordered list
    final maxIndex = batchSize ??
        (indexed.keys.isEmpty ? 0 : indexed.keys.reduce((a, b) => a > b ? a : b) + 1);
    final results = <AnalysisResult>[];
    for (var i = 0; i < maxIndex; i++) {
      results.add(
        indexed[i] ??
            const AnalysisResult(
              description: 'Screenshot analyzed.',
              tags: ['screenshot'],
            ),
      );
    }
    return results;
  }

  static List<AnalysisResult> _fillDefaults(
    List<AnalysisResult> partial,
    int? batchSize,
  ) {
    if (batchSize == null) return partial;
    return List.generate(batchSize, (i) {
      return i < partial.length
          ? partial[i]
          : const AnalysisResult(
              description: 'Screenshot analyzed.',
              tags: ['screenshot'],
            );
    });
  }
}
