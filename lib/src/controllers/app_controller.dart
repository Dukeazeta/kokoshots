import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/screenshot_item.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/media_service.dart';
import '../services/rate_limiter.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());
final mediaServiceProvider = Provider((ref) => MediaService());
final geminiServiceProvider = Provider((ref) => GeminiService());
final rateLimiterProvider = Provider((ref) => RateLimiter());

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(
    database: ref.watch(databaseServiceProvider),
    media: ref.watch(mediaServiceProvider),
    gemini: ref.watch(geminiServiceProvider),
    rateLimiter: ref.watch(rateLimiterProvider),
  )..initialize();
});

/// Maximum screenshots per single Gemini API call.
const _batchSize = 25;

class AppController extends ChangeNotifier {
  AppController({
    required DatabaseService database,
    required MediaService media,
    required GeminiService gemini,
    required RateLimiter rateLimiter,
    List<ScreenshotItem> initialScreenshots = const [],
    List<ChatMessage> initialMessages = const [],
    String initialStatusText = 'Ready',
    bool isLoading = true,
  })  : _database = database,
        _media = media,
        _gemini = gemini,
        _rateLimiter = rateLimiter,
        _screenshots = initialScreenshots,
        _messages = initialMessages,
        _statusText = initialStatusText,
        _isLoading = isLoading;

  final DatabaseService _database;
  final MediaService _media;
  final GeminiService _gemini;
  final RateLimiter _rateLimiter;
  final _uuid = const Uuid();
  Timer? _pollTimer;

  List<ScreenshotItem> _screenshots;
  List<ChatMessage> _messages;
  String _query = '';
  String _statusText;
  bool _isLoading;
  bool _isScanning = false;
  bool _isThinking = false;
  int _processedThisRun = 0;
  int _discoveredThisRun = 0;
  bool _dailyLimitReached = false;
  PermissionState? _permission;

  List<ScreenshotItem> get screenshots => _screenshots;
  List<ChatMessage> get messages => _messages;
  String get query => _query;
  String get statusText => _statusText;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  bool get isThinking => _isThinking;
  int get processedThisRun => _processedThisRun;
  int get discoveredThisRun => _discoveredThisRun;
  bool get dailyLimitReached => _dailyLimitReached;
  PermissionState? get permission => _permission;
  bool get geminiConfigured => _gemini.isConfigured;
  int get remainingAnalysisBudget => _rateLimiter.remainingAnalysisBudget;
  int get remainingChatBudget => _rateLimiter.remainingChatBudget;

  List<ScreenshotItem> get filteredScreenshots {
    return _screenshots.where((item) => item.matches(_query)).toList();
  }

