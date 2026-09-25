import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:snake_game/app/core/utils/enums.dart';
import 'package:snake_game/features/game/components/snake_game.dart';
import 'package:snake_game/features/game/rendering/snake_game_paints.dart';

/// Canvas renderer for [SnakeGame].
///
/// Encapsulates all canvas drawing logic, leaving [SnakeGame] as a pure
/// gameplay controller and coordinator. Maintains read-only access to
/// [SnakeGame] state and holds graphic/shader caches.
class SnakeCanvasRenderer {
  final SnakeGame game;

  SnakeCanvasRenderer(this.game);

  // --- Optimization: Shader & painter cache trackers ---
  TextPainter? _appleTextPainter;
  double _appleTextPainterCellSize = 0.0;

  double _lastPearCx = -1.0;
  double _lastPearCy = -1.0;
  double _lastPearRadius = -1.0;

  /// Resets cached shader geometry trackers on game restart or reset.
  void resetCache() {
    _appleTextPainter = null;
    _appleTextPainterCellSize = 0.0;
    _lastPearCx = -1.0;
    _lastPearCy = -1.0;
    _lastPearRadius = -1.0;
  }

  /// Master render pass for the gameplay canvas.
  void render(Canvas canvas) {
    drawObstacles(canvas);
    drawLasers(canvas);
    drawShockwave(canvas);
    drawBullets(canvas);
    drawFood(canvas);
    drawExplosions(canvas);
    drawPear(canvas);
    drawSnake(canvas);
    if (game.gameMode.value == GameMode.casual) {
      game.casualPowerUp.render(
        canvas: canvas,
        offsetX: game.offsetX,
        offsetY: game.offsetY,
        cellSize: game.cellSize,
        snake: game.snake,
        food: game.food,
      );
    }
    if (game.parasite != null) {
      game.parasite!.render(canvas);
    }
    if (game.gameMode.value == GameMode.crabChase) {
      game.crab.render(canvas, game.offsetX, game.offsetY, game.cellSize);
    }
    drawSlicedParticles(canvas);
    drawFloatingTexts(canvas);
    drawInfectionFogOfWar(canvas);
    drawStormAndRain(canvas);
  }

