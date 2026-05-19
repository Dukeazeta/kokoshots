import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/screenshot_item.dart';
import '../screens/screenshot_viewer.dart';
import '../theme/app_theme.dart';
import 'shimmer_tile.dart';

/// Image-only grid tile with Hero animation. Tapping opens the full-screen
/// viewer. A shimmer placeholder shows while the thumbnail loads.
class ScreenshotTile extends StatelessWidget {
  const ScreenshotTile({
    super.key,
    required this.item,
    required this.items,
    required this.index,
  });

  final ScreenshotItem item;
  final List<ScreenshotItem> items;
  final int index;

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ScreenshotViewer(items: items, initialIndex: index);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: KokoRadius.mdBorder,
        child: _ThumbnailLoader(item: item),
      ),
    );
  }
}

/// Loads the asset thumbnail and shows a shimmer while loading.
class _ThumbnailLoader extends StatefulWidget {
  const _ThumbnailLoader({required this.item});

  final ScreenshotItem item;

  @override
  State<_ThumbnailLoader> createState() => _ThumbnailLoaderState();
}

class _ThumbnailLoaderState extends State<_ThumbnailLoader> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final asset = await AssetEntity.fromId(widget.item.assetId);
    if (asset == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize.square(420),
      quality: 82,
    );
    if (mounted) {
      setState(() {
        _bytes = bytes;
        if (bytes == null) _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: KokoColors.canvasSoft,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: KokoColors.mute,
            size: 24,
          ),
        ),
      );
    }

    if (_bytes == null) {
      return const ShimmerTile();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'screenshot_${widget.item.assetId}',
          child: Image.memory(_bytes!, fit: BoxFit.cover),
        ),
        // Status dot
        Positioned(
          left: 6,
          top: 6,
          child: _StatusDot(status: widget.item.status),
        ),
      ],
    );
  }
}

/// Small dot indicator — processed = ink, pending = muted.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final processed = status == 'processed';
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: processed ? KokoColors.ink : KokoColors.mute,
        shape: BoxShape.circle,
        border: Border.all(
          color: KokoColors.canvas.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );
  }
}
