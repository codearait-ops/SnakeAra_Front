import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../cosmetics/models/cosmetics_models.dart';

/// Reusable widget displaying player Avatar encircled seamlessly by an animated Snake XP Progress Ring
/// matching the avatar's custom color palette, with an integrated round Level Emblem badge.
class AvatarXpRing extends StatelessWidget {
  final PresetAvatar? avatar;
  final CosmeticAvatar? cosmeticAvatar;
  final String? imageUrl;
  final Color? primaryColor;
  final Color? secondaryColor;
  final int level;
  final double progress; // 0.0 to 1.0
  final double size;
  final VoidCallback? onTap;
  final Color badgeBackgroundColor;
  final String? customImagePath;

  const AvatarXpRing({
    super.key,
    this.avatar,
    this.cosmeticAvatar,
    this.imageUrl,
    this.primaryColor,
    this.secondaryColor,
    required this.level,
    required this.progress,
    this.size = 48,
    this.onTap,
    this.badgeBackgroundColor = const Color(0xFF161B22),
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Sleeker thickness of snake body around avatar
    final snakeBodyWidth = (size * 0.048).clamp(3.0, 4.8);
    // 2. Avatar size fits snugly inside snake ring
    final innerAvatarSize = size - (snakeBodyWidth * 2) - 1.5;
    // 3. Compact round level emblem size
    final emblemSize = (size * 0.28).clamp(16.0, 28.0);
    final emblemFontSize = (emblemSize * 0.52).clamp(7.5, 13.5);

    final effectivePrimary = primaryColor ?? kAvatarPrimaryColor;
    final effectiveSecondary = secondaryColor ?? kAvatarSecondaryColor;
    final effectiveImageUrl =
        imageUrl ?? cosmeticAvatar?.imageUrl ?? avatar?.imageUrl ?? '';

    Widget innerChild;
    if (customImagePath != null &&
        customImagePath!.isNotEmpty &&
        File(customImagePath!).existsSync()) {
      innerChild = ClipOval(
        child: Image.file(
          File(customImagePath!),
          fit: BoxFit.cover,
          width: innerAvatarSize,
          height: innerAvatarSize,
        ),
      );
    } else if (effectiveImageUrl.isNotEmpty) {
      innerChild = ClipOval(
        child: CachedNetworkImage(
          imageUrl: effectiveImageUrl,
          fit: BoxFit.cover,
          width: innerAvatarSize,
          height: innerAvatarSize,
          placeholder: (_, __) =>
              Container(color: effectivePrimary.withValues(alpha: 0.3)),
          errorWidget: (_, __, ___) => Icon(
            Icons.person_rounded,
            color: effectivePrimary,
            size: innerAvatarSize * 0.56,
          ),
        ),
      );
    } else {
      innerChild = Icon(
        Icons.person_rounded,
        color: effectivePrimary,
        size: innerAvatarSize * 0.56,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Inner Avatar Circle (zero gap inside snake ring)
            Container(
              width: innerAvatarSize,
              height: innerAvatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [effectivePrimary, effectiveSecondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectivePrimary.withValues(alpha: 0.35),
                    blurRadius: size * 0.15,
                  ),
                ],
              ),
              child: innerChild,
            ),

            // 2. Snake-Shaped XP Progress Ring matching avatar colors
            CustomPaint(
              size: Size(size, size),
              painter: SnakeXpRingPainter(
                progress: progress,
                primaryColor: effectivePrimary,
                secondaryColor: effectiveSecondary,
                bodyWidth: snakeBodyWidth,
              ),
            ),

            // 3. Round Level Emblem Badge on Bottom-Right (themed to avatar color)
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                width: emblemSize,
                height: emblemSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeBackgroundColor,
                  border: Border.all(
                    color: effectivePrimary.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectivePrimary.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: TextStyle(
                      color: effectivePrimary,
                      fontSize: emblemFontSize,
                      fontWeight: FontWeight.w900,
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

/// Custom painter that renders a dynamic Snake XP progress ring:
/// - Coiled body arc with a sweep gradient from tail (secondary) to head (primary)
/// - Subtle alternating snake scale bands along the body
/// - Detailed snake head with eyes, ridge highlight, and forked tongue at the progress tip
/// - Faint scaly background track
class SnakeXpRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;
  final double bodyWidth;

  const SnakeXpRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bodyWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - bodyWidth) / 2;
    if (radius <= 0) return;

    // 1. Subtle Background Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyWidth * 0.75
      ..color = primaryColor.withValues(alpha: 0.16)
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Subtle track scale ribs (snake footprint trail)
    final trackRibPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = primaryColor.withValues(alpha: 0.22);

    const totalTrackSegments = 32;
    for (int i = 0; i < totalTrackSegments; i++) {
      final angle = (i / totalTrackSegments) * 2 * math.pi;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      final p1 = Offset(
        center.dx + (radius - bodyWidth * 0.28) * cosA,
        center.dy + (radius - bodyWidth * 0.28) * sinA,
      );
      final p2 = Offset(
        center.dx + (radius + bodyWidth * 0.28) * cosA,
        center.dy + (radius + bodyWidth * 0.28) * sinA,
      );
      canvas.drawLine(p1, p2, trackRibPaint);
    }

    // 2. Snake Body Arc
    final clampedProgress = progress.clamp(0.04, 1.0);
    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = clampedProgress * 2 * math.pi;

    // Gradient along snake body from tail to head
    final sweepGradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [secondaryColor, primaryColor],
    );

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bodyWidth
      ..strokeCap = StrokeCap.round
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bodyPaint,
    );

    // 3. Snake Scales / Rib pattern along the body
    final scaleStep = (bodyWidth * 1.5) / radius;
    final numScales = (sweepAngle / scaleStep).floor();
    if (numScales > 1) {
      final scalePaintDark = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withValues(alpha: 0.28);

      final scalePaintLight = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.25);

      for (int i = 1; i < numScales; i++) {
        final currentAngle = startAngle + (i * scaleStep);
        final cosA = math.cos(currentAngle);
        final sinA = math.sin(currentAngle);

        final p1 = Offset(
          center.dx + (radius - bodyWidth * 0.35) * cosA,
          center.dy + (radius - bodyWidth * 0.35) * sinA,
        );
        final p2 = Offset(
          center.dx + (radius + bodyWidth * 0.35) * cosA,
          center.dy + (radius + bodyWidth * 0.35) * sinA,
        );

        canvas.drawLine(p1, p2, i.isEven ? scalePaintDark : scalePaintLight);
      }
    }

