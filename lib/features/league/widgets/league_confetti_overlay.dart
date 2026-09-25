import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Types of confetti particles
enum _ConfettiShape {
  ribbon,
  circle,
  diamond,
}

class _ConfettiParticle {
  final double startX; // Normalized initial X (0.0 to 1.0)
  final double startY; // Initial Y in pixels (-25 to 5)
  final double vx; // Initial horizontal velocity in px/s
  final double vy0; // Initial vertical velocity in px/s
  final double vTerm; // Terminal downward fall speed in px/s
  final double dragK; // Aerodynamic drag coefficient
  final double delay; // Staggered launch delay in seconds (0.0 to 0.45s)
  final double size; // Base dimension
  final double aspectRatio; // Width-to-height ratio (ribbons vs dots)
  final Color color;
  final _ConfettiShape shape;
  final double swayFreq; // Oscillation frequency in rad/s
  final double swayAmp; // Oscillation amplitude in px
  final double rotSpeed; // 2D rotation rate in rad/s
  final double tumbleSpeed; // 3D flip rate in rad/s
  final double phase; // Random initial phase angle

  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy0,
    required this.vTerm,
    required this.dragK,
    required this.delay,
    required this.size,
    required this.aspectRatio,
    required this.color,
    required this.shape,
    required this.swayFreq,
    required this.swayAmp,
    required this.rotSpeed,
    required this.tumbleSpeed,
    required this.phase,
  });
}

/// A high-performance, single-burst Confetti Effect overlay designed for League
/// championship celebrations, podium victories, and promotion screens.
/// Fires realistic dual-cannon fountain bursts with authentic aerodynamic drag,
/// wide organic dispersion, and smooth 3D tumbling before fading out.
class LeagueConfettiOverlay extends StatefulWidget {
  final int particleCount;
  final Duration duration;

  const LeagueConfettiOverlay({
    super.key,
    this.particleCount = 95,
    this.duration = const Duration(milliseconds: 4800),
  });

  @override
  State<LeagueConfettiOverlay> createState() => _LeagueConfettiOverlayState();
}

