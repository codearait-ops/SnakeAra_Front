import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/wallet_controller.dart';

/// Celebratory popup dialog awarding free coins upon new user registration/first login.
/// Completely driven by backend POST /wallet/claim-welcome-bonus (no hardcoded coin values).
class WelcomeBonusDialog extends StatefulWidget {
  final int? coins;
  final String username;
  final VoidCallback? onDismiss;

  const WelcomeBonusDialog({
    super.key,
    this.coins,
    required this.username,
    this.onDismiss,
  });

  @override
  State<WelcomeBonusDialog> createState() => _WelcomeBonusDialogState();
}

class _WelcomeBonusDialogState extends State<WelcomeBonusDialog> {
  int? _awardedCoins;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _awardedCoins = widget.coins;
  }

  Future<void> _handleClaim() async {
    // If coins were already claimed and passed in from the server, dismiss the dialog
    if (_awardedCoins != null && _awardedCoins! > 0) {
      Get.back();
      widget.onDismiss?.call();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final controller = Get.find<WalletController>();
      final bonus = await controller.claimWelcomeBonus();
      if (bonus != null && bonus.coinsAwarded > 0) {
        if (mounted) {
          setState(() {
            _awardedCoins = bonus.coinsAwarded;
          });
        }
      } else {
        Get.back();
        widget.onDismiss?.call();
      }
    } catch (_) {
      Get.back();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCoins = _awardedCoins;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B10), Color(0xFF0F1117)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Gift / Coins Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.3),
                      const Color(0xFFFF8F00).withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFFFD700),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'welcome_bonus_title'.tr,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                'welcome_bonus_desc'.trParams({'username': widget.username}),
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Coin Amount Badge (from server response)
              if (displayCoins != null && displayCoins > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.25),
                        Colors.orange.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFFD700),
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'welcome_bonus_badge'.trParams({
                          'count': '$displayCoins',
                        }),
                        style: GoogleFonts.vazirmatn(
                          color: const Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
              ],

              // Action Button (Claim or Dismiss)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'welcome_bonus_btn'.tr,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
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
