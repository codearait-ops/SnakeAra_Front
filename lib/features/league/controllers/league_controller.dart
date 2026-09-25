import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/league_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/weekend_league_models.dart';

/// GetX controller managing Weekend League lifecycle, status polling,
/// registration with client pre-check, auto-enrollment, and group leaderboard.
class LeagueController extends GetxController {
  final LeagueApiService _api = Get.find<LeagueApiService>();
  final AuthController _auth = Get.find<AuthController>();

  // State flags
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  // Weekend League Season Status
  final Rx<LeagueSeasonStatus?> seasonStatus = Rx<LeagueSeasonStatus?>(null);
  final RxBool isRegistered = false.obs;
  final RxBool autoEnrollEnabled = false.obs;

  // Group Leaderboard State (active phase)
  final Rx<LeagueGroupResponse?> groupData = Rx<LeagueGroupResponse?>(null);
  final RxBool isLoadingGroup = false.obs;
  final RxString groupErrorMessage = ''.obs;

  // Action states
  final RxBool isRegistering = false.obs;
  final RxBool isTogglingAutoEnroll = false.obs;

  // Countdown timer state
  final Rx<Duration> remainingCountdown = Duration.zero.obs;
  Timer? _countdownTimer;
  DateTime? _targetUtcTime;

  // Periodic polling timers
  Timer? _statusPollTimer;
  Timer? _groupPollTimer;

  // Polling intervals
  static const Duration _statusPollInterval = Duration(seconds: 60);
  static const Duration _groupPollInterval = Duration(seconds: 45);

  // Backward compatibility getters
  bool get canPlayLeague =>
      seasonStatus.value?.phase == LeagueSeasonPhase.active &&
      isRegistered.value;

  bool get isEntered => isRegistered.value;

  LeagueSeasonPhase get phase =>
      seasonStatus.value?.phase ?? LeagueSeasonPhase.unknown;

  int get seasonNumber => seasonStatus.value?.seasonNumber ?? 1;

  bool _isFetchingStatus = false;

  @override
  void onInit() {
    super.onInit();
    _startPeriodicStatusPolling();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
    _groupPollTimer?.cancel();
    _groupPollTimer = null;
    super.onClose();
  }

  // ===========================================================================
  // 1. SEASON STATUS & COUNTDOWN (§1.1)
  // ===========================================================================

  /// Fetches season phase, timers, cost, and registration status from GET /league/status
  Future<void> fetchLeagueStatus({
    bool isPullToRefresh = false,
    bool resetState = false,
  }) async {
    if (_isFetchingStatus) {
      debugPrint('⏳ [LeagueController] fetchLeagueStatus already in progress, skipping duplicate call');
      return;
    }
    _isFetchingStatus = true;

    debugPrint(
      '🏆 [LeagueController] fetchLeagueStatus started (pullToRefresh: $isPullToRefresh, resetState: $resetState, user: ${_auth.currentUser.value?.username})',
    );
    if (isPullToRefresh) {
      isRefreshing.value = true;
    } else if (resetState || seasonStatus.value == null) {
      isLoading.value = true;
      if (resetState) {
        seasonStatus.value = null;
        groupData.value = null;
      }
    }
    errorMessage.value = '';

    try {
      final token = _auth.currentUser.value?.token;
      final res = await _api.getLeagueStatus(
        token: token != null && token.isNotEmpty ? token : null,
      );

      if (res.isSuccess && res.data != null) {
        final status = res.data!;
        isRegistered.value = status.isRegistered;
        autoEnrollEnabled.value = status.autoEnroll;

        debugPrint(
          '🏆 [LeagueController] League status received: '
          'phase=${status.phase.name} (raw: ${status.rawStatus}), '
          'seasonNumber=${status.seasonNumber}, '
          'isRegistered=${status.isRegistered}, '
          'autoEnroll=${status.autoEnroll}',
        );

        // If backend returned user coins, update wallet
        if (status.userCoins != null && Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().receiveCoins(
            0,
            newServerBalance: status.userCoins,
            animate: false,
          );
        }

        // Setup countdown target based on current phase and registration state
        _updateCountdownTarget(status);

        // Fetch group data FIRST before revealing seasonStatus to UI
        if (status.phase == LeagueSeasonPhase.active && status.isRegistered) {
          debugPrint(
            '⚔️ [LeagueController] Season is active and user registered — fetching group data',
          );
          await fetchLeagueGroup();
          _startPeriodicGroupPolling();
        } else if (status.phase == LeagueSeasonPhase.completed &&
            status.isRegistered) {
          debugPrint(
            '🏁 [LeagueController] Season completed and user registered — fetching final group standings for podium',
          );
          await fetchLeagueGroup();
          _groupPollTimer?.cancel();
          _groupPollTimer = null;
        } else {
          _groupPollTimer?.cancel();
          _groupPollTimer = null;
        }

        // Set status atomically so UI renders once with all data ready
        seasonStatus.value = status;
      } else {
        debugPrint(
          '⚠️ [LeagueController] Failed to fetch league status: ${res.message} (status: ${res.statusCode})',
        );
        errorMessage.value = res.message ?? 'error_loading_data'.tr;
      }
    } catch (e, stack) {
      debugPrint(
        '💥 [LeagueController] Exception in fetchLeagueStatus: $e\n$stack',
      );
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      _isFetchingStatus = false;
    }
  }

