import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app/core/constants/app_constants.dart';

/// GetX service that wraps SharedPreferences for level progress,
/// classic mode records, and highscore storage.
class StorageService extends GetxService {
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Expose SharedPreferences getter.
  SharedPreferences get prefs => _prefs;

  // --- In-Memory (RAM only) Session State for Guest & Practice Play ---
  final RxMap<String, int> _sessionBestScores = <String, int>{}.obs;
  final RxInt sessionGamesPlayed = 0.obs;

  /// Get the highest score achieved in the current app session for a specific mode
  int getSessionBestScore(String mode) => _sessionBestScores[mode] ?? 0;

  /// Update the in-memory session record if the new score is higher.
  /// Returns true if a new in-memory session record was achieved.
  bool updateSessionBestScore(String mode, int score) {
    sessionGamesPlayed.value++;
    final currentBest = _sessionBestScores[mode] ?? 0;
    if (score > currentBest) {
      _sessionBestScores[mode] = score;
      return true;
    }
    return false;
  }

  String? _cachedUserToken;

  /// In-memory cached user token for synchronous access on boot
  String? get cachedUserToken => _cachedUserToken;

  /// Initialize SharedPreferences instance and preload cached secure storage items.
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      _cachedUserToken = await _secureStorage.read(key: kUserTokenKey);
    } catch (_) {
      _cachedUserToken = null;
    }
    return this;
  }

  /// Load the last unlocked level. Returns 1 if no progress saved.
  int getLastUnlockedLevel() {
    return _prefs.getInt(kLevelProgressKey) ?? 1;
  }

  /// Save the last unlocked level.
  Future<void> saveLastUnlockedLevel(int level) async {
    await _prefs.setInt(kLevelProgressKey, level);
  }

  /// Get play count for a specific game mode
  int getPlayCount(String modeId) {
    return _prefs.getInt('play_count_$modeId') ?? 0;
  }

  /// Increment play count for a specific game mode
  Future<int> incrementPlayCount(String modeId) async {
    final current = getPlayCount(modeId);
    final next = current + 1;
    await _prefs.setInt('play_count_$modeId', next);
    return next;
  }

  /// Check whether to show the mode intro dialog
  bool shouldShowModeIntro(String modeId) {
    return !(_prefs.getBool('hide_mode_intro_$modeId') ?? false);
  }

  /// Set whether to hide the mode intro dialog for a specific mode.
  Future<void> setHideModeIntro(String modeId, bool hide) async {
    await _prefs.setBool('hide_mode_intro_$modeId', hide);
  }

  /// Key for tracking game entry count for interstitial ads
  static const String _kGameEnterCounterKey = 'game_enter_ad_counter';

  /// Get current game entry count.
  int getGameEnterCount() => _prefs.getInt(_kGameEnterCounterKey) ?? 0;

  /// Increment game entry count and return the new value.
  Future<int> incrementGameEnterCount() async {
    final next = getGameEnterCount() + 1;
    await _prefs.setInt(_kGameEnterCounterKey, next);
    return next;
  }

  /// Reset game entry count back to 0.
  Future<void> resetGameEnterCount() async {
    await _prefs.setInt(_kGameEnterCounterKey, 0);
  }

  // --- Player XP & Level Persistence ---

  int getPlayerXp() => _prefs.getInt('player_xp') ?? 0;

  Future<void> addPlayerXp(int amount) async {
    final current = getPlayerXp();
    await _prefs.setInt('player_xp', current + amount);
  }

  Future<void> setPlayerXp(int xp, {int? level, int? nextLevelXp}) async {
    await _prefs.setInt('player_xp', xp);
    if (level != null && level > 0) {
      await _prefs.setInt('player_level', level);
    }
    if (nextLevelXp != null && nextLevelXp > 0) {
      await _prefs.setInt('next_level_xp', nextLevelXp);
    }
  }

  /// Get player level saved from server.
  int getPlayerLevel() {
    final storedLevel = _prefs.getInt('player_level');
    if (storedLevel != null && storedLevel > 0) return storedLevel;
    return 1;
  }

  /// XP required to reach the next level (saved from server).
  int getXpForNextLevel() {
    final storedNext = _prefs.getInt('next_level_xp');
    if (storedNext != null && storedNext > 0) return storedNext;
    return 0;
  }

  // --- Language / i18n Persistence ---

  String getLanguageCode() => _prefs.getString('app_language_code') ?? 'en';
  Future<void> saveLanguageCode(String code) async =>
      await _prefs.setString('app_language_code', code);

  String getSelectedSkinId() => _prefs.getString('snake_skin') ?? 'neon_green';
  Future<void> saveSelectedSkinId(String skinId) async =>
      await _prefs.setString('snake_skin', skinId);

  String getSelectedBoardSkinId() =>
      _prefs.getString('board_skin') ?? 'default';
  Future<void> saveSelectedBoardSkinId(String skinId) async =>
      await _prefs.setString('board_skin', skinId);

  bool getShowJoystick() => _prefs.getBool('show_joystick') ?? true;
  Future<void> saveShowJoystick(bool show) async =>
      await _prefs.setBool('show_joystick', show);

  // --- Auth & Profile Persistence ---

  String? getSavedUserId() => _prefs.getString(kUserIdKey);
  Future<void> saveUserId(String userId) async =>
      await _prefs.setString(kUserIdKey, userId);

  Future<String?> getUserToken() async {
    _cachedUserToken ??= await _secureStorage.read(key: kUserTokenKey);
    return _cachedUserToken;
  }

  Future<void> saveUserToken(String token) async {
    _cachedUserToken = token;
    await _secureStorage.write(key: kUserTokenKey, value: token);
  }

  String? getSavedUsername() => _prefs.getString(kUsernameKey);
  Future<void> saveUsername(String username) async =>
      await _prefs.setString(kUsernameKey, username);

  String getSavedAvatarId() => _prefs.getString(kAvatarIdKey) ?? 'avatar_1';
  Future<void> saveAvatarId(String avatarId) async =>
      await _prefs.setString(kAvatarIdKey, avatarId);

  String? getCustomAvatarPath() => _prefs.getString('custom_avatar_path');
  Future<void> saveCustomAvatarPath(String path) async =>
      await _prefs.setString('custom_avatar_path', path);

  // --- Daily Challenge Persistence ---

  int getDailyChallengeAttempts(String challengeId) {
    return _prefs.getInt('daily_challenge_attempts_$challengeId') ?? 0;
  }

  Future<void> recordDailyChallengeAttempt(String challengeId) async {
    final current = getDailyChallengeAttempts(challengeId);
    await _prefs.setInt('daily_challenge_attempts_$challengeId', current + 1);
  }

  // --- Pending Score Submission (Offline Retry) ---
  static const String _kPendingScoreSubmissionKey = 'pending_score_submission';

  /// Save a pending score submission payload locally for offline retry.
  Future<void> savePendingScoreSubmission(Map<String, dynamic> payload) async {
    try {
      await _prefs.setString(_kPendingScoreSubmissionKey, jsonEncode(payload));
    } catch (_) {}
  }

  /// Retrieve the single pending score submission payload, if any.
  Map<String, dynamic>? getPendingScoreSubmission() {
    final raw = _prefs.getString(_kPendingScoreSubmissionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if a pending score submission payload exists.
  bool hasPendingScoreSubmission() {
    final raw = _prefs.getString(_kPendingScoreSubmissionKey);
    return raw != null && raw.isNotEmpty;
  }

  /// Clear the pending score submission payload upon success or terminal error.
  Future<void> clearPendingScoreSubmission() async {
    await _prefs.remove(_kPendingScoreSubmissionKey);
  }

  Future<void> clearUserData() async {
    _cachedUserToken = null;
    await _prefs.remove(kUserIdKey);
    await _secureStorage.delete(key: kUserTokenKey);
    await _prefs.remove(kUsernameKey);
    await _prefs.remove(kAvatarIdKey);
    await _prefs.remove('custom_avatar_path');
    await _prefs.remove('player_xp');
    await _prefs.remove('player_level');
    await _prefs.remove('next_level_xp');
    await clearPendingScoreSubmission();
  }
}
