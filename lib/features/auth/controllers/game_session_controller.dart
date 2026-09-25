import 'package:get/get.dart';

/// In-memory session controller tracking per-mode session best scores.
///
/// This controller is strictly in-memory (RAM only) and does NOT persist to disk,
/// Hive, or SharedPreferences. It resets cleanly when the app restarts.
class GameSessionController extends GetxController {
  final RxMap<String, int> sessionBestByMode = <String, int>{}.obs;

  /// Updates the in-memory session best score for a specific game mode
  /// if [score] is higher than the existing record.
  /// Returns `true` if this score is a new session record.
  bool updateIfBetter(String mode, int score) {
    final currentBest = sessionBestByMode[mode];
    if (currentBest == null || score > currentBest) {
      sessionBestByMode[mode] = score;
      return true;
    }
    return false;
  }

  /// Returns the current session best score for [mode].
  int bestFor(String mode) => sessionBestByMode[mode] ?? 0;

  /// Checks if [score] beats the current session best without mutating state.
  bool isSessionRecord(String mode, int score) {
    final currentBest = sessionBestByMode[mode];
    return currentBest == null || score > currentBest;
  }

  /// Clear session data (e.g. on explicit reset if needed)
  void clearSession() {
    sessionBestByMode.clear();
  }
}