  /// Calculates target UTC instant from backend response and starts local 1-second ticks.
  /// Re-evaluating on each status poll corrects any client clock drift.
  void _updateCountdownTarget(LeagueSeasonStatus status) {
    DateTime? target;

    switch (status.phase) {
      case LeagueSeasonPhase.registrationOpen:
        if (status.isRegistered) {
          target = status.startsAt;
        } else {
          target = status.registrationClosesAt ?? status.startsAt;
        }
        break;
      case LeagueSeasonPhase.grouping:
        target = status.startsAt;
        break;
      case LeagueSeasonPhase.active:
        target = status.endsAt;
        break;
      case LeagueSeasonPhase.completed:
      case LeagueSeasonPhase.cancelledLowTurnout:
      case LeagueSeasonPhase.unknown:
        target = null;
        break;
    }

    _targetUtcTime = target;
    _countdownTimer?.cancel();

    if (_targetUtcTime != null) {
      _tick();
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _tick(),
      );
    } else {
      remainingCountdown.value = Duration.zero;
    }
  }

  /// Executes 1-second countdown tick against device UTC time.
  void _tick() {
    if (_targetUtcTime == null) {
      remainingCountdown.value = Duration.zero;
      return;
    }
    final nowUtc = DateTime.now().toUtc();
    final diff = _targetUtcTime!.difference(nowUtc);
    if (diff.isNegative || diff.inSeconds <= 0) {
      remainingCountdown.value = Duration.zero;
      _countdownTimer?.cancel();
      // Auto-refresh status when a countdown expires to transition phase
      fetchLeagueStatus();
    } else {
      remainingCountdown.value = diff;
    }
  }

  void _startPeriodicStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(_statusPollInterval, (_) {
      fetchLeagueStatus();
    });
  }

  // ===========================================================================
  // 2. REGISTRATION FLOW (§4)
  // ===========================================================================

  /// Registers current player with client pre-check, server balance update, and idempotency
  Future<bool> registerForLeague() async {
    final user = _auth.currentUser.value;
    debugPrint('📝 [LeagueController] registerForLeague initiated by user: ${user?.username} (id: ${user?.id})');
    if (user == null || user.token.isEmpty) {
      debugPrint('⚠️ [LeagueController] Registration aborted: No authenticated user');
      Get.snackbar(
        'login_required'.tr,
        'login_to_participate_league'.tr,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    final status = seasonStatus.value;
    final cost = status?.entryCost ?? 150;
    final isFree = status?.isFreeEntry ?? false;

    // Client-side pre-check purely for UX
    if (!isFree) {
      final currentBalance = Get.isRegistered<WalletController>()
          ? Get.find<WalletController>().balance.value
          : (status?.userCoins ?? 0);

      debugPrint('💳 [LeagueController] Pre-check: cost=$cost, balance=$currentBalance, isFree=$isFree');
      if (currentBalance < cost) {
        debugPrint('⚠️ [LeagueController] Insufficient coins for league registration: cost=$cost, balance=$currentBalance');
        Get.snackbar(
          'insufficient_coins_title'.tr,
          'insufficient_coins_for_league'.trParams({
            'cost': cost.toString(),
            'balance': currentBalance.toString(),
          }),
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          mainButton: TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/shop');
            },
            child: Text(
              'get_coins'.tr,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        return false;
      }
    }

    isRegistering.value = true;
    try {
      debugPrint('🚀 [LeagueController] Sending register request to backend...');
      final res = await _api.registerForLeague(token: user.token);

      if (res.isSuccess && res.data != null) {
        debugPrint('✅ [LeagueController] Registration confirmed! alreadyRegistered=${res.data!.alreadyRegistered}, newBalance=${res.data!.newBalance}');
        isRegistered.value = true;
        if (seasonStatus.value != null) {
          seasonStatus.value = seasonStatus.value!.copyWith(isRegistered: true);
        }

        // Authoritatively update wallet balance from server response
        if (res.data!.newBalance != null && Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().receiveCoins(
            0,
            newServerBalance: res.data!.newBalance,
            animate: false,
          );
        }

        // Refresh countdown target to "You're in — starts in X"
        if (seasonStatus.value != null) {
          _updateCountdownTarget(seasonStatus.value!);
        }

        Get.snackbar(
          'success'.tr,
          res.data!.alreadyRegistered
              ? 'league_already_registered'.tr
              : 'league_registration_success'.tr,
          backgroundColor: const Color(0xFF00E676),
          colorText: Colors.black,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        debugPrint('❌ [LeagueController] Registration failed: ${res.message}');
        Get.snackbar(
          'error'.tr,
          res.message ?? 'failed_to_register_league'.tr,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e, stack) {
      debugPrint('💥 [LeagueController] Registration exception: $e\n$stack');
      return false;
    } finally {
      isRegistering.value = false;
    }
  }

  // ===========================================================================
  // 3. AUTO-ENROLL TOGGLE (§1.3)
  // ===========================================================================

  /// Toggles auto-enrollment with optimistic UI update and revert on error
  Future<void> toggleAutoEnroll(bool enabled) async {
    final user = _auth.currentUser.value;
    if (user == null || user.token.isEmpty) {
      debugPrint('⚠️ [LeagueController] toggleAutoEnroll aborted: No user logged in');
      return;
    }

    final prevValue = autoEnrollEnabled.value;
    debugPrint('🔄 [LeagueController] toggleAutoEnroll: $prevValue -> $enabled (optimistic)');
    // Optimistic UI update
    autoEnrollEnabled.value = enabled;
    if (seasonStatus.value != null) {
      seasonStatus.value = seasonStatus.value!.copyWith(autoEnroll: enabled);
    }

    isTogglingAutoEnroll.value = true;
    try {
      final res = await _api.toggleAutoEnroll(token: user.token, enabled: enabled);
      if (res.isSuccess) {
        debugPrint('✅ [LeagueController] toggleAutoEnroll successful! serverValue=${res.data}');
        autoEnrollEnabled.value = res.data ?? enabled;
        if (seasonStatus.value != null) {
          seasonStatus.value =
              seasonStatus.value!.copyWith(autoEnroll: autoEnrollEnabled.value);
        }
      } else {
        debugPrint('❌ [LeagueController] toggleAutoEnroll failed on server: ${res.message} — reverting to $prevValue');
        // Revert on error
        autoEnrollEnabled.value = prevValue;
        if (seasonStatus.value != null) {
          seasonStatus.value =
              seasonStatus.value!.copyWith(autoEnroll: prevValue);
        }
        Get.snackbar(
          'error'.tr,
          res.message ?? 'failed_to_update_auto_enroll'.tr,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e, stack) {
      debugPrint('💥 [LeagueController] Exception in toggleAutoEnroll: $e\n$stack — reverting to $prevValue');
      // Revert on exception
      autoEnrollEnabled.value = prevValue;
      if (seasonStatus.value != null) {
        seasonStatus.value = seasonStatus.value!.copyWith(autoEnroll: prevValue);
      }
    } finally {
      isTogglingAutoEnroll.value = false;
    }
  }

  // ===========================================================================
  // 4. GROUP LEADERBOARD (§1.2)
  // ===========================================================================

  /// Fetches live group standings from GET /league/group
  Future<void> fetchLeagueGroup({bool isPull = false}) async {
    final user = _auth.currentUser.value;
    if (user == null || user.token.isEmpty) {
      debugPrint('⚠️ [LeagueController] fetchLeagueGroup aborted: User not authenticated');
      return;
    }

    // Do not attempt to fetch group if user is not registered in this season
    if (seasonStatus.value != null && !seasonStatus.value!.isRegistered) {
      debugPrint('⚠️ [LeagueController] fetchLeagueGroup aborted: User is not registered in this season');
      isLoadingGroup.value = false;
      return;
    }

    debugPrint('👥 [LeagueController] fetchLeagueGroup started (isPull: $isPull, user: ${user.username})');
    if (!isPull && groupData.value == null) {
      isLoadingGroup.value = true;
    }
    groupErrorMessage.value = '';

    try {
      final res = await _api.getLeagueGroup(
        token: user.token,
        currentUserId: int.tryParse(user.id),
        currentUsername: user.username,
      );

      if (res.isSuccess && res.data != null) {
        final group = res.data!;
        groupData.value = group;
        debugPrint(
          '👥 [LeagueController] League group standings loaded: '
          'groupId=${group.groupId}, '
          'membersCount=${group.members.length}, '
          'myRank=${group.myRank}, '
          'myScore=${group.myScore}, '
          'promotionCutoff=${group.promotionCutoff}, '
          'relegationCutoff=${group.relegationCutoff}',
        );
      } else {
        debugPrint('⚠️ [LeagueController] Error loading league group: ${res.message} (status: ${res.statusCode})');
        // Handle 403 (e.g. user not assigned to a group) gracefully
        if (res.statusCode == 403 ||
            (res.message != null &&
                res.message!.toLowerCase().contains('not assigned to any group'))) {
          if (isRegistered.value) {
            isRegistered.value = false;
          }
          groupData.value = null;
          _groupPollTimer?.cancel();
          _groupPollTimer = null;
        } else {
          groupErrorMessage.value = res.message ?? 'error_loading_leaderboard'.tr;
        }
      }
    } catch (e, stack) {
      debugPrint('💥 [LeagueController] Exception in fetchLeagueGroup: $e\n$stack');
      groupErrorMessage.value = e.toString();
    } finally {
      isLoadingGroup.value = false;
    }
  }

  void _startPeriodicGroupPolling() {
    _groupPollTimer?.cancel();
    _groupPollTimer = Timer.periodic(_groupPollInterval, (_) {
      if (seasonStatus.value?.phase == LeagueSeasonPhase.active &&
          seasonStatus.value?.isRegistered == true) {
        fetchLeagueGroup(isPull: true);
      } else {
        _groupPollTimer?.cancel();
        _groupPollTimer = null;
      }
    });
  }

  /// Backward compatible wrapper
  Future<void> fetchLeagueData() => fetchLeagueStatus(isPullToRefresh: true);
}
