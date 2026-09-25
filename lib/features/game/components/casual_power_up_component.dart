import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/core/constants/app_constants.dart';
import '../models/casual_mode_models.dart';
import 'food_component.dart';
import 'snake_component.dart';

/// Component responsible for managing power-ups in Casual Mode.
///
/// Features:
/// - Exactly 5 Power-Ups: 🧲 Magnet, ⚡ Turbo, 🧊 Ice, 🌧️ Apple Rain, 👻 Ghost.
/// - Maximum 1 power-up on the board at a time.
/// - 5–8 second random cooldown after game start and power-up collection/expiration.
/// - 8 second duration for active power-ups.
/// - Anti-repetitive selection avoiding recent history duplicates.
/// - Independent from the Mission system.
/// - Smooth 60/120fps canvas rendering with custom visual FX for all states.
class CasualPowerUpComponent {
  PowerUpItem? _boardItem;
  PowerUpType? _activePowerUp;
  double _activeDurationRemaining = 0.0;
  double _spawnCooldown = 0.0;
  final List<PowerUpType> _recentSpawnTypes = [];
  final Random _rng = Random();

  // Multi-apple pool for Apple Rain (collectable apples placed on ground)
  final List<RainAppleItem> _rainApples = [];
  double _appleRainSpawnTimer = 0.0;

  // Active paints for rendering
  static final Paint _glowPaint = Paint();
  static final Paint _itemBgPaint = Paint();
  static final Paint _magnetRadiusFillPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint _magnetFieldPaint = Paint()..style = PaintingStyle.fill;

  /// Power-Up currently active on the board (waiting to be collected).
  PowerUpItem? get boardItem => _boardItem;

  /// Currently collected and active power-up effect (lasts 8 seconds).
  PowerUpType? get activePowerUp => _activePowerUp;

  /// Remaining duration in seconds for the active power-up (0.0 to 8.0).
  double get activeDurationRemaining => _activeDurationRemaining;

  /// Whether a power-up effect is currently active on the player.
  bool get hasActivePowerUp => _activePowerUp != null && _activeDurationRemaining > 0;

  /// Whether Ghost power-up is active (immune to self-collision cuts).
  bool get isGhostActive => _activePowerUp == PowerUpType.ghost && _activeDurationRemaining > 0;

  /// Whether Turbo power-up is active (increased speed).
  bool get isTurboActive => _activePowerUp == PowerUpType.turbo && _activeDurationRemaining > 0;

  /// Whether Ice power-up is active (slippery inertia).
  bool get isIceActive => _activePowerUp == PowerUpType.ice && _activeDurationRemaining > 0;

  /// Whether Apple Rain power-up is active.
  bool get isAppleRainActive => _activePowerUp == PowerUpType.appleRain && _activeDurationRemaining > 0;

  /// Extra rain apples active on the board during Apple Rain.
  List<GridPos> get rainApples =>
      List.unmodifiable(_rainApples.map((a) => a.position));

  /// Initialize / reset state at start of Casual Mode.
  void init() {
    _boardItem = null;
    _activePowerUp = null;
    _activeDurationRemaining = 0.0;
    _recentSpawnTypes.clear();
    _rainApples.clear();
    _appleRainSpawnTimer = 0.0;

    // Initial spawn delay between 5.0 and 8.0 seconds
    _spawnCooldown = _getRandomSpawnDelay();
  }

  /// Random delay in range [CasualModeConfig.powerUpSpawnMinDelay, CasualModeConfig.powerUpSpawnMaxDelay]
  double _getRandomSpawnDelay() {
    final minDelay = CasualModeConfig.powerUpSpawnMinDelay;
    final maxDelay = CasualModeConfig.powerUpSpawnMaxDelay;
    return minDelay + _rng.nextDouble() * (maxDelay - minDelay);
  }

  /// Check if the snake head collected the board item.
  /// Returns the collected [PowerUpType], or null.
  PowerUpType? checkCollection(GridPos headPos) {
    if (_boardItem != null && _boardItem!.position == headPos) {
      final collectedType = _boardItem!.type;
      _boardItem = null;
      _activePowerUp = collectedType;
      _activeDurationRemaining = CasualModeConfig.powerUpDuration;

      // Special setup for Apple Rain
      if (collectedType == PowerUpType.appleRain) {
        _appleRainSpawnTimer = 0.0;
      }

      return collectedType;
    }
    return null;
  }

