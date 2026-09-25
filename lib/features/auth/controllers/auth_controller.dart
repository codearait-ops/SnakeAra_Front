import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart' hide MenuController;
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/game_event_logger.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../menu/controllers/menu_controller.dart';
import '../../profile/models/xp_reward_model.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/user_model.dart';
import '../widgets/auth_prompt_sheet.dart';

/// GetX controller managing authentication state, active profile,
/// connectivity gate, and preset avatar selection using the backend API.
class AuthController extends GetxController {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedAvatarId = 'avatar_1'.obs;
  final RxString customAvatarPath = ''.obs;

  // Realtime network connectivity state
  final RxBool hasNetworkConnection = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Central Gate Layer getter: Can the client officially submit scores to the server?
  bool get canSubmitScore =>
      isLoggedIn.value &&
      currentUser.value != null &&
      hasNetworkConnection.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedUser();
    _initConnectivity();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  /// Initialize real-time network connectivity listener
  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('[AuthController] Connectivity check error: $e');
    }
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    hasNetworkConnection.value = results.any(
      (r) => r != ConnectivityResult.none,
    );
  }

  /// Guard wrapper: Checks authentication. If logged in, calls [onAuthenticated];
  /// otherwise presents the context-aware [AuthPromptSheet].
  void requireAuth(VoidCallback onAuthenticated, {String? contextMessage}) {
    if (isLoggedIn.value && currentUser.value != null) {
      onAuthenticated();
    } else {
      Get.bottomSheet(
        AuthPromptSheet(
          message: contextMessage,
          onAuthenticated: onAuthenticated,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      );
    }
  }

  /// Load user state on app boot from local storage
  Future<void> _loadSavedUser() async {
    final storage = Get.find<StorageService>();
    final userId = storage.getSavedUserId();
    final token = storage.cachedUserToken ?? await storage.getUserToken();
    final username = storage.getSavedUsername();
    final avatarId = storage.getSavedAvatarId();
    customAvatarPath.value = storage.getCustomAvatarPath() ?? '';
    selectedAvatarId.value = avatarId;

    if (username != null && username.isNotEmpty) {
      if (userId == null ||
          userId.isEmpty ||
          userId == '0' ||
          userId == 'saved_user') {
        storage.clearUserData();
        currentUser.value = null;
        isLoggedIn.value = false;
        return;
      }

      currentUser.value = UserModel(
        id: userId,
        username: username,
        avatarId: avatarId,
        token: token ?? '',
      );
      isLoggedIn.value = true;

      if (token != null && token.isNotEmpty) {
        fetchUserProfile();
        _syncDeviceToken(token);
      }
    }
  }

  /// Handle invalid or expired session/token gracefully
  Future<void> handleSessionExpired({bool showNotice = false}) async {
    final storage = Get.find<StorageService>();
    await storage.clearUserData();
    await storage.clearPendingScoreSubmission();
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().hasPendingSubmission.value = false;
    }
    currentUser.value = null;
    isLoggedIn.value = false;
    selectedAvatarId.value = 'avatar_1';
    customAvatarPath.value = '';

    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().reset();
    }

    if (Get.isRegistered<MenuController>()) {
      Get.find<MenuController>().resetForGuest();
      Get.find<MenuController>().fetchHomeDashboard(forceRefresh: true);
    }

    if (Get.currentRoute == AppRoutes.profile) {
      Get.offAllNamed(AppRoutes.menu);
    }

    if (showNotice) {
      Get.snackbar(
        'session_expired_title'.tr.isNotEmpty
            ? 'session_expired_title'.tr
            : 'Session Expired',
        'err_unauthenticated'.tr.isNotEmpty
            ? 'err_unauthenticated'.tr
            : 'Your session has expired. Please log in again.',
      );
    }
  }

  /// Fetch user profile details from backend API
  Future<void> fetchUserProfile() async {
    final token = currentUser.value?.token ?? '';
    if (token.isEmpty) return;
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final api = Get.find<ApiService>();
      final response = await api.fetchUserProfile(token: token);
      if (response.isSuccess && response.data != null) {
        final user = response.data!;
        currentUser.value = user;
        selectedAvatarId.value = user.avatarId;

        final storage = Get.find<StorageService>();
        await storage.saveUsername(user.username);
        await storage.saveAvatarId(user.avatarId);
        await storage.setPlayerXp(
          user.xpTotal,
          level: user.level,
          nextLevelXp: user.nextLevelXp,
        );
      } else {
        if (response.statusCode == 401 ||
            response.message?.contains('Unauthenticated') == true ||
            response.message == 'err_unauthenticated'.tr) {
          debugPrint(
            '[AUTH CONTROLLER] ⚠️ Token is invalid/expired (401). Clearing user session.',
          );
          await handleSessionExpired(showNotice: true);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Update XP and Level after score submission or level complete
  void updateXpAndLevel(XpReward xpReward) {
    final finalLevel = xpReward.level;
    final nextXp = xpReward.nextLevelXp ?? currentUser.value?.nextLevelXp;

    if (currentUser.value != null) {
      final updated = currentUser.value!.copyWith(
        xpTotal: xpReward.xpTotal,
        level: finalLevel,
        nextLevelXp: nextXp,
      );
      currentUser.value = updated;
    }
    final storage = Get.find<StorageService>();
    storage.setPlayerXp(
      xpReward.xpTotal,
      level: finalLevel,
      nextLevelXp: nextXp,
    );
  }

  /// Select preset avatar in UI dialog
  void setAvatar(String avatarId) {
    selectedAvatarId.value = avatarId;
  }

  /// Register a new account with username, password, preset avatar, and optional email
  Future<bool> register({
    required String username,
    required String password,
    required String avatarId,
    String? email,
  }) async {
    isLoading.value = true;
    final storage = Get.find<StorageService>();
    final api = Get.find<ApiService>();

    final response = await api.register(
      username: username,
      password: password,
      avatarId: avatarId,
      email: email,
    );

    isLoading.value = false;

    if (response.isSuccess && response.data != null) {
      final user = response.data!;
      currentUser.value = user;
      isLoggedIn.value = true;

      await storage.saveUserId(user.id);
      await storage.saveUserToken(user.token);
      await storage.saveUsername(user.username);
      await storage.saveAvatarId(user.avatarId);

      if (Get.isRegistered<MenuController>()) {
        Get.find<MenuController>().fetchHomeDashboard(forceRefresh: true);
      }

      _syncDeviceToken(user.token);

      Get.snackbar(
        'welcome_title'.tr.isNotEmpty ? 'welcome_title'.tr : 'Welcome!',
        'welcome_msg'.tr.isNotEmpty
            ? '${'welcome_msg'.tr} ${user.username}'
            : 'Logged in as ${user.username}',
      );
      return true;
    } else {
      Get.snackbar('error'.tr, response.message ?? 'Registration failed');
      return false;
    }
  }

  /// Request password reset via API
  Future<bool> forgotPassword({required String email}) async {
    debugPrint(
      '[AUTH CONTROLLER -> FORGOT PASSWORD] Requesting for email: $email',
    );
    isLoading.value = true;

    final api = Get.find<ApiService>();
    final response = await api.forgotPassword(email: email);
    isLoading.value = false;

    if (response.isSuccess) {
      Get.snackbar(
        'notice'.tr.isNotEmpty ? 'notice'.tr : 'Notice',
        response.message ??
            'If this email is registered, you will receive a new temporary password.',
      );
      return true;
    } else {
      Get.snackbar(
        'error'.tr,
        response.message ?? 'Forgot password request failed.',
      );
      return false;
    }
  }

  /// Login with username & password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    isLoading.value = true;
    final storage = Get.find<StorageService>();
    final api = Get.find<ApiService>();

    final response = await api.login(username: username, password: password);
    isLoading.value = false;

    if (response.isSuccess && response.data != null) {
      final user = response.data!;
      currentUser.value = user;
      isLoggedIn.value = true;
      selectedAvatarId.value = user.avatarId;

      await storage.saveUserId(user.id);
      await storage.saveUserToken(user.token);
      await storage.saveUsername(user.username);
      await storage.saveAvatarId(user.avatarId);

      debugPrint('====================================================');
      debugPrint(
        '[AUTH CONTROLLER -> LOGIN SUCCESS] USER TOKEN: ${user.token}',
      );
      debugPrint('====================================================');

      if (Get.isRegistered<MenuController>()) {
        Get.find<MenuController>().fetchHomeDashboard(forceRefresh: true);
      }

      _syncDeviceToken(user.token);

      Get.snackbar(
        'welcome_title'.tr.isNotEmpty ? 'welcome_title'.tr : 'Success',
        'welcome_msg'.tr.isNotEmpty
            ? '${'welcome_msg'.tr} ${user.username}'
            : 'Welcome back, ${user.username}!',
      );
      return true;
    } else {
      Get.snackbar(
        'error'.tr,
        response.message ?? 'Invalid username or password',
      );
      return false;
    }
  }

  /// Logout active session
  Future<void> logout() async {
    final storage = Get.find<StorageService>();
    await storage.clearUserData();
    await storage.clearPendingScoreSubmission();
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().hasPendingSubmission.value = false;
    }
    currentUser.value = null;
    isLoggedIn.value = false;
    selectedAvatarId.value = 'avatar_1';
    customAvatarPath.value = '';

    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().reset();
    }

    if (Get.isRegistered<MenuController>()) {
      Get.find<MenuController>().resetForGuest();
      Get.find<MenuController>().fetchHomeDashboard(forceRefresh: true);
    }

    if (Get.currentRoute == AppRoutes.profile) {
      Get.offAllNamed(AppRoutes.menu);
    }

    Get.snackbar(
      'logged_out_title'.tr.isNotEmpty ? 'logged_out_title'.tr : 'Logged Out',
      'logged_out_msg'.tr.isNotEmpty
          ? 'logged_out_msg'.tr
          : 'Your session has ended.',
    );
  }

  /// Update active profile avatar
  Future<void> updateAvatar(String newAvatarId) async {
    selectedAvatarId.value = newAvatarId;
    if (currentUser.value != null) {
      currentUser.value = currentUser.value!.copyWith(avatarId: newAvatarId);
      final storage = Get.find<StorageService>();
      await storage.saveAvatarId(newAvatarId);
    }
  }

  /// Save local custom cropped image path
  Future<void> saveCustomAvatar(String imagePath) async {
    customAvatarPath.value = imagePath;
    selectedAvatarId.value = 'avatar_7';
    final storage = Get.find<StorageService>();
    await storage.saveCustomAvatarPath(imagePath);
    await storage.saveAvatarId('avatar_7');
    if (currentUser.value != null) {
      currentUser.value = currentUser.value!.copyWith(avatarId: 'avatar_7');
    }
  }

  /// Update full profile (username, avatar, currentPassword, newPassword, email, bio)
  Future<String?> updateFullProfile({
    required String username,
    required String avatarId,
    File? avatar,
    String? currentPassword,
    String? newPassword,
    String? email,
    String? bio,
  }) async {
    isLoading.value = true;
    final api = Get.find<ApiService>();
    final token = currentUser.value?.token ?? '';

    // If online token exists, call API
    if (token.isNotEmpty) {
      final response = await api.updateProfile(
        token: token,
        username: username,
        avatarId: avatarId,
        avatar: avatar,
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: email,
        bio: bio,
      );

      isLoading.value = false;

      if (response.isSuccess && response.data != null) {
        final user = response.data!;
        currentUser.value = user;
        selectedAvatarId.value = user.avatarId;

        return response.message ?? 'profile_updated_success'.tr;
      } else {
        Get.snackbar(
          'error'.tr,
          response.message ?? 'profile_updated_failed'.tr,
        );
        return null;
      }
    } else {
      // Local storage fallback for guest or offline mode
      selectedAvatarId.value = avatarId;
      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          username: username,
          avatarId: avatarId,
          email: email,
          bio: bio,
        );
      }

      isLoading.value = false;
      return 'profile_updated_success'.tr;
    }
  }

  void _syncDeviceToken(String? token) {
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.sendDeviceTokenToServer(authToken: token);
    }
  }
}
