import 'package:flutter/material.dart';
import '../../../../app/core/utils/enums.dart';

/// Detects finger swipes in four directions and reports via [onSwipe].
class SwipeDetector extends StatefulWidget {
  final void Function(Direction) onSwipe;
  final Widget child;

  const SwipeDetector({super.key, required this.onSwipe, required this.child});

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  static const double _threshold = 30.0;
  Offset? _startPos;
  Direction? _lastFired;

  void _onPanStart(DragStartDetails details) {
    _startPos = details.localPosition;
    _lastFired = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _startPos;
    if (start == null) return;

    final delta = details.localPosition - start;

    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx.abs() > _threshold) {
        final dir = delta.dx > 0 ? Direction.right : Direction.left;
        if (dir != _lastFired) {
          _lastFired = dir;
          widget.onSwipe(dir);
          _startPos = details.localPosition;
        }
      }
    } else {
      if (delta.dy.abs() > _threshold) {
        final dir = delta.dy > 0 ? Direction.down : Direction.up;
        if (dir != _lastFired) {
          _lastFired = dir;
          widget.onSwipe(dir);
          _startPos = details.localPosition;
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _startPos = null;
    _lastFired = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: widget.child,
    );
  }
}
