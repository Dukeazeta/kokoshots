import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/screenshot_item.dart';
import '../theme/app_theme.dart';

class ScreenshotTile extends StatelessWidget {
  const ScreenshotTile({super.key, required this.item});

  final ScreenshotItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<AssetEntity?>(
                future: AssetEntity.fromId(item.assetId),
                builder: (context, snapshot) {
                  final asset = snapshot.data;
                  if (asset == null) {
                    return Container(
                      color: KokoColors.cream,
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  }
                  return FutureBuilder(
                    future: asset.thumbnailDataWithSize(
                      const ThumbnailSize.square(420),
                      quality: 82,
                    ),
                    builder: (context, thumbSnapshot) {
                      final bytes = thumbSnapshot.data;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (bytes == null)
                            Container(
                              color: KokoColors.cream,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            Image.memory(bytes, fit: BoxFit.cover),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _StatusPill(status: item.status),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KokoColors.black,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: item.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: KokoColors.cream,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(tag, style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KokoColors.ivory,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat.yMMMd().add_jm().format(item.dateTaken),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: KokoColors.cream,
                          side: const BorderSide(color: KokoColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (item.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.errorMessage!,
                    style: const TextStyle(color: KokoColors.orange),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final processed = status == 'processed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: processed ? KokoColors.black : KokoColors.orange,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        processed ? 'AI' : status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: KokoColors.white,
          fontSize: 10,
          letterSpacing: .5,
        ),
      ),
    );
  }
}