    // 4. Snake Head at progress tip
    final headAngle = startAngle + sweepAngle;
    final headCenter = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );

    // Tangent angle in clockwise direction
    final tangentAngle = headAngle + (math.pi / 2);

    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(tangentAngle);

    final headLength = bodyWidth * 1.6;
    final headWidth = bodyWidth * 1.35;

    // A. Tiny Flicking Forked Tongue in front of snout
    final tonguePaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final tongueBaseX = headLength * 0.48;
    final tongueTipX = tongueBaseX + (bodyWidth * 0.65);

    // Main tongue stem
    canvas.drawLine(Offset(tongueBaseX, 0), Offset(tongueTipX, 0), tonguePaint);
    // Fork tips
    canvas.drawLine(
      Offset(tongueTipX, 0),
      Offset(tongueTipX + (bodyWidth * 0.26), -bodyWidth * 0.22),
      tonguePaint,
    );
    canvas.drawLine(
      Offset(tongueTipX, 0),
      Offset(tongueTipX + (bodyWidth * 0.26), bodyWidth * 0.22),
      tonguePaint,
    );

    // B. Snake Head (Smooth diamond / rounded oblong shape)
    final headPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final headRect = Rect.fromCenter(
      center: Offset(headLength * 0.05, 0),
      width: headLength,
      height: headWidth,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(headWidth * 0.45)),
      headPaint,
    );

    // Head center highlight line
    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-headLength * 0.25, 0),
      Offset(headLength * 0.28, 0),
      ridgePaint,
    );

    // C. Snake Eyes (Pair of distinct cute eyes)
    final eyeOffset = headWidth * 0.35;
    final eyeX = headLength * 0.1;

    final eyeScleraPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final eyePupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final eyeRadius = (bodyWidth * 0.23).clamp(1.0, 1.8);
    final pupilRadius = (eyeRadius * 0.58).clamp(0.6, 1.1);

    // Eye 1 (outer)
    canvas.drawCircle(Offset(eyeX, -eyeOffset), eyeRadius, eyeScleraPaint);
    canvas.drawCircle(
      Offset(eyeX + 0.3, -eyeOffset),
      pupilRadius,
      eyePupilPaint,
    );

    // Eye 2 (inner)
    canvas.drawCircle(Offset(eyeX, eyeOffset), eyeRadius, eyeScleraPaint);
    canvas.drawCircle(
      Offset(eyeX + 0.3, eyeOffset),
      pupilRadius,
      eyePupilPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SnakeXpRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.bodyWidth != bodyWidth;
  }
}
