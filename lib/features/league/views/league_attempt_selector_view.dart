import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../../app/core/utils/enums.dart';
import '../../../services/ad_service.dart';
import '../../../services/league_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../game/models/game_mode_config.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/league_controller.dart';
import '../models/league_tier_models.dart';

/// Standalone view for selecting game mode, viewing remaining daily attempts,
/// unlocking extra attempts via ads/coins, and launching a competitive League attempt.
class LeagueAttemptSelectorView extends StatefulWidget {
  const LeagueAttemptSelectorView({super.key});

  @override
  State<LeagueAttemptSelectorView> createState() =>
      _LeagueAttemptSelectorViewState();
}

class _LeagueAttemptSelectorViewState extends State<LeagueAttemptSelectorView> {
  final LeagueApiService _leagueApi = Get.find<LeagueApiService>();
  final AdService _adService = Get.find<AdService>();
  final AuthController _auth = Get.find<AuthController>();
  final WalletController _wallet = Get.find<WalletController>();

  final Rx<LeagueCycleStatus?> cycleStatus = Rx<LeagueCycleStatus?>(null);
  final RxBool isLoading = false.obs;
  final Rx<GameMode> selectedMode = GameMode.classic.obs;

  static const List<GameMode> _leagueModes = [
    GameMode.classic,
    GameMode.laser,
    GameMode.infection,
    GameMode.blindMemory,
    GameMode.meltdown,
    GameMode.crabChase,
  ];

  List<GameModeConfig> get _leagueGameModes => availableGameModes
      .where((config) => _leagueModes.contains(config.mode))
      .toList();

  @override
  void initState() {
    super.initState();
    _fetchCycleStatus();
  }

