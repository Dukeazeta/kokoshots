import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

class MediaService {
  Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend();
  }

  Future<List<AssetEntity>> discoverScreenshots({int limit = 500}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) return const [];

    final filter = FilterOptionGroup(
      imageOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: filter,
    );

    final screenshotAlbums = albums.where((album) {
      final name = album.name.toLowerCase();
      return name.contains('screenshot') || name.contains('screen shot');
    }).toList();

    final sourceAlbums = screenshotAlbums.isNotEmpty
        ? screenshotAlbums
        : albums;
    final assets = <AssetEntity>[];
    for (final album in sourceAlbums) {
      final page = await album.getAssetListPaged(page: 0, size: limit);
      for (final asset in page) {
        if (_looksLikeScreenshot(asset)) {
          assets.add(asset);
        }
      }
      if (assets.length >= limit) break;
    }

    final unique = <String, AssetEntity>{};
    for (final asset in assets) {
      unique[asset.id] = asset;
    }
    return unique.values.take(limit).toList(growable: false);
  }

  Future<String> bestFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path ?? asset.title ?? asset.id;
  }

  Future<Uint8List?> thumbnailBytes(AssetEntity asset) {
    return asset.thumbnailDataWithSize(
      const ThumbnailSize.square(320),
      quality: 82,
    );
  }

  Future<Uint8List?> analysisBytes(AssetEntity asset) async {
    final thumbnail = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1024, 1024),
      quality: 86,
    );
    if (thumbnail != null) return thumbnail;
    final file = await asset.file;
    if (file == null || !await file.exists()) return null;
    return File(file.path).readAsBytes();
  }

  bool _looksLikeScreenshot(AssetEntity asset) {
    final title = (asset.title ?? '').toLowerCase();
    final ratio = asset.width == 0 || asset.height == 0
        ? 0
        : asset.height / asset.width;
    return title.contains('screenshot') ||
        title.contains('screen shot') ||
        ratio > 1.55;
  }
}
