import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../../services/sound_service.dart';
import '../controllers/daily_mission_controller.dart';
import '../widgets/daily_mission_card_view.dart';

/// Dedicated full-screen view for the Daily Mission.
///
/// Features:
/// - Floating Glassmorphic App Bar with coin balance & rules info button
/// - Atmospheric dark futuristic background with ambient glowing halo
/// - Centered Hero graphic with localized taglines
/// - Full interactive Daily Mission card (Attempts, Ad retry, Play button)
/// - Rules dialog accessible via the App Bar info icon
class DailyMissionView extends StatelessWidget {
  const DailyMissionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DailyMissionController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F16),
      extendBodyBehindAppBar: false,
      appBar: FloatingAppBar(
        titleText: 'daily_mission_title'.tr,
        accentColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => _showRulesDialog(context),
            tooltip: 'daily_mission_guide_title'.tr,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.currentMission.value == null) {
          return const Center(child: AppLoadingWidget(size: 32));
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.currentMission.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchTodayMission(forceRefresh: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'retry'.tr,
                      style: GoogleFonts.vazirmatn(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTodayMission(forceRefresh: true),
          color: Colors.white,
          backgroundColor: const Color(0xFF141F28),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sleek Centered Hero Header (Fully localized & responsive)
                _buildHeroHeader(context),

                const SizedBox(height: 12),

                // 2. Main Daily Mission Interactive Card
                const DailyMissionCardView(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Modern, atmospheric Hero Header with glowing icon and localized tagline
  Widget _buildHeroHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Daily Mission Graphic with Ambient Glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Natural realistic depth drop shadow under the parchment paper
              Container(
                width: 72,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.60),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Image
              Image.asset(
                'assets/image/daily.png',
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Localized Tagline Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'daily_mission_header_tagline'.tr,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Localized Subtitle description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'daily_mission_header_desc'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the unified rules & guidance dialog
  void _showRulesDialog(BuildContext context) {
    if (Get.isRegistered<SoundService>()) {
      Get.find<SoundService>().playButtonTap();
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF0D141E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Row with Icon & Close
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'daily_mission_guide_title'.tr,
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (Get.isRegistered<SoundService>()) {
                              Get.find<SoundService>().playButtonTap();
                            }
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Complete Unified Text
                  Text(
                    'daily_mission_guide_body'.tr,
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13.5,
                      height: 1.65,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Got it / Confirm Button
                  ElevatedButton(
                    onPressed: () {
                      if (Get.isRegistered<SoundService>()) {
                        Get.find<SoundService>().playButtonTap();
                      }
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'got_it'.tr,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
    );
  }
}
