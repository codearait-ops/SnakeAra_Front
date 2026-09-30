import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_checker/store_checker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/app_update/models/app_version_model.dart';
import 'api_service.dart';

/// Central Service for checking app updates, comparing versions,
/// throttling optional prompts, and resolving appropriate store URLs.
class AppUpdateService extends GetxService {
  static const String _kLastDismissKey = 'app_update_last_dismissed_ms';
  static const int _kOneDayMs = 24 * 60 * 60 * 1000;

  /// Compares two semantic version strings numerically (e.g. "1.10.0" > "1.9.0").
  /// Returns:
  /// - negative if v1 < v2
  /// - 0 if v1 == v2
  /// - positive if v1 > v2
  static int versionCompare(String v1, String v2) {
    try {
      // Clean up pre-release or build suffixes (e.g., '1.0.0+1' -> '1.0.0')
      final cleanV1 = v1.split('+').first.split('-').first.trim();
      final cleanV2 = v2.split('+').first.split('-').first.trim();

      final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
      while (parts1.length < maxLen) parts1.add(0);
      while (parts2.length < maxLen) parts2.add(0);

      for (int i = 0; i < maxLen; i++) {
        if (parts1[i] < parts2[i]) return -1;
        if (parts1[i] > parts2[i]) return 1;
      }
      return 0;
    } catch (e) {
      debugPrint('[AppUpdateService] versionCompare error: $e');
      return 0;
    }
  }

  /// Checks server for newer version and determines whether an update is required or optional.
  /// Strictly non-blocking: catches timeouts & errors gracefully.
  Future<UpdateEvaluationResult> checkForUpdate({bool ignoreThrottling = false}) async {
    String currentVersion = '1.0.0';
    int currentBuild = 1;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to read package info: $e');
    }

    try {
      final platformStr = _detectPlatform();
      final storeStr = await _detectStore();

      // Retrieve Dio instance from ApiService if registered, or create a standalone one
      Dio dio;
      if (Get.isRegistered<ApiService>()) {
        dio = Get.find<ApiService>().dio;
      } else {
        dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));
      }

      final queryParams = <String, dynamic>{
        'platform': platformStr,
        if (storeStr != null && storeStr.isNotEmpty) 'store': storeStr,
      };

      debugPrint('[AppUpdateService] Checking version with params: $queryParams');

      final response = await dio.get(
        '/app/version-check',
        queryParameters: queryParams,
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final data = response.data;
      if (data == null || data is! Map) {
        return UpdateEvaluationResult(
          action: UpdateActionType.none,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }

      final rawData = data['data'] is Map ? data['data'] as Map<String, dynamic> : data as Map<String, dynamic>;
      final versionModel = AppVersionModel.fromJson(rawData);

      // --- Decision Logic ---
      // 1. Check if installed version is below minimum supported version -> Force Update
      if (versionCompare(currentVersion, versionModel.minSupportedVersion) < 0) {
        debugPrint('[AppUpdateService] Force update required: installed $currentVersion < min ${versionModel.minSupportedVersion}');
        return UpdateEvaluationResult(
          action: UpdateActionType.force,
          versionModel: versionModel,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }

      // 2. Check if server flagged force update explicitly
      if (versionModel.isForceUpdate) {
        debugPrint('[AppUpdateService] Server explicitly flagged is_force_update = true');
        return UpdateEvaluationResult(
          action: UpdateActionType.force,
          versionModel: versionModel,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }

      // 3. Check for optional update (newer version or higher build number)
      final hasNewerVersion = versionCompare(currentVersion, versionModel.latestVersion) < 0;
      final hasNewerBuild = currentBuild < versionModel.latestBuild;

      if (hasNewerVersion || hasNewerBuild) {
        if (!ignoreThrottling && await _wasDismissedWithin24Hours()) {
          debugPrint('[AppUpdateService] Optional update available ($currentVersion -> ${versionModel.latestVersion}), but dismissed today');
          return UpdateEvaluationResult(
            action: UpdateActionType.none,
            versionModel: versionModel,
            currentVersion: currentVersion,
            currentBuild: currentBuild,
          );
        }

        debugPrint('[AppUpdateService] Optional update available: $currentVersion -> ${versionModel.latestVersion}');
        return UpdateEvaluationResult(
          action: UpdateActionType.optional,
          versionModel: versionModel,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }

      // No update needed
      return UpdateEvaluationResult(
        action: UpdateActionType.none,
        versionModel: versionModel,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Version check silently failed/timeout: $e');
      return UpdateEvaluationResult(
        action: UpdateActionType.none,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
    }
  }

  /// Records that the user chose "Later" on an optional update, silencing reminders for 24h.
  Future<void> recordDismissal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastDismissKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to record dismissal: $e');
    }
  }

  /// Checks whether user dismissed optional update in the last 24 hours.
  Future<bool> _wasDismissedWithin24Hours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastDismissKey);
      if (lastMs == null) return false;

      final diff = DateTime.now().millisecondsSinceEpoch - lastMs;
      return diff < _kOneDayMs;
    } catch (e) {
      return false;
    }
  }

  /// Resolves the best store/download URL and launches it externally.
  Future<bool> launchUpdateUrl(AppVersionModel model) async {
    try {
      String targetUrl = model.downloadUrl;

      if (Platform.isAndroid) {
        final store = await _detectStore();
        if (store == 'bazaar' && model.downloadUrls.containsKey('android_bazaar')) {
          targetUrl = model.downloadUrls['android_bazaar']!;
        } else if (store == 'myket' && model.downloadUrls.containsKey('android_myket')) {
          targetUrl = model.downloadUrls['android_myket']!;
        } else if (store == 'play' && model.downloadUrls.containsKey('android_play')) {
          targetUrl = model.downloadUrls['android_play']!;
        } else if (model.downloadUrls.containsKey('android_direct') &&
            model.downloadUrls['android_direct']!.isNotEmpty) {
          targetUrl = model.downloadUrls['android_direct']!;
        }
      } else if (Platform.isIOS) {
        if (model.downloadUrls.containsKey('ios')) {
          targetUrl = model.downloadUrls['ios']!;
        }
      } else if (Platform.isWindows) {
        if (model.downloadUrls.containsKey('windows')) {
          targetUrl = model.downloadUrls['windows']!;
        }
      }

      if (targetUrl.isEmpty) {
        targetUrl = model.downloadUrl;
      }

      if (targetUrl.isEmpty) {
        debugPrint('[AppUpdateService] No valid download URL found');
        return false;
      }

      final uri = Uri.parse(targetUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to launch update URL: $e');
      return false;
    }
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'other';
  }

  Future<String?> _detectStore() async {
    if (!Platform.isAndroid) return null;
    try {
      final source = await StoreChecker.getSource;
      switch (source) {
        case Source.IS_INSTALLED_FROM_PLAY_STORE:
          return 'play';
        case Source.IS_INSTALLED_FROM_LOCAL_SOURCE:
        case Source.IS_INSTALLED_FROM_OTHER_SOURCE:
          return 'bazaar'; // Fallback / local default
        default:
          return 'bazaar';
      }
    } catch (_) {
      return 'bazaar';
    }
  }
}