  Future<void> _fetchCycleStatus() async {
    final user = _auth.currentUser.value;
    if (user == null || user.token.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await _leagueApi.getLeagueCycleStatus(
        token: user.token,
        currentUserId: int.tryParse(user.id),
      );
      if (response.isSuccess && response.data != null) {
        cycleStatus.value = response.data;
      } else {
        // Fallback default cycle status
        cycleStatus.value = LeagueCycleStatus(
          seasonNumber: 1,
          currentTier: LeagueTier.bronze,
          groupId: 1,
          isEntered: false,
          freeAttemptsRemaining: LeagueCycleStatus.defaultFreeAttempts(),
        );
      }
    } catch (e) {
      cycleStatus.value = LeagueCycleStatus(
        seasonNumber: 1,
        currentTier: LeagueTier.bronze,
        groupId: 1,
        isEntered: false,
        freeAttemptsRemaining: LeagueCycleStatus.defaultFreeAttempts(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _unlockAttemptViaAd({bool autoStart = false}) async {
    final user = _auth.currentUser.value;
    if (user == null) return;

    final modeKey = selectedMode.value.apiName;
    final adSuccess = await _adService.showRewardedAdAndVerify(
      context: context,
      placement: 'league_extra_attempt',
      token: user.token,
    );

    if (adSuccess) {
      final res = await _leagueApi.unlockExtraAttemptViaAd(
        token: user.token,
        gameMode: modeKey,
      );
      if (res.isSuccess) {
        Get.snackbar(
          'success'.tr,
          'extra_attempt_ad_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await _fetchCycleStatus();
        if (autoStart) {
          _startAttempt(forceStart: true);
        }
      }
    }
  }

  int get _extraAttemptCost => cycleStatus.value?.extraAttemptCostCoins ?? 15;

  Future<void> _unlockAttemptViaCoins({bool autoStart = false}) async {
    final user = _auth.currentUser.value;
    if (user == null) return;

    final cost = _extraAttemptCost;
    if (!_wallet.hasEnoughCoins(cost)) {
      Get.snackbar(
        'insufficient_coins'.tr,
        'insufficient_coins_extra_attempt'.trParams({'cost': '$cost'}),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final modeKey = selectedMode.value.apiName;
    final res = await _leagueApi.unlockExtraAttemptViaCoins(
      token: user.token,
      gameMode: modeKey,
    );
    if (res.isSuccess) {
      await _wallet.fetchWalletBalance();
      Get.snackbar(
        'success'.tr,
        'extra_attempt_purchased'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await _fetchCycleStatus();
      if (autoStart) {
        _startAttempt(forceStart: true);
      }
    } else {
      Get.snackbar('error'.tr, res.message ?? 'error'.tr);
    }
  }

  void _showUnlockAttemptDialog() {
    final modeConfig = availableGameModes.firstWhere(
      (c) => c.mode == selectedMode.value,
      orElse: () => availableGameModes.first,
    );

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Icon Header
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade500,
                      Colors.orangeAccent.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'free_attempts_exhausted_title'.tr,
                style: GoogleFonts.vazirmatn(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'extra_attempt_dialog_desc'.trParams({'mode': modeConfig.titleTr}),
                style: GoogleFonts.vazirmatn(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),

              // Option 1: Ad Option
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Get.back();
                    _unlockAttemptViaAd(autoStart: true);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade800.withValues(alpha: 0.25),
                          Colors.deepOrange.shade900.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.video_library_rounded,
                            color: Colors.orangeAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'extra_attempt_ad_btn'.tr,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'extra_attempt_ad_desc'.tr,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.orangeAccent,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: 40 Coins Option
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Get.back();
                    _unlockAttemptViaCoins(autoStart: true);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade800.withValues(alpha: 0.25),
                          Colors.yellow.shade900.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFD700),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'extra_attempt_coins_btn'.trParams({'cost': '$_extraAttemptCost'}),
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Obx(() => Text(
                                'your_coin_balance'.trParams({'balance': '${_wallet.balance.value}'}),
                                style: GoogleFonts.vazirmatn(
                                  color: _wallet.hasEnoughCoins(_extraAttemptCost)
                                      ? Colors.white54
                                      : Colors.redAccent,
                                  fontSize: 11,
                                ),
                              )),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFFFD700),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Cancel button
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'cancel'.tr,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  bool get _canPlayLeague {
    if (Get.isRegistered<LeagueController>()) {
      return Get.find<LeagueController>().canPlayLeague;
    }
    return true;
  }

  /// Starts a league game attempt.
  ///
  /// [forceStart] should be `true` when called immediately after a successful
  /// extra-attempt purchase (via coins or ad). In that case, the `freeLeft <= 0`
  /// gate is bypassed — the server already deducted the cost and granted the
  /// attempt, so we must not re-show the unlock dialog.
  void _startAttempt({bool forceStart = false}) {
    final status = cycleStatus.value;
    if (!_canPlayLeague || (status != null && !status.isEntered)) {
      Get.snackbar(
        'league_ended_title'.tr,
        'league_not_registered_desc'.tr,
        backgroundColor: Colors.orange.shade900.withValues(alpha: 0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
      );
      return;
    }

    final modeKey = selectedMode.value.apiName;
    final freeLeft = status?.getFreeAttempts(modeKey) ??
        (status?.maxFreeAttempts ?? 8);

    // Only gate on zero free attempts when this is NOT a post-purchase start.
    // After a successful coin/ad purchase the server has already granted the
    // extra attempt; blocking here would silently discard the paid attempt.
    if (!forceStart && status != null && freeLeft <= 0) {
      _showUnlockAttemptDialog();
      return;
    }

    Get.toNamed(
      '/game',
      arguments: {
        'mode': selectedMode.value.name,
        'isLeagueAttempt': true,
        'attemptsRemaining': freeLeft,
        'seed': DateTime.now().millisecondsSinceEpoch,
      },
    )?.then((_) => _fetchCycleStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'league_attempt_selector_title'.tr,
        accentColor: Colors.white,
      ),
      bottomNavigationBar: Obx(() {
        final canPlay = _canPlayLeague;
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withValues(alpha: 0.96),
            border: const Border(
              top: BorderSide(color: Color(0xFF21262D), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The actual play button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _startAttempt,
                  icon: Icon(
                    canPlay
                        ? Icons.play_arrow_rounded
                        : Icons.hourglass_bottom_rounded,
                    size: 24,
                    color: canPlay ? Colors.black : Colors.white70,
                  ),
                  label: Text(
                    canPlay
                        ? 'start_league_attempt_btn'.tr
                        : 'league_season_closed_btn'.tr,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: canPlay ? Colors.black : Colors.white70,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canPlay ? kPrimaryColor : const Color(0xFF2A2E37),
                    foregroundColor:
                        canPlay ? Colors.black : Colors.white70,
                    elevation: canPlay ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: canPlay
                        ? kPrimaryColor.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
              ),

              // Floating particles rising from the button when league is playable
              if (canPlay)
                const Positioned(
                  top: -20,
                  left: -8,
                  right: -8,
                  bottom: -4,
                  child: IgnorePointer(
                    child: _LeaguePlayParticlesOverlay(),
                  ),
                ),
            ],
          ),
        );
      }),
      body: SafeArea(
        child: Obx(() {
          final status = cycleStatus.value;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Not Entered Notice Banner ---
                if (status != null && !status.isEntered)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'league_not_registered_desc'.tr,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- Season Closed / Ended Notice Banner ---
                if (!_canPlayLeague)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade900.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          color: Colors.orangeAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'league_ended_msg'.tr,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section Title: Select Mode
                Text(
                  'select_mode_to_play'.tr,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // --- Mode Selection 2-Column Grid ---
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: _leagueGameModes.length,
                  itemBuilder: (context, index) {
                    final config = _leagueGameModes[index];
                    return Obx(() {
                      final isSelected = selectedMode.value == config.mode;
                      final modeFree =
                          status?.getFreeAttempts(config.mode.apiName) ?? 2;
                      final assetPath = config.iconAsset ??
                          GameModeConfig.getIconAssetForMode(config.id);

                      return GestureDetector(
                        onTap: () => selectedMode.value = config.mode,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSelected
                                  ? [
                                      config.accentColor.withValues(alpha: 0.28),
                                      const Color(0xFF161B22),
                                    ]
                                  : [
                                      const Color(0xFF161B22),
                                      const Color(0xFF0D1016),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? config.accentColor.withValues(alpha: 0.90)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: config.accentColor
                                          .withValues(alpha: 0.28),
                                      blurRadius: 12,
                                      spreadRadius: 0.5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 1. Background Pattern Image (Distinct line-art doodles)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: isSelected ? 0.45 : 0.22,
                                    child: Image.asset(
                                      config.patternAsset,
                                      fit: BoxFit.cover,
                                      color: config.accentColor,
                                      colorBlendMode: BlendMode.srcIn,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),

                                // 2. Subtle Bottom Gradient for title text legibility
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 48,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFF0A0D12)
                                              .withValues(alpha: 0.85),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. Foreground Content
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Top Row: Attempts Badge + Selection Indicator
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: modeFree > 0
                                                  ? const Color(0xFF00E676)
                                                      .withValues(alpha: 0.18)
                                                  : Colors.redAccent
                                                      .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: modeFree > 0
                                                    ? const Color(0xFF00E676)
                                                        .withValues(alpha: 0.55)
                                                    : Colors.redAccent
                                                        .withValues(alpha: 0.55),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              '$modeFree/${status?.maxFreeAttempts ?? 8}',
                                              style: GoogleFonts.vazirmatn(
                                                color: modeFree > 0
                                                    ? const Color(0xFF00E676)
                                                    : Colors.redAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check_circle_rounded,
                                                    key: const ValueKey(
                                                      'selected',
                                                    ),
                                                    color: config.accentColor,
                                                    size: 18,
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .radio_button_unchecked_rounded,
                                                    key: const ValueKey(
                                                      'unselected',
                                                    ),
                                                    color: Colors.white24,
                                                    size: 18,
                                                  ),
                                          ),
                                        ],
                                      ),

                                      // Center: Mode Icon from Assets with Glow
                                      Container(
                                        width: 44,
                                        height: 44,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0D1117)
                                              .withValues(alpha: 0.55),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: config.accentColor
                                                        .withValues(alpha: 0.40),
                                                    blurRadius: 12,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                        ),
                                        child: Image.asset(
                                          assetPath,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder: (_, __, ___) => Icon(
                                            config.icon,
                                            color: config.accentColor,
                                            size: 28,
                                          ),
                                        ),
                                      ),

                                      // Bottom: Mode Title
                                      Text(
                                        config.titleTr,
                                        style: GoogleFonts.vazirmatn(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating Particles for League Play Button
// Small white/gold circles drift upward from the button to signal
// that the league is active and the player can start an attempt.
// ---------------------------------------------------------------------------

class _LeaguePlayParticlesOverlay extends StatefulWidget {
  const _LeaguePlayParticlesOverlay();

  @override
  State<_LeaguePlayParticlesOverlay> createState() =>
      _LeaguePlayParticlesOverlayState();
}

class _LeaguePlayParticlesOverlayState
    extends State<_LeaguePlayParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Each entry: [xBase (0-1), phase (0-1), radius, driftAmplitude]
  static const int _kCount = 16;
  final List<List<double>> _particles = [];

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    for (int i = 0; i < _kCount; i++) {
      _particles.add([
        rng.nextDouble(),               // x base
        rng.nextDouble(),               // phase
        1.2 + rng.nextDouble() * 2.0,   // radius
        0.03 + rng.nextDouble() * 0.05, // drift amplitude
      ]);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _LeaguePlayParticlesPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaguePlayParticlesPainter extends CustomPainter {
  final double progress;
  final List<List<double>> particles;

  const _LeaguePlayParticlesPainter({
    required this.progress,
    required this.particles,
  });

  // Alternate between white and gold to match kPrimaryColor feel
  static const _colors = [Color(0xFFFFFFFF), Color(0xFFFFE57F), Color(0xFFFFD740)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final baseX = p[0];
      final phase = p[1];
      final radius = p[2];
      final driftAmp = p[3];

      // t goes 0 -> 1: particle travels bottom-to-top
      final t = (progress + phase) % 1.0;

      // Particles rise from the bottom of the overlay area upward
      final y = (1.0 - t) * size.height;

      // Subtle horizontal sine sway
      final xDrift = math.sin(t * math.pi * 3 + phase * math.pi * 5) * driftAmp;
      final x = ((baseX + xDrift).clamp(0.0, 1.0)) * size.width;

      // Fade in quickly, hold, fade out as particle exits the top
      double opacity;
      if (t < 0.15) {
        opacity = t / 0.15;
      } else if (t > 0.75) {
        opacity = (1.0 - t) / 0.25;
      } else {
        opacity = 1.0;
      }
      opacity = (opacity * 0.65).clamp(0.0, 1.0);

      paint.color = _colors[i % _colors.length].withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaguePlayParticlesPainter old) =>
      old.progress != progress;
}
