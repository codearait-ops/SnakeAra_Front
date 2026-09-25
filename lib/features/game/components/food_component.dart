import 'dart:math';
import '../../../app/core/constants/app_constants.dart';

/// Represents the food item on the game grid.
///
/// Supports both discrete grid coordinates and continuous floating-point visual
/// coordinates ([visualX], [visualY]) for 60/120fps smooth magnet attraction.
class FoodComponent {
  GridPos _position = const GridPos(0, 0);
  double visualX = 0.0;
  double visualY = 0.0;

  /// Current discrete food position on grid.
  GridPos get position => _position;

  /// Set the food position directly and sync visual coordinates.
  void setDirectPosition(GridPos newPos) {
    _position = newPos;
    visualX = newPos.x.toDouble();
    visualY = newPos.y.toDouble();
  }

  /// Set continuous floating-point position for smooth physical movement.
  void setContinuousPosition(double x, double y) {
    visualX = x;
    visualY = y;
    _position = GridPos(x.round(), y.round());
  }

  /// Spawn food at a random position not occupied by snake, obstacles, or pear.
  void spawn(
    int gridWidth,
    int gridHeight,
    List<GridPos> snakeSegments,
    List<GridPos> obstacles,
    Random rng, {
    GridPos? pearPos,
  }) {
    final occupied = <GridPos>{
      ...snakeSegments,
      ...obstacles,
      if (pearPos != null) pearPos,
    };

    final totalCells = gridWidth * gridHeight;
    if (occupied.length >= totalCells) return;

    // Fast-path: Random sampling (succeeds on attempt 1 in 95%+ of cases)
    if (occupied.length < totalCells * 0.75) {
      for (int attempt = 0; attempt < 25; attempt++) {
        final pos = GridPos(rng.nextInt(gridWidth), rng.nextInt(gridHeight));
        if (!occupied.contains(pos)) {
          _position = pos;
          visualX = pos.x.toDouble();
          visualY = pos.y.toDouble();
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
      visualX = _position.x.toDouble();
      visualY = _position.y.toDouble();
    }
  }
}

