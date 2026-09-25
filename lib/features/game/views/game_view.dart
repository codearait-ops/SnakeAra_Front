import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snake_game/features/cosmetics/controllers/cosmetics_controller.dart';
import '../../../app/core/utils/enums.dart';
import '../controllers/game_controller.dart';
import '../widgets/casual_mission_hud.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/hud/game_top_bar.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/mode_intro_dialog.dart';
import '../widgets/controls/swipe_detector.dart';
import '../widgets/controls/virtual_joystick.dart';
import '../widgets/overlays/pause_overlay.dart';

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

/// The main game screen with Flame canvas and Flutter HUD overlay.
class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress(context, controller);
      },
      child: Scaffold(
        body: Stack(
        children: [
          // --- Fullscreen Background (Purely Data-Driven / Cached) ---
          Positioned.fill(
            child: Obx(() {
              final _ = controller.gameMode.value;
              final cosmetics = Get.isRegistered<CosmeticsController>()
                  ? Get.find<CosmeticsController>()
                  : null;
              cosmetics?.activeTheme.value;
              final skin = controller.snakeGame.currentBoardSkin;

              if (skin.cachedImagePath != null &&
                  skin.cachedImagePath!.isNotEmpty &&
                  File(skin.cachedImagePath!).existsSync()) {
                return Image.file(
                  File(skin.cachedImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF0D1117)),
                );
              } else if (skin.remoteImageUrl != null &&
                  skin.remoteImageUrl!.isNotEmpty) {
                return CachedNetworkImage(
                  imageUrl: skin.remoteImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF0D1117)),
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFF0D1117)),
                );
              }

              return Container(color: const Color(0xFF0D1117));
            }),
          ),

          // --- Main game layout ---
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64), // Clearance for floating glass bar
                Obx(() {
                  if (controller.gameMode.value == GameMode.casual) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                      child: CasualMissionHud(controller: controller),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 400,
                          height: 400,
                          child: SwipeDetector(
                            onSwipe: (dir) => controller.changeDirection(dir),
                            child: const GameBoardWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                VirtualJoystickWidget(controller: controller),
              ],
            ),
          ),

          // --- Floating Glassmorphic Top Bar ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: GameTopBar(controller: controller),
          ),

          // --- Casual Mode Active Power-Up Floating Badge (Zero layout shift) ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 64 + 54,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: CasualActivePowerUpBadge(controller: controller),
              ),
            ),
          ),

          // --- Game Over overlay ---
          Obx(() {
            if (controller.gameStatus.value == GameStatus.gameOver) {
              return const GameOverOverlay();
            }
            return const SizedBox.shrink();
          }),

          // --- Level Complete overlay ---
          Obx(() {
            if (controller.gameStatus.value == GameStatus.levelComplete) {
              return const LevelCompleteOverlay();
            }
            return const SizedBox.shrink();
          }),

          // --- Pause overlay (tappable to resume) ---
          Obx(() {
            if (controller.gameStatus.value == GameStatus.paused &&
                !controller.isIntroShowing.value) {
              return GestureDetector(
                onTap: () => controller.togglePause(),
                child: Container(
                  color: Colors.black87,
                  child: Center(child: PauseContent(controller: controller)),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // --- Mode Intro Dialog (Rules + Checkbox + Start Button) ---
          Obx(() {
            if (controller.isIntroShowing.value) {
              return ModeIntroDialog(
                controller: controller,
                config: controller.currentModeConfig,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    ),
    );
  }

  Future<void> _handleBackPress(
    BuildContext context,
    GameController controller,
  ) async {
    // If game has already ended, exit directly
    if (controller.gameStatus.value == GameStatus.gameOver ||
        controller.gameStatus.value == GameStatus.levelComplete ||
        controller.gameStatus.value == GameStatus.idle) {
      controller.goToMenu();
      return;
    }

    // Active gameplay (or already paused): pause engine & sounds immediately
    if (controller.gameStatus.value == GameStatus.playing) {
      controller.snakeGame.pauseGame();
    }

    final isFa = Get.locale?.languageCode == 'fa';
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Directionality(
          textDirection: isFa ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: const Color(0xFF161F2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF5252),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'exit_game_title'.tr,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            content: Text(
              'exit_game_confirm'.tr,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'resume_game_btn'.tr,
                  style: GoogleFonts.vazirmatn(
                    color: const Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'exit_game_btn'.tr,
                  style: GoogleFonts.vazirmatn(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldExit == true) {
      controller.goToMenu();
    } else {
      // User cancelled dialog -> resume game
      controller.snakeGame.resumeGame();
    }
  }
}

