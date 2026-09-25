import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';

/// Interactive top-bar badge showing player's current coin balance
/// designed in the same 3D Gold Coin pill style as the Home screen.
class WalletBadgeWidget extends StatelessWidget {
  final bool showAddButton;
  final VoidCallback? onAddTap;

  const WalletBadgeWidget({
    super.key,
    this.showAddButton = false,
    this.onAddTap,
  });

  static String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = Get.find<WalletController>();
    final auth = Get.find<AuthController>();

    return Obx(() {
      final balance = wallet.balance.value;
      final isLoggedIn = auth.isLoggedIn.value;

      return GestureDetector(
        onTap: () {
          if (onAddTap != null) {
            onAddTap!();
            return;
          }
          auth.requireAuth(() {
            Get.toNamed('/wallet/history');
          }, contextMessage: 'login_required_wallet'.tr);
        },
        child: Container(
          height: 30,
          padding: const EdgeInsetsDirectional.fromSTEB(7, 0, 5, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2230).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _GoldCoinIcon(size: 17),
              const SizedBox(width: 5),
              Text(
                isLoggedIn ? _formatNumber(balance) : '0',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  height: 1.15,
                ),
              ),
              if (showAddButton) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    if (onAddTap != null) {
                      onAddTap!();
                      return;
                    }
                    auth.requireAuth(() {
                      Get.toNamed('/wallet/history');
                    }, contextMessage: 'login_required_wallet'.tr);
                  },
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
            ],
          ),
        ),
      );
    });
  }
}

/// 3D Glossy Gold Coin Icon (matching Home Screen style)
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
            color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
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
