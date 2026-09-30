import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../services/storage_service.dart';
import '../../../services/app_update_service.dart';
import '../../app_update/models/app_version_model.dart';
import '../../app_update/widgets/app_update_dialog.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../menu/controllers/menu_controller.dart';

/// Controller handling splash screen lifecycle, progress animations,
/// network synchronization, timeout fallback, and navigation to menu.
class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxDouble progress = 0.0.obs;
  final RxString statusMessage = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorDetails = ''.obs;

  /// Minimum duration to keep splash visible for smooth branding experience (3 seconds)
  static const Duration minSplashDuration = Duration(seconds: 3);

  /// Maximum duration to wait before timing out (10 seconds)
  static const Duration timeoutDuration = Duration(seconds: 10);

  @override
  void onInit() {
    super.onInit();
    startInitialization();
  }

  /// Initiates the full application startup flow with stepped progress, minimum 3s display, and timeout safety.
  Future<void> startInitialization() async {
    final stopwatch = Stopwatch()..start();
    isLoading.value = true;
    hasError.value = false;
    errorDetails.value = '';
    progress.value = 0.15;
    statusMessage.value = 'splash_loading_init'.tr;

    try {
      // Step 1: Small initial delay & Auth check
      await Future.delayed(const Duration(milliseconds: 400));
      progress.value = 0.4;
      statusMessage.value = 'splash_checking_auth'.tr;

      // Ensure AuthController is loaded
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        // Wait briefly if auth is currently loading saved user
        if (auth.currentUser.value == null && Get.isRegistered<StorageService>()) {
          final storage = Get.find<StorageService>();
          final token = storage.cachedUserToken ?? await storage.getUserToken();
          if (token != null && token.isNotEmpty) {
            await auth.fetchUserProfile().timeout(
              const Duration(seconds: 4),
              onTimeout: () => debugPrint('[SplashController] Auth fetch timeout'),
            );
          }
        }
      }

      // Step 2: Fetch Home Dashboard & Game Data with overall timeout
      progress.value = 0.7;
      statusMessage.value = 'splash_loading_data'.tr;

      await _fetchDashboardWithTimeout();

      // Step 2.5: Check for App Updates (Non-blocking with 8s timeout)
      UpdateEvaluationResult? updateResult;
      if (Get.isRegistered<AppUpdateService>()) {
        try {
          updateResult = await Get.find<AppUpdateService>()
              .checkForUpdate()
              .timeout(
                const Duration(seconds: 8),
                onTimeout: () => const UpdateEvaluationResult(
                  action: UpdateActionType.none,
                  currentVersion: '1.0.0',
                  currentBuild: 1,
                ),
              );
        } catch (e) {
          debugPrint('[SplashController] Update check non-blocking error: $e');
        }
      }

      // Step 3: Ensure minimum 3 seconds has elapsed for smooth splash experience
      progress.value = 0.95;
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final remainingMs = minSplashDuration.inMilliseconds - elapsedMs;
      if (remainingMs > 0) {
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      // Complete progress
      progress.value = 1.0;
      statusMessage.value = 'splash_ready'.tr;
      isLoading.value = false;

      // Mandatory Update check: Block entry if force update required
      if (updateResult != null && updateResult.isForce) {
        debugPrint('[SplashController] Mandatory update required. Halting navigation.');
        if (Get.context != null) {
          AppUpdateDialog.show(
            context: Get.context!,
            evaluationResult: updateResult,
          );
        }
        return;
      }

      // Short aesthetic delay for the 100% progress animation to finish
      await Future.delayed(const Duration(milliseconds: 350));

      _navigateToHome();

      // If optional update available, prompt on top of Home screen
      if (updateResult != null && updateResult.isOptional) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (Get.context != null) {
            AppUpdateDialog.show(
              context: Get.context!,
              evaluationResult: updateResult!,
            );
          }
        });
      }
    } catch (e, stack) {
      debugPrint('[SplashController] Initialization error: $e\n$stack');
      _handleInitializationError(e.toString());
    } finally {
      stopwatch.stop();
    }
  }

  /// Attempts to fetch the aggregated dashboard with strict timeout.
  Future<void> _fetchDashboardWithTimeout() async {
    try {
      // Ensure MenuController exists
      MenuController menuCtrl;
      if (Get.isRegistered<MenuController>()) {
        menuCtrl = Get.find<MenuController>();
      } else {
        menuCtrl = Get.put<MenuController>(MenuController(), permanent: true);
      }

      await menuCtrl.fetchHomeDashboard(forceRefresh: true).timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException('Request timed out after ${timeoutDuration.inSeconds} seconds');
        },
      );
    } catch (e) {
      // Re-throw to be captured by startInitialization handler
      rethrow;
    }
  }

  /// Handles timeout or network failure by presenting retry & offline options.
  void _handleInitializationError(String err) {
    isLoading.value = false;
    hasError.value = true;
    errorDetails.value = err;
    if (err.toLowerCase().contains('timeout')) {
      statusMessage.value = 'splash_error_timeout'.tr;
    } else {
      statusMessage.value = 'splash_error_general'.tr;
    }
  }

  /// User action: Retry connection and loading
  void retry() {
    startInitialization();
  }

  /// User action: Bypass online synchronization and continue as guest / offline
  void continueOffline() {
    _navigateToHome();
  }

  /// Navigates to the Home/Menu screen safely
  void _navigateToHome() {
    Get.offAllNamed(AppRoutes.menu);
  }
}
