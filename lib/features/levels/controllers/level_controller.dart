import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../menu/models/home_dashboard_model.dart';
import '../data/levels_data.dart';

/// Controller for the 100-level system.
///
/// Manages level progress (which levels are unlocked) saved to
/// SharedPreferences, and provides data for the level selection UI.
class LevelController extends GetxController {
  static const String kCompletedLevelsKey = 'completed_levels_set';

  final RxInt lastUnlockedLevel = 1.obs;
  final RxInt selectedLevel = 1.obs;
  final RxSet<int> completedLevels = <int>{}.obs;

  late SharedPreferences _prefs;

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    lastUnlockedLevel.value = _prefs.getInt(kLevelProgressKey) ?? 1;

    final saved = _prefs.getStringList(kCompletedLevelsKey) ?? [];
    completedLevels.addAll(
      saved.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0),
    );
    // Backwards compatibility: any level strictly below lastUnlockedLevel was completed
    for (int i = 1; i < lastUnlockedLevel.value; i++) {
      completedLevels.add(i);
    }
  }

  /// Returns level data for a given level number (1-based).
  Map<String, dynamic> getLevelData(int level) {
    return gameLevels.firstWhere(
      (l) => l['level'] == level,
      orElse: () => gameLevels[0],
    );
  }

  /// Total number of levels.
  int get totalLevels => gameLevels.length;

  /// Returns true if the given level is unlocked.
  bool isLevelUnlocked(int level) {
    return level <= lastUnlockedLevel.value;
  }

  /// Returns true if the level was previously completed.
  bool isLevelCompleted(int level) {
    return completedLevels.contains(level) || level < lastUnlockedLevel.value;
  }

  /// Record level completion and unlock the next level.
  Future<void> markLevelCompleted(int completedLevel) async {
    completedLevels.add(completedLevel);
    await _prefs.setStringList(
      kCompletedLevelsKey,
      completedLevels.map((e) => e.toString()).toList(),
    );
    await unlockNextLevel(completedLevel);
  }

  /// Mark the next level as unlocked (called when a level is completed).
  Future<void> unlockNextLevel(int completedLevel) async {
    final nextLevel = completedLevel + 1;
    if (nextLevel > lastUnlockedLevel.value && nextLevel <= totalLevels) {
      lastUnlockedLevel.value = nextLevel;
      await _prefs.setInt(kLevelProgressKey, nextLevel);
    }
  }

  /// Reset all progress (for testing).
  Future<void> resetProgress() async {
    lastUnlockedLevel.value = 1;
    completedLevels.clear();
    await _prefs.setInt(kLevelProgressKey, 1);
    await _prefs.remove(kCompletedLevelsKey);
  }

  /// Syncs level progress received from backend (e.g. via GET /home/dashboard).
  ///
  /// Merges remote and local progress (taking the higher level) and saves to SharedPreferences.
  Future<void> syncFromBackend(LevelProgressData data) async {
    _prefs = await SharedPreferences.getInstance();

    final int newUnlocked = data.lastUnlockedLevel > lastUnlockedLevel.value
        ? data.lastUnlockedLevel
        : lastUnlockedLevel.value;

    lastUnlockedLevel.value = newUnlocked;
    completedLevels.addAll(data.completedLevels);
    for (int i = 1; i < newUnlocked; i++) {
      completedLevels.add(i);
    }

    await _prefs.setInt(kLevelProgressKey, newUnlocked);
    await _prefs.setStringList(
      kCompletedLevelsKey,
      completedLevels.map((e) => e.toString()).toList(),
    );
    debugPrint(
      '[LevelController] 🔄 Level progress synced from backend: lastUnlockedLevel=$newUnlocked, totalCompleted=${completedLevels.length}',
    );
  }


  /// Select a level (if unlocked).
  void selectLevel(int level) {
    if (isLevelUnlocked(level)) {
      selectedLevel.value = level;
    }
  }

  /// Total number of chapters (10 levels per chapter).
  int get totalChapters => (totalLevels / 10).ceil();

  /// Total levels per chapter.
  int get levelsPerChapter => 10;

  /// Returns the number of unlocked levels in a given chapter (1-based chapter index).
  int getChapterUnlockedCount(int chapter) {
    final startLevel = (chapter - 1) * 10 + 1;
    if (lastUnlockedLevel.value < startLevel) return 0;
    final count = lastUnlockedLevel.value - startLevel + 1;
    return count.clamp(0, 10);
  }

  /// Returns true if a given chapter is accessible (at least 1st level unlocked).
  bool isChapterUnlocked(int chapter) {
    if (chapter == 1) return true;
    final startLevel = (chapter - 1) * 10 + 1;
    return lastUnlockedLevel.value >= startLevel;
  }

  /// Returns translation key for chapter title.
  String getChapterTitleKey(int chapter) => 'chapter_${chapter}_title';

  /// Returns true if the given level number is a Boss level.
  bool isBossLevel(int level) => level % 10 == 0;

  /// Returns Boss data if the level is a Boss level.
  Map<String, dynamic>? getBossData(int level) {
    if (!isBossLevel(level)) return null;
    final data = getLevelData(level);
    if (data['isBoss'] == true) return data;
    return null;
  }
}
