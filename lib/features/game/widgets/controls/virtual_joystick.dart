import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/utils/enums.dart';
import '../../../settings/controllers/settings_controller.dart';
import '../../controllers/game_controller.dart';

/// Virtual Hybrid 4-Way Directional Joystick widget placed below the game board.
class VirtualJoystickWidget extends StatelessWidget {
  final GameController controller;
  const VirtualJoystickWidget({super.key, required this.controller});

  Color _getModeAccentColor(GameMode mode) {
    switch (mode) {
      case GameMode.infection:
        return const Color(0xFFFF1744); // Neon Crimson
      case GameMode.blindMemory:
        return const Color(0xFFD500F9); // Neon Electric Purple
      case GameMode.level:
        return kGoldColor; // Cyber Gold
      case GameMode.laser:
        return const Color(0xFFFF9100); // Neon Plasma Orange
      case GameMode.meltdown:
        return const Color(0xFFC6FF00); // Neon Radioactive Lime
      case GameMode.crabChase:
        return const Color(0xFF00E5FF); // Electric Cyan
      case GameMode.casual:
        return const Color(0xFFA855F7); // Vibrant Fantasy Purple
      case GameMode.classic:
      case GameMode.custom:
        return const Color(0xFF00E676); // Cyber Emerald Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final isEnabled = settingsController.showJoystickEnabled.value;
      if (!isEnabled) return const SizedBox(height: 8);

      final accentColor = _getModeAccentColor(controller.gameMode.value);

      return Padding(
        padding: const EdgeInsets.only(bottom: 22, top: 2),
        child: Directional4WayJoystick(
          size: 146,
          accentColor: accentColor,
          onDirectionChanged: (dir) => controller.changeDirection(dir),
        ),
      );
    });
  }
}

/// Cyberpunk & Modern Neon 4-Way Directional Joystick widget.
class Directional4WayJoystick extends StatefulWidget {
  final Function(Direction) onDirectionChanged;
  final double size;
  final Color accentColor;

  const Directional4WayJoystick({
    super.key,
    required this.onDirectionChanged,
    this.size = 146.0,
    this.accentColor = kPrimaryColor,
  });

  @override
  State<Directional4WayJoystick> createState() =>
      _Directional4WayJoystickState();
}

class _Directional4WayJoystickState extends State<Directional4WayJoystick> {
  Offset _knobOffset = Offset.zero;
  Direction? _activeDirection;

  void _updatePosition(Offset localPosition) {
    final radius = widget.size / 2;
    final center = Offset(radius, radius);
    final delta = localPosition - center;

    final maxDistance = radius * 0.46;
    final distance = delta.distance;

    if (distance < 5.0) {
      setState(() {
        _knobOffset = Offset.zero;
        _activeDirection = null;
      });
      return;
    }

    final angle = atan2(delta.dy, delta.dx);
    Direction newDir;
    Offset axisOffset;

    if (angle >= -3 * pi / 4 && angle < -pi / 4) {
      newDir = Direction.up;
      axisOffset = Offset(0, -maxDistance);
    } else if (angle >= pi / 4 && angle < 3 * pi / 4) {
      newDir = Direction.down;
      axisOffset = Offset(0, maxDistance);
    } else if (angle >= -pi / 4 && angle < pi / 4) {
      newDir = Direction.right;
      axisOffset = Offset(maxDistance, 0);
    } else {
      newDir = Direction.left;
      axisOffset = Offset(-maxDistance, 0);
    }

    setState(() {
      _knobOffset = axisOffset;
      if (newDir != _activeDirection) {
        _activeDirection = newDir;
        HapticFeedback.selectionClick();
        widget.onDirectionChanged(newDir);
      }
    });
  }