  int get processedCount =>
      _screenshots.where((item) => item.isProcessed).length;
  int get pendingCount => _screenshots.length - processedCount;
  List<MapEntry<String, int>> get categories {
    final counts = <String, int>{};
    for (final item in _screenshots) {
      for (final tag in item.tags) {
        if (tag == 'queued' || tag == 'needs-key') continue;
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
    return entries.take(12).toList(growable: false);
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    // Load persisted API key and rate limiter state
    await _gemini.loadApiKey();
    await _rateLimiter.initialize();
    _screenshots = await _database.loadScreenshots();
    _messages = await _database.loadChatMessages();
    _isLoading = false;
    _dailyLimitReached = _rateLimiter.dailyAnalysisLimitReached;
    _statusText = _screenshots.isEmpty
        ? 'No screenshots indexed yet'
        : '${_screenshots.length} screenshots indexed';
    _startPolling();
    notifyListeners();
    if (_screenshots.isEmpty) {
      unawaited(requestPermissionAndScan());
    } else {
      // Auto-resume pending analysis if budget is available
      unawaited(_resumeIfNeeded());
    }
  }

  /// Save a Gemini API key at runtime.
  Future<void> setApiKey(String key) async {
    await _gemini.setApiKey(key);
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> requestPermissionAndScan() async {
    _permission = await _media.requestPermission();
    if (_permission?.isAuth != true && _permission?.hasAccess != true) {
      _statusText = 'Photo access is required to scan screenshots';
      notifyListeners();
      return;
    }
    await scanScreenshots();
  }

  Future<void> scanScreenshots() async {
    if (_isScanning) return;
    _isScanning = true;
    _processedThisRun = 0;
    _discoveredThisRun = 0;
    _dailyLimitReached = false;
    _statusText = 'Scanning gallery';
    notifyListeners();

    try {
      final assets = await _media.discoverScreenshots();
      _discoveredThisRun = assets.length;
      _statusText = 'Found ${assets.length} screenshot candidates';
      notifyListeners();

      // ── Phase 1: Discover & register all screenshots ──
      final unprocessed = <(AssetEntity asset, ScreenshotItem item)>[];

      for (final asset in assets) {
        final existing = await _database.screenshotByAssetId(asset.id);
        if (existing != null && existing.isProcessed) continue;

        final filePath = await _media.bestFilePath(asset);
        final item =
            existing ??
            ScreenshotItem(
              id: _uuid.v4(),
              assetId: asset.id,
              filePath: filePath,
              thumbnailPath: asset.id,
              description: _gemini.isConfigured
                  ? 'Queued for AI analysis'
                  : 'Waiting for Gemini API key',
              tags: _gemini.isConfigured
                  ? const ['queued']
                  : const ['needs-key', 'screenshot'],
              dateTaken: asset.createDateTime,
              dateIndexed: DateTime.now(),
              isProcessed: false,
              status: _gemini.isConfigured ? 'queued' : 'needs_api_key',
            );

        await _database.upsertScreenshot(item);
        _mergeScreenshot(item);
        unprocessed.add((asset, item));
      }

      // Sort newest-first so recent screenshots get analyzed first
      unprocessed.sort((a, b) => b.$2.dateTaken.compareTo(a.$2.dateTaken));

      // ── Phase 2: Batch-analyze with rate limiting ──
      if (_gemini.isConfigured && unprocessed.isNotEmpty) {
        await _batchAnalyze(unprocessed);
      }

      _screenshots = await _database.loadScreenshots();
      _statusText = _dailyLimitReached
          ? 'Daily limit reached — $processedCount analyzed, $pendingCount remaining. Resumes tomorrow.'
          : _gemini.isConfigured
              ? 'Index updated'
              : 'Index ready. Add Gemini API key for AI descriptions.';
    } catch (error) {
      _statusText = 'Scan failed: $error';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isScanning) return;
      if (_permission?.isAuth == true || _permission?.hasAccess == true) {
        // Check if daily budget has reset (new day)
        if (_rateLimiter.canMakeRequest(ApiRequestType.analysis)) {
          _dailyLimitReached = false;
        }
        await _resumeIfNeeded();
      }
    });
  }

  /// Checks for unprocessed screenshots and resumes if budget allows.
  Future<void> _resumeIfNeeded() async {
    if (!_gemini.isConfigured) return;
    if (_isScanning) return;
    if (!_rateLimiter.canMakeRequest(ApiRequestType.analysis)) return;

    final pending = _screenshots.where((item) => !item.isProcessed).toList();
    if (pending.isEmpty) return;

    // We have pending items and budget — trigger a scan
    await scanScreenshots();
  }

  Future<void> analyzePending() async {
    if (!_gemini.isConfigured) {
      _statusText = 'Add GEMINI_API_KEY to analyze screenshots';
      notifyListeners();
      return;
    }
    if (_isScanning) return;
    _isScanning = true;
    _processedThisRun = 0;
    _dailyLimitReached = false;
    final pending = _screenshots.where((item) => !item.isProcessed).toList();
    // Sort newest-first
    pending.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
    _discoveredThisRun = pending.length;
    notifyListeners();

    try {
      // Build asset+item pairs
      final pairs = <(AssetEntity asset, ScreenshotItem item)>[];
      for (final item in pending) {
        final asset = await AssetEntity.fromId(item.assetId);
        if (asset == null) continue;
        pairs.add((asset, item));
      }

      await _batchAnalyze(pairs);

      _screenshots = await _database.loadScreenshots();
      _statusText = _dailyLimitReached
          ? 'Daily limit reached — $processedCount analyzed, $pendingCount remaining. Resumes tomorrow.'
          : 'AI analysis complete';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Core batched analysis loop with rate limiting and 429 handling.
  Future<void> _batchAnalyze(
    List<(AssetEntity asset, ScreenshotItem item)> pairs,
  ) async {
    final totalItems = pairs.length;

    for (var offset = 0; offset < totalItems; offset += _batchSize) {
      // ── Budget check ──
      if (!_rateLimiter.canMakeRequest(ApiRequestType.analysis)) {
        _dailyLimitReached = true;
        _statusText =
            'Daily API limit reached — will resume tomorrow. '
            '$_processedThisRun analyzed this session.';
        notifyListeners();
        return;
      }

      final end = (offset + _batchSize).clamp(0, totalItems);
      final batch = pairs.sublist(offset, end);
      final batchNum = (offset ~/ _batchSize) + 1;
      final totalBatches = (totalItems / _batchSize).ceil();

      _statusText = 'Analyzing batch $batchNum of $totalBatches '
          '($_processedThisRun/$totalItems done)';
      notifyListeners();

      // ── Load image bytes for the batch ──
      final images = <(String, Uint8List)>[];
      final batchItems = <ScreenshotItem>[];

      for (final (asset, item) in batch) {
        final bytes = await _media.analysisBytes(asset);
        if (bytes == null) {
          // Can't read image — mark as error, skip
          final updated = item.copyWith(
            status: 'error',
            errorMessage: 'Could not read image bytes',
            isProcessed: false,
          );
          await _database.upsertScreenshot(updated);
          _mergeScreenshot(updated);
          continue;
        }
        images.add(('Image ${images.length}', bytes));
        batchItems.add(item);
      }

      if (images.isEmpty) continue;

      // ── Throttle ──
      await _rateLimiter.waitForNextSlot();

      // ── API call with retry ──
      var retries = 0;
      const maxRetries = 3;

      while (retries < maxRetries) {
        try {
          final results = await _gemini.analyzeBatch(images);

          // ── Success! Record and update all items ──
          await _rateLimiter.recordRequest(ApiRequestType.analysis);

          for (var i = 0; i < batchItems.length; i++) {
            final result = i < results.length ? results[i] : null;
            final updated = batchItems[i].copyWith(
              description: result?.description ?? 'Screenshot analyzed.',
              tags: result?.tags ?? const ['screenshot'],
              dateIndexed: DateTime.now(),
              isProcessed: true,
              status: 'processed',
              errorMessage: null,
            );
            await _database.upsertScreenshot(updated);
            _mergeScreenshot(updated);
          }

          _processedThisRun += batchItems.length;
          _statusText = 'Analyzed $_processedThisRun of $totalItems';
          notifyListeners();
          break; // Success — exit retry loop

        } on RateLimitException catch (e) {
          _rateLimiter.record429();
          retries++;
          if (retries >= maxRetries) {
            // Max retries exhausted — pause for the day
            _dailyLimitReached = true;
            _statusText =
                'Rate limited by API. $_processedThisRun analyzed. '
                'Will retry later.';
            notifyListeners();
            return;
          }
          // Wait and retry (waitForNextSlot includes backoff)
          _statusText = 'Rate limited — waiting to retry '
              '(attempt ${retries + 1}/$maxRetries)';
          notifyListeners();
          final waitSeconds = e.retryAfterSeconds ?? 30;
          await Future<void>.delayed(Duration(seconds: waitSeconds));
          await _rateLimiter.waitForNextSlot();

        } on GeminiNotConfiguredException {
          // API key removed mid-scan
          _statusText = 'API key missing — analysis paused';
          notifyListeners();
          return;

        } catch (error) {
          // Non-rate-limit error — mark batch items as error, continue
          for (final item in batchItems) {
            final updated = item.copyWith(
              status: 'error',
              errorMessage: error.toString(),
              isProcessed: false,
            );
            await _database.upsertScreenshot(updated);
            _mergeScreenshot(updated);
          }
          _processedThisRun += batchItems.length;
          break; // Move to next batch
        }
      }
    }
  }

  Future<void> ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _database.addChatMessage(userMessage);
    _messages = [..._messages, userMessage];
    _query = trimmed;
    _isThinking = true;
    notifyListeners();

    final matches = filteredScreenshots;
    final matchedIds = matches.take(8).map((m) => m.assetId).toList();

    String reply;

    // Check chat budget before making an API call
    if (_rateLimiter.canMakeRequest(ApiRequestType.chat)) {
      try {
        reply = await _gemini.buildSearchReply(
          question: trimmed,
          localMatches: matches,
          totalIndexed: _screenshots.length,
        );
        await _rateLimiter.recordRequest(ApiRequestType.chat);
      } on RateLimitException {
        _rateLimiter.record429();
        reply = _localOnlyReply(trimmed, matches);
      } catch (_) {
        reply = _localOnlyReply(trimmed, matches);
      }
    } else {
      reply = _localOnlyReply(trimmed, matches);
    }

    _isThinking = false;
    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      text: reply,
      createdAt: DateTime.now(),
      matchedAssetIds: matchedIds.isNotEmpty ? matchedIds : null,
    );
    await _database.addChatMessage(assistantMessage);
    _messages = [..._messages, assistantMessage];
    notifyListeners();
  }

  /// Fallback reply when AI chat budget is exhausted.
  String _localOnlyReply(String question, List<ScreenshotItem> matches) {
    final budgetNote = _rateLimiter.dailyChatLimitReached
        ? ' (AI replies paused until tomorrow — daily limit reached)'
        : '';
    if (matches.isEmpty) {
      return 'No matches found for "$question".$budgetNote';
    }
    return 'Found ${matches.length} match${matches.length == 1 ? '' : 'es'} '
        'for "$question".$budgetNote';
  }

  Future<void> clearChat() async {
    await _database.clearChatMessages();
    _messages = const [];
    notifyListeners();
  }

  void _mergeScreenshot(ScreenshotItem item) {
    final next = [..._screenshots];
    final index = next.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      next.add(item);
    } else {
      next[index] = item;
    }
    next.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
    _screenshots = next;
  }
}
