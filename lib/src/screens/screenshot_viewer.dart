import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/screenshot_item.dart';
import '../theme/app_theme.dart';

/// Full-screen screenshot viewer with swipe navigation, pinch-to-zoom,
/// and a toggleable metadata overlay.
class ScreenshotViewer extends StatefulWidget {
  const ScreenshotViewer({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<ScreenshotItem> items;
  final int initialIndex;

  @override
  State<ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<ScreenshotViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ScreenshotItem get _currentItem => widget.items[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Image pages ──
          GestureDetector(
            onTap: () => setState(() => _overlayVisible = !_overlayVisible),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return _ZoomableImage(
                  item: widget.items[index],
                  isHero: index == widget.initialIndex,
                );
              },
            ),
          ),

          // ── Top overlay ──
          AnimatedOpacity(
            opacity: _overlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _TopOverlay(
              item: _currentItem,
              position: '${_currentIndex + 1} / ${widget.items.length}',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          // ── Bottom overlay ──
          AnimatedOpacity(
            opacity: _overlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _BottomOverlay(item: _currentItem),
          ),
        ],
      ),
    );
  }
}

// ── Zoomable image page ──

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.item, required this.isHero});

  final ScreenshotItem item;
  final bool isHero;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  Uint8List? _fullBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.item.assetId);
    // Load a high-res version for the viewer
    final bytes =
        await asset?.thumbnailDataWithSize(
          const ThumbnailSize(1080, 1920),
          quality: 92,
        ) ??
        await _fileBytes();
    if (mounted) {
      setState(() {
        _fullBytes = bytes;
        _loading = false;
      });
    }
  }

  Future<Uint8List?> _fileBytes() async {
    final path = widget.item.filePath;
    if (path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: KokoColors.ink,
          ),
        ),
      );
    }

    if (_fullBytes == null) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: KokoColors.mute,
          size: 48,
        ),
      );
    }

    final imageWidget = InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Center(child: Image.memory(_fullBytes!, fit: BoxFit.contain)),
    );

    if (widget.isHero) {
      return Hero(tag: 'screenshot_${widget.item.assetId}', child: imageWidget);
    }
    return imageWidget;
  }
}

// ── Top overlay ──

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.item,
    required this.position,
    required this.onBack,
  });

  final ScreenshotItem item;
  final String position;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          KokoSpacing.sm,
          topPadding + KokoSpacing.sm,
          KokoSpacing.xl,
          KokoSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: KokoColors.ink,
              iconSize: 22,
            ),
            const Spacer(),
            // Position counter
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KokoSpacing.md,
                vertical: KokoSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: KokoColors.canvasSoft.withValues(alpha: 0.8),
                borderRadius: KokoRadius.smBorder,
              ),
              child: Text(
                position,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KokoColors.ink,
                ),
              ),
            ),
            const SizedBox(width: KokoSpacing.sm),
            // Status pill
            _ViewerStatusPill(status: item.status),
          ],
        ),
      ),
    );
  }
}

// ── Bottom overlay ──

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.item});

  final ScreenshotItem item;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          KokoSpacing.xl,
          KokoSpacing.xxl,
          KokoSpacing.xl,
          bottomPadding + KokoSpacing.xl,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Description
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.sm),
            // Date
            Text(
              DateFormat.yMMMd().add_jm().format(item.dateTaken),
              style: const TextStyle(fontSize: 13, color: KokoColors.body),
            ),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: KokoSpacing.lg),
              // Tags
              Wrap(
                spacing: KokoSpacing.sm,
                runSpacing: KokoSpacing.sm,
                children: item.tags.take(6).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KokoSpacing.md,
                      vertical: KokoSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: KokoColors.canvasSoft.withValues(alpha: 0.7),
                      borderRadius: KokoRadius.smBorder,
                      border: Border.all(
                        color: KokoColors.hairline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KokoColors.bodyStrong,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status pill ──

class _ViewerStatusPill extends StatelessWidget {
  const _ViewerStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final processed = status == 'processed';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KokoSpacing.sm,
        vertical: KokoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: processed
            ? KokoColors.ink.withValues(alpha: 0.9)
            : KokoColors.mute.withValues(alpha: 0.7),
        borderRadius: KokoRadius.smBorder,
      ),
      child: Text(
        processed ? 'AI' : status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: processed ? KokoColors.onPrimary : KokoColors.ink,
        ),
      ),
    );
  }
}
