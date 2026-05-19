import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_result.dart';
import '../models/screenshot_item.dart';

class GeminiService {
  GeminiService({Dio? dio}) : _dio = dio ?? Dio();

  /// Compile-time key (fallback) via --dart-define=GEMINI_API_KEY
  static const _compileTimeKey = String.fromEnvironment('GEMINI_API_KEY');

  static const model = 'gemini-2.5-flash';

  final Dio _dio;

  /// Runtime API key, loaded from SharedPreferences.
  String? _runtimeKey;

  /// The effective API key: runtime > compile-time.
  String get _apiKey => (_runtimeKey ?? '').isNotEmpty
      ? _runtimeKey!
      : _compileTimeKey;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// Load the persisted key from SharedPreferences.
  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeKey = prefs.getString('gemini_api_key');
  }

  /// Save a new API key at runtime.
  Future<void> setApiKey(String key) async {
    _runtimeKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_runtimeKey!.isEmpty) {
      await prefs.remove('gemini_api_key');
    } else {
      await prefs.setString('gemini_api_key', _runtimeKey!);
    }
  }

  Future<AnalysisResult> analyzeScreenshot(Uint8List bytes) async {
    if (!isConfigured) {
      throw const GeminiNotConfiguredException();
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text': '''
Analyze this device screenshot. Return only compact JSON with:
description: one useful sentence,
tags: 4 to 8 lowercase tags.
Avoid guessing sensitive account numbers or private credentials.
''',
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(bytes),
                },
              },
            ],
          },
        ],
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
      ),
    );

    final text = _extractText(response.data);
    return _parseAnalysis(text);
  }

  Future<String> buildSearchReply({
    required String question,
    required List<ScreenshotItem> localMatches,
    required int totalIndexed,
  }) async {
    if (!isConfigured) {
      return _fallbackReply(question, localMatches, totalIndexed);
    }

    final context = localMatches.take(12).map((item) {
      return {
        'description': item.description,
        'tags': item.tags,
        'dateTaken': item.dateTaken.toIso8601String(),
      };
    }).toList();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''
You are KokoShots, an assistant that helps find screenshots from local metadata.
User question: $question
Total indexed screenshots: $totalIndexed
Matching metadata JSON: ${jsonEncode(context)}
Reply briefly with what was found and what to try next if results are weak.
''',
                },
              ],
            },
          ],
        },
      );
      return _extractText(response.data).trim();
    } catch (_) {
      return _fallbackReply(question, localMatches, totalIndexed);
    }
  }

  static String _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final content = candidates.first['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) return '';
    return parts
        .map((part) => part is Map ? part['text']?.toString() ?? '' : '')
        .join('\n');
  }

  static AnalysisResult _parseAnalysis(String rawText) {
    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end <= start) {
      return AnalysisResult(
        description: cleaned.isEmpty ? 'Screenshot analyzed.' : cleaned,
        tags: const ['screenshot'],
      );
    }

    final decoded = jsonDecode(cleaned.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) {
      return const AnalysisResult(
        description: 'Screenshot analyzed.',
        tags: ['screenshot'],
      );
    }
    final tags = decoded['tags'];
    return AnalysisResult(
      description:
          decoded['description']?.toString().trim() ?? 'Screenshot analyzed.',
      tags: tags is List
          ? tags.map((tag) => tag.toString().toLowerCase()).toList()
          : const ['screenshot'],
    );
  }

  static String _fallbackReply(
    String question,
    List<ScreenshotItem> localMatches,
    int totalIndexed,
  ) {
    if (localMatches.isEmpty) {
      return 'No local matches for "$question" yet. $totalIndexed screenshots are indexed; add your Gemini API key to unlock richer descriptions and better tags.';
    }
    return 'Found ${localMatches.length} local match${localMatches.length == 1 ? '' : 'es'} for "$question". Add your Gemini API key for smarter natural-language replies.';
  }
}

class GeminiNotConfiguredException implements Exception {
  const GeminiNotConfiguredException();
}
