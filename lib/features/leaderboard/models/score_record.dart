/// A simple data class representing a highscore record for a given level.
class ScoreRecord {
  final int level;
  final int score;

  const ScoreRecord({
    required this.level,
    required this.score,
  });
}