  void _resetPosition() {
    setState(() {
      _knobOffset = Offset.zero;
      _activeDirection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final knobSize = size * 0.40;
    final accent = widget.accentColor;

    return GestureDetector(
      onPanStart: (details) => _updatePosition(details.localPosition),
      onPanUpdate: (details) => _updatePosition(details.localPosition),
      onPanEnd: (_) => _resetPosition(),
      onPanCancel: () => _resetPosition(),
      onTapDown: (details) => _updatePosition(details.localPosition),
      onTapUp: (_) => _resetPosition(),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ultra-Subtle Translucent Frosted Glass Base
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),

            // Subtle Cyber HUD Base
            CustomPaint(
              size: Size(size, size),
              painter: _JoystickBasePainter(
                activeDirection: _activeDirection,
                accentColor: accent,
              ),
            ),

            // UP Indicator
            Positioned(
              top: 8,
              child: AnimatedScale(
                scale: _activeDirection == Direction.up ? 1.20 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 28,
                  color: _activeDirection == Direction.up
                      ? accent
                      : Colors.white.withValues(alpha: 0.28),
                  shadows: _activeDirection == Direction.up
                      ? [
                          Shadow(
                            color: accent.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),

            // DOWN Indicator
            Positioned(
              bottom: 8,
              child: AnimatedScale(
                scale: _activeDirection == Direction.down ? 1.20 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 28,
                  color: _activeDirection == Direction.down
                      ? accent
                      : Colors.white.withValues(alpha: 0.28),
                  shadows: _activeDirection == Direction.down
                      ? [
                          Shadow(
                            color: accent.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),

            // LEFT Indicator
            Positioned(
              left: 8,
              child: AnimatedScale(
                scale: _activeDirection == Direction.left ? 1.20 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.keyboard_arrow_left_rounded,
                  size: 28,
                  color: _activeDirection == Direction.left
                      ? accent
                      : Colors.white.withValues(alpha: 0.28),
                  shadows: _activeDirection == Direction.left
                      ? [
                          Shadow(
                            color: accent.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),

            // RIGHT Indicator
            Positioned(
              right: 8,
              child: AnimatedScale(
                scale: _activeDirection == Direction.right ? 1.20 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.keyboard_arrow_right_rounded,
                  size: 28,
                  color: _activeDirection == Direction.right
                      ? accent
                      : Colors.white.withValues(alpha: 0.28),
                  shadows: _activeDirection == Direction.right
                      ? [
                          Shadow(
                            color: accent.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),

            // Central Translucent Thumbstick Knob
            AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(
                _knobOffset.dx,
                _knobOffset.dy,
                0,
              ),
              width: knobSize,
              height: knobSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _activeDirection != null
                      ? [
                          accent.withValues(alpha: 0.80),
                          const Color(0xFF1E293B).withValues(alpha: 0.65),
                          const Color(0xFF090D16).withValues(alpha: 0.70),
                        ]
                      : [
                          const Color(0xFF334155).withValues(alpha: 0.35),
                          const Color(0xFF1E293B).withValues(alpha: 0.40),
                          const Color(0xFF0F172A).withValues(alpha: 0.45),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: _activeDirection != null
                      ? accent.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.22),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: accent.withValues(
                      alpha: _activeDirection != null ? 0.45 : 0.0,
                    ),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: knobSize * 0.45,
                  height: knobSize * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _activeDirection != null
                        ? accent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: _activeDirection != null
                          ? accent.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.18),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _activeDirection != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: _activeDirection != null ? 0.9 : 0.0,
                            ),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoystickBasePainter extends CustomPainter {
  final Direction? activeDirection;
  final Color accentColor;

  _JoystickBasePainter({
    required this.activeDirection,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw outer subtle translucent circle base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0F172A).withValues(alpha: 0.15),
          const Color(0xFF090D16).withValues(alpha: 0.22),
          const Color(0xFF05080E).withValues(alpha: 0.30),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, bgPaint);

    // 2. Inner concentric HUD tech ring
    final innerTrackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.65, innerTrackPaint);

    // 3. Draw active neon beam & glow if active
    if (activeDirection != null) {
      double startAngle;
      switch (activeDirection!) {
        case Direction.up:
          startAngle = -3 * pi / 4;
          break;
        case Direction.down:
          startAngle = pi / 4;
          break;
        case Direction.right:
          startAngle = -pi / 4;
          break;
        case Direction.left:
          startAngle = 3 * pi / 4;
          break;
      }

      // Conical energy gradient sector
      final activeSectorPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            accentColor.withValues(alpha: 0.30),
            accentColor.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          stops: const [0.2, 0.7, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, pi / 2, true, activeSectorPaint);

      // Active rim glow arc
      final rimGlowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.65)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.5),
        startAngle + 0.05,
        (pi / 2) - 0.1,
        false,
        rimGlowPaint,
      );
    }

    // 4. Draw 4 diagonal tech dividing lines
    final linePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final innerRadius = radius * 0.36;
    for (int i = 0; i < 4; i++) {
      final angle = (pi / 4) + (i * pi / 2);
      final p1 = Offset(
        center.dx + cos(angle) * innerRadius,
        center.dy + sin(angle) * innerRadius,
      );
      final p2 = Offset(
        center.dx + cos(angle) * (radius - 2),
        center.dy + sin(angle) * (radius - 2),
      );
      canvas.drawLine(p1, p2, linePaint);
    }

    // 5. Draw 4 futuristic corner notches / tick marks along outer rim
    final notchPaint = Paint()
      ..color = activeDirection != null
          ? accentColor.withValues(alpha: 0.5)
          : const Color(0xFF64748B).withValues(alpha: 0.22)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final angle = (pi / 4) + (i * pi / 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        angle - 0.12,
        0.24,
        false,
        notchPaint,
      );
    }

    // 6. Draw outer border ring with neon glow
    final borderPaint = Paint()
      ..color = activeDirection != null
          ? accentColor.withValues(alpha: 0.6)
          : const Color(0xFF64748B).withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickBasePainter oldDelegate) {
    return oldDelegate.activeDirection != activeDirection ||
        oldDelegate.accentColor != accentColor;
  }
}
