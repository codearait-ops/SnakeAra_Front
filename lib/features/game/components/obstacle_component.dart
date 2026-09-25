import '../../../app/core/constants/app_constants.dart';

/// Represents a set of obstacle positions on the game grid.
///
/// Obstacles are provided by the level data and must never overlap
/// with the snake's initial spawn area.
class ObstacleComponent {
  final List<GridPos> _obstacles = [];

  /// List of obstacle positions.
  List<GridPos> get obstacles => List.unmodifiable(_obstacles);

  /// Returns true if a grid coordinate (x, y) is inside the Snake's initial spawn safety corridor.
  ///
  /// The snake spawns at grid center (centerX=10, centerY=10) facing Direction.right with 3 initial segments:
  /// Head: (10, 10), Body 1: (9, 10), Body 2: (8, 10).
  ///
  /// The Spawn Safety Corridor guarantees:
  /// 1. Unobstructed runway ahead of the head (x = 6..15, y = 10).
  /// 2. Clear turning room above and below (x = 6..15, y = 8..12).
  static bool isPositionInSpawnSafetyZone(int x, int y, {int gridWidth = kGridSize, int gridHeight = kGridSize}) {
    final centerX = gridWidth ~/ 2;   // 10
    final centerY = gridHeight ~/ 2;  // 10

    // Safety rectangle covering initial body, forward runway, and turning room:
    // x range: [centerX - 4, centerX + 5] -> [6, 15]
    // y range: [centerY - 2, centerY + 2] -> [8, 12]
    return (x >= centerX - 4 && x <= centerX + 5) &&
           (y >= centerY - 2 && y <= centerY + 2);
  }

  /// Load obstacles from level data (list of {'x': int, 'y': int} maps),
  /// automatically filtering out any obstacles that fall within the Spawn Safety Corridor.
  void loadFromLevelData(List<dynamic> levelObstacles, {int gridWidth = kGridSize, int gridHeight = kGridSize}) {
    _obstacles.clear();
    for (final obs in levelObstacles) {
      final x = obs['x'] as int;
      final y = obs['y'] as int;
      if (!isPositionInSpawnSafetyZone(x, y, gridWidth: gridWidth, gridHeight: gridHeight)) {
        _obstacles.add(GridPos(x, y));
      }
    }
  }

  /// Returns true if the given position is occupied by an obstacle.
  bool occupiesPosition(GridPos position) {
    return _obstacles.any((o) => o == position);
  }

  /// Add a dynamic obstacle position during gameplay (e.g. Boss 3 Architect),
  /// ensuring it never spawns in the Spawn Safety Zone unless [ignoreSafetyZone] is true.
  void addObstacle(GridPos position, {int gridWidth = kGridSize, int gridHeight = kGridSize, bool ignoreSafetyZone = false}) {
    if ((ignoreSafetyZone || !isPositionInSpawnSafetyZone(position.x, position.y, gridWidth: gridWidth, gridHeight: gridHeight)) &&
        !occupiesPosition(position)) {
      _obstacles.add(position);
    }
  }
}
