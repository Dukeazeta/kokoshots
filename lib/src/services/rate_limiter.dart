import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// The type of API request, used to track separate daily budgets.
enum ApiRequestType { analysis, chat }

/// Enforces Gemini API rate limits locally:
///
/// - **RPM**: minimum gap between requests (default 12 s → ≤ 5 RPM).
/// - **RPD**: daily request counter per [ApiRequestType], persisted across sessions.
/// - **429 backoff**: exponential pause when the API returns 429.
class RateLimiter {
  RateLimiter({
    this.maxAnalysisPerDay = 15,
    this.maxChatPerDay = 5,
    this.minRequestGap = const Duration(seconds: 12),
  });

  // ── Configuration ──

  final int maxAnalysisPerDay;
  final int maxChatPerDay;
  final Duration minRequestGap;

  // ── Internal state ──

  DateTime? _lastRequestTime;
  int _backoffMultiplier = 0;

  // Cached daily counters
  int _analysisCount = 0;
  int _chatCount = 0;
  String _counterDate = ''; // ISO date string (yyyy-MM-dd)

  // SharedPreferences keys
  static const _keyDate = 'rl_date';
  static const _keyAnalysis = 'rl_analysis';
  static const _keyChat = 'rl_chat';

  // ── Getters for UI ──

  int get remainingAnalysisBudget =>
      (maxAnalysisPerDay - _analysisCount).clamp(0, maxAnalysisPerDay);

  int get remainingChatBudget =>
      (maxChatPerDay - _chatCount).clamp(0, maxChatPerDay);

  bool get dailyAnalysisLimitReached => remainingAnalysisBudget <= 0;

  bool get dailyChatLimitReached => remainingChatBudget <= 0;

  int get analysisRequestsUsedToday => _analysisCount;
  int get chatRequestsUsedToday => _chatCount;

  /// Estimated time when counters reset (next midnight local time).
  DateTime get nextResetTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  // ── Initialisation ──

  /// Load persisted counters. Call once at app startup.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate) ?? '';
    final today = _todayString();

    if (savedDate == today) {
      _analysisCount = prefs.getInt(_keyAnalysis) ?? 0;
      _chatCount = prefs.getInt(_keyChat) ?? 0;
    } else {
      // New day → reset
      _analysisCount = 0;
      _chatCount = 0;
    }
    _counterDate = today;
  }

  // ── Budget checks ──

  /// Returns `true` if there is remaining daily budget for [type].
  bool canMakeRequest(ApiRequestType type) {
    _resetIfNewDay();
    return switch (type) {
      ApiRequestType.analysis => _analysisCount < maxAnalysisPerDay,
      ApiRequestType.chat => _chatCount < maxChatPerDay,
    };
  }

  // ── Throttle ──

  /// Waits until it is safe to fire the next request (RPM + backoff).
  /// Call this **before** every API request.
  Future<void> waitForNextSlot() async {
    // Exponential backoff from previous 429
    if (_backoffMultiplier > 0) {
      final backoffSeconds = 30 * pow(2, _backoffMultiplier - 1);
      final capped = min(backoffSeconds.toInt(), 300); // max 5 min
      await Future<void>.delayed(Duration(seconds: capped));
    }

    // RPM gap
    final last = _lastRequestTime;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minRequestGap) {
        await Future<void>.delayed(minRequestGap - elapsed);
      }
    }
  }

  // ── Recording ──

  /// Record that a successful request was made. Updates counters + timestamp.
  Future<void> recordRequest(ApiRequestType type) async {
    _resetIfNewDay();
    _lastRequestTime = DateTime.now();
    _backoffMultiplier = 0; // success resets backoff

    switch (type) {
      case ApiRequestType.analysis:
        _analysisCount++;
      case ApiRequestType.chat:
        _chatCount++;
    }
    await _persist();
  }

  /// Record a 429 response. Increases the exponential backoff multiplier.
  void record429() {
    _backoffMultiplier = min(_backoffMultiplier + 1, 5);
  }

  // ── Internals ──

  void _resetIfNewDay() {
    final today = _todayString();
    if (_counterDate != today) {
      _analysisCount = 0;
      _chatCount = 0;
      _counterDate = today;
      _backoffMultiplier = 0;
      _persist(); // fire-and-forget
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDate, _counterDate);
    await prefs.setInt(_keyAnalysis, _analysisCount);
    await prefs.setInt(_keyChat, _chatCount);
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
