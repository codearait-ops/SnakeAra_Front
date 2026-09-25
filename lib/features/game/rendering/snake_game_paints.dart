import 'dart:ui';
import 'package:flutter/material.dart' show Color, PaintingStyle, StrokeCap, MaskFilter, BlurStyle;
import 'package:snake_game/app/core/constants/app_constants.dart';

/// Centralized static, reusable [Paint] allocations for SnakeGame and its sub-renderers.
/// Pre-allocating paints avoids allocation churn during 60/120fps render loops.
class SnakeGamePaints {
  SnakeGamePaints._();

  // --- Background Paints ---
  static final Paint bgFillPaint = Paint()..color = const Color(0xFF0D1117);
  static final Paint bgLightTilePaint = Paint()
    ..color = const Color(0xFF0F141E);
  static final Paint bgDarkTilePaint = Paint()
    ..color = const Color(0xFF0B101A);
  static final Paint bgBorderPaint = Paint()
    ..color = const Color(0xFF00E676)
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  // --- Obstacle Paints ---
  static final Paint obstacleFillPaint = Paint()..color = kObstacleColor;
  static final Paint obstacleBorderPaint = Paint()
    ..color = kObstacleBorderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint obstacleGlowPaint = Paint()
    ..color = kObstacleBorderColor.withValues(alpha: 0.25);

  // --- Food Paints ---
  static final Paint foodOuterGlowPaint = Paint()
    ..color = kFoodGlowColor.withValues(alpha: 0.2);
  static final Paint foodSecondaryGlowPaint = Paint()
    ..color = kFoodGlowColor.withValues(alpha: 0.1);
  static final Paint foodHighlightPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35);
  static final Paint foodSparklePaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
  static final Paint foodCenterPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5);
  static final Paint foodBodyPaint = Paint();

  // --- Bonus Pear Paints ---
  static final Paint pearOuterGlowPaint = Paint()
    ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25);
  static final Paint pearSecondaryGlowPaint = Paint()
    ..color = const Color(0xFFFFB300).withValues(alpha: 0.12);
  static final Paint pearStemPaint = Paint()
    ..color = const Color(0xFF5D4037)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final Paint pearLeafPaint = Paint()..color = const Color(0xFF4CAF50);
  static final Paint pearTimerBgPaint = Paint()
    ..color = const Color(0xFF1E293B).withValues(alpha: 0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final Paint pearTimerFgPaint = Paint()
    ..color = const Color(0xFFFFC107)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final Paint pearBodyPaint = Paint();

  // --- Snake Paints ---
  static final Paint snakeGlowPaint = Paint();
  static final Paint snakeBodyPaint = Paint();
  static final Paint snakeShinePaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.12);
  static final Paint eyeWhitePaint = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint eyePupilPaint = Paint()..color = const Color(0xFF1A1A2E);
  static final Paint snakeHeadGlowPaint = Paint()
    ..color = kSnakeHeadColor.withValues(alpha: 0.25);
  static final Paint snakeHeadPaint = Paint();

  // --- Infected Snake Paints ---
  static final Paint infectedSegmentPaint = Paint()
    ..color = const Color(0xFF19101C);
  static final Paint infectedGlowPaint = Paint()
    ..color = const Color(0xFFFF1744).withValues(alpha: 0.35);
  static final Paint infectedEyePupilPaint = Paint()
    ..color = const Color(0xFFFF1744);

  // --- Fossil / Skeletal Infected Snake Static Cached Paints ---
  static final Paint fossilShadowPaint = Paint()
    ..color = const Color(0x66000000);
  static final Paint fossilBoneDarkPaint = Paint()
    ..color = const Color(0xFF231C16);
  static final Paint fossilBoneMainPaint = Paint()
    ..color = const Color(0xFFD6CCA9);
  static final Paint fossilBoneLightPaint = Paint()
    ..color = const Color(0xFFF3EDE2);
  static final Paint fossilBoneRimPaint = Paint()
    ..color = const Color(0xFF8C7E68)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final Paint fossilSpinalHolePaint = Paint()
    ..color = const Color(0xFF120E0A);
  static final Paint fossilMarrowPulsePaint = Paint()
    ..color = const Color(0xFF76FF03);
  static final Paint fossilRibPaint = Paint()
    ..color = const Color(0xFFC7BCA5)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint fossilCrackPaint = Paint()
    ..color = const Color(0xFF534638)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  // --- Optimization: Reusable static particle & effect paints ---
  static final Paint slicedParticleGlowPaint = Paint();
  static final Paint slicedParticleCorePaint = Paint();
  static final Paint blindMemoryOuterGlowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18);
  static final Paint blindMemoryMidGlowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.38);
  static final Paint stormTintPaint = Paint();
  static final Paint rainDropPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final Paint lightningFlashGlowPaint = Paint();
  static final Paint lightningFlashCorePaint = Paint();
  static final Paint lightningOuterGlowPaint = Paint()
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint lightningMidGlowPaint = Paint()
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint lightningCoreBoltPaint = Paint()
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  // --- Fog & Darkness Mode Paints ---
  static final Paint fogPaint = Paint()..color = const Color(0xFB05070A);
  static final Paint fogSoftGradientPaint = Paint();
  static final Paint fogVignettePaint = Paint();
}