  /// Check if snake head collected any of the Apple Rain apples.
  /// Returns true if a rain apple was consumed.
  bool checkRainAppleCollection(GridPos headPos) {
    final index = _rainApples.indexWhere((item) => item.position == headPos);
    if (index != -1) {
      _rainApples.removeAt(index);
      return true;
    }
    return false;
  }

  /// Update loop called per frame.
  /// Returns true if food or rain apple was consumed by Magnet.
  bool update({
    required double dt,
    required int gridWidth,
    required int gridHeight,
    required List<GridPos> snakeSegments,
    required List<GridPos> obstacles,
    required FoodComponent food,
  }) {
    // 1. Update active power-up timer
    if (_activePowerUp != null) {
      _activeDurationRemaining -= dt;

      // Update Apple Rain active logic
      if (_activePowerUp == PowerUpType.appleRain) {
        _updateAppleRain(dt, gridWidth, gridHeight, snakeSegments, obstacles, food.position);
      }

      if (_activeDurationRemaining <= 0) {
        _activePowerUp = null;
        _activeDurationRemaining = 0.0;
        _rainApples.clear();
        // Start cooldown before spawning next power-up
        _spawnCooldown = _getRandomSpawnDelay();
      }
    }

    // 2. Animate board item pulsing if present
    if (_boardItem != null) {
      _boardItem!.animationTimer += dt;
    }

    // 3. Magnet attraction mechanics: Pull main apple smoothly towards snake head
    bool foodConsumedByMagnet = false;
    if (_activePowerUp == PowerUpType.magnet && snakeSegments.isNotEmpty) {
      foodConsumedByMagnet = _updateMagnetAttraction(dt, snakeSegments.first, snakeSegments, food);
    }



    // 5. Handle spawn cooldown when no power-up is on board and no active power-up
    if (_boardItem == null && _activePowerUp == null) {
      _spawnCooldown -= dt;
      if (_spawnCooldown <= 0) {
        _spawn(gridWidth, gridHeight, snakeSegments, obstacles, food.position);
      }
    }

    return foodConsumedByMagnet;
  }

  /// Update Apple Rain multi-apple scatter & falling physics.
  /// Real apples fall from above and land directly on grid cells so they sit on the ground.
  void _updateAppleRain(
    double dt,
    int gridWidth,
    int gridHeight,
    List<GridPos> snakeSegments,
    List<GridPos> obstacles,
    GridPos mainFoodPos,
  ) {
    // 1. Update physics for all currently falling or landed apples
    for (final apple in _rainApples) {
      apple.update(dt);
    }

    // 2. Initial rain shower wave: spawn up to max apples at once with staggered fall
    if (_rainApples.isEmpty) {
      final needed = CasualModeConfig.appleRainMaxApples;
      for (int i = 0; i < needed; i++) {
        _spawnSingleRainApple(
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          snakeSegments: snakeSegments,
          obstacles: obstacles,
          mainFoodPos: mainFoodPos,
          initialDelayY: i * 0.55,
        );
      }
      _appleRainSpawnTimer = 0.0;
    } else {
      // 3. Replenish collected apples periodically while Apple Rain is active
      _appleRainSpawnTimer += dt;
      if (_appleRainSpawnTimer >= 0.8 &&
          _rainApples.length < CasualModeConfig.appleRainMaxApples) {
        _appleRainSpawnTimer = 0.0;
        _spawnSingleRainApple(
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          snakeSegments: snakeSegments,
          obstacles: obstacles,
          mainFoodPos: mainFoodPos,
          initialDelayY: 0.0,
        );
      }
    }
  }

  /// Spawns a single collectable rain apple on a free cell.
  void _spawnSingleRainApple({
    required int gridWidth,
    required int gridHeight,
    required List<GridPos> snakeSegments,
    required List<GridPos> obstacles,
    required GridPos mainFoodPos,
    double initialDelayY = 0.0,
  }) {
    final occupied = <GridPos>{
      ...snakeSegments,
      ...obstacles,
      ..._rainApples.map((a) => a.position),
      mainFoodPos,
      if (_boardItem != null) _boardItem!.position,
    };

    for (int attempt = 0; attempt < 30; attempt++) {
      final candidate = GridPos(_rng.nextInt(gridWidth), _rng.nextInt(gridHeight));
      if (!occupied.contains(candidate)) {
        _rainApples.add(
          RainAppleItem(
            position: candidate,
            initialDelayY: initialDelayY,
          ),
        );
        break;
      }
    }
  }

