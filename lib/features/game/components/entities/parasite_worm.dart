import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_particles.dart';

/// Dynamic, fast-moving parasite worm that swoops in from off-screen in Infection Mode.
class ParasiteWorm {
  double headX;
  double headY;
  final List<Offset> _bodyNodes = [];
  final List<SlicedParticle> trailParticles = [];
  double speed = 1400.0; // Fast invasion speed
  bool hasReachedTarget = false;
  double _timeAlive = 0.0;
  final double cellSize;

  ParasiteWorm({
    required this.headX,
    required this.headY,
    required this.cellSize,
  }) {
    for (int i = 0; i < 6; i++) {
      _bodyNodes.add(Offset(headX, headY));
    }
  }

  void update(double dt, Offset targetPos) {
    _timeAlive += dt;
    final dx = targetPos.dx - headX;
    final dy = targetPos.dy - headY;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < cellSize * 0.6 || _timeAlive > 1.2) {
      headX = targetPos.dx;
      headY = targetPos.dy;
      hasReachedTarget = true;
      return;
    }

    final dirX = dx / dist;
    final dirY = dy / dist;
    final step = min(speed * dt, dist);

    headX += dirX * step;
    headY += dirY * step;

    // Update body node chain with wriggling sine wave motion
    final angle = atan2(dy, dx);
    final perpX = -sin(angle);
    final perpY = cos(angle);

    _bodyNodes[0] = Offset(headX, headY);
    for (int i = 1; i < _bodyNodes.length; i++) {
      final prev = _bodyNodes[i - 1];
      final current = _bodyNodes[i];
      final segmentDist = (current - prev).distance;
      final targetSpacing = cellSize * 0.26;

      Offset nextPos;
      if (segmentDist > targetSpacing) {
        final ndx = (current.dx - prev.dx) / segmentDist;
        final ndy = (current.dy - prev.dy) / segmentDist;
        nextPos = Offset(
          prev.dx + ndx * targetSpacing,
          prev.dy + ndy * targetSpacing,
        );
      } else {
        nextPos = current;
      }

      // Add undulating wriggle wave
      final wriggle = sin(_timeAlive * 32.0 - i * 0.9) * (cellSize * 0.2);
      _bodyNodes[i] = Offset(
        nextPos.dx + perpX * wriggle * 0.45,
        nextPos.dy + perpY * wriggle * 0.45,
      );
    }

    // Spawn toxic particle trail behind worm
    if (Random().nextDouble() < 0.7) {
      trailParticles.add(
        SlicedParticle(
          x: headX + (Random().nextDouble() - 0.5) * cellSize * 0.4,
          y: headY + (Random().nextDouble() - 0.5) * cellSize * 0.4,
          vx: (Random().nextDouble() - 0.5) * 60 - dirX * 120,
          vy: (Random().nextDouble() - 0.5) * 60 - dirY * 120,
          radius: cellSize * 0.12,
          color: Random().nextBool()
              ? const Color(0xFF00E676)
              : const Color(0xFFE040FB),
          life: 0.0,
          maxLife: 0.35,
        ),
      );
    }

    // Update particle trail
    for (int i = trailParticles.length - 1; i >= 0; i--) {
      final p = trailParticles[i];
      p.life += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.life >= p.maxLife) {
        trailParticles.removeAt(i);
      }
    }
  }

  void render(Canvas canvas) {
    // Render toxic smoke trail
    for (final p in trailParticles) {
      final alpha = (1.0 - (p.life / p.maxLife)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }

    if (_bodyNodes.isEmpty) return;

    // Outer toxic bio-aura
    for (int i = _bodyNodes.length - 1; i >= 0; i--) {
      final node = _bodyNodes[i];
      final nodeRadius = cellSize * (0.36 - (i * 0.035));
      final glowPaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(node, nodeRadius * 1.5, glowPaint);
    }

    // Wriggling segmented body
    for (int i = _bodyNodes.length - 1; i >= 0; i--) {
      final node = _bodyNodes[i];
      final nodeRadius = cellSize * (0.30 - (i * 0.03));
      final t = i / _bodyNodes.length;
      final bodyColor = Color.lerp(
        const Color(0xFF00E676), // Neon toxic green
        const Color(0xFF7C4DFF), // Alien violet
        t,
      )!;
      final bodyPaint = Paint()..color = bodyColor;
      canvas.drawCircle(node, max(2.0, nodeRadius), bodyPaint);
    }

    // Glowing menacing parasite eyes on head
    final head = _bodyNodes.first;
    final eyePaint = Paint()..color = const Color(0xFFFF1744); // Neon red
    final eyeGlow = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(
      Offset(head.dx - cellSize * 0.09, head.dy - cellSize * 0.09),
      cellSize * 0.09,
      eyeGlow,
    );
    canvas.drawCircle(
      Offset(head.dx - cellSize * 0.09, head.dy - cellSize * 0.09),
      cellSize * 0.055,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(head.dx + cellSize * 0.09, head.dy - cellSize * 0.09),
      cellSize * 0.09,
      eyeGlow,
    );
    canvas.drawCircle(
      Offset(head.dx + cellSize * 0.09, head.dy - cellSize * 0.09),
      cellSize * 0.055,
      eyePaint,
    );
  }
}
