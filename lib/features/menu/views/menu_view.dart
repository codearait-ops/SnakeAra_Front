import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide MenuController;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app_routes.dart';
import '../../../services/sound_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/widgets/user_profile_bar.dart';
import '../../daily_mission/controllers/daily_mission_controller.dart';
import '../../daily_mission/models/daily_mission_model.dart';
import '../../game/models/game_mode_config.dart';
import '../../league/models/league_tier_models.dart';
import '../controllers/menu_controller.dart';

/// Main menu screen with neon-styled title, Settings action, and dynamic game modes.
class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MenuController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Checkered game board pattern (Static background)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CheckerboardPainter(
                  tileSize: 66.0,
                  lightColor: Color(0xFF11151D),
                  darkColor: Color(0xFF0D1117),
                ),
              ),
            ),
          ),
          // Subtle dark radial vignette for neon contrast
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0D1117).withValues(alpha: 0.4),
                    const Color(0xFF06090E).withValues(alpha: 0.85),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Main Menu Content
          SafeArea(
            child: Column(
              children: [
                // --- Pinned / Fixed Top Header Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),

                      // Top Header Bar inspired by reference design
                      const UserProfileBar(),
                      const SizedBox(height: 6),

                      // Animated App Logo pinned outside scroll
                      const _AppLogo(height: 82),
                    ],
                  ),
                ),

                // --- Smooth Scrollable Body Section ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),

                        // Section 1: Weekly League & Daily Mission (Competition Header & Divider)
                        _MenuSectionDivider(
                          title: 'competition_section_title'.tr,
                          subtitle: 'competition_section_tagline'.tr,
                          icon: Icons.emoji_events_rounded,
                          accentColor: Colors.white,
                        ),
                        const SizedBox(height: 16),

                        // Quick Action Buttons: Weekly League & Daily Mission (Game Emblem style)
                        Row(
                          children: [
                            Expanded(
                              child: _LeagueMenuCard(controller: controller),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DailyMissionMenuCard(
                                controller: controller,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),

                        // Section 2: Dynamic Game Modes (Modes Header & Subtitle Divider)
                        _MenuSectionDivider(
                          title: 'game_modes_title'.tr,
                          subtitle: 'subtitle'.tr,
                          icon: Icons.sports_esports_rounded,
                          accentColor: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(height: 16),

                        // --- Dynamic Game Modes List ---
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.65,
                              ),
                          itemCount: availableGameModes.length,
                          itemBuilder: (context, index) {
                            final modeConfig = availableGameModes[index];
                            return _ModeButton(
                              config: modeConfig,
                              onPressed: () =>
                                  controller.openModeDetails(modeConfig),
                            );
                          },
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylish section divider with glowing gradient lines and competition/modes tagline.
class _MenuSectionDivider extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accentColor;

  const _MenuSectionDivider({
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor = const Color(0xFFFFB300),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accentColor.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated app logo for the main menu header.
class _AppLogo extends StatefulWidget {
  final double height;
  const _AppLogo({super.key, this.height = 84});

  @override
  State<_AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<_AppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: Image.asset(
        'assets/image/appLogo.png',
        height: widget.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Custom Game Mode selection card widget driven by [GameModeConfig].
class _ModeButton extends StatelessWidget {
  final GameModeConfig config;
  final VoidCallback onPressed;

  const _ModeButton({required this.config, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isAvailable = config.isAvailable;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: isAvailable ? 1.0 : 0.4,
            child: Image.asset(config.imageAsset, fit: BoxFit.fill),
          ),
          if (!isAvailable)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white70,
                  size: 40,
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: isAvailable ? onPressed : null),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the checkered / grid background pattern (like the snake game board).
class _CheckerboardPainter extends CustomPainter {
  final double tileSize;
  final Color lightColor;
  final Color darkColor;

  const _CheckerboardPainter({
    this.tileSize = 66.0,
    this.lightColor = const Color(0xFF11151D),
    this.darkColor = const Color(0xFF0D1117),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = lightColor;
    final darkPaint = Paint()..color = darkColor;

    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        final isEven = (col + row) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(col * tileSize, row * tileSize, tileSize, tileSize),
          isEven ? lightPaint : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.tileSize != tileSize ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor;
  }
}

/// Animated glowing breathing pulse card border for highlighting active challenges.
class _GlowingPulseCard extends StatefulWidget {
  final Widget child;
  final bool isGlowing;
  final Color glowColor;

  const _GlowingPulseCard({
    required this.child,
    required this.isGlowing,
    this.glowColor = Colors.white,
  });

  @override
  State<_GlowingPulseCard> createState() => _GlowingPulseCardState();
}

class _GlowingPulseCardState extends State<_GlowingPulseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.isGlowing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _GlowingPulseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlowing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isGlowing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isGlowing) {
      return widget.child;
    }

    const borderRadius = BorderRadius.all(Radius.circular(16));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: widget.glowColor.withValues(alpha: 0.55 + t * 0.45),
              width: 1.8 + t * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.30 + t * 0.40),
                blurRadius: 10 + t * 8,
                spreadRadius: 1.0 + t * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(borderRadius: borderRadius, child: widget.child),
    );
  }
}

/// Sleek action button for Weekly League styled exactly like the game emblem reference:
/// - Prominent 3D rank shield from assets/image/ranks/
/// - Background luminous halo when player has not entered the league
/// - Overlapping golden-bordered pill badge displaying player's rank
class _LeagueMenuCard extends StatelessWidget {
  final MenuController controller;

  const _LeagueMenuCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Obx(() {
        final summary = controller.leagueSummary.value;
        final myRank = controller.myLeagueRank.value;
        final rank = summary?.rank ?? myRank?.rank;
        final bool inLeague =
            (summary?.hasActiveRank ?? false) ||
            (summary?.isEntered ?? false) ||
            (myRank?.hasActiveRank ?? false) ||
            (rank != null && rank > 0);
        final tier = summary?.leagueTier ?? LeagueTier.bronze;
        final tierColor = tier.color;
        final accentColor = inLeague ? tierColor : Colors.white;

        return GestureDetector(
          onTap: () => controller.openLeague(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-bleed stretched banner image
                  Image.asset(
                    'assets/image/league.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Image.asset(
                      tier.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Bottom subtle gradient shade for title readability
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.80),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title / Status label
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Text(
                      _buildTitle(inLeague, rank),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        color: inLeague ? tierColor : Colors.white,
                        shadows: [
                          const Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _buildTitle(bool inLeague, int? rank) {
    if (!inLeague || rank == null || rank <= 0) {
      return 'weekly_league_title'.tr;
    }
    return 'league_rank_title'.trParams({'rank': '$rank'});
  }
}

/// Sleek action button for Daily Mission:
/// - Full stretched banner with rounded corners
/// - Active badge indicating player can participate today
/// - Navigates to dedicated daily mission screen on tap
class _DailyMissionMenuCard extends StatelessWidget {
  final MenuController controller;

  const _DailyMissionMenuCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Obx(() {
        final auth = Get.find<AuthController>();
        final isLoggedIn = auth.isLoggedIn.value;

        DailyMissionModel? mission;
        if (isLoggedIn) {
          if (Get.isRegistered<DailyMissionController>()) {
            mission = Get.find<DailyMissionController>().currentMission.value;
          }
          mission ??= controller.dashboard.value?.dailyMission;
        }

        final isCompleted = isLoggedIn && (mission?.isCompleted ?? false);
        final isFailed = isLoggedIn && (mission?.isFailed ?? false);

        final canParticipate = isLoggedIn &&
            mission != null &&
            !isCompleted &&
            !isFailed &&
            (mission.canPlay || mission.canUnlockSecondAttempt);

        final accentColor = isCompleted
            ? const Color(0xFF00E676)
            : (isLoggedIn ? const Color(0xFF00E5FF) : Colors.white);

        return GestureDetector(
          onTap: () => controller.openDailyMission(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-bleed stretched banner image
                  Image.asset(
                    'assets/image/daily1.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.assignment_turned_in_rounded,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),

                  // Bottom subtle gradient shade for title readability
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.80),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Active Challenge Badge (top-right)
                  if (canParticipate)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: _DailyMissionActiveBadge(),
                    ),

                  // Title label
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Text(
                      isCompleted
                          ? 'mission_completed_title'.tr
                          : 'daily_mission_title'.tr,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? const Color(0xFF00E676)
                            : Colors.white,
                        shadows: [
                          const Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      }),
    );
  }
}

/// Simple elegant red circle badge placed on the bottom-left of the Daily Mission photo
/// when a challenge is active and playable.
class _DailyMissionActiveBadge extends StatefulWidget {
  const _DailyMissionActiveBadge();

  @override
  State<_DailyMissionActiveBadge> createState() =>
      _DailyMissionActiveBadgeState();
}

class _DailyMissionActiveBadgeState extends State<_DailyMissionActiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF1744),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.90),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that paints curved text along a circular arc with no background and no border.
class _CurvedText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final double radius;
  final Offset centerOffset;

  const _CurvedText({
    required this.text,
    required this.textStyle,
    required this.radius,
    required this.centerOffset,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(centerOffset.dx * 2, centerOffset.dy),
        painter: _CurvedTextPainter(
          text: text,
          textStyle: textStyle,
          radius: radius,
          centerOffset: centerOffset,
        ),
      ),
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final double radius;
  final Offset centerOffset;

  _CurvedTextPainter({
    required this.text,
    required this.textStyle,
    required this.radius,
    required this.centerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final isRtl = _isRtlText(text);
    final processed = isRtl ? _shapePersianText(text) : text;
    final characters = processed.characters.toList();
    if (characters.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    );

    final List<double> charAngles = [];
    double totalAngle = 0.0;

    for (final ch in characters) {
      textPainter.text = TextSpan(text: ch, style: textStyle);
      textPainter.layout();
      final w = textPainter.width;
      final isSpace = ch == ' ';
      final double factor;
      if (isRtl) {
        factor = isSpace ? 0.95 : 0.90;
      } else {
        factor = isSpace ? 1.0 : 1.06;
      }
      final dTheta = (w * factor) / radius;
      charAngles.add(dTheta);
      totalAngle += dTheta;
    }

    if (isRtl) {
      // In RTL (Persian), start at the right and curve towards the left
      double currentAngle = -math.pi / 2 + totalAngle / 2;

      for (int i = 0; i < characters.length; i++) {
        final ch = characters[i];
        final dTheta = charAngles[i];
        final theta = currentAngle - dTheta / 2;

        textPainter.text = TextSpan(text: ch, style: textStyle);
        textPainter.layout();

        final x = centerOffset.dx + radius * math.cos(theta);
        final y = centerOffset.dy + radius * math.sin(theta);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(theta + math.pi / 2);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();

        currentAngle -= dTheta;
      }
    } else {
      // In LTR (English), start at the left and curve towards the right
      double currentAngle = -math.pi / 2 - totalAngle / 2;

      for (int i = 0; i < characters.length; i++) {
        final ch = characters[i];
        final dTheta = charAngles[i];
        final theta = currentAngle + dTheta / 2;

        textPainter.text = TextSpan(text: ch, style: textStyle);
        textPainter.layout();

        final x = centerOffset.dx + radius * math.cos(theta);
        final y = centerOffset.dy + radius * math.sin(theta);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(theta + math.pi / 2);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();

        currentAngle += dTheta;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.radius != radius ||
        oldDelegate.centerOffset != centerOffset;
  }
}

class _GlyphForms {
  final int isolated;
  final int finalForm;
  final int initial;
  final int medial;

  const _GlyphForms(this.isolated, this.finalForm, this.initial, this.medial);
  const _GlyphForms.rightOnly(int iso, int fin) : this(iso, fin, iso, fin);
}

const Map<int, _GlyphForms> _persianFormsMap = {
  // Alef & variations (right-only)
  0x0622: _GlyphForms.rightOnly(0xFE81, 0xFE82), // آ
  0x0623: _GlyphForms.rightOnly(0xFE83, 0xFE84), // أ
  0x0625: _GlyphForms.rightOnly(0xFE87, 0xFE88), // إ
  0x0627: _GlyphForms.rightOnly(0xFE8D, 0xFE8E), // ا
  0x0624: _GlyphForms.rightOnly(0xFE85, 0xFE86), // ؤ

  // Dal & Zal (right-only)
  0x062F: _GlyphForms.rightOnly(0xFEA9, 0xFEAA), // د
  0x0630: _GlyphForms.rightOnly(0xFEAB, 0xFEAC), // ذ

  // Re, Ze, Zhe (right-only)
  0x0631: _GlyphForms.rightOnly(0xFEAD, 0xFEAE), // ر
  0x0632: _GlyphForms.rightOnly(0xFEAF, 0xFEB0), // ز
  0x0698: _GlyphForms.rightOnly(0xFB8A, 0xFB8B), // ژ

  // Vav (right-only)
  0x0648: _GlyphForms.rightOnly(0xFEED, 0xFEEE), // و

  // Dual-connecting letters
  0x0626: _GlyphForms(0xFE89, 0xFE8A, 0xFE8B, 0xFE8C), // ئ
  0x0628: _GlyphForms(0xFE8F, 0xFE90, 0xFE91, 0xFE92), // ب
  0x067E: _GlyphForms(0xFB56, 0xFB57, 0xFB58, 0xFB59), // پ
  0x062A: _GlyphForms(0xFE95, 0xFE96, 0xFE97, 0xFE98), // ت
  0x062B: _GlyphForms(0xFE99, 0xFE9A, 0xFE9B, 0xFE9C), // ث
  0x062C: _GlyphForms(0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0), // ج
  0x0686: _GlyphForms(0xFB7A, 0xFB7B, 0xFB7C, 0xFB7D), // چ
  0x062D: _GlyphForms(0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4), // ح
  0x062E: _GlyphForms(0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8), // خ
  0x0633: _GlyphForms(0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4), // س
  0x0634: _GlyphForms(0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8), // ش
  0x0635: _GlyphForms(0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC), // ص
  0x0636: _GlyphForms(0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0), // ض
  0x0637: _GlyphForms(0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4), // ط
  0x0638: _GlyphForms(0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8), // ظ
  0x0639: _GlyphForms(0xFEC9, 0xFECA, 0xFECB, 0xFECC), // ع
  0x063A: _GlyphForms(0xFECD, 0xFECE, 0xFECF, 0xFED0), // غ
  0x0641: _GlyphForms(0xFED1, 0xFED2, 0xFED3, 0xFED4), // ف
  0x0642: _GlyphForms(0xFED5, 0xFED6, 0xFED7, 0xFED8), // ق
  0x06A9: _GlyphForms(0xFB8E, 0xFB8F, 0xFB90, 0xFB91), // ک (Persian)
  0x0643: _GlyphForms(0xFED9, 0xFEDA, 0xFEDB, 0xFEDC), // ك (Arabic)
  0x06AF: _GlyphForms(0xFB92, 0xFB93, 0xFB94, 0xFB95), // گ
  0x0644: _GlyphForms(0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0), // ل
  0x0645: _GlyphForms(0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4), // م
  0x0646: _GlyphForms(0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8), // ن
  0x0647: _GlyphForms(0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC), // ه
  0x06CC: _GlyphForms(0xFBFC, 0xFBFD, 0xFBFE, 0xFBFF), // ی (Persian)
  0x064A: _GlyphForms(0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4), // ي (Arabic)
};

bool _isRtlText(String s) {
  for (final code in s.runes) {
    if ((code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) ||
        (code >= 0xFE70 && code <= 0xFEFC)) {
      return true;
    }
  }
  return false;
}

bool _isRightOnly(int code) {
  return code == 0x0622 ||
      code == 0x0623 ||
      code == 0x0625 ||
      code == 0x0627 ||
      code == 0x0624 ||
      code == 0x062F ||
      code == 0x0630 ||
      code == 0x0631 ||
      code == 0x0632 ||
      code == 0x0698 ||
      code == 0x0648;
}

String _shapePersianText(String input) {
  final runes = input.runes.toList();
  final len = runes.length;
  if (len == 0) return input;

  final buffer = StringBuffer();

  for (int i = 0; i < len; i++) {
    final code = runes[i];
    final forms = _persianFormsMap[code];

    if (forms == null) {
      buffer.writeCharCode(code);
      continue;
    }

    bool connectsToPrev = false;
    if (i > 0) {
      final prevCode = runes[i - 1];
      final prevForms = _persianFormsMap[prevCode];
      if (prevForms != null && !_isRightOnly(prevCode)) {
        connectsToPrev = true;
      }
    }

    bool connectsToNext = false;
    if (i < len - 1 && !_isRightOnly(code)) {
      final nextCode = runes[i + 1];
      final nextForms = _persianFormsMap[nextCode];
      if (nextForms != null) {
        connectsToNext = true;
      }
    }

    int shaped;
    if (connectsToPrev && connectsToNext) {
      shaped = forms.medial;
    } else if (connectsToPrev) {
      shaped = forms.finalForm;
    } else if (connectsToNext) {
      shaped = forms.initial;
    } else {
      shaped = forms.isolated;
    }

    buffer.writeCharCode(shaped);
  }

  return buffer.toString();
}