  /// Magnet attraction algorithm: Moves food smoothly and continuously towards snake head.
  /// Uses continuous sub-pixel coordinates for 60/120fps fluid motion without discrete tile jumping.
  bool _updateMagnetAttraction(
    double dt,
    GridPos headPos,
    List<GridPos> snakeSegments,
    FoodComponent food,
  ) {
    if (food.position == headPos || (snakeSegments.isNotEmpty && food.position == snakeSegments.first)) {
      return true;
    }

    final double fx = food.visualX;
    final double fy = food.visualY;
    final double hx = headPos.x.toDouble();
    final double hy = headPos.y.toDouble();

    final double dx = hx - fx;
    final double dy = hy - fy;
    final double dist = sqrt(dx * dx + dy * dy);

    if (dist <= 0.45) {
      return true;
    }

    if (dist <= CasualModeConfig.magnetRadius) {
      // Continuous magnetic attraction with smooth acceleration curve
      final double progress = (1.0 - dist / CasualModeConfig.magnetRadius).clamp(0.0, 1.0);
      final double speed = 8.5 + progress * 11.5; // 8.5 to 20.0 cells per second
      final double step = speed * dt;

      if (step >= dist) {
        food.setContinuousPosition(hx, hy);
        return true;
      } else {
        final double nx = dx / dist;
        final double ny = dy / dist;
        final double nextX = fx + nx * step;
        final double nextY = fy + ny * step;
        food.setContinuousPosition(nextX, nextY);

        // Check if food center is now close to head
        final double newDist = sqrt((hx - nextX) * (hx - nextX) + (hy - nextY) * (hy - nextY));
        if (newDist <= 0.45) {
          return true;
        }

        // Also check if pulled into any body segment
        for (final seg in snakeSegments) {
          final double segDist = sqrt((seg.x - nextX) * (seg.x - nextX) + (seg.y - nextY) * (seg.y - nextY));
          if (segDist <= 0.45) {
            return true;
          }
        }
      }
    } else {
      // Outside attraction radius: smoothly drift back if displaced
      final double targetX = food.position.x.toDouble();
      final double targetY = food.position.y.toDouble();
      final double driftDx = targetX - fx;
      final double driftDy = targetY - fy;
      final double driftDist = sqrt(driftDx * driftDx + driftDy * driftDy);
      if (driftDist > 0.01) {
        final double driftSpeed = 6.0 * dt;
        if (driftSpeed >= driftDist) {
          food.setContinuousPosition(targetX, targetY);
        } else {
          food.setContinuousPosition(
            fx + (driftDx / driftDist) * driftSpeed,
            fy + (driftDy / driftDist) * driftSpeed,
          );
        }
      }
    }
    return false;
  }

