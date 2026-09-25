import 'dart:math';
import '../../../app/core/constants/app_constants.dart';

/// Represents a bonus Pear item on the game grid.
/// Spawns in Classic Mode every 5 apples and stays active for 5 seconds.
class PearComponent {
  GridPos? _position;
  double _timer = 0.0;
  static const double duration = 7.0; // 7 seconds timer limit

  /// Current pear position on grid, or null if not active.
  GridPos? get position => _position;

  /// Remaining active time in seconds.
  double get timer => _timer;

  /// Whether the pear is currently active on the board.
  bool get isActive => _position != null;

  /// Progress ratio of remaining time (1.0 down to 0.0).
  double get timeProgress => isActive ? (_timer / duration).clamp(0.0, 1.0) : 0.0;

  /// Spawn pear at a random cell not occupied by snake, obstacles, or apple.
  void spawn(
    int gridWidth,
    int gridHeight,
    List<GridPos> snakeSegments,
    List<GridPos> obstacles,
    GridPos applePos,
    Random rng,
  ) {
    final occupied = <GridPos>{
      ...snakeSegments,
      ...obstacles,
      applePos,
    };

    final totalCells = gridWidth * gridHeight;
    if (occupied.length >= totalCells) return;

    // Fast-path: Random sampling
    if (occupied.length < totalCells * 0.75) {
      for (int attempt = 0; attempt < 25; attempt++) {
        final pos = GridPos(rng.nextInt(gridWidth), rng.nextInt(gridHeight));
        if (!occupied.contains(pos)) {
          _position = pos;
          _timer = duration;
          return;
        }
      }
    }

    // Fallback if board is densely crowded
    final freeCells = <GridPos>[];
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        final pos = GridPos(x, y);
        if (!occupied.contains(pos)) {
          freeCells.add(pos);
        }
      }
    }

    if (freeCells.isNotEmpty) {
      _position = freeCells[rng.nextInt(freeCells.length)];
      _timer = duration;
    }
  }

  /// Update timer each tick.
  void update(double dt) {
    if (!isActive) return;

    _timer -= dt;
    if (_timer <= 0) {
      despawn();
    }
  }

  /// Despawn pear from board.
  void despawn() {
    _position = null;
    _timer = 0.0;
  }
}
