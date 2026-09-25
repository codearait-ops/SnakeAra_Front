import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../controllers/game_controller.dart';

/// Renders the game board inside a premium cyber-glass holographic frame
/// with subtle ambient glow, mode-adaptive neon accents, and smooth screen shake.
class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({super.key});

  Color _getModeAccentColor(GameMode mode) {
    switch (mode) {
      case GameMode.infection:
        return const Color(0xFFFF1744);
      case GameMode.blindMemory:
        return const Color(0xFFD500F9);
      case GameMode.level:
        return kGoldColor;
      case GameMode.laser:
        return const Color(0xFFFF9100);
      case GameMode.meltdown:
        return const Color(0xFFC6FF00);
      case GameMode.crabChase:
        return const Color(0xFF00E5FF);
      case GameMode.casual:
        return const Color(0xFFA855F7);
      case GameMode.classic:
      case GameMode.custom:
        return const Color(0xFF00E676);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();
    final gameWidget = GameWidget(game: controller.snakeGame);

    return Obx(() {
      final shakeX = controller.shakeOffsetX.value;
      final shakeY = controller.shakeOffsetY.value;
      final accent = _getModeAccentColor(controller.gameMode.value);

      return RepaintBoundary(
        child: Transform.translate(
          offset: Offset(shakeX, shakeY),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Frosted Glass Board Frame (Clipped only to background)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.5),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Unclipped Game Canvas
              Positioned.fill(child: gameWidget),
            ],
          ),
        ),
      );
    });
  }
}