  /// Spawns a new random power-up on an unoccupied grid cell.
  void _spawn(
    int gridWidth,
    int gridHeight,
    List<GridPos> snakeSegments,
    List<GridPos> obstacles,
    GridPos foodPos,
  ) {
    // Select power-up type avoiding recent repeats
    final allTypes = PowerUpType.values.toList();
    final candidateTypes = allTypes
        .where((t) => !_recentSpawnTypes.contains(t))
        .toList();

    final nextType = candidateTypes.isNotEmpty
        ? candidateTypes[_rng.nextInt(candidateTypes.length)]
        : allTypes[_rng.nextInt(allTypes.length)];

    // Maintain recent history (last 2)
    _recentSpawnTypes.add(nextType);
    if (_recentSpawnTypes.length > 2) {
      _recentSpawnTypes.removeAt(0);
    }

    final occupied = <GridPos>{
      ...snakeSegments,
      ...obstacles,
      ..._rainApples.map((a) => a.position),
      foodPos,
    };

    final totalCells = gridWidth * gridHeight;
    if (occupied.length >= totalCells) return;

    // Fast-path random sampling
    if (occupied.length < totalCells * 0.75) {
      for (int attempt = 0; attempt < 25; attempt++) {
        final pos = GridPos(_rng.nextInt(gridWidth), _rng.nextInt(gridHeight));
        if (!occupied.contains(pos)) {
          _boardItem = PowerUpItem(position: pos, type: nextType);
          return;
        }
      }
    }

    // Fallback search
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
      final pos = freeCells[_rng.nextInt(freeCells.length)];
      _boardItem = PowerUpItem(position: pos, type: nextType);
    }
  }

  /// Render power-up on canvas (both board item, rain apples, and active state visual FX).
  void render({
    required Canvas canvas,
    required double offsetX,
    required double offsetY,
    required double cellSize,
    required SnakeComponent snake,
    FoodComponent? food,
  }) {
    // 1. Draw Magnet attraction radius around snake head when Magnet is active
    if (_activePowerUp == PowerUpType.magnet && snake.segments.isNotEmpty) {
      final head = snake.head;
      final headCenter = Offset(
        offsetX + head.x * cellSize + cellSize / 2,
        offsetY + head.y * cellSize + cellSize / 2,
      );
      final radiusPx = CasualModeConfig.magnetRadius * cellSize;

      _magnetFieldPaint.color = const Color(0xFFFF4081).withValues(alpha: 0.08);
      canvas.drawCircle(headCenter, radiusPx, _magnetFieldPaint);

      _magnetRadiusFillPaint.color =
          const Color(0xFFFF4081).withValues(alpha: 0.35);
      canvas.drawCircle(headCenter, radiusPx, _magnetRadiusFillPaint);

      // Inner pulse ring
      final pulseRadius = (radiusPx * (0.4 + 0.5 * (sin(_activeDurationRemaining * 5.0) * 0.5 + 0.5)));
      _magnetRadiusFillPaint.color =
          const Color(0xFFFF4081).withValues(alpha: 0.2);
      canvas.drawCircle(headCenter, pulseRadius, _magnetRadiusFillPaint);

      // Magnetic beam to food if within radius
      if (food != null) {
        final foodCenter = Offset(
          offsetX + food.visualX * cellSize + cellSize / 2,
          offsetY + food.visualY * cellSize + cellSize / 2,
        );
        final dist = (headCenter - foodCenter).distance;
        if (dist <= radiusPx) {
          final beamProgress = (1.0 - dist / radiusPx).clamp(0.0, 1.0);
          final beamPaint = Paint()
            ..color = const Color(0xFFFF4081).withValues(alpha: 0.25 + 0.35 * beamProgress)
            ..strokeWidth = 2.0 + 2.0 * beamProgress
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(headCenter, foodCenter, beamPaint);
        }
      }
    }

    // 2. Draw Ice board overlay when Ice is active
    if (_activePowerUp == PowerUpType.ice) {
      final iceSheenPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08);
      canvas.drawRect(
        Rect.fromLTWH(
          offsetX,
          offsetY,
          20 * cellSize,
          20 * cellSize,
        ),
        iceSheenPaint,
      );

      // Draw subtle frosted border around board
      final iceBorderPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
        Rect.fromLTWH(
          offsetX,
          offsetY,
          20 * cellSize,
          20 * cellSize,
        ),
        iceBorderPaint,
      );
    }

    // 3. Draw Turbo speedlines / electric halo when Turbo is active
    if (_activePowerUp == PowerUpType.turbo && snake.segments.isNotEmpty) {
      final head = snake.head;
      final headCenter = Offset(
        offsetX + head.x * cellSize + cellSize / 2,
        offsetY + head.y * cellSize + cellSize / 2,
      );
      final turboAuraPaint = Paint()
        ..color = const Color(0xFFFFD600).withValues(alpha: 0.25 + 0.15 * sin(_activeDurationRemaining * 12.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(headCenter, cellSize * 0.75, turboAuraPaint);
    }

    // 4. Draw Ghost ethereal aura around snake head when Ghost is active
    if (_activePowerUp == PowerUpType.ghost && snake.segments.isNotEmpty) {
      final head = snake.head;
      final headCenter = Offset(
        offsetX + head.x * cellSize + cellSize / 2,
        offsetY + head.y * cellSize + cellSize / 2,
      );
      final ghostAuraPaint = Paint()
        ..color = const Color(0xFFB388FF).withValues(alpha: 0.3 + 0.2 * sin(_activeDurationRemaining * 8.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(headCenter, cellSize * 0.8, ghostAuraPaint);
    }

    // 5. Draw Apple Rain apples on board (falling from sky & sitting on ground)
    if (_rainApples.isNotEmpty) {
      for (final apple in _rainApples) {
        final cx = offsetX + apple.position.x * cellSize + cellSize / 2;
        final cy = offsetY + apple.visualY * cellSize + cellSize / 2;
        final groundCy = offsetY + apple.targetY * cellSize + cellSize / 2;

        // While falling, draw ground landing shadow target so player sees where it lands
        if (!apple.isLanded) {
          final distanceToGround = (apple.targetY - apple.visualY).clamp(0.0, 10.0);
          final shadowFraction = (1.0 - (distanceToGround / 10.0)).clamp(0.0, 1.0);
          final shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.3 * shadowFraction);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, groundCy + cellSize * 0.25),
              width: cellSize * (0.3 + 0.3 * shadowFraction),
              height: cellSize * (0.15 + 0.15 * shadowFraction),
            ),
            shadowPaint,
          );
        }

        canvas.save();
        canvas.translate(cx, cy);
        final scale = apple.scale;
        if (scale != 1.0) {
          canvas.scale(scale, scale);
        }

        // Glowing aura around rain apples sitting on the ground
        final appleGlow = Paint()
          ..color = const Color(0xFFFF5722).withValues(alpha: apple.isLanded ? 0.35 : 0.2);
        canvas.drawCircle(Offset.zero, cellSize * 0.48, appleGlow);

        // Apple emoji
        final textSpan = TextSpan(
          text: '🍎',
          style: TextStyle(fontSize: cellSize * 0.68),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );

        canvas.restore();
      }
    }

    // 7. Draw power-up entity on board if spawned
    if (_boardItem != null) {
      final pos = _boardItem!.position;
      final type = _boardItem!.type;
      final cx = offsetX + pos.x * cellSize + cellSize / 2;
      final cy = offsetY + pos.y * cellSize + cellSize / 2;
      final baseRadius = cellSize * 0.42;

      final pulse = sin(_boardItem!.animationTimer * 4.0) * 0.12;
      final radius = baseRadius * (1.0 + pulse);

      // Glowing outer aura
      _glowPaint.color = type.color.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(cx, cy), radius * 1.5, _glowPaint);

      // Background bubble
      _itemBgPaint.color = const Color(0xFF0F172A).withValues(alpha: 0.9);
      _itemBgPaint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius, _itemBgPaint);

      // Border ring
      final borderPaint = Paint()
        ..color = type.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

      // Render emoji icon inside bubble
      final textSpan = TextSpan(
        text: type.emoji,
        style: TextStyle(
          fontSize: cellSize * 0.55,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }
}

