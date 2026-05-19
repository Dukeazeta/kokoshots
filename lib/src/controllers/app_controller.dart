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

final databaseServiceProvider = Provider((ref) => DatabaseService());
final mediaServiceProvider = Provider((ref) => MediaService());
final geminiServiceProvider = Provider((ref) => GeminiService());

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(
    database: ref.watch(databaseServiceProvider),
    media: ref.watch(mediaServiceProvider),
    gemini: ref.watch(geminiServiceProvider),
  )..initialize();
});

class AppController extends ChangeNotifier {
  AppController({
    required DatabaseService database,
    required MediaService media,
    required GeminiService gemini,
    List<ScreenshotItem> initialScreenshots = const [],
    List<ChatMessage> initialMessages = const [],
    String initialStatusText = 'Ready',
    bool isLoading = true,
  }) : _database = database,
       _media = media,
       _gemini = gemini,
       _screenshots = initialScreenshots,
       _messages = initialMessages,
       _statusText = initialStatusText,
       _isLoading = isLoading;

  final DatabaseService _database;
  final MediaService _media;
  final GeminiService _gemini;
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
  PermissionState? get permission => _permission;
  bool get geminiConfigured => _gemini.isConfigured;

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
    _screenshots = await _database.loadScreenshots();
    _messages = await _database.loadChatMessages();
    _isLoading = false;
    _statusText = _screenshots.isEmpty
        ? 'No screenshots indexed yet'
        : '${_screenshots.length} screenshots indexed';
    _startPolling();
    notifyListeners();
    if (_screenshots.isEmpty) {
      unawaited(requestPermissionAndScan());
    }
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
    _statusText = 'Scanning gallery';
    notifyListeners();

    try {
      final assets = await _media.discoverScreenshots();
      _discoveredThisRun = assets.length;
      _statusText = 'Found ${assets.length} screenshot candidates';
      notifyListeners();

      for (final asset in assets) {
        final existing = await _database.screenshotByAssetId(asset.id);
        if (existing != null && existing.isProcessed) continue;

        final filePath = await _media.bestFilePath(asset);
        var item =
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

        if (_gemini.isConfigured) {
          item = await _analyze(asset, item);
        }
        _processedThisRun++;
        _statusText = 'Indexed $_processedThisRun of $_discoveredThisRun';
        notifyListeners();
      }

      _screenshots = await _database.loadScreenshots();
      _statusText = _gemini.isConfigured
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
        await scanScreenshots();
      }
    });
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
    _discoveredThisRun = pendingCount;
    notifyListeners();

    try {
      final pending = _screenshots.where((item) => !item.isProcessed).toList();
      for (final item in pending) {
        final asset = await AssetEntity.fromId(item.assetId);
        if (asset == null) continue;
        await _analyze(asset, item);
        _processedThisRun++;
        _statusText = 'Analyzed $_processedThisRun of $_discoveredThisRun';
        notifyListeners();
      }
      _screenshots = await _database.loadScreenshots();
      _statusText = 'AI analysis complete';
    } finally {
      _isScanning = false;
      notifyListeners();
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
    final reply = await _gemini.buildSearchReply(
      question: trimmed,
      localMatches: matches,
      totalIndexed: _screenshots.length,
    );
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

  Future<void> clearChat() async {
    await _database.clearChatMessages();
    _messages = const [];
    notifyListeners();
  }

  Future<ScreenshotItem> _analyze(
    AssetEntity asset,
    ScreenshotItem item,
  ) async {
    try {
      final bytes = await _media.analysisBytes(asset);
      if (bytes == null) {
        throw Exception('Could not read image bytes');
      }
      final analysis = await _gemini.analyzeScreenshot(bytes);
      final updated = item.copyWith(
        description: analysis.description,
        tags: analysis.tags,
        dateIndexed: DateTime.now(),
        isProcessed: true,
        status: 'processed',
        errorMessage: null,
      );
      await _database.upsertScreenshot(updated);
      _mergeScreenshot(updated);
      return updated;
    } on GeminiNotConfiguredException {
      final updated = item.copyWith(
        description: 'Waiting for Gemini API key',
        tags: const ['needs-key', 'screenshot'],
        status: 'needs_api_key',
        isProcessed: false,
      );
      await _database.upsertScreenshot(updated);
      _mergeScreenshot(updated);
      return updated;
    } catch (error) {
      final updated = item.copyWith(
        status: 'error',
        errorMessage: error.toString(),
        isProcessed: false,
      );
      await _database.upsertScreenshot(updated);
      _mergeScreenshot(updated);
      return updated;
    }
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