class _LeagueConfettiOverlayState extends State<LeagueConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  static const List<Color> _palette = [
    Color(0xFFFFD700), // Pure Gold
    Color(0xFFFFC107), // Amber Gold
    Color(0xFFFF9100), // Bright Orange
    Color(0xFF00E676), // Emerald Green
    Color(0xFF00E5FF), // Electric Cyan
    Color(0xFFFF4081), // Neon Pink
    Color(0xFFE040FB), // Magenta
    Color(0xFF7C4DFF), // Royal Violet
    Color(0xFFFFFFFF), // Sparkle White
    Color(0xFFECEFF1), // Metallic Silver
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();

    _particles = List.generate(widget.particleCount, (index) {
      final shapeIndex = rng.nextInt(10);
      final shape = shapeIndex < 5
          ? _ConfettiShape.ribbon
          : (shapeIndex < 8 ? _ConfettiShape.diamond : _ConfettiShape.circle);

      // Distribute particles across 3 launch zones:
      // 0: Left cannon (arcs up & right)
      // 1: Right cannon (arcs up & left)
      // 2: Center blast (arcs outward)
      final cannon = rng.nextInt(3);
      double startX;
      double vx;
      double vy0;

      if (cannon == 0) {
        // Left cannon: fires toward center-right
        startX = rng.nextDouble() * 0.15;
        vx = 140.0 + rng.nextDouble() * 240.0;
        vy0 = -70.0 - rng.nextDouble() * 110.0;
      } else if (cannon == 1) {
        // Right cannon: fires toward center-left
        startX = 0.85 + rng.nextDouble() * 0.15;
        vx = -140.0 - rng.nextDouble() * 240.0;
        vy0 = -70.0 - rng.nextDouble() * 110.0;
      } else {
        // Center spread: wide fountain fan
        startX = 0.25 + rng.nextDouble() * 0.50;
        vx = (rng.nextDouble() - 0.5) * 260.0;
        vy0 = -50.0 + rng.nextDouble() * 90.0;
      }

      return _ConfettiParticle(
        startX: startX,
        startY: -20.0 + rng.nextDouble() * 15.0,
        vx: vx,
        vy0: vy0,
        vTerm: 170.0 + rng.nextDouble() * 220.0,
        dragK: 0.95 + rng.nextDouble() * 0.55,
        delay: rng.nextDouble() * 0.45,
        size: shape == _ConfettiShape.circle
            ? 5.0 + rng.nextDouble() * 4.0
            : (shape == _ConfettiShape.diamond
                ? 7.0 + rng.nextDouble() * 5.0
                : 7.5 + rng.nextDouble() * 5.5),
        aspectRatio: shape == _ConfettiShape.ribbon
            ? 1.9 + rng.nextDouble() * 1.5
            : 1.0,
        color: _palette[rng.nextInt(_palette.length)],
        shape: shape,
        swayFreq: 2.5 + rng.nextDouble() * 3.5,
        swayAmp: 16.0 + rng.nextDouble() * 26.0,
        rotSpeed: (rng.nextBool() ? 1.0 : -1.0) * (2.0 + rng.nextDouble() * 4.0),
        tumbleSpeed: 3.0 + rng.nextDouble() * 5.0,
        phase: rng.nextDouble() * math.pi * 2,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isCompleted) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              size: Size.infinite,
              painter: _LeagueConfettiPainter(
                timeSeconds: _controller.value * (widget.duration.inMilliseconds / 1000.0),
                totalDurationSeconds: widget.duration.inMilliseconds / 1000.0,
                particles: _particles,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeagueConfettiPainter extends CustomPainter {
  final double timeSeconds;
  final double totalDurationSeconds;
  final List<_ConfettiParticle> particles;

  _LeagueConfettiPainter({
    required this.timeSeconds,
    required this.totalDurationSeconds,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (timeSeconds >= totalDurationSeconds) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (timeSeconds < p.delay) continue;

      final tau = timeSeconds - p.delay;
      final decay = 1.0 - math.exp(-p.dragK * tau);

      // Aerodynamic projectile trajectories with drag & terminal velocity
      final xBase = (p.startX * size.width) + (p.vx * decay / p.dragK);
      final y = p.startY + (p.vTerm * tau) + (((p.vy0 - p.vTerm) / p.dragK) * decay);

      // Off-screen culling
      if (y < -80 || y > size.height + 60) continue;

      // Sinusoidal wind sway
      final sway = math.sin(tau * p.swayFreq + p.phase) * p.swayAmp;
      final x = xBase + sway;

      // Smooth opacity fading
      double alpha = 1.0;
      if (tau < 0.15) {
        alpha = (tau / 0.15).clamp(0.0, 1.0);
      } else if (y > size.height - 100) {
        final dist = (y - (size.height - 100)) / 140.0;
        alpha = (1.0 - dist).clamp(0.0, 1.0);
      }

      final remainingTime = totalDurationSeconds - timeSeconds;
      if (remainingTime < 0.6) {
        alpha = math.min(alpha, (remainingTime / 0.6).clamp(0.0, 1.0));
      }

      if (alpha <= 0.01) continue;

      paint.color = p.color.withValues(alpha: alpha);

      // 3D tumbling & 2D spin
      final tumble = math.cos(tau * p.tumbleSpeed + p.phase);
      final spin = tau * p.rotSpeed + p.phase;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.scale(tumble, 1.0);

      final w = p.size;
      final h = p.size * p.aspectRatio;

      switch (p.shape) {
        case _ConfettiShape.ribbon:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: w, height: h),
              const Radius.circular(2.0),
            ),
            paint,
          );
          break;

        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, w / 2, paint);
          break;

        case _ConfettiShape.diamond:
          final path = Path()
            ..moveTo(0, -h / 2)
            ..lineTo(w / 2, 0)
            ..lineTo(0, h / 2)
            ..lineTo(-w / 2, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeagueConfettiPainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds;
  }
}
