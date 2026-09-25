import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../services/sound_service.dart';
import '../../../services/storage_service.dart';
import '../../cosmetics/controllers/cosmetics_controller.dart';
import '../../cosmetics/models/cosmetics_models.dart';
import '../../menu/controllers/menu_controller.dart' as menu;
import '../../settings/controllers/settings_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/auth_controller.dart';
import 'auth_dialog.dart';

/// Redesigned Modern Game Top AppBar:
/// - Squircle Avatar with green online status dot
/// - Player name with edit pencil icon
/// - Level indicator (e.g. سطح 24 / Level 24)
/// - Sleek neon green XP progress bar with numeric counter (e.g. 1200 / 2000)
/// - Glossy 3D Coin pill with add (+) button
/// - Settings circular action button
class UserProfileBar extends StatefulWidget {
  final Widget? trailing;

  const UserProfileBar({super.key, this.trailing});

  static String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  State<UserProfileBar> createState() => _UserProfileBarState();
}

class _UserProfileBarState extends State<UserProfileBar> {
  final GlobalKey _pillKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<WalletController>()) {
      final wallet = Get.find<WalletController>();
      wallet.coinTargetKey = _pillKey;
      debugPrint('👤 [UserProfileBar] initState: coinTargetKey set, pendingCoins=${wallet.pendingCoinAnimation.value}');
      wallet.checkAndTriggerPendingCoins();
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<WalletController>()) {
      final wallet = Get.find<WalletController>();
      if (wallet.coinTargetKey == _pillKey) {
        wallet.coinTargetKey = GlobalKey();
      }
    }
    super.dispose();
  }

  void _playTapSound() {
    if (Get.isRegistered<SoundService>()) {
      Get.find<SoundService>().playButtonTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final storage = Get.find<StorageService>();
    final wallet = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : null;
    final menuCtrl = Get.isRegistered<menu.MenuController>()
        ? Get.find<menu.MenuController>()
        : null;
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;

    return Obx(() {
      final isRtl = settings != null
          ? settings.currentLanguage.value == 'fa'
          : Directionality.of(context) == TextDirection.rtl;
      final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

      final user = auth.currentUser.value;
      final isLoggedIn = auth.isLoggedIn.value;
      final cosmetics = Get.isRegistered<CosmeticsController>()
          ? Get.find<CosmeticsController>()
          : null;
      final effectiveAvatarId = user?.avatarId ?? auth.selectedAvatarId.value;
      final cosmeticAvatar = cosmetics?.getAvatarById(effectiveAvatarId);
      final avatar = getAvatarById(effectiveAvatarId);
      final customImg = isLoggedIn ? auth.customAvatarPath.value : '';

      // XP & Level calculations directly from User Model / Dashboard
      // In guest mode, values are strictly reset to 0 / Level 1
      final xp = isLoggedIn
          ? (user != null ? user.xpTotal : storage.getPlayerXp())
          : 0;
      final level = isLoggedIn
          ? (user != null ? user.level : storage.getPlayerLevel())
          : 1;
      final nextXp = (isLoggedIn && user != null && user.nextLevelXp != null && user.nextLevelXp! > 0)
          ? user.nextLevelXp
          : (isLoggedIn ? (storage.getXpForNextLevel() > 0 ? storage.getXpForNextLevel() : 100) : 100);
      final progressInfo = calculateLevelProgress(
        xp: xp,
        level: level,
        nextLevelXp: nextXp,
      );
      final double progress = isLoggedIn ? progressInfo.progress : 0.0;

      // Currency (wallet displayBalance with fallback to balance/user.coinBalance)
      // In guest mode, coins are strictly 0
      final coinBalance = isLoggedIn
          ? (wallet?.displayBalance.value ?? wallet?.balance.value ?? user?.coinBalance ?? 0)
          : 0;

      final username = isLoggedIn ? user!.username : 'guest_player'.tr;
      final levelLabel = isRtl ? 'سطح $level' : 'Level $level';

      return Directionality(
        textDirection: textDirection,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121722).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Squircle Player Avatar with Online Green Dot / Guest Icon
              GestureDetector(
                onTap: () {
                  _playTapSound();
                  if (isLoggedIn) {
                    Get.toNamed(AppRoutes.profile);
                  } else {
                    Get.dialog(const AuthDialog());
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLoggedIn
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFF00E676).withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      colors: isLoggedIn
                          ? [avatar.primaryColor, avatar.secondaryColor]
                          : [const Color(0xFF0F241A), const Color(0xFF163828)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLoggedIn
                                ? avatar.primaryColor
                                : const Color(0xFF00E676))
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.5),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isLoggedIn)
                          _buildAvatarImage(
                            customImg: customImg,
                            avatar: avatar,
                            cosmeticAvatar: cosmeticAvatar,
                            userAvatarUrl: user?.avatarUrl,
                          )
                        else
                          const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: Color(0xFF00E676),
                              size: 26,
                            ),
                          ),
                        if (!isLoggedIn)
                          PositionedDirectional(
                            bottom: 2,
                            end: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.login_rounded,
                                size: 8,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              // 2. Center Column: Name/Edit or Login, and Level
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row A: Name & Pencil Edit Icon / Login Action
                    GestureDetector(
                      onTap: () {
                        _playTapSound();
                        if (isLoggedIn) {
                          Get.toNamed(AppRoutes.profile);
                        } else {
                          Get.dialog(const AuthDialog());
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isLoggedIn)
                            const Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00E676),
                                    Color(0xFF00C853),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.login_rounded,
                                    size: 10,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'login'.tr,
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Row B: Level text (only shown when logged in)
                    if (isLoggedIn) ...[
                      const SizedBox(height: 2),
                      Text(
                        levelLabel,
                        style: GoogleFonts.vazirmatn(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                          height: 1.2,
                        ),
                      ),
                    ],

                    // Row C: Animated Snake XP Progress Bar + counter (only when logged in)
                    if (isLoggedIn) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: SnakeXpProgressBar(
                              progress: progress,
                              isRtl: isRtl,
                              primaryColor: avatar.primaryColor != const Color(0xFF0F5A47)
                                  ? avatar.primaryColor
                                  : const Color(0xFF00E676),
                              secondaryColor: avatar.secondaryColor != const Color(0xFF1E8267)
                                  ? avatar.secondaryColor
                                  : const Color(0xFF69F0AE),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${progressInfo.currentLevelXp} / ${progressInfo.levelSpan}',
                            style: GoogleFonts.vazirmatn(
                              color: const Color(0xFF94A3B8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Right Action: Coin Pill (logged in only) & Settings Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoggedIn) ...[
                    // --- Gold Coin Pill ---
                    _CurrencyPill(
                      key: _pillKey,
                      icon: const _GoldCoinIcon(size: 18),
                      value: coinBalance,
                      isPulsing: wallet?.isCoinTargetPulsing.value ?? false,
                      onTap: () {
                        _playTapSound();
                        auth.requireAuth(() {
                          Get.toNamed(AppRoutes.walletHistory);
                        }, contextMessage: 'login_required_wallet'.tr);
                      },
                      onAddTap: () {
                        _playTapSound();
                        auth.requireAuth(() {
                          Get.toNamed(AppRoutes.shop);
                        }, contextMessage: 'login_required_wallet'.tr);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],

                  // --- Settings Button ---
                  _SettingsButton(
                    onTap: () {
                      _playTapSound();
                      if (menuCtrl != null) {
                        menuCtrl.openSettings();
                      } else {
                        Get.toNamed(AppRoutes.settings);
                      }
                    },
                  ),

                  if (widget.trailing != null) ...[
                    const SizedBox(width: 6),
                    widget.trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvatarImage({
    required String? customImg,
    required PresetAvatar avatar,
    CosmeticAvatar? cosmeticAvatar,
    String? userAvatarUrl,
  }) {
    if (customImg != null &&
        customImg.isNotEmpty &&
        File(customImg).existsSync()) {
      return Image.file(
        File(customImg),
        fit: BoxFit.cover,
        width: 48,
        height: 48,
      );
    }
    final effectiveUrl = (userAvatarUrl != null && userAvatarUrl.isNotEmpty)
        ? userAvatarUrl
        : (cosmeticAvatar?.imageUrl ?? avatar.imageUrl ?? '');

    final primary = cosmeticAvatar?.primaryColor ?? avatar.primaryColor;

    if (effectiveUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: effectiveUrl,
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        placeholder: (_, __) => Container(
          color: primary.withValues(alpha: 0.3),
        ),
        errorWidget: (_, __, ___) => Icon(
          Icons.person_rounded,
          color: primary,
          size: 24,
        ),
      );
    }
    return Icon(Icons.person_rounded, color: primary, size: 24);
  }
}

/// Glossy Currency Capsule / Pill with currency icon, animated counter value, and plus (+) button.
class _CurrencyPill extends StatelessWidget {
  final Widget icon;
  final int value;
  final bool isPulsing;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  const _CurrencyPill({
    super.key,
    required this.icon,
    required this.value,
    this.isPulsing = false,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPulsing ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 32,
          padding: const EdgeInsetsDirectional.fromSTEB(7, 0, 5, 0),
          decoration: BoxDecoration(
            color: isPulsing
                ? const Color(0xFF242E3F)
                : const Color(0xFF1B2230).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPulsing
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.10),
              width: isPulsing ? 1.4 : 1,
            ),
            boxShadow: [
              if (isPulsing)
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 4.5),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: value.toDouble(), end: value.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animVal, child) {
                  return Text(
                    UserProfileBar._formatNumber(animVal.round()),
                    style: GoogleFonts.vazirmatn(
                      color: isPulsing ? const Color(0xFFFFE082) : Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.15,
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
              // Plus (+) Button
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF283143),
                    borderRadius: BorderRadius.circular(5.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 11, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3D Glossy Gold Coin Icon
class _GoldCoinIcon extends StatelessWidget {
  final double size;

  const _GoldCoinIcon({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [Color(0xFFFFF176), Color(0xFFFFB300), Color(0xFFFF8F00)],
        ),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: const Color(0xFF7A4100),
            fontSize: size * 0.58,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// Settings Icon Button matching the pill style
class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2230).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.settings_rounded, color: Colors.white70, size: 17),
        ),
      ),
    );
  }
}

/// Snake-themed XP progress bar where a cute animated snake slithers
/// towards a mini red apple at the end of the track to level up!
class SnakeXpProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final bool isRtl;
  final Color primaryColor;
  final Color secondaryColor;

  const SnakeXpProgressBar({
    super.key,
    required this.progress,
    this.isRtl = false,
    this.primaryColor = const Color(0xFF00E676),
    this.secondaryColor = const Color(0xFF69F0AE),
  });

  @override
  State<SnakeXpProgressBar> createState() => _SnakeXpProgressBarState();
}

class _SnakeXpProgressBarState extends State<SnakeXpProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    // Repeating gentle breathing / tongue flick cycle
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        final t = _animCtrl.value;
        // Snappy tongue flick in the last 20% of cycle
        double tongueValue = 0.0;
        if (t > 0.80) {
          tongueValue = math.sin((t - 0.80) / 0.20 * math.pi);
        }

        return Transform.scale(
          scaleX: widget.isRtl ? -1.0 : 1.0,
          child: SizedBox(
            height: 12,
            child: CustomPaint(
              painter: _SnakeProgressBarPainter(
                progress: widget.progress.clamp(0.04, 1.0),
                tongueValue: tongueValue,
                animValue: t,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SnakeProgressBarPainter extends CustomPainter {
  final double progress;
  final double tongueValue;
  final double animValue;
  final Color primaryColor;
  final Color secondaryColor;

  _SnakeProgressBarPainter({
    required this.progress,
    required this.tongueValue,
    required this.animValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // 1. Background Track
    const trackHeight = 7.0;
    final trackRect = Rect.fromLTWH(
      0,
      centerY - trackHeight / 2,
      size.width,
      trackHeight,
    );
    final trackRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(trackHeight / 2),
    );

    final trackPaint = Paint()
      ..color = const Color(0xFF1B2332)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(trackRRect, trackPaint);

    final trackBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(trackRRect, trackBorderPaint);

    // 2. Goal: Mini Target Apple at the finish line (far right)
    final appleCenterX = size.width - 5.5;
    final appleCenterY = centerY;

    // Apple Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(appleCenterX, appleCenterY - 3.2),
      Offset(appleCenterX + 1.0, appleCenterY - 4.8),
      stemPaint,
    );

    // Apple Leaf
    final leafPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(appleCenterX - 1.6, appleCenterY - 3.6),
        width: 2.8,
        height: 1.8,
      ),
      leafPaint,
    );

    // Apple Body
    final applePaint = Paint()
      ..shader =
          const RadialGradient(
            center: Alignment(-0.3, -0.3),
            radius: 0.7,
            colors: [Color(0xFFF87171), Color(0xFFEF4444), Color(0xFFB91C1C)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(appleCenterX, appleCenterY),
              radius: 3.8,
            ),
          );
    canvas.drawCircle(Offset(appleCenterX, appleCenterY), 3.8, applePaint);

    // Apple Highlight
    final appleHighlight = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(
      Offset(appleCenterX - 1.2, appleCenterY - 1.2),
      0.8,
      appleHighlight,
    );

    // 3. Snake Crawl Calculations
    final availableWidth = size.width - 13.0;
    final headCenterX = (progress * availableWidth).clamp(7.5, availableWidth);

    // 4. Snake Body
    const bodyHeight = 6.2;
    final bodyRect = Rect.fromLTWH(
      1.5,
      centerY - bodyHeight / 2,
      (headCenterX - 1.5).clamp(1.0, availableWidth),
      bodyHeight,
    );
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      const Radius.circular(bodyHeight / 2),
    );

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.85),
          primaryColor,
          secondaryColor,
          secondaryColor.withValues(alpha: 0.95),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 4.1 Diagonal Hatched Pattern (هاشور ماری)
    canvas.save();
    canvas.clipRRect(bodyRRect);

    final hatchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const double stripeSpacing = 6.5;
    final double animShift = animValue * stripeSpacing;
    final double startX = -12.0 + animShift;

    for (double sx = startX; sx < headCenterX + 10.0; sx += stripeSpacing) {
      canvas.drawLine(
        Offset(sx - 3.5, centerY + bodyHeight / 2 + 1.0),
        Offset(sx + 3.5, centerY - bodyHeight / 2 - 1.0),
        hatchPaint,
      );
    }
    canvas.restore();

    // 5. Snake Head (Slightly taller rounded capsule)
    const headWidth = 10.5;
    const headHeight = 8.8;
    final headCenter = Offset(headCenterX, centerY);
    final headRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: headCenter, width: headWidth, height: headHeight),
      const Radius.circular(4.4),
    );

    final headPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          secondaryColor,
          Colors.white.withValues(alpha: 0.75),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(headRRect.outerRect);
    canvas.drawRRect(headRRect, headPaint);

    // 6. Eyes (Looking ahead towards the apple!)
    const eyeRadius = 1.7;
    final topEyeCenter = Offset(headCenterX + 0.8, centerY - 2.3);
    final bottomEyeCenter = Offset(headCenterX + 0.8, centerY + 2.3);

    final scleraPaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);
    final shinePaint = Paint()..color = Colors.white;

    // Draw Top Eye
    canvas.drawCircle(topEyeCenter, eyeRadius, scleraPaint);
    canvas.drawCircle(
      Offset(topEyeCenter.dx + 0.5, topEyeCenter.dy),
      0.85,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(topEyeCenter.dx + 0.2, topEyeCenter.dy - 0.4),
      0.35,
      shinePaint,
    );

    // Draw Bottom Eye
    canvas.drawCircle(bottomEyeCenter, eyeRadius, scleraPaint);
    canvas.drawCircle(
      Offset(bottomEyeCenter.dx + 0.5, bottomEyeCenter.dy),
      0.85,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(bottomEyeCenter.dx + 0.2, bottomEyeCenter.dy - 0.4),
      0.35,
      shinePaint,
    );

    // 7. Animated Forked Tongue Flick
    if (tongueValue > 0.05) {
      final tongueStart = Offset(headCenterX + headWidth / 2 - 0.5, centerY);
      final tongueLength = tongueValue * 4.0;
      final tongueEnd = Offset(tongueStart.dx + tongueLength, centerY);

      final tonguePaint = Paint()
        ..color = const Color(0xFFF43F5E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;

      // Tongue main stem
      canvas.drawLine(tongueStart, tongueEnd, tonguePaint);

      // Forked tips
      canvas.drawLine(
        tongueEnd,
        Offset(tongueEnd.dx + 1.4, centerY - 1.2),
        tonguePaint,
      );
      canvas.drawLine(
        tongueEnd,
        Offset(tongueEnd.dx + 1.4, centerY + 1.2),
        tonguePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tongueValue != tongueValue ||
        oldDelegate.animValue != animValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
