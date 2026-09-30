/// Model representing the response from `/api/app/version-check`.
class AppVersionModel {
  final String latestVersion;
  final int latestBuild;
  final String minSupportedVersion;
  final bool isForceUpdate;
  final String platform;
  final String store;
  final String downloadUrl;
  final Map<String, String> downloadUrls;
  final String titleFa;
  final String titleEn;
  final String releaseNotesFa;
  final String releaseNotesEn;

  AppVersionModel({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedVersion,
    required this.isForceUpdate,
    required this.platform,
    required this.store,
    required this.downloadUrl,
    required this.downloadUrls,
    required this.titleFa,
    required this.titleEn,
    required this.releaseNotesFa,
    required this.releaseNotesEn,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    final urlsRaw = json['download_urls'];
    final Map<String, String> urlsMap = {};
    if (urlsRaw is Map) {
      urlsRaw.forEach((k, v) {
        if (v != null) urlsMap[k.toString()] = v.toString();
      });
    }

    return AppVersionModel(
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      latestBuild: int.tryParse(json['latest_build']?.toString() ?? '1') ?? 1,
      minSupportedVersion: json['min_supported_version']?.toString() ?? '1.0.0',
      isForceUpdate: json['is_force_update'] == true ||
          json['is_force_update'] == 1 ||
          json['is_force_update']?.toString().toLowerCase() == 'true',
      platform: json['platform']?.toString() ?? 'android',
      store: json['store']?.toString() ?? 'bazaar',
      downloadUrl: json['download_url']?.toString() ?? '',
      downloadUrls: urlsMap,
      titleFa: json['title_fa']?.toString() ?? 'نسخه جدید اسنیک‌آرا آماده است! 🚀',
      titleEn: json['title_en']?.toString() ?? 'New SnakeAra Update Available! 🚀',
      releaseNotesFa: json['release_notes_fa']?.toString() ?? '',
      releaseNotesEn: json['release_notes_en']?.toString() ?? '',
    );
  }

  /// Returns the localized title according to language code ('fa' vs 'en')
  String getTitle(String langCode) => langCode == 'fa' ? titleFa : titleEn;

  /// Returns the localized release notes according to language code ('fa' vs 'en')
  String getReleaseNotes(String langCode) =>
      langCode == 'fa' ? releaseNotesFa : releaseNotesEn;
}

/// The outcome of the version evaluation
enum UpdateActionType {
  none,
  optional,
  force,
}

/// Result object holding decision state and version payload
class UpdateEvaluationResult {
  final UpdateActionType action;
  final AppVersionModel? versionModel;
  final String currentVersion;
  final int currentBuild;

  const UpdateEvaluationResult({
    required this.action,
    this.versionModel,
    required this.currentVersion,
    required this.currentBuild,
  });

  bool get isForce => action == UpdateActionType.force;
  bool get isOptional => action == UpdateActionType.optional;
  bool get hasUpdate => isForce || isOptional;
}