/// Represents an apple raining down onto the board during the Apple Rain power-up.
///
/// Falls smoothly from the sky onto its target cell, lands with a juicy bounce,
/// and stays on the ground ready for the snake to collect it.
class RainAppleItem {
  final GridPos position;
  double visualY;
  final double targetY;
  double vy;
  bool isLanded;
  double bounceTimer;

  RainAppleItem({
    required this.position,
    double initialDelayY = 0.0,
  })  : targetY = position.y.toDouble(),
        visualY = -2.0 - initialDelayY,
        vy = 12.0,
        isLanded = false,
        bounceTimer = 0.0;

  void update(double dt) {
    if (!isLanded) {
      visualY += vy * dt;
      vy += 26.0 * dt; // gravity
      if (visualY >= targetY) {
        visualY = targetY;
        isLanded = true;
        bounceTimer = 0.22; // bounce effect duration
      }
    } else if (bounceTimer > 0) {
      bounceTimer -= dt;
      if (bounceTimer < 0) bounceTimer = 0;
    }
  }

  /// Scale factor for bounce squish/stretch upon landing on the ground.
  double get scale {
    if (!isLanded || bounceTimer <= 0) return 1.0;
    final progress = bounceTimer / 0.22;
    return 1.0 + sin(progress * pi) * 0.25;
  }
}