  void drawSlicedParticles(Canvas canvas) {
    if (game.slicedParticles.isEmpty) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    for (final p in game.slicedParticles) {
      final progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final cx = offsetX + p.x * cellSize;
      final cy = offsetY + p.y * cellSize;

      SnakeGamePaints.slicedParticleGlowPaint.color =
          p.color.withValues(alpha: alpha * 0.8);
      SnakeGamePaints.slicedParticleCorePaint.color =
          Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(cx, cy),
        p.radius * cellSize * 0.22,
        SnakeGamePaints.slicedParticleGlowPaint,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        p.radius * cellSize * 0.10,
        SnakeGamePaints.slicedParticleCorePaint,
      );
    }
  }

  void drawFloatingTexts(Canvas canvas) {
    if (game.floatingTexts.isEmpty) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    for (final ft in game.floatingTexts) {
      final progress = (ft.life / ft.maxLife).clamp(0.0, 1.0);
      final scale = 1.0 + sin(progress * pi * 0.5) * 0.25;

      final cx = offsetX + ft.x * cellSize;
      final cy = offsetY + ft.y * cellSize;

      ft.painter ??= TextPainter(
        text: TextSpan(
          text: ft.text,
          style: TextStyle(
            color: ft.color,
            fontSize: cellSize * 0.75,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black87, offset: Offset(1.5, 1.5)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final tp = ft.painter!;
      final halfW = tp.width / 2;
      final halfH = tp.height / 2;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale);
      tp.paint(canvas, Offset(-halfW, -halfH));
      canvas.restore();
    }
  }

  void drawLasers(Canvas canvas) {
    if (game.gameMode.value != GameMode.laser &&
        (game.gameMode.value != GameMode.level || game.currentLevel != 20)) {
      return;
    }

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    // Warning Laser Line (Glowing Red semi-transparent)
    if (game.warningLaserRow.value >= 0) {
      final y = offsetY + game.warningLaserRow.value * cellSize + cellSize / 2;
      final paint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.55)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + 20 * cellSize, y),
        paint,
      );
    }
    if (game.warningLaserCol.value >= 0) {
      final x = offsetX + game.warningLaserCol.value * cellSize + cellSize / 2;
      final paint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.55)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + 20 * cellSize),
        paint,
      );
    }

    // Active Deadly Laser Beam (Neon Red & White Core)
    if (game.activeLaserRow.value >= 0) {
      final y = offsetY + game.activeLaserRow.value * cellSize + cellSize / 2;
      final outerGlow = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.85)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final coreLine = Paint()
        ..color = Colors.white
        ..strokeWidth = 6;
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + 20 * cellSize, y),
        outerGlow,
      );
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + 20 * cellSize, y),
        coreLine,
      );
    }
    if (game.activeLaserCol.value >= 0) {
      final x = offsetX + game.activeLaserCol.value * cellSize + cellSize / 2;
      final outerGlow = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.85)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final coreLine = Paint()
        ..color = Colors.white
        ..strokeWidth = 6;
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + 20 * cellSize),
        outerGlow,
      );
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + 20 * cellSize),
        coreLine,
      );
    }
  }

  void drawShockwave(Canvas canvas) {
    if (game.gameMode.value != GameMode.level || game.currentLevel != 40) return;
    final r = game.shockwaveRadius.value;
    if (r <= 0) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;
    final gridRows = game.gridRows;
    final gridCols = game.gridCols;

    final y = offsetY + r * cellSize;
    final alpha = (1.0 - r / gridRows).clamp(0.1, 1.0);

    // Draw Fire Tail
    final tailHeight = 5.0 * cellSize;
    final topY = (y - tailHeight).clamp(offsetY, y);
    if (y > offsetY) {
      final tailRect = Rect.fromLTRB(
        offsetX,
        topY,
        offsetX + gridCols * cellSize,
        y,
      );

      final tailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFF1744).withValues(alpha: alpha * 0.3), // Faded Red
            const Color(
              0xFFFF9100,
            ).withValues(alpha: alpha * 0.7), // Intense Orange
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(tailRect);

      canvas.drawRect(tailRect, tailPaint);
    }

    // Deep outer blast glow (Fire Red)
    final outerGlow = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: alpha * 0.5)
      ..strokeWidth = 30
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Mid intense blast energy (Fire Orange)
    final midGlow = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: alpha * 0.8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Blinding core (Yellow/White)
    final corePaint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: alpha)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final p1 = Offset(offsetX, y);
    final p2 = Offset(offsetX + gridCols * cellSize, y);

    canvas.drawLine(p1, p2, outerGlow);
    canvas.drawLine(p1, p2, midGlow);
    canvas.drawLine(p1, p2, corePaint);
  }

  void drawBullets(Canvas canvas) {
    if (game.gameMode.value != GameMode.level || game.currentLevel != 50) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    final bulletGlow = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final bulletCore = Paint()..color = const Color(0xFFFFD700);

    for (final b in game.bullets) {
      final cx = offsetX + b.x * cellSize;
      final cy = offsetY + b.y * cellSize;
      canvas.drawCircle(Offset(cx, cy), cellSize * 0.45, bulletGlow);
      canvas.drawCircle(Offset(cx, cy), cellSize * 0.28, bulletCore);
    }
  }

  void drawObstacles(Canvas canvas) {
    final mode = game.gameMode.value;
    if (mode == GameMode.classic ||
        mode == GameMode.infection ||
        mode == GameMode.casual) {
      return; // No obstacles in Classic, Infection, or Casual Mode
    }

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    for (final obs in game.obstacles.obstacles) {
      final x = offsetX + obs.x * cellSize;
      final y = offsetY + obs.y * cellSize;
      const padding = 1.5;

      final glowRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + padding - 1.0,
          y + padding - 1.0,
          cellSize - padding * 2 + 2.0,
          cellSize - padding * 2 + 2.0,
        ),
        Radius.circular(cellSize * 0.22),
      );
      canvas.drawRRect(glowRRect, SnakeGamePaints.obstacleGlowPaint);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + padding,
          y + padding,
          cellSize - padding * 2,
          cellSize - padding * 2,
        ),
        Radius.circular(cellSize * 0.2),
      );
      if (mode == GameMode.meltdown) {
        // Draw Crater
        final craterPaint = Paint()..color = const Color(0xFF1B1B1B);
        final craterRim = Paint()
          ..color = const Color(0xFFFF5722) // Orange-red rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(
          Offset(x + cellSize / 2, y + cellSize / 2),
          cellSize * 0.4,
          craterPaint,
        );
        canvas.drawCircle(
          Offset(x + cellSize / 2, y + cellSize / 2),
          cellSize * 0.4,
          craterRim,
        );
        // Inner crack
        canvas.drawCircle(
          Offset(x + cellSize / 2, y + cellSize / 2),
          cellSize * 0.15,
          Paint()..color = Colors.black,
        );
      } else {
        canvas.drawRRect(rrect, SnakeGamePaints.obstacleFillPaint);
        canvas.drawRRect(rrect, SnakeGamePaints.obstacleBorderPaint);
      }
    }
  }

  void drawFood(Canvas canvas) {
    if (game.gameMode.value == GameMode.meltdown &&
        game.meltdownAppleTimer <= 1.0) {
      drawBombState(canvas);
      return;
    }

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    final cx = offsetX + game.food.visualX * cellSize + cellSize / 2;
    final cy = offsetY + game.food.visualY * cellSize + cellSize / 2;

    // Heartbeat pulse animation calculation (lub-dub pulse curve)
    final double t = (game.gameTime * 1.6) % 1.0;
    double pulseScale = 1.0;
    if (t < 0.15) {
      // First heartbeat expansion
      pulseScale = 1.0 + 0.22 * sin(t / 0.15 * pi);
    } else if (t >= 0.2 && t < 0.35) {
      // Second heartbeat mini expansion
      pulseScale = 1.0 + 0.14 * sin((t - 0.2) / 0.15 * pi);
    }

    final baseRadius = cellSize * 0.38 * pulseScale;

    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius * 2.2,
      SnakeGamePaints.foodOuterGlowPaint,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius * 3.5,
      SnakeGamePaints.foodSecondaryGlowPaint,
    );

    // Render Apple emoji matching Apple Rain
    canvas.save();
    canvas.translate(cx, cy);
    if (pulseScale != 1.0) {
      canvas.scale(pulseScale, pulseScale);
    }

    // Glowing aura directly around apple
    final appleGlow = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.35);
    canvas.drawCircle(Offset.zero, cellSize * 0.48, appleGlow);

    if (_appleTextPainter == null || _appleTextPainterCellSize != cellSize) {
      _appleTextPainterCellSize = cellSize;
      _appleTextPainter = TextPainter(
        text: TextSpan(
          text: '🍎',
          style: TextStyle(fontSize: cellSize * 0.68),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _appleTextPainter!.paint(
      canvas,
      Offset(-_appleTextPainter!.width / 2, -_appleTextPainter!.height / 2),
    );

    canvas.restore();

    if (game.gameMode.value == GameMode.meltdown) {
      // Draw Countdown Ring
      final progress = game.meltdownAppleTimer / game.meltdownMaxTimer;
      final ringColor = progress < 0.2
          ? Colors.redAccent
          : const Color(0xFFC6FF00);
      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius * 1.8),
        -pi / 2,
        2 * pi * progress,
        false,
        ringPaint,
      );
    }
  }

  void drawBombState(Canvas canvas) {
    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    final cx = offsetX + game.food.visualX * cellSize + cellSize / 2;
    final cy = offsetY + game.food.visualY * cellSize + cellSize / 2;

    // Fast blinking in the last 1 second
    final blink = (sin(game.meltdownAppleTimer * pi * 12) > 0);
    final pulse = (1.0 + sin(game.meltdownAppleTimer * pi * 4)) / 2.0;
    final baseRadius = cellSize * 0.45 + (pulse * 2.0);

    // Glow
    final glowPaint = Paint()
      ..color = (blink ? Colors.white : const Color(0xFFFF1744)).withValues(
        alpha: 0.6,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy), baseRadius * 1.5, glowPaint);

    // Bomb body
    final bombPaint = Paint()
      ..color = blink ? Colors.white : const Color(0xFF1E1E1E);
    canvas.drawCircle(Offset(cx, cy), baseRadius, bombPaint);

    // Draw the countdown ring around it
    final progress = game.meltdownAppleTimer / game.meltdownMaxTimer;
    final ringPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius * 1.8),
      -pi / 2,
      2 * pi * progress,
      false,
      ringPaint,
    );
  }

  void drawExplosions(Canvas canvas) {
    if (game.gameMode.value != GameMode.meltdown) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    for (final exp in game.explosions) {
      final pos = exp.position;
      final cx = offsetX + pos.x * cellSize + cellSize / 2;
      final cy = offsetY + pos.y * cellSize + cellSize / 2;

      final progress = 1.0 - (exp.life / exp.maxLife); // 0 to 1
      final blastRadius = cellSize * 0.5 + (progress * cellSize * 2.5);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      // Expanding fiery blast
      final blastPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(cx, cy), blastRadius, blastPaint);

      // Bright inner core
      final corePaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy), blastRadius * 0.5, corePaint);

      // Shockwave ring
      final shockwavePaint = Paint()
        ..color = const Color(0xFFFF9100).withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(Offset(cx, cy), blastRadius * 1.2, shockwavePaint);
    }
  }

  void drawPear(Canvas canvas) {
    if (!game.pear.isActive) return;
    final pos = game.pear.position!;
    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    final cx = offsetX + pos.x * cellSize + cellSize / 2;
    final cy = offsetY + pos.y * cellSize + cellSize / 2;
    final baseRadius = cellSize * 0.36;

    // Outer glowing effects
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius * 2.2,
      SnakeGamePaints.pearOuterGlowPaint,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius * 3.2,
      SnakeGamePaints.pearSecondaryGlowPaint,
    );

    // Pear body - bottom circle (larger) & top circle (smaller)
    final bottomCenter = Offset(cx, cy + baseRadius * 0.15);
    final bottomRadius = baseRadius * 0.85;
    final topCenter = Offset(cx, cy - baseRadius * 0.3);
    final topRadius = baseRadius * 0.6;

    if (_lastPearCx != cx ||
        _lastPearCy != cy ||
        _lastPearRadius != baseRadius) {
      _lastPearCx = cx;
      _lastPearCy = cy;
      _lastPearRadius = baseRadius;
      SnakeGamePaints.pearBodyPaint.shader = ui.Gradient.radial(
        Offset(cx - baseRadius * 0.2, cy - baseRadius * 0.2),
        baseRadius * 1.5,
        const [
          Color(0xFFFFEE58), // Bright Yellow
          Color(0xFFFBC02D), // Gold/Amber
          Color(0xFFF57F17), // Deep Amber Pear
        ],
        const [0.0, 0.65, 1.0],
      );
    }

    // Draw pear body
    canvas.drawCircle(bottomCenter, bottomRadius, SnakeGamePaints.pearBodyPaint);
    canvas.drawCircle(topCenter, topRadius, SnakeGamePaints.pearBodyPaint);

    // Pear highlight
    canvas.drawCircle(
      Offset(cx - baseRadius * 0.25, cy - baseRadius * 0.2),
      baseRadius * 0.22,
      SnakeGamePaints.foodHighlightPaint,
    );

    // Pear Stem
    final stemPath = Path()
      ..moveTo(cx, cy - baseRadius * 0.85)
      ..quadraticBezierTo(
        cx + 2,
        cy - baseRadius * 1.1,
        cx + 4,
        cy - baseRadius * 1.25,
      );
    canvas.drawPath(stemPath, SnakeGamePaints.pearStemPaint);

    // Pear Leaf
    final leafPath = Path()
      ..moveTo(cx + 2, cy - baseRadius * 1.05)
      ..quadraticBezierTo(
        cx + 8,
        cy - baseRadius * 1.2,
        cx + 7,
        cy - baseRadius * 0.85,
      )
      ..quadraticBezierTo(
        cx + 3,
        cy - baseRadius * 0.85,
        cx + 2,
        cy - baseRadius * 1.05,
      );
    canvas.drawPath(leafPath, SnakeGamePaints.pearLeafPaint);

    // Timer countdown ring around pear (shrinks over 5s)
    final ringRadius = baseRadius * 1.4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: ringRadius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi,
      false,
      SnakeGamePaints.pearTimerBgPaint,
    );
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * game.pear.timeProgress,
      false,
      SnakeGamePaints.pearTimerFgPaint,
    );
  }

  void drawSnake(Canvas canvas) {
    final segments = game.snake.segments;
    if (segments.isEmpty) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;

    final activeSkin = game.currentSkin;
    final segmentCount = segments.length;
    final bodyRadius = cellSize * 0.38;
    final headRadius = cellSize * 0.48;
    final isInfectedMode = game.gameMode.value == GameMode.infection;
    final isBlindMemoryMode = game.gameMode.value == GameMode.blindMemory;

    final moveInterval = game.effectiveMoveInterval;
    final double interpolationT = moveInterval > 0
        ? (game.moveAccumulator / moveInterval).clamp(0.0, 1.0)
        : 1.0;

    final bodyAlpha = isBlindMemoryMode
        ? game.memoryBodyOpacity.value
        : (game.gameMode.value == GameMode.casual &&
                  game.casualPowerUp.isGhostActive
              ? (0.42 + 0.18 * (sin(game.gameTime * 8.0) * 0.5 + 0.5))
              : 1.0);

    for (int i = segmentCount - 1; i >= 1; i--) {
      final visualPos = game.snake.getInterpolatedPosition(
        i,
        interpolationT,
        cellSize,
        cellSize,
      );
      final cx = offsetX + visualPos.dx;
      final cy = offsetY + visualPos.dy;
      final t = segmentCount > 1 ? i / (segmentCount - 1) : 0.0;

      final isSegInfected = isInfectedMode && game.snake.isSegmentInfected(i);

      if (isSegInfected) {
        drawInfectedSegment(canvas, cx, cy, bodyRadius, i);
      } else if (isBlindMemoryMode && bodyAlpha <= 0.05) {
        // Extremely faint 0.5% ghost echo stealth rendering
        final ghostFillPaint = Paint()
          ..color = const Color(0xFFD500F9).withValues(alpha: 0.005);
        canvas.drawCircle(Offset(cx, cy), bodyRadius, ghostFillPaint);

        final ghostRingPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.01)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), bodyRadius * 0.85, ghostRingPaint);
      } else {
        final color = activeSkin.getColorAt(t);
        SnakeGamePaints.snakeGlowPaint.color = activeSkin.glowColor.withValues(
          alpha: 0.2 * bodyAlpha,
        );
        canvas.drawCircle(
          Offset(cx, cy),
          bodyRadius * 1.3,
          SnakeGamePaints.snakeGlowPaint,
        );

        SnakeGamePaints.snakeBodyPaint.color = color.withValues(
          alpha: bodyAlpha,
        );
        canvas.drawCircle(
          Offset(cx, cy),
          bodyRadius,
          SnakeGamePaints.snakeBodyPaint,
        );

        if (bodyAlpha > 0.3) {
          canvas.drawCircle(
            Offset(cx - bodyRadius * 0.2, cy - bodyRadius * 0.2),
            bodyRadius * 0.35,
            SnakeGamePaints.snakeShinePaint,
          );
        }
      }
    }

    if (segmentCount > 0) {
      final headVisualPos = game.snake.getInterpolatedPosition(
        0,
        interpolationT,
        cellSize,
        cellSize,
      );

      // Add sick jitter vibration if infection > 40%
      double jitterX = 0;
      double jitterY = 0;
      if (isInfectedMode && game.snake.infectionRatio > 0.4) {
        final t = game.gameTime * 20.0;
        final intensity = (game.snake.infectionRatio - 0.4) * 3.5;
        jitterX = sin(t * 1.7) * intensity;
        jitterY = cos(t * 2.3) * intensity;
      }

      final hx = offsetX + headVisualPos.dx + jitterX;
      final hy = offsetY + headVisualPos.dy + jitterY;

      final isHeadInfected = isInfectedMode && game.snake.isHeadInfected;

      if (isHeadInfected) {
        drawInfectedSegment(canvas, hx, hy, headRadius, 0, isHead: true);
      } else if (isBlindMemoryMode) {
        // Head is a luminous guide with electric storm glow in the dark
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius * 2.2,
          SnakeGamePaints.blindMemoryOuterGlowPaint,
        );
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius * 1.5,
          SnakeGamePaints.blindMemoryMidGlowPaint,
        );

        SnakeGamePaints.snakeHeadPaint.shader = ui.Gradient.radial(
          Offset(hx, hy),
          headRadius,
          const [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF0091EA)],
          const [0.0, 0.55, 1.0],
        );
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius,
          SnakeGamePaints.snakeHeadPaint,
        );
      }

      if (game.gameMode.value == GameMode.casual &&
          game.casualPowerUp.hasActivePowerUp) {
        final powerUpColor = game.casualPowerUp.activePowerUp!.color;
        final auraPaint = Paint()
          ..color = powerUpColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(hx, hy), headRadius * 1.6, auraPaint);
      } else {
        SnakeGamePaints.snakeHeadGlowPaint.color =
            isInfectedMode && game.snake.infectionRatio > 0.5
                ? const Color(0xFFFF1744).withValues(alpha: 0.4)
                : activeSkin.glowColor.withValues(alpha: 0.3);
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius * 1.5,
          SnakeGamePaints.snakeHeadGlowPaint,
        );

        final headColor1 = isInfectedMode && game.snake.infectionRatio > 0.5
            ? const Color(0xFFD50000)
            : activeSkin.headColor;
        final headColor2 = activeSkin.getColorAt(0.2);

        SnakeGamePaints.snakeHeadPaint.shader = ui.Gradient.radial(
          Offset(hx, hy),
          headRadius,
          [headColor1, headColor2],
          const [0.0, 0.85],
        );
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius,
          SnakeGamePaints.snakeHeadPaint,
        );
      }

      drawEyes(
        canvas,
        hx,
        hy,
        headRadius,
        isSick:
            isInfectedMode &&
            (game.snake.infectionRatio > 0.25 || isHeadInfected),
      );
    }
  }

  void drawEyes(
    Canvas canvas,
    double cx,
    double cy,
    double headRadius, {
    bool isSick = false,
  }) {
    final eyeRadius = headRadius * 0.23;
    final pupilRadius = eyeRadius * 0.55;
    final offset = headRadius * 0.38;

    final pupilPaint = isSick
        ? SnakeGamePaints.infectedEyePupilPaint
        : SnakeGamePaints.eyePupilPaint;

    canvas.drawCircle(
      Offset(cx - offset, cy - offset * 0.8),
      eyeRadius,
      SnakeGamePaints.eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(cx - offset, cy - offset * 0.8),
      pupilRadius,
      pupilPaint,
    );

    canvas.drawCircle(
      Offset(cx + offset, cy - offset * 0.8),
      eyeRadius,
      SnakeGamePaints.eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(cx + offset, cy - offset * 0.8),
      pupilRadius,
      pupilPaint,
    );
  }

  /// Ultra-performant Fossil / Skeletal Vertebra infected snake segment renderer.
  /// Uses pre-allocated static paints with zero runtime GC overhead for steady 60/120fps.
  void drawInfectedSegment(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    int index, {
    bool isHead = false,
  }) {
    if (isHead) {
      // --- FOSSIL SKULL (HEAD) ---
      // 1. Dark background skull drop-shadow
      canvas.drawCircle(
        Offset(cx + 1.0, cy + 1.5),
        radius * 1.05,
        SnakeGamePaints.fossilShadowPaint,
      );

      // 2. Base weathered bone cranium
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 1.02,
        SnakeGamePaints.fossilBoneDarkPaint,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.94,
        SnakeGamePaints.fossilBoneMainPaint,
      );

      // 3. Cranial highlight crest
      canvas.drawCircle(
        Offset(cx - radius * 0.22, cy - radius * 0.25),
        radius * 0.38,
        SnakeGamePaints.fossilBoneLightPaint,
      );

      // 4. Skull outer bone rim
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.94,
        SnakeGamePaints.fossilBoneRimPaint,
      );

      // 5. Skull bone suture / cranial fracture line
      canvas.drawLine(
        Offset(cx - radius * 0.5, cy - radius * 0.1),
        Offset(cx + radius * 0.4, cy + radius * 0.3),
        SnakeGamePaints.fossilCrackPaint,
      );

      // 6. Deep hollow eye sockets with eerie glowing core
      final eyeOffset = radius * 0.38;
      final socketRadius = radius * 0.28;
      final pupilRadius = radius * 0.11;

      // Left eye socket
      final leftSocket = Offset(cx - eyeOffset, cy - eyeOffset * 0.6);
      canvas.drawCircle(
        leftSocket,
        socketRadius,
        SnakeGamePaints.fossilSpinalHolePaint,
      );
      SnakeGamePaints.fossilMarrowPulsePaint.color = const Color(
        0xFF76FF03,
      ).withValues(alpha: 0.85 + 0.15 * sin(game.gameTime * 6.0));
      canvas.drawCircle(
        leftSocket,
        pupilRadius,
        SnakeGamePaints.fossilMarrowPulsePaint,
      );

      // Right eye socket
      final rightSocket = Offset(cx + eyeOffset, cy - eyeOffset * 0.6);
      canvas.drawCircle(
        rightSocket,
        socketRadius,
        SnakeGamePaints.fossilSpinalHolePaint,
      );
      canvas.drawCircle(
        rightSocket,
        pupilRadius,
        SnakeGamePaints.fossilMarrowPulsePaint,
      );

      // 7. Nasal fossil hollow
      canvas.drawCircle(
        Offset(cx, cy + radius * 0.18),
        radius * 0.14,
        SnakeGamePaints.fossilSpinalHolePaint,
      );
    } else {
      // --- FOSSIL VERTEBRA (BODY SEGMENT) ---
      // 1. Lateral Skeletal Ribs / Bone Spurs (4 Symmetrical spurs)
      final ribAngle = (index * 0.4);
      final rCos = cos(ribAngle);
      final rSin = sin(ribAngle);
      final spurExt = radius * 1.35;
      final spurIn = radius * 0.55;

      // Primary rib pair
      canvas.drawLine(
        Offset(cx - rCos * spurIn, cy - rSin * spurIn),
        Offset(cx - rCos * spurExt, cy - rSin * spurExt),
        SnakeGamePaints.fossilRibPaint,
      );
      canvas.drawLine(
        Offset(cx + rCos * spurIn, cy + rSin * spurIn),
        Offset(cx + rCos * spurExt, cy + rSin * spurExt),
        SnakeGamePaints.fossilRibPaint,
      );

      // Secondary transverse process pair (perpendicular)
      canvas.drawLine(
        Offset(cx + rSin * (spurIn * 0.8), cy - rCos * (spurIn * 0.8)),
        Offset(cx + rSin * (spurExt * 0.85), cy - rCos * (spurExt * 0.85)),
        SnakeGamePaints.fossilRibPaint,
      );
      canvas.drawLine(
        Offset(cx - rSin * (spurIn * 0.8), cy + rCos * (spurIn * 0.8)),
        Offset(cx - rSin * (spurExt * 0.85), cy + rCos * (spurExt * 0.85)),
        SnakeGamePaints.fossilRibPaint,
      );

      // 2. Drop shadow under vertebra
      canvas.drawCircle(
        Offset(cx + 0.8, cy + 1.2),
        radius * 0.95,
        SnakeGamePaints.fossilShadowPaint,
      );

      // 3. Ancient Fossilized Bone Disk (Centrum)
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.96,
        SnakeGamePaints.fossilBoneDarkPaint,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.86,
        SnakeGamePaints.fossilBoneMainPaint,
      );

      // 4. Bone light bevel & highlight
      canvas.drawCircle(
        Offset(cx - radius * 0.2, cy - radius * 0.22),
        radius * 0.32,
        SnakeGamePaints.fossilBoneLightPaint,
      );

      // 5. Outer bone rim line
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.86,
        SnakeGamePaints.fossilBoneRimPaint,
      );

      // 6. Central Neural Canal / Spinal Marrow Cavity (Dark hollow)
      final canalRadius = radius * 0.34;
      canvas.drawCircle(
        Offset(cx, cy),
        canalRadius,
        SnakeGamePaints.fossilSpinalHolePaint,
      );

      // 7. Eerie toxic marrow luminescence inside spinal cavity (minimal pulse)
      final pulse = sin(game.gameTime * 4.0 + index * 0.7) * 0.5 + 0.5;
      SnakeGamePaints.fossilMarrowPulsePaint.color = const Color(
        0xFF76FF03,
      ).withValues(alpha: 0.4 + 0.45 * pulse);
      canvas.drawCircle(
        Offset(cx, cy),
        canalRadius * 0.55,
        SnakeGamePaints.fossilMarrowPulsePaint,
      );

      // 8. Natural bone fissure / seam crack
      final crackAngle = ribAngle + 0.6;
      canvas.drawLine(
        Offset(
          cx + cos(crackAngle) * (canalRadius * 0.9),
          cy + sin(crackAngle) * (canalRadius * 0.9),
        ),
        Offset(
          cx + cos(crackAngle) * (radius * 0.78),
          cy + sin(crackAngle) * (radius * 0.78),
        ),
        SnakeGamePaints.fossilCrackPaint,
      );
    }
  }

  /// Dynamic Fog of War & Vision Decay overlay for Infection Mode (clipped to game board).
  void drawInfectionFogOfWar(Canvas canvas) {
    if (game.gameMode.value != GameMode.infection) return;
    if (!game.parasiteAttached && game.snake.infectedSegmentCount == 0) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;
    final gridCols = game.gridCols;
    final gridRows = game.gridRows;

    final boardRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      gridCols * cellSize,
      gridRows * cellSize,
    );

    final ratio = game.snake.infectionRatio;
    final moveInterval = game.effectiveMoveInterval;
    final double interpolationT = moveInterval > 0
        ? (game.moveAccumulator / moveInterval).clamp(0.0, 1.0)
        : 1.0;
    final headVisualPos = game.snake.getInterpolatedPosition(
      0,
      interpolationT,
      cellSize,
      cellSize,
    );
    final hx = offsetX + headVisualPos.dx;
    final hy = offsetY + headVisualPos.dy;

    final boardSide = min(gridCols * cellSize, gridRows * cellSize);

    // Non-linear vision decay curve relative to game board size:
    // 0.0 - 0.30: 1.1 * boardSide (clear vision)
    // 0.30 - 0.60: 1.1 -> 0.55 * boardSide (gradually shrinking)
    // 0.60 - 0.80: 0.55 -> 0.30 * boardSide (rapidly shrinking)
    // 0.80 - 1.00: 0.30 -> 0.15 * boardSide (extreme narrow spotlight)
    double visionRadiusMultiplier;
    if (ratio <= 0.30) {
      visionRadiusMultiplier = 1.1;
    } else if (ratio <= 0.60) {
      final t = (ratio - 0.30) / 0.30;
      visionRadiusMultiplier = 1.1 - t * 0.55;
    } else if (ratio <= 0.80) {
      final t = (ratio - 0.60) / 0.20;
      visionRadiusMultiplier = 0.55 - t * 0.25;
    } else {
      final t = (ratio - 0.80) / 0.20;
      visionRadiusMultiplier = 0.30 - t * 0.15;
    }

    final radius = max(cellSize * 1.5, boardSide * visionRadiusMultiplier);

    canvas.save();
    canvas.clipRect(boardRect);

    // Dark path with circular vision cut-out at snake head within boardRect
    final fogPath = Path()
      ..addRect(boardRect)
      ..addOval(Rect.fromCircle(center: Offset(hx, hy), radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(fogPath, SnakeGamePaints.fogPaint);

    // Soft gradient transition edge
    SnakeGamePaints.fogSoftGradientPaint.shader = ui.Gradient.radial(
      Offset(hx, hy),
      radius,
      const [Color(0x00000000), Color(0x9905070A), Color(0xFB05070A)],
      const [0.60, 0.88, 1.0],
    );
    canvas.drawCircle(Offset(hx, hy), radius, SnakeGamePaints.fogSoftGradientPaint);

    // Red pulsating vignette border when infection is severe (>65%)
    if (ratio > 0.65) {
      final pulseTime = game.gameTime * 2.5;
      final redAlpha = (0.2 + 0.25 * sin(pulseTime)).clamp(0.0, 0.5);
      SnakeGamePaints.fogVignettePaint.shader = ui.Gradient.radial(
        Offset(offsetX + boardSide / 2, offsetY + boardSide / 2),
        boardSide * 0.75,
        [
          const Color(0x00000000),
          Color(0xFFFF1744).withValues(alpha: redAlpha * 0.4),
          Color(0xFFFF1744).withValues(alpha: redAlpha),
        ],
        const [0.4, 0.8, 1.0],
      );
      canvas.drawRect(boardRect, SnakeGamePaints.fogVignettePaint);
    }

    canvas.restore();
  }

  void drawStormAndRain(Canvas canvas) {
    if (game.gameMode.value != GameMode.blindMemory) return;

    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final cellSize = game.cellSize;
    final gridCols = game.gridCols;
    final gridRows = game.gridRows;

    final boardRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      gridCols * cellSize,
      gridRows * cellSize,
    );

    canvas.save();
    canvas.clipRect(boardRect);

    // 1. Dark stormy ambient tint over the board (clears during lightning)
    final double tintAlpha = game.isFlashActive.value ? 0.0 : 0.40;
    SnakeGamePaints.stormTintPaint.color = const Color(
      0xFF020617,
    ).withValues(alpha: tintAlpha);
    canvas.drawRect(boardRect, SnakeGamePaints.stormTintPaint);

    // 2. Falling Raindrops
    final boardW = gridCols * cellSize;
    final boardH = gridRows * cellSize;

    for (final drop in game.rainDrops) {
      final startX = offsetX + drop.x * boardW;
      final startY = offsetY + drop.y * boardH;
      final endX = startX - drop.length * 0.22;
      final endY = startY + drop.length;

      SnakeGamePaints.rainDropPaint.color = Colors.white.withValues(
        alpha: drop.alpha,
      );
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        SnakeGamePaints.rainDropPaint,
      );
    }

    // 3. Lightning Electric Bolts & Flash Overlay
    if (game.isFlashActive.value) {
      final flashProg = (game.flashTimer - 3.2).clamp(0.0, 1.0);
      final flicker = (sin(flashProg * pi * 8).abs() * 0.5 + 0.5) * flashProg;

      // Ambient screen flash glow (pure white)
      SnakeGamePaints.lightningFlashGlowPaint.color = Colors.white.withValues(
        alpha: (flicker * 0.45).clamp(0.0, 0.45),
      );
      canvas.drawRect(boardRect, SnakeGamePaints.lightningFlashGlowPaint);

      SnakeGamePaints.lightningFlashCorePaint.color = Colors.white.withValues(
        alpha: (flicker * 0.25).clamp(0.0, 0.25),
      );
      canvas.drawRect(boardRect, SnakeGamePaints.lightningFlashCorePaint);

      // Draw Jagged Lightning Bolts (pure white outer glow, mid glow and core)
      SnakeGamePaints.lightningOuterGlowPaint.color = Colors.white.withValues(
        alpha: (flicker * 0.85).clamp(0.0, 0.85),
      );

      SnakeGamePaints.lightningMidGlowPaint.color = Colors.white.withValues(
        alpha: (flicker * 0.95).clamp(0.0, 0.95),
      );

      SnakeGamePaints.lightningCoreBoltPaint.color = Colors.white.withValues(
        alpha: (flicker * 1.0).clamp(0.0, 1.0),
      );

      for (final branch in game.lightningBranches) {
        if (branch.length >= 2) {
          canvas.drawLine(
            branch[0],
            branch[1],
            SnakeGamePaints.lightningOuterGlowPaint,
          );
          canvas.drawLine(
            branch[0],
            branch[1],
            SnakeGamePaints.lightningMidGlowPaint,
          );
          canvas.drawLine(
            branch[0],
            branch[1],
            SnakeGamePaints.lightningCoreBoltPaint,
          );
        }
      }
    }

    canvas.restore();
  }
}
