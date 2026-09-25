import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import 'auth_dialog.dart';

/// A context-aware bottom sheet prompting unauthenticated / guest players
/// to sign in or create an account before accessing online/competitive features.
class AuthPromptSheet extends StatelessWidget {
  final String? message;
  final VoidCallback? onAuthenticated;

  const AuthPromptSheet({super.key, this.message, this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? 'login_prompt_default'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: kPrimaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Glowing Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryColor.withValues(alpha: 0.25),
                    kSecondaryColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: kPrimaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: kPrimaryColor,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'guest_gate_title'.tr,
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Context-Aware Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Primary CTA: Login / Register Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.dialog(const AuthDialog()).then((_) {
                    final auth = Get.find<AuthController>();
                    if (auth.isLoggedIn.value && onAuthenticated != null) {
                      onAuthenticated!();
                    }
                  });
                },

                icon: const Icon(Icons.login_rounded, size: 20),
                label: Text(
                  'guest_gate_login_btn'.tr,
                  style: GoogleFonts.vazirmatn(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: kPrimaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Cancel / Continue as Guest
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'guest_gate_cancel_btn'.tr,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
