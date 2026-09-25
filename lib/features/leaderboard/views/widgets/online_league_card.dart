import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snake_game/app/core/constants/app_constants.dart';
import 'package:snake_game/app/core/widgets/app_cached_avatar.dart';
import '../../models/game_mode_leaderboard_entry.dart';

String formatLeaderboardValue(int val, String modeId) {
  if (modeId == 'infection') {
    final mins = (val ~/ 60).toString().padLeft(2, '0');
    final secs = (val % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
  return '$val';
}

/// Card component for an Online Leaderboard Entry with compact height,
/// unified border, player bio, fixed-width score badge, and rotating half-sunburst
/// anchored on the right edge of the card.
class OnlineLeagueCard extends StatelessWidget {
  final GameModeLeaderboardEntry entry;
  final Color accentColor;
  final String modeId;
  final VoidCallback? onTap;

  const OnlineLeagueCard({
    super.key,
    required this.entry,
    required this.accentColor,
    required this.modeId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = getAvatarById(entry.avatarId ?? 'avatar_1');
    final rank = entry.rank;

    // Rank accent color (for the rank number and rotating sunlight rays)
    final rankAccentColor = rank == 1
        ? kGoldColor
        : rank == 2
            ? const Color(0xFFE2E8F0) // Silver / Platinum
            : rank == 3
                ? const Color(0xFFCD7F32) // Bronze
                : const Color(0xFFFFA726); // Warm Sunlight / Amber

    final scoreColor = rank == 1
        ? kGoldColor
        : rank == 2
            ? const Color(0xFFE2E8F0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : accentColor;

    final bio = entry.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF262F3D), // Unified single border color
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating sunburst on the leading edge for top 3 podium entries only
            if (rank <= 3)
              PositionedDirectional(
                start: -55,
                top: -35,
                bottom: -35,
                width: 120,
                child: Center(
                  child: _SunburstAnimation(
                    color: rankAccentColor,
                    size: 120,
                  ),
                ),
              ),

            // Foreground Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint(
                    '>>> [TAP] OnlineLeagueCard tapped for ${entry.username} (userId: ${entry.userId})',
                  );
                  if (onTap != null) {
                    onTap!();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Rank Badge (Filled background)
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rank <= 3
                              ? rankAccentColor
                              : const Color(0xFF1C222C),
                          border: Border.all(
                            color: rank <= 3
                                ? rankAccentColor
                                : Colors.white.withValues(alpha: 0.15),
                            width: 1.2,
                          ),
                          boxShadow: rank <= 3
                              ? [
                                  BoxShadow(
                                    color: rankAccentColor.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              color: rank <= 2
                                  ? const Color(0xFF0D1117)
                                  : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Player Avatar
                      AppCachedAvatar(
                        avatarUrl: entry.avatarUrl,
                        avatarId: entry.avatarId,
                        size: 34,
                        iconSize: 18,
                      ),
                      const SizedBox(width: 10),

                      // Player Info: Username + Bio (completely empty if no bio)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasBio) ...[
                              const SizedBox(height: 2),
                              Text(
                                bio,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Score Display (Clean number without background, border, or repeated unit label)
                      SizedBox(
                        width: 86,
                        child: Center(
                          child: Text(
                            formatLeaderboardValue(entry.bestValue, modeId),
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: rank <= 3
                                  ? scoreColor
                                  : Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
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

/// Rotating sunburst sunlight rays animation anchored on the right edge of the card
class _SunburstAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const _SunburstAnimation({
    required this.color,
    required this.size,
  });

  @override
  State<_SunburstAnimation> createState() => _SunburstAnimationState();
}

class _SunburstAnimationState extends State<_SunburstAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SunburstPainter(color: widget.color),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final Color color;
  const _SunburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const numRays = 16;
    const angleStep = (2 * math.pi) / numRays;
    const halfRay = angleStep / 3.0;

    // 1. Soft Core Ambient Radial Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.75));
    canvas.drawCircle(center, radius * 0.75, glowPaint);

    // 2. Rotating Sunburst Rays (More vibrant and distinct)
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.32),
          color.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (int i = 0; i < numRays; i++) {
      final angle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(angle - halfRay),
          center.dy + radius * math.sin(angle - halfRay),
        )
        ..arcToPoint(
          Offset(
            center.dx + radius * math.cos(angle + halfRay),
            center.dy + radius * math.sin(angle + halfRay),
          ),
          radius: Radius.circular(radius),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      oldDelegate.color != color;
}
