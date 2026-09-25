import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import '../models/cosmetics_models.dart';

/// Service responsible for parallel downloading, caching, and pre-warming of 8 mode theme backgrounds.
class ThemeCacheService extends GetxService {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// In-memory cache of resolved local file paths: pattern 'theme_{themeKey}_{modeKey}' -> filePath
  final RxMap<String, String> resolvedFilePaths = <String, String>{}.obs;
  final RxBool isDownloadingTheme = false.obs;

  static const List<String> allModes = [
    'classic',
    'adventure',
    'crab',
    'infection',
    'laser',
    'level',
    'meltdown',
    'memory',
  ];

  static String buildCacheKey(String themeKey, String modeKey) {
    return 'theme_${themeKey.trim().toLowerCase()}_${modeKey.trim().toLowerCase()}';
  }

  /// Returns synchronously resolved file path if cached and present on disk
  String? getCachedThemeFilePath(String themeKey, String modeKey) {
    final key = buildCacheKey(themeKey, modeKey);
    final mem = resolvedFilePaths[key];
    if (mem != null && mem.isNotEmpty && File(mem).existsSync()) {
      return mem;
    }
    return null;
  }

  /// Check if all 8 mode backgrounds for a theme exist in disk cache
  Future<bool> isThemeFullyCached(CosmeticTheme theme) async {
    if (theme.modes.isEmpty) return false;
    for (final mode in allModes) {
      final key = buildCacheKey(theme.themeKey, mode);
      final fileInfo = await _cacheManager.getFileFromCache(key);
      if (fileInfo == null || !fileInfo.file.existsSync()) {
        return false;
      }
      resolvedFilePaths[key] = fileInfo.file.path;
    }
    return true;
  }

  /// Downloads all 8 mode variants in parallel using Future.wait
  Future<void> preWarmTheme(CosmeticTheme theme, {bool showLoading = false}) async {
    if (theme.modes.isEmpty) return;

    if (showLoading) {
      isDownloadingTheme.value = true;
    }

    try {
      final List<Future<void>> downloadTasks = [];

      for (final mode in allModes) {
        final url = theme.getModeUrl(mode);
        if (url == null || url.isEmpty) continue;

        final key = buildCacheKey(theme.themeKey, mode);

        // Check if already in cache before initiating download
        downloadTasks.add(() async {
          try {
            final fileInfo = await _cacheManager.getFileFromCache(key);
            if (fileInfo != null && fileInfo.file.existsSync()) {
              resolvedFilePaths[key] = fileInfo.file.path;
              return;
            }

            final downloadedFile = await _cacheManager.getSingleFile(url, key: key);
            if (downloadedFile.existsSync()) {
              resolvedFilePaths[key] = downloadedFile.path;
            }
          } catch (e) {
            debugPrint('[ThemeCacheService] Error downloading mode $mode for theme ${theme.themeKey}: $e');
          }
        }());
      }

      if (downloadTasks.isNotEmpty) {
        await Future.wait(downloadTasks);
      }
    } catch (e) {
      debugPrint('[ThemeCacheService] Failed pre-warming theme ${theme.themeKey}: $e');
    } finally {
      if (showLoading) {
        isDownloadingTheme.value = false;
      }
    }
  }

  /// Resolves the cached File for a specific theme and game mode
  Future<File?> getCachedFile(String themeKey, String modeKey) async {
    final key = buildCacheKey(themeKey, modeKey);
    final fileInfo = await _cacheManager.getFileFromCache(key);
    if (fileInfo != null && fileInfo.file.existsSync()) {
      resolvedFilePaths[key] = fileInfo.file.path;
      return fileInfo.file;
    }
    return null;
  }
}
