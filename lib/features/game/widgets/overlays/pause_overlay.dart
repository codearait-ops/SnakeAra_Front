import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../controllers/game_controller.dart';

/// Animated pause content with pulsing icon and controls.
class PauseContent extends StatefulWidget {
  final GameController controller;
  const PauseContent({super.key, required this.controller});

  @override
  State<PauseContent> createState() => _PauseContentState();
}

class _PauseContentState extends State<PauseContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) =>
              Transform.scale(scale: _pulseAnim.value, child: child),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: kPrimaryColor.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.pause, color: kPrimaryColor, size: 48),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'paused'.tr,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
            shadows: [Shadow(color: kPrimaryColor, blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'resume'.tr,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => widget.controller.goToMenu(),
              icon: Icon(
                widget.controller.snakeGame.isLeagueAttempt
                    ? Icons.emoji_events_rounded
                    : Icons.home_rounded,
                size: 22,
              ),
              label: Text(
                widget.controller.snakeGame.isLeagueAttempt
                    ? 'back_to_league'.tr
                    : 'home'.tr,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => widget.controller.togglePause(),
              icon: const Icon(Icons.play_arrow, size: 24),
              label: Text('resume'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: kPrimaryColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
