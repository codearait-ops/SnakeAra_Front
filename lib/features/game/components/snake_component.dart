import 'dart:ui';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';

/// Represents the snake on the game grid.
///
/// The snake is stored as a list of [GridPos] segments where index 0 is the head.
/// Movement advances the head in the current direction with wrap-around boundaries.
class SnakeComponent {
  final List<GridPos> _segments = [];
  final List<GridPos> _previousSegments = [];
  Direction _currentDirection = Direction.right;
  Direction _nextDirection = Direction.right;
  bool _isGrowing = false;
  int _infectedSegmentCount = 0;

  /// All snake segments (head first).
  List<GridPos> get segments => List.unmodifiable(_segments);

  /// Current direction of movement.
  Direction get currentDirection => _currentDirection;

  /// The head position.
  GridPos get head => _segments.first;

  /// Number of segments currently infected starting from the tail.
  int get infectedSegmentCount =>
      _infectedSegmentCount.clamp(0, _segments.length);

  /// Infection progress ratio (0.0 to 1.0).
  double get infectionRatio => _segments.isEmpty
      ? 0.0
      : (_infectedSegmentCount / _segments.length).clamp(0.0, 1.0);

  /// Returns whether segment at [index] (0 is head) is infected.
  bool isSegmentInfected(int index) {
    if (_segments.isEmpty) return false;
    final cleanCount = _segments.length - _infectedSegmentCount;
    return index >= cleanCount;
  }

  /// Returns true if the snake's head is infected.
  bool get isHeadInfected => isSegmentInfected(0);

  /// Increment infected segment count from the tail.
  void infectTail() {
    if (_infectedSegmentCount < _segments.length) {
      _infectedSegmentCount++;
    }
  }

  /// Heal/reduce infected segment count by [amount].
  void healInfection([int amount = 1]) {
    _infectedSegmentCount = (_infectedSegmentCount - amount).clamp(
      0,
      _segments.length,
    );
  }

  /// Reset infection state.
  void resetInfection() {
    _infectedSegmentCount = 0;
  }

  /// Cut/slice the snake at the given segment [sliceIndex].
  ///
  /// Keeps all segments from 0 up to [sliceIndex - 1] and returns the list of removed tail segments.
  List<GridPos> sliceAt(int sliceIndex) {
    if (sliceIndex <= 0 || sliceIndex >= _segments.length) return [];
    final cutSegments = _segments.sublist(sliceIndex);
    _segments.removeRange(sliceIndex, _segments.length);
    if (_infectedSegmentCount > _segments.length) {
      _infectedSegmentCount = _segments.length;
    }
    return cutSegments;
  }

  /// Initialize the snake at the center of the grid.
  void init(int gridWidth, int gridHeight) {
    final centerX = gridWidth ~/ 2;
    final centerY = gridHeight ~/ 2;
    _segments.clear();
    _segments.addAll([
      GridPos(centerX, centerY),
      GridPos(centerX - 1, centerY),
      GridPos(centerX - 2, centerY),
    ]);
    _currentDirection = Direction.right;
    _nextDirection = Direction.right;
    _isGrowing = false;
    _infectedSegmentCount = 0;
    _previousSegments.clear();
    _previousSegments.addAll(_segments);
  }

  /// Attempt to change direction. Reversals are ignored.
  void changeDirection(Direction newDirection) {
    if (_currentDirection.isOpposite(newDirection)) return;
    if (_nextDirection.isOpposite(newDirection)) return;
    _nextDirection = newDirection;
  }

  /// Move the snake one step forward with grid boundary wrap-around.
  void move(int gridWidth, int gridHeight) {
    _previousSegments.clear();
    _previousSegments.addAll(_segments);

    _currentDirection = _nextDirection;
    final newHead = _computeNewHead(gridWidth, gridHeight);
    _segments.insert(0, newHead);
    if (_isGrowing) {
      _isGrowing = false;
    } else {
      _segments.removeLast();
    }
  }

  /// Returns the interpolated visual position of the segment at [index] given the interpolation factor [t].
  Offset getInterpolatedPosition(
    int index,
    double t,
    double cellW,
    double cellH,
  ) {
    if (_previousSegments.isEmpty ||
        _previousSegments.length > _segments.length ||
        index >= _segments.length) {
      final pos = _segments[index];
      return Offset(pos.x * cellW + cellW / 2, pos.y * cellH + cellH / 2);
    }

    final GridPos current = _segments[index];
    final GridPos previous;

    if (index < _previousSegments.length) {
      previous = _previousSegments[index];
    } else {
      // The newly added segment during growth
      previous = _previousSegments.last;
    }

    // If segment wrapped around the grid edge, jump directly to avoid stretching across the board
    if ((current.x - previous.x).abs() > 1 ||
        (current.y - previous.y).abs() > 1) {
      return Offset(
        current.x * cellW + cellW / 2,
        current.y * cellH + cellH / 2,
      );
    }

    final double startX = previous.x * cellW + cellW / 2;
    final double startY = previous.y * cellH + cellH / 2;
    final double endX = current.x * cellW + cellW / 2;
    final double endY = current.y * cellH + cellH / 2;

    final double x = startX + (endX - startX) * t;
    final double y = startY + (endY - startY) * t;
    return Offset(x, y);
  }

  /// Mark the snake as growing (called when food is eaten).
  void grow() {
    _isGrowing = true;
  }

  /// Returns true if the given position overlaps any segment.
  bool occupiesPosition(GridPos position) {
    return _segments.any((seg) => seg == position);
  }

  /// Check if the head collides with the body (self-collision).
  bool checkSelfCollision() {
    final h = head;
    for (int i = 1; i < _segments.length; i++) {
      if (_segments[i] == h) return true;
    }
    return false;
  }

  /// Compute the next head position with wall wrap-around.
  GridPos _computeNewHead(int gridWidth, int gridHeight) {
    final h = head;
    int newX = h.x;
    int newY = h.y;

    switch (_currentDirection) {
      case Direction.up:
        newY = h.y - 1;
        break;
      case Direction.down:
        newY = h.y + 1;
        break;
      case Direction.left:
        newX = h.x - 1;
        break;
      case Direction.right:
        newX = h.x + 1;
        break;
    }

    // Wrap around screen edges
    if (newX < 0) newX = gridWidth - 1;
    if (newX >= gridWidth) newX = 0;
    if (newY < 0) newY = gridHeight - 1;
    if (newY >= gridHeight) newY = 0;

    return GridPos(newX, newY);
  }
}
