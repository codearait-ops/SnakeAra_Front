import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../services/app_update_service.dart';
import '../../../services/sound_service.dart';
import '../models/app_version_model.dart';

/// Cyberpunk-themed modal dialog for displaying optional and mandatory app updates.
class AppUpdateDialog extends StatelessWidget {
  final UpdateEvaluationResult evaluationResult;

  const AppUpdateDialog({
    super.key,
    required this.evaluationResult,
  });

  /// Displays the update dialog in the given context or Get overlay.
  static Future<void> show({
    required BuildContext context,
    required UpdateEvaluationResult evaluationResult,
  }) async {
    final isForce = evaluationResult.isForce;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isForce,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (ctx) => AppUpdateDialog(evaluationResult: evaluationResult),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = evaluationResult.versionModel;
    final isForce = evaluationResult.isForce;
    final langCode = Get.locale?.languageCode ?? 'fa';

    final title = model?.getTitle(langCode) ??
        (isForce ? 'update_force_title'.tr : 'update_optional_title'.tr);
    final releaseNotes = model?.getReleaseNotes(langCode) ?? '';

    return PopScope(
      canPop: !isForce,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF12161F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isForce
                  ? const Color(0xFFFF5252).withValues(alpha: 0.6)
                  : kPrimaryColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isForce ? const Color(0xFFFF5252) : kPrimaryColor)
                    .withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Header Banner ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isForce ? const Color(0xFFFF5252) : kPrimaryColor)
                              .withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Glowing Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A2230),
                            border: Border.all(
                              color: isForce
                                  ? const Color(0xFFFF5252)
                                  : kPrimaryColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isForce
                                        ? const Color(0xFFFF5252)
                                        : kPrimaryColor)
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Icon(
                            isForce
                                ? Icons.system_security_update_rounded
                                : Icons.rocket_launch_rounded,
                            color: isForce
                                ? const Color(0xFFFF5252)
                                : kPrimaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Mandatory Tag if force
                        if (isForce) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF5252)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'update_mandatory_badge'.tr,
                              style: GoogleFonts.vazirmatn(
                                color: const Color(0xFFFF5252),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Version transition badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF30363D),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'v${evaluationResult.currentVersion}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: kPrimaryColor,
                                  size: 14,
                                ),
                              ),
                              Text(
                                'v${model?.latestVersion ?? 'New'}',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Release Notes Body ---
                  if (releaseNotes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.new_releases_outlined,
                                color: Color(0xFFFFD700),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'update_whats_new'.tr,
                                style: GoogleFonts.vazirmatn(
                                  color: const Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 120),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF21262D),
                              ),
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                releaseNotes,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- Action Buttons ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: Column(
                      children: [
                        // Update Now Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (Get.isRegistered<SoundService>()) {
                                Get.find<SoundService>().playButtonClick();
                              }
                              if (model != null &&
                                  Get.isRegistered<AppUpdateService>()) {
                                Get.find<AppUpdateService>()
                                    .launchUpdateUrl(model);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isForce
                                  ? const Color(0xFFFF5252)
                                  : kPrimaryColor,
                              foregroundColor: Colors.black,
                              elevation: 6,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              shadowColor: (isForce
                                      ? const Color(0xFFFF5252)
                                      : kPrimaryColor)
                                  .withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.download_rounded,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'update_now_btn'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.black87,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Optional "Later" Button
                        if (!isForce) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () async {
                                if (Get.isRegistered<SoundService>()) {
                                  Get.find<SoundService>().playButtonClick();
                                }
                                if (Get.isRegistered<AppUpdateService>()) {
                                  await Get.find<AppUpdateService>()
                                      .recordDismissal();
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                foregroundColor: Colors.white54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'update_later_btn'.tr,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
