import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import '../../../app/core/utils/enums.dart';
import 'snake_component.dart';

enum CrabState { idle, chase, attackPrepare, attackSnap, recover }

class CrabComponent {
  // Configurable gameplay constants
  static const double baseSpeed = 0.5; // Reduced from 1.0
  static const double maxSpeed = 1.6;
  static const double predictionDistance = 1.5;
  static const double attackCooldown = 0.8;
  static const double hitboxRadius = 0.4; // relative to cell size

  // Animation configuration
  static const double animSpeedChase = 8.0; // Reduced from 15.0 for slower legs
  static const double animSpeedIdle = 2.0; // Idle breathing speed
  static const double bodyBobAmplitude = 0.05; // Relative to cell size
  static const double bodyTiltAmplitude = 0.15; // Radians
  static const double legSwingAmplitude = 0.5; // Radians

  // Attack timings (highly configurable)
  static const double timeAttackPrepare = 0.4;
  static const double timeAttackSnap = 0.1;
  static const double timeAttackRecover = 0.5;

  // State
  double x = 0;
  double y = 0;
  double speedMultiplier = 1.0;
  CrabState state = CrabState.idle;

  double _stateTimer = 0.0;
  double _animationTimer = 0.0;

  int _attackTargetSegmentIndex = -1;
  int get lastHitSegmentIndex => _attackTargetSegmentIndex;

  bool _hasAppliedCut = false;
  bool _isLoaded = false;
  bool get isAttacking =>
      state == CrabState.attackPrepare ||
      state == CrabState.attackSnap ||
      state == CrabState.recover;

  double _rotation = 0.0;

  // Hierarchical Parts (Sprites)
  late Sprite _bodySprite;
  late Sprite _headSprite;
  late Sprite _jawSprite;
  late Sprite _leg1Sprite;
  late Sprite _leg2Sprite;

  Future<void> loadAssets(FlameGame game) async {
    try {
      final oldPrefix = game.images.prefix;
      game.images.prefix = 'assets/image/';

      _bodySprite = Sprite(await game.images.load('Parts/crab_body.png'));
      _headSprite = Sprite(await game.images.load('Parts/crab_head.png'));
      _jawSprite = Sprite(await game.images.load('Parts/crab_jaw.png'));
      _leg1Sprite = Sprite(await game.images.load('Parts/crab_leg1.png'));
      _leg2Sprite = Sprite(await game.images.load('Parts/crab_leg2.png'));

      game.images.prefix = oldPrefix;
      _isLoaded = true;
    } catch (e) {
      debugPrint('CrabComponent asset load failed: $e');
    }
  }

  void spawn(int gridWidth, int gridHeight, SnakeComponent snake) {
    // Spawn far away from the snake head
    final head = snake.head;
    int spawnX, spawnY;
    do {
      spawnX = Random().nextInt(gridWidth);
      spawnY = Random().nextInt(gridHeight);
    } while ((spawnX - head.x).abs() < 5 && (spawnY - head.y).abs() < 5);

    x = spawnX.toDouble();
    y = spawnY.toDouble();
    state = CrabState.idle;
    _stateTimer = 0.0;
    _animationTimer = 0.0;
    speedMultiplier = 1.0;
    _attackTargetSegmentIndex = -1;
    _hasAppliedCut = false;
  }

