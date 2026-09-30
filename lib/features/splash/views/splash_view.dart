import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../controllers/splash_controller.dart';

/// Modern, sleek Splash Screen with neon aesthetic, smooth progress tracking,
/// and interactive retry/offline timeout recovery.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: Stack(
        children: [
          // 0. Checkered Grid Background
          const _CheckeredBackground(),

          // 1. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Floating Animated App Logo with Glow
                  const _FloatingLogo(),

                  const SizedBox(height: 16),

                  // App Tagline
                  Text(
                    'splash_tagline'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white60,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Section: Progress Bar / Status / Error Action
                  _buildBottomSection(),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBottomSection() {
    return Obx(() {
      if (controller.hasError.value) {
        return _buildErrorState();
      }
      return _buildLoadingState();
    });
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Message
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              controller.statusMessage.value,
              key: ValueKey(controller.statusMessage.value),
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sleek Progress Bar
        Obx(() {
          final progress = controller.progress.value.clamp(0.0, 1.0);
          return Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E5FF),
                          Color(0xFF00E676),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A24).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFFF5252),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.statusMessage.value,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Retry Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: controller.retry,
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.black),
              label: Text(
                'splash_retry_btn'.tr,
                style: GoogleFonts.vazirmatn(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                elevation: 4,
                shadowColor: kPrimaryColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Continue Offline Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton.icon(
              onPressed: controller.continueOffline,
              icon: const Icon(
                Icons.play_arrow_outlined,
                size: 18,
                color: Colors.white70,
              ),
              label: Text(
                'splash_offline_btn'.tr,
                style: GoogleFonts.vazirmatn(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating animated app logo with smooth up-and-down bobbing and breathing glow.
class _FloatingLogo extends StatefulWidget {
  const _FloatingLogo();

  @override
  State<_FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<_FloatingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _translateAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient Pulsing Glow behind the Logo
              Container(
                width: 220,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(
                        alpha: _glowAnimation.value,
                      ),
                      blurRadius: 45,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(
                        alpha: _glowAnimation.value * 0.6,
                      ),
                      blurRadius: 60,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // The Main App Logo Image
              Image.asset(
                'assets/image/appLogo.png',
                width: 240,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/image/appIcon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Checkered snake-grid background widget.
class _CheckeredBackground extends StatelessWidget {
  const _CheckeredBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CheckeredGridPainter(),
      ),
    );
  }
}

/// CustomPainter rendering a crisp dark checkered grid with subtle radial vignette.
class _CheckeredGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double cellSize = 56.0;
    final paintDark = Paint()..color = const Color(0xFF070B11);
    final paintLight = Paint()..color = const Color(0xFF0E141E);
    final gridLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    // 1. Draw alternating checkered tiles
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );
        final paint = (r + c) % 2 == 0 ? paintDark : paintLight;
        canvas.drawRect(rect, paint);
      }
    }

    // 2. Draw subtle grid dividing lines
    for (double x = 0; x <= size.width + cellSize; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridLinePaint);
    }
    for (double y = 0; y <= size.height + cellSize; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridLinePaint);
    }

    // 3. Radial Vignette for focused center ambiance
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          const Color(0xFF070B11).withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


