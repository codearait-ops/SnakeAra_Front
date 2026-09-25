import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/sound_service.dart';
import '../controllers/game_controller.dart';
import '../models/game_mode_config.dart';

/// Fullscreen overlay dialog presented at mode start with rules,
/// a "Don't show again" checkbox, and a "Start Game" action button.
class ModeIntroDialog extends StatefulWidget {
  final GameController controller;
  final GameModeConfig config;

  const ModeIntroDialog({
    super.key,
    required this.controller,
    required this.config,
  });

  @override
  State<ModeIntroDialog> createState() => _ModeIntroDialogState();
}

class _ModeIntroDialogState extends State<ModeIntroDialog>
    with SingleTickerProviderStateMixin {
  bool _dontShowAgain = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onStartGame() {
    if (Get.isRegistered<SoundService>()) {
      Get.find<SoundService>().playButtonTap();
    }
    widget.controller.startGameAfterIntro(dontShowAgain: _dontShowAgain);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final accent = config.accentColor;

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 360,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.5),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with glow & icon
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accent.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Glowing Icon Badge
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Icon(
                                config.icon,
                                size: 32,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Mode Title
                            Text(
                              config.titleTr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: accent.withValues(alpha: 0.6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Subtitle
                            Text(
                              config.subtitleTr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              accent.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Rules Content (Scrollable)
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF030712).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              config.rulesTr,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: Get.locale?.languageCode == 'fa'
                                  ? TextAlign.right
                                  : TextAlign.left,
                            ),
                          ),
                        ),
                      ),

                      // Footer: Checkbox & Start Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Checkbox: Don't show again
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _dontShowAgain = !_dontShowAgain;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _dontShowAgain,
                                        activeColor: accent,
                                        checkColor: Colors.black,
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _dontShowAgain = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'dont_show_again'.tr,
                                      style: GoogleFonts.vazirmatn(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Start Game Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      accent,
                                      accent.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _onStartGame,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 26,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'start_game'.tr,
                                        style: GoogleFonts.vazirmatn(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          height: 1.1,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