  /// Returns the exact segment index that was hit, or -1 if none.
  /// Also checks for head collision (returns 0).
  int checkCollision(SnakeComponent snake, double cellSize) {
    if (isAttacking) {
      return -1; // Don't hit again while attacking/recovering
    }

    final crabPos = Offset(x, y);

    for (int i = 0; i < snake.segments.length; i++) {
      final segVisualPos = snake.getInterpolatedPosition(
        i,
        1.0,
        cellSize,
        cellSize,
      );
      final segLogicalPos = Offset(
        segVisualPos.dx / cellSize - 0.5,
        segVisualPos.dy / cellSize - 0.5,
      );

      final dx = crabPos.dx - segLogicalPos.dx;
      final dy = crabPos.dy - segLogicalPos.dy;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < hitboxRadius * 2) {
        return i;
      }
    }
    return -1;
  }

  void triggerAttack(int segmentIndex) {
    state = CrabState.attackPrepare;
    _stateTimer = 0.0;
    _attackTargetSegmentIndex = segmentIndex;
    _hasAppliedCut = false;
  }

  void update(double dt, SnakeComponent snake, int gridWidth, int gridHeight) {
    if (!_isLoaded) return;

    _animationTimer += dt;
    _stateTimer += dt;

    switch (state) {
      case CrabState.idle:
        if (_stateTimer > 1.0) {
          state = CrabState.chase;
          _stateTimer = 0.0;
        }
        break;

      case CrabState.chase:
        _chaseSnake(dt, snake, gridWidth, gridHeight);
        break;

      case CrabState.attackPrepare:
        // Wait for anticipation to finish (jaws opening, pulling back)
        if (_stateTimer >= timeAttackPrepare) {
          state = CrabState.attackSnap;
          _stateTimer = 0.0;
        }
        break;

      case CrabState.attackSnap:
        // Very fast snap
        if (_stateTimer >= timeAttackSnap) {
          state = CrabState.recover;
          _stateTimer = 0.0;
        }
        break;

      case CrabState.recover:
        // Ease back to neutral stance
        if (_stateTimer >= timeAttackRecover) {
          state = CrabState.chase;
          _stateTimer = 0.0;
        }
        break;
    }
  }

  /// Triggered exactly ONCE at the start of the ATTACK_SNAP phase.
  /// This signals `snake_game.dart` to apply the cut, score penalty, particles, and sound.
  bool shouldApplyCutThisFrame() {
    if (state == CrabState.attackSnap && !_hasAppliedCut) {
      _hasAppliedCut = true;
      return true;
    }
    return false;
  }

  void _chaseSnake(
    double dt,
    SnakeComponent snake,
    int gridWidth,
    int gridHeight,
  ) {
    final head = snake.head;
    final dir = snake.currentDirection;

    // Predict snake position
    double targetX = head.x.toDouble();
    double targetY = head.y.toDouble();

    switch (dir) {
      case Direction.up:
        targetY -= predictionDistance;
        break;
      case Direction.down:
        targetY += predictionDistance;
        break;
      case Direction.left:
        targetX -= predictionDistance;
        break;
      case Direction.right:
        targetX += predictionDistance;
        break;
    }

    // Wrap target coordinates
    if (targetX < 0) targetX += gridWidth;
    if (targetX >= gridWidth) targetX -= gridWidth;
    if (targetY < 0) targetY += gridHeight;
    if (targetY >= gridHeight) targetY -= gridHeight;

    double dx = targetX - x;
    double dy = targetY - y;

    // Shortest path wrap-around distance
    if (dx.abs() > gridWidth / 2) {
      dx = dx > 0 ? dx - gridWidth : dx + gridWidth;
    }
    if (dy.abs() > gridHeight / 2) {
      dy = dy > 0 ? dy - gridHeight : dy + gridHeight;
    }

    final distance = sqrt(dx * dx + dy * dy);

    if (distance > 0.1) {
      final actualSpeed = baseSpeed * speedMultiplier * 4.5;
      final moveDist = min(actualSpeed * dt, distance);

      final moveX = (dx / distance) * moveDist;
      final moveY = (dy / distance) * moveDist;

      x += moveX;
      y += moveY;

      // Update rotation to face movement direction smoothly
      _rotation = atan2(dy, dx);

      // Wrap crab position
      if (x < 0) x += gridWidth;
      if (x >= gridWidth) x -= gridWidth;
      if (y < 0) y += gridHeight;
      if (y >= gridHeight) y -= gridHeight;
    }
  }

  void render(Canvas canvas, double offsetX, double offsetY, double cellSize) {
    if (!_isLoaded) {
      // Fallback rendering
      final cx = offsetX + x * cellSize + cellSize / 2;
      final cy = offsetY + y * cellSize + cellSize / 2;
      final paint = Paint()..color = const Color(0xFFFF5722);
      canvas.drawCircle(Offset(cx, cy), cellSize * hitboxRadius, paint);
      return;
    }

    final cx = offsetX + x * cellSize + cellSize / 2;
    final cy = offsetY + y * cellSize + cellSize / 2;

    canvas.save();
    canvas.translate(cx, cy);

    // Apply world rotation so the crab faces movement direction.
    // Adding pi/2 assumes the crab's front points "UP" visually at rotation 0.
    canvas.rotate(_rotation + pi / 2);

    // Calculate procedural variables based on the deterministic state machine
    double bodyOffset = 0.0;
    double jawOpenAmount = 0.0; // 0 to 1
    double jawLunge = 0.0;
    double legPhaseMult = 0.0; // 0 when idle, 1 when walking
    double bodyTilt = 0.0;

    if (state == CrabState.idle) {
      // Subtle breathing
      bodyOffset =
          sin(_animationTimer * animSpeedIdle) * bodyBobAmplitude * cellSize;
    } else if (state == CrabState.chase) {
      // Walking gait
      bodyOffset =
          sin(_animationTimer * animSpeedChase) * bodyBobAmplitude * cellSize;
      bodyTilt = sin(_animationTimer * animSpeedChase / 2) * bodyTiltAmplitude;
      legPhaseMult = 1.0;
    } else if (state == CrabState.attackPrepare) {
      // Anticipation: pull back slightly, open jaws wide
      double t = (_stateTimer / timeAttackPrepare).clamp(0.0, 1.0);
      double smoothT = 0.5 - 0.5 * cos(t * pi);
      bodyOffset = smoothT * (-cellSize * 0.15); // Pull back
      jawOpenAmount = smoothT;
    } else if (state == CrabState.attackSnap) {
      // Snap: lunge forward rapidly, snap jaws shut
      double t = (_stateTimer / timeAttackSnap).clamp(0.0, 1.0);
      bodyOffset = (1.0 - t) * (cellSize * 0.35); // Lunge forward
      jawOpenAmount = 1.0 - t; // Close very fast
      jawLunge = (1.0 - t) * (cellSize * 0.2); // Jaws thrust forward extra
    } else if (state == CrabState.recover) {
      // Recover: ease back to neutral stance
      double t = (_stateTimer / timeAttackRecover).clamp(0.0, 1.0);
      double smoothT = 0.5 - 0.5 * cos(t * pi);
      bodyOffset = (1.0 - smoothT) * (cellSize * 0.35); // Ease back from lunge
    }

    // Apply procedural body tilt and vertical bob
    canvas.rotate(bodyTilt);
    canvas.translate(0, bodyOffset);

    final double scale =
        cellSize * 2.0; // Baseline scale, around 2x2 cells (4 cells area)

    // Leg anchors: Joint is at top-right for native left legs (approx 0.9, 0.2)
    final legAnchor = Vector2(0.9, 0.2);
    // Leg 4 is a native right leg, so its joint is at top-left (approx 0.1, 0.2)

    // Left side legs (mirrored = false for native left legs, true for native right legs)
    _renderLeg(
      canvas,
      _leg1Sprite,
      Vector2(-0.25, -0.2),
      legAnchor,
      legPhaseMult,
      0,
      scale,
      false,
      sizeMult: 0.5,
    );
    _renderLeg(
      canvas,
      _leg2Sprite,
      Vector2(-0.30, 0.0),
      legAnchor,
      legPhaseMult,
      1,
      scale,
      false,
      sizeMult: 0.62,
    );
    // _renderLeg(
    //   canvas,
    //   _leg3Sprite,
    //   Vector2(-0.25, 0.2),
    //   legAnchor,
    //   legPhaseMult,
    //   2,
    //   scale,
    //   false,
    //   sizeMult: 0.45,
    // );
    // _renderLeg(
    //   canvas,
    //   _leg4Sprite,
    //   Vector2(-0.15, 0.35),
    //   leg4Anchor,
    //   legPhaseMult,
    //   3,
    //   scale,
    //   false,
    //   sizeMult: 0.6,
    //   isNativeRight: true,
    // );

    // Right side legs (mirrored = true for native left legs, false for native right legs)
    _renderLeg(
      canvas,
      _leg1Sprite,
      Vector2(0.25, -0.2),
      legAnchor,
      legPhaseMult,
      0,
      scale,
      true,
      sizeMult: 0.5,
    );
    _renderLeg(
      canvas,
      _leg2Sprite,
      Vector2(0.30, 0.0),
      legAnchor,
      legPhaseMult,
      1,
      scale,
      true,
      sizeMult: 0.62,
    );
    // _renderLeg(
    //   canvas,
    //   _leg3Sprite,
    //   Vector2(0.25, 0.2),
    //   legAnchor,
    //   legPhaseMult,
    //   2,
    //   scale,
    //   true,
    //   sizeMult: 0.45,
    // );
    // _renderLeg(
    //   canvas,
    //   _leg4Sprite,
    //   Vector2(0.15, 0.35),
    //   leg4Anchor,
    //   legPhaseMult,
    //   3,
    //   scale,
    //   true,
    //   sizeMult: 0.6,
    //   isNativeRight: true,
    // );

    // Render Jaws (Single piece) underneath head
    canvas.save();
    canvas.translate(0, -jawLunge * 1.5 - (jawOpenAmount * cellSize * 0.15));
    _renderPart(
      canvas,
      _jawSprite,
      Vector2(0, -0.25),
      Vector2(0.5, 0.6),
      0.0,
      scale,
      false,
      sizeMult: 0.9,
    );
    canvas.restore();

    // Render Body (Base)
    _renderPart(
      canvas,
      _bodySprite,
      Vector2(0, 0),
      Vector2(0.5, 0.5),
      0.0,
      scale,
      false,
      sizeMult: 1.0,
    );

    // Render Head
    _renderPart(
      canvas,
      _headSprite,
      Vector2(0, -0.3),
      Vector2(0.5, 0.5),
      0.0,
      scale,
      false,
      sizeMult: 0.77,
    );

    canvas.restore();
    canvas.restore();
  }

  void _renderLeg(
    Canvas canvas,
    Sprite sprite,
    Vector2 localOffset,
    Vector2 anchor,
    double phaseMult,
    int index,
    double scale,
    bool isRight, {
    double sizeMult = 0.5,
    bool isNativeRight = false,
  }) {
    // Alternating leg phases
    double phase = (_animationTimer * animSpeedChase) + (index * pi / 2);
    if (isRight) phase += pi; // Opposite phase for right side

    double rot = sin(phase) * legSwingAmplitude * phaseMult;

    bool mirrored = isNativeRight ? !isRight : isRight;
    if (mirrored) {
      rot =
          -rot; // Invert rotation for mirrored side so visual rotation remains consistent
    }

    _renderPart(
      canvas,
      sprite,
      localOffset,
      anchor,
      rot,
      scale,
      mirrored,
      sizeMult: sizeMult,
    );
  }

  /// Renders an independent body part with its own transformation matrix.
  /// [localOffset] is the pivot point on the crab body (-1.0 to 1.0 space).
  /// [anchor] is the anchor point on the image itself (0.0 to 1.0 space).
  void _renderPart(
    Canvas canvas,
    Sprite sprite,
    Vector2 localOffset,
    Vector2 anchor,
    double rotation,
    double scale,
    bool mirrored, {
    double sizeMult = 1.0,
  }) {
    canvas.save();

    // Move to the local pivot attachment point
    canvas.translate(localOffset.x * scale, localOffset.y * scale);
    canvas.rotate(rotation);

    if (mirrored) {
      canvas.scale(-1, 1);
    }

    // Preserve image aspect ratio
    final drawWidth = scale * sizeMult;
    final drawHeight = (sprite.srcSize.y / sprite.srcSize.x) * drawWidth;
    final drawSize = Vector2(drawWidth, drawHeight);

    // Shift image so the specified anchor sits exactly at (0,0)
    final px = drawSize.x * anchor.x;
    final py = drawSize.y * anchor.y;

    sprite.render(canvas, position: Vector2(-px, -py), size: drawSize);

    canvas.restore();
  }
}
