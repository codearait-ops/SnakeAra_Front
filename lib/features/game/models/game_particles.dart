import 'package:flutter/material.dart';
import '../../../app/core/constants/app_constants.dart';

class ExplosionEffect {
  final GridPos position;
  double life;
  final double maxLife;
  ExplosionEffect(this.position, this.life, this.maxLife);
}

/// Projectile bullet data structure used in Boss 5 (The Overlord).
class BossBullet {
  double x;
  double y;
  final double vx;
  final double vy;

  BossBullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

/// Floating text particle for animated score popups (+10, -1, etc.)
class FloatingTextParticle {
  String text;
  double x;
  double y;
  double vy;
  Color color;
  double life;
  double maxLife;
  TextPainter? painter;

  FloatingTextParticle({
    required this.text,
    required this.x,
    required this.y,
    this.vy = -1.5,
    required this.color,
    this.life = 0.0,
    this.maxLife = 1.1,
    this.painter,
  });
}

/// Represents a disintegrating particle spawned when a laser cuts the snake.
class SlicedParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double life;
  double maxLife;

  SlicedParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    this.life = 0.0,
    this.maxLife = 0.5,
  });
}

/// Represents a falling raindrop particle in Storm / Blind Memory mode.
class RainDrop {
  double x;
  double y;
  double speed;
  double length;
  double alpha;

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.alpha,
  });
}
