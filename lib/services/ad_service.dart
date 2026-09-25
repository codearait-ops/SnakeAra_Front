import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/core/widgets/app_loading_widget.dart';
import 'ads/admob_provider.dart';
import 'ads/tapsell_provider.dart';
import 'api_service.dart';

/// Service responsible for managing Rewarded and Video Ads with Waterfall Fallback:
/// 1. Priority 1: Google AdMob (for international users or users with VPN)
/// 2. Priority 2: Tapsell Plus (Fallback for Iranian users or when AdMob fails/times out)
class AdService extends GetxService {
  /// Toggle for development simulation vs production SDK.
  /// Configurable at build time via `--dart-define=AD_MOCK_MODE=true` (defaults to false for release builds).
  static const bool isDevelopmentMock = bool.fromEnvironment(
    'AD_MOCK_MODE',
    defaultValue: false,
  );

  final AdMobProvider _adMobProvider = AdMobProvider();
  final TapsellProvider _tapsellProvider = TapsellProvider();

  bool _isLoadingDialogVisible = false;

  @override
  void onInit() {
    super.onInit();
    _initAdSdk();
  }

  /// Initialize both Ad SDKs in parallel.
  Future<void> _initAdSdk() async {
    if (isDevelopmentMock) {
      debugPrint('[AdService] Running in Development / Mock Mode.');
      return;
    }

    try {
      debugPrint('[AdService] Initializing Google AdMob & Tapsell Plus SDKs...');
      await Future.wait([
        _adMobProvider.initialize(),
        _tapsellProvider.initialize(),
      ]);
      debugPrint('[AdService] All Ad SDKs initialized.');
    } catch (e) {
      debugPrint('[AdService] Error during Ad SDKs initialization: $e');
    }
  }

  /// Shows a rewarded video ad to the user using the Waterfall strategy:
  /// First Google AdMob -> If fails/times out -> Fallback to Tapsell Plus.
  ///
  /// Returns `true` if the user completed watching the ad and earned the reward,
  /// or `false` if the ads failed to load, was skipped, or an error occurred.
  Future<bool> showRewardedAd({
    required BuildContext context,
    String placement = 'daily_challenge_retry',
  }) async {
    if (isDevelopmentMock) {
      return await _showMockRewardedAd(context, placement);
    }

    _showLoadingIndicator();

    try {
      // -----------------------------------------------------------------------
      // Step 1: Priority 1 - Google AdMob
      // -----------------------------------------------------------------------
      debugPrint(
        '[AdService] [Waterfall] Step 1: Trying Google AdMob for placement: $placement',
      );
      final bool adMobSuccess = await _adMobProvider.showRewardedAd(
        context: context,
        onBeforeShow: _dismissLoadingIndicator,
      );

      if (adMobSuccess) {
        debugPrint(
          '[AdService] [Waterfall] Google AdMob rewarded ad watched successfully.',
        );
        return true;
      }

      // -----------------------------------------------------------------------
      // Step 2: Priority 2 - Tapsell Plus Fallback
      // -----------------------------------------------------------------------
      if (!context.mounted) return false;

      debugPrint(
        '[AdService] [Waterfall] Step 2: AdMob unavailable. Falling back to Tapsell Plus for: $placement',
      );
      final bool tapsellSuccess = await _tapsellProvider.showRewardedAd(
        context: context,
        onBeforeShow: _dismissLoadingIndicator,
      );

      if (tapsellSuccess) {
        debugPrint(
          '[AdService] [Waterfall] Tapsell Plus rewarded ad watched successfully.',
        );
        return true;
      }

      // -----------------------------------------------------------------------
      // Step 3: All Providers Failed
      // -----------------------------------------------------------------------
      debugPrint(
        '[AdService] [Waterfall] Both Google AdMob and Tapsell Plus failed to load/display ads.',
      );
      _showAdUnavailableSnackbar();
      return false;
    } catch (e) {
      debugPrint('[AdService] Unexpected exception during ad waterfall: $e');
      _showAdUnavailableSnackbar();
      return false;
    } finally {
      _dismissLoadingIndicator();
    }
  }

  /// Shows a rewarded video ad AND verifies the reward with the backend server
  /// via POST /api/ads/verify-reward before confirming completion.
  Future<bool> showRewardedAdAndVerify({
    required BuildContext context,
    required String placement,
    required String token,
    String? rewardToken,
  }) async {
    if (token.isEmpty) {
      debugPrint('[AdService] Ad reward claim rejected: user is unauthenticated.');
      Get.snackbar(
        'login_required_title'.tr.isNotEmpty
            ? 'login_required_title'.tr
            : 'Login Required',
        'login_required_ad_coins'.tr.isNotEmpty
            ? 'login_required_ad_coins'.tr
            : 'Please log in to watch ads and earn rewards.',
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    }

    final adWatched = await showRewardedAd(context: context, placement: placement);
    if (!adWatched) return false;

    try {
      final api = Get.find<ApiService>();
      final verifyRes = await api.verifyAdReward(
        placement: placement,
        token: token,
        rewardToken: rewardToken,
      );
      if (verifyRes.isSuccess) {
        return true;
      } else {
        debugPrint(
          '[AdService] Server ad reward verification failed: ${verifyRes.message}',
        );
        Get.snackbar(
          'ad_verify_error_title'.tr,
          verifyRes.message ?? 'ad_verify_error_msg'.tr,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      debugPrint('[AdService] Error verifying ad reward: $e');
      return false;
    }
  }

  /// Displays an unobtrusive loading dialog while the ad is requested.
  void _showLoadingIndicator() {
    if (_isLoadingDialogVisible) return;
    _isLoadingDialogVisible = true;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF161B22).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00E676), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingWidget.gold(size: 32),
                const SizedBox(height: 16),
                Text(
                  'loading_ad'.tr.isNotEmpty
                      ? 'loading_ad'.tr
                      : 'در حال دریافت تبلیغ...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Safely dismisses the loading indicator.
  void _dismissLoadingIndicator() {
    if (_isLoadingDialogVisible) {
      _isLoadingDialogVisible = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  /// Informs the user when no video ads could be loaded.
  void _showAdUnavailableSnackbar() {
    Get.snackbar(
      'ads_unavailable_title'.tr.isNotEmpty
          ? 'ads_unavailable_title'.tr
          : 'تبلیغ در دسترس نیست',
      'ads_unavailable_msg'.tr.isNotEmpty
          ? 'ads_unavailable_msg'.tr
          : 'در حال حاضر ویدیوی تبلیغاتی موجود نیست. لطفاً لحظاتی دیگر تلاش فرمایید.',
      backgroundColor: Colors.orange.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  /// Displays a temporary mock dialog simulating an ad watch during development.
  Future<bool> _showMockRewardedAd(
    BuildContext context,
    String placement,
  ) async {
    bool isCompleted = false;

    await Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.ondemand_video_rounded,
                  color: Colors.amber,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'mock_ad_title'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'mock_ad_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const AppLoadingWidget.gold(size: 28),
              const SizedBox(height: 16),
              Text(
                'mock_ad_sim_note'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Simulate 2 seconds ad viewing duration
    await Future.delayed(const Duration(seconds: 2));
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    isCompleted = true;
    return isCompleted;
  }
}
