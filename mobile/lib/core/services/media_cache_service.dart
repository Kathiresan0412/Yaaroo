import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Handles local caching of chat media (photos, voice notes, GIFs).
/// Files are stored in the device's cache directory and managed automatically.
class MediaCacheService {
  MediaCacheService._internal();
  static final MediaCacheService instance = MediaCacheService._internal();

  static const _cacheKey = 'yaaro_chat_media';

  final CacheManager _manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  /// Returns the local file for a URL. Downloads if not cached.
  Future<File> getFile(String url) async {
    final fileInfo = await _manager.getSingleFile(url);
    return fileInfo;
  }

  /// Check if a URL is already cached locally.
  Future<File?> getCachedFile(String url) async {
    final info = await _manager.getFileFromCache(url);
    return info?.file;
  }

  /// Pre-download a media URL in the background.
  Future<void> prefetch(String url) async {
    try {
      await _manager.getSingleFile(url);
    } catch (_) {
      // Silently fail — media will be fetched on demand.
    }
  }

  /// Pre-download multiple URLs (e.g. when loading a conversation).
  Future<void> prefetchAll(List<String> urls) async {
    await Future.wait(
      urls.map((url) => prefetch(url)),
      eagerError: false,
    );
  }

  /// Remove a specific file from cache.
  Future<void> removeFile(String url) async {
    await _manager.removeFile(url);
  }

  /// Clear all cached media.
  Future<void> clearAll() async {
    await _manager.emptyCache();
  }
}
