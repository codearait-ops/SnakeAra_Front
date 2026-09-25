import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../services/ad_service.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/wallet_models.dart';
import '../widgets/welcome_bonus_dialog.dart';

/// GetX controller managing user coin balance, transaction history,
/// store catalog purchases, welcome bonus rewards, and direct ad rewards.
class WalletController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxInt balance = 0.obs;
  final RxInt displayBalance = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isShopLoading = false.obs;
  final RxBool isPurchasing = false.obs;
  final RxList<CoinTransactionModel> transactions =
      <CoinTransactionModel>[].obs;
  final RxList<ShopItemModel> shopItems = <ShopItemModel>[].obs;

  // Pagination state for transactions
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreTransactions = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isClaimingBonus = false.obs;

  // Direct Ad Reward state with daily limits and cooldown
  final Rx<AdRewardInfoModel> adRewardInfo = AdRewardInfoModel().obs;
  final RxInt secondsUntilNextAd = 0.obs;
  Timer? _adCountdownTimer;

  // Centralized Coin Fly Animation State
  /// Single source of truth for pending coins to animate when returning to Home
  final RxInt pendingCoinAnimation = 0.obs;

  /// GlobalKey attached to _CurrencyPill on MenuView for runtime coordinate targeting
  GlobalKey coinTargetKey = GlobalKey();

  /// Optional custom origin for coin fly animation
  final Rx<Offset?> customFlyOrigin = Rx<Offset?>(null);

  /// Reactive state to trigger pulse/bounce on the target currency pill
  final RxBool isCoinTargetPulsing = false.obs;

  /// Whether coin fly animation is currently actively in flight
  final RxBool isCoinFlyActive = false.obs;

  /// Signal counter incremented to trigger CoinFlyAnimationOverlay
  final RxInt flyAnimationTrigger = 0.obs;

  /// Amount of coins awarded in the latest animation trigger
  final RxInt lastRewardedAmount = 0.obs;

  bool get canWatchAd =>
      adRewardInfo.value.canWatchNow &&
      secondsUntilNextAd.value <= 0 &&
      adRewardInfo.value.viewsToday < adRewardInfo.value.maxDailyViews;

  /// Centralized unified funnel for receiving coins into user wallet.
  /// All sources of coin earnings must go through this method.
  void receiveCoins(
    int amount, {
    bool animate = true,
    int? newServerBalance,
    Offset? fromOffset,
  }) {
    debugPrint(
      '[WalletController] 🪙 receiveCoins: amount=$amount, animate=$animate, newBalance=$newServerBalance, isHome=${_isHomeCurrentlyVisible()}, pendingBefore=${pendingCoinAnimation.value}',
    );

    if (amount <= 0) {
      if (newServerBalance != null) {
        balance.value = newServerBalance;
        if (!isCoinFlyActive.value) {
          displayBalance.value = newServerBalance;
        }
      }
      return;
    }

    if (fromOffset != null) {
      customFlyOrigin.value = fromOffset;
    }

    if (newServerBalance != null) {
      balance.value = newServerBalance;
    } else {
      balance.value += amount;
    }

    if (!animate) {
      displayBalance.value = balance.value;
      return;
    }

    // In gameplay (/game), defer animation until returning to Home
    final route = Get.currentRoute;
    if (route.contains('game')) {
      pendingCoinAnimation.value += amount;
      displayBalance.value = (balance.value - pendingCoinAnimation.value).clamp(
        0,
        balance.value,
      );
      debugPrint(
        '🪙 [WalletController] receiveCoins: inside game ($route) -> deferred $amount coins. pendingNow=${pendingCoinAnimation.value}, displayBalance=${displayBalance.value}, serverBalance=${balance.value}',
      );
    } else {
      debugPrint(
        '🪙 [WalletController] receiveCoins: outside game ($route) -> triggering immediate fly animation for $amount coins',
      );
      triggerImmediateFlyAnimation(amount: amount, fromOffset: fromOffset);
    }
  }

  /// Checks whether the user is currently on the Home/MenuView screen.
  bool _isHomeCurrentlyVisible() {
    final currentRoute = Get.currentRoute;
    return currentRoute == '/' ||
        currentRoute == '/home' ||
        currentRoute == '/menu' ||
        currentRoute.contains('menu') ||
        currentRoute.isEmpty;
  }

  /// Checks for any deferred/pending coins earned in game or other views,
  /// triggering the fly animation once Home/MenuView is stably rendered.
  void checkAndTriggerPendingCoins() {
    final pending = pendingCoinAnimation.value;
    final currentRoute = Get.currentRoute;
    debugPrint(
      '🔍 [WalletController] checkAndTriggerPendingCoins called: pending=$pending, currentRoute=$currentRoute',
    );
    if (pending <= 0) return;

    Future.delayed(const Duration(milliseconds: 450), () {
      final pendingNow = pendingCoinAnimation.value;
      final routeNow = Get.currentRoute;
      debugPrint(
        '🔍 [WalletController] checkAndTriggerPendingCoins timer fired: pending=$pendingNow, currentRoute=$routeNow',
      );
      if (pendingNow > 0) {
        triggerImmediateFlyAnimation();
      }
    });
  }

  /// Triggers immediate coin fly animation with the given amount or pending amount
  void triggerImmediateFlyAnimation({int? amount, Offset? fromOffset}) {
    final amt = amount ?? pendingCoinAnimation.value;
    debugPrint(
      '🚀 [WalletController] triggerImmediateFlyAnimation called: amt=$amt, pendingCoinAnimation=${pendingCoinAnimation.value}, fromOffset=$fromOffset',
    );
    if (amt <= 0) {
      debugPrint(
        '⚠️ [WalletController] triggerImmediateFlyAnimation: amt <= 0, skipping.',
      );
      return;
    }
    if (fromOffset != null) {
      customFlyOrigin.value = fromOffset;
    }
    lastRewardedAmount.value = amt;
    isCoinFlyActive.value = true;
    flyAnimationTrigger.value++;
    debugPrint(
      '🚀 [WalletController] triggerImmediateFlyAnimation: new trigger count=${flyAnimationTrigger.value}',
    );
  }

  /// Clears pending coin animation count once triggered
  void clearPendingAnimation() {
    debugPrint(
      '🧹 [WalletController] clearPendingAnimation called (was ${pendingCoinAnimation.value})',
    );
    pendingCoinAnimation.value = 0;
  }

  /// Called by CoinFlyAnimationOverlay as particles arrive at the target
  void onCoinParticleArrived(int increment) {
    if (displayBalance.value < balance.value) {
      displayBalance.value = (displayBalance.value + increment).clamp(
        0,
        balance.value,
      );
    }
    debugPrint(
      '✨ [WalletController] onCoinParticleArrived: increment=$increment, newDisplayBalance=${displayBalance.value}/${balance.value}',
    );
    triggerTargetPulse();
  }

  /// Called when the entire coin fly animation completes
  void onCoinFlyAnimationCompleted() {
    debugPrint(
      '🏁 [WalletController] onCoinFlyAnimationCompleted: final displayBalance=${balance.value}',
    );
    displayBalance.value = balance.value;
    isCoinFlyActive.value = false;
    customFlyOrigin.value = null;
    clearPendingAnimation();
  }

  /// Temporarily activates the pulse effect on the currency pill badge with haptic feedback
  void triggerTargetPulse() {
    isCoinTargetPulsing.value = true;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    Future.delayed(const Duration(milliseconds: 300), () {
      isCoinTargetPulsing.value = false;
    });
  }

  @override
  void onInit() {
    super.onInit();
    // Keep display balance in sync with balance when not actively animating coins
    displayBalance.value = balance.value;
    ever<int>(balance, (newVal) {
      if (!isCoinFlyActive.value && pendingCoinAnimation.value <= 0) {
        displayBalance.value = newVal;
      }
    });

    // Reactively refresh wallet only when auth state transitions to logged in
    ever(_auth.isLoggedIn, (isLogged) {
      if (isLogged) {
        if (!isLoading.value) {
          fetchWalletBalance();
          claimWelcomeBonusIfEligible();
        }
      } else {
        balance.value = 0;
        transactions.clear();
        adRewardInfo.value = AdRewardInfoModel();
        secondsUntilNextAd.value = 0;
      }
    });

    // Only fetch if already logged in and balance not yet populated from Home Dashboard
    if (_auth.isLoggedIn.value && balance.value == 0 && !isLoading.value) {
      fetchWalletBalance();
      claimWelcomeBonusIfEligible();
    }
  }

  @override
  void onClose() {
    _adCountdownTimer?.cancel();
    super.onClose();
  }

  bool hasEnoughCoins(int amount) => balance.value >= amount;

  /// Fetches current coin balance and ad reward metadata from backend API (GET /api/wallet)
  Future<void> fetchWalletBalance() async {
    final token = _auth.currentUser.value?.token;
    if (token == null || token.isEmpty) return;
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final response = await _api.getWallet(token: token);
      if (response.isSuccess && response.data != null) {
        balance.value = response.data!.balance;
        adRewardInfo.value = response.data!.adReward;
        _startAdCountdown(response.data!.adReward.secondsUntilNextView);

        // Populate recent_transactions directly from GET /wallet for initial display
        if (response.data!.recentTransactions.isNotEmpty ||
            transactions.isEmpty) {
          transactions.assignAll(response.data!.recentTransactions);
          currentPage.value = 1;
          hasMoreTransactions.value =
              response.data!.recentTransactions.isNotEmpty;
        }
      } else {
        // Fallback to balance endpoint if full wallet object isn't returned
        final balRes = await _api.getWalletBalance(token: token);
        if (balRes.isSuccess && balRes.data != null) {
          balance.value = balRes.data!;
        }
      }
    } catch (e) {
      debugPrint('[WalletController] fetchWalletBalance error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _startAdCountdown(int seconds) {
    _adCountdownTimer?.cancel();
    secondsUntilNextAd.value = seconds > 0 ? seconds : 0;
    if (secondsUntilNextAd.value <= 0) {
      if (adRewardInfo.value.viewsToday < adRewardInfo.value.maxDailyViews) {
        adRewardInfo.value = adRewardInfo.value.copyWith(canWatchNow: true);
      }
      return;
    }

    _adCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsUntilNextAd.value > 1) {
        secondsUntilNextAd.value--;
      } else {
        secondsUntilNextAd.value = 0;
        if (adRewardInfo.value.viewsToday < adRewardInfo.value.maxDailyViews) {
          adRewardInfo.value = adRewardInfo.value.copyWith(
            canWatchNow: true,
            secondsUntilNextView: 0,
          );
        }
        timer.cancel();
      }
    });
  }

  /// Watch a rewarded video ad to receive direct 15 coins with server verification
  Future<bool> watchAdForCoins(BuildContext context) async {
    final user = _auth.currentUser.value;
    if (user == null || user.token.isEmpty) {
      _auth.requireAuth(() {}, contextMessage: 'login_required_ad_coins'.tr);
      return false;
    }

    if (!canWatchAd) {
      if (adRewardInfo.value.viewsToday >= adRewardInfo.value.maxDailyViews) {
        Get.snackbar(
          'ad_daily_cap_title'.tr,
          'ad_daily_cap_msg'.trParams({
            'max': '${adRewardInfo.value.maxDailyViews}',
          }),
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
      } else if (secondsUntilNextAd.value > 0) {
        final mins = secondsUntilNextAd.value ~/ 60;
        final secs = secondsUntilNextAd.value % 60;
        Get.snackbar(
          'please_wait'.tr,
          'ad_cooldown_wait_msg'.trParams({
            'time':
                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          }),
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
      }
      return false;
    }

    isLoading.value = true;
    try {
      final adService = Get.find<AdService>();
      final adSuccess = await adService.showRewardedAdAndVerify(
        context: context,
        placement: 'wallet_coins',
        token: user.token,
      );

      if (adSuccess) {
        final reward = adRewardInfo.value.rewardAmount;
        // Authoritatively refresh balance and ad reward info from backend
        await fetchWalletBalance();
        await fetchTransactions();

        if (reward > 0) {
          receiveCoins(reward, animate: true, newServerBalance: balance.value);
        }

        Get.snackbar(
          'reward_claimed_title'.tr,
          'reward_coins_added_msg'.trParams({
            'count': '${adRewardInfo.value.rewardAmount}',
          }),
          backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.95),
          colorText: Colors.black,
          icon: const Icon(Icons.monetization_on_rounded, color: Colors.black),
        );
        return true;
      }
    } catch (e) {
      debugPrint('[WalletController] watchAdForCoins error: $e');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  /// Fetches transaction history with pagination support
  Future<void> fetchTransactions({bool refresh = false}) async {
    final token = _auth.currentUser.value?.token;
    if (token == null || token.isEmpty) return;

    if (refresh) {
      currentPage.value = 1;
      hasMoreTransactions.value = true;
    }

    isLoading.value = true;
    try {
      final response = await _api.getCoinTransactions(
        token: token,
        page: currentPage.value,
      );
      if (response.isSuccess && response.data != null) {
        final newItems = response.data!;
        if (refresh || currentPage.value == 1) {
          transactions.assignAll(newItems);
        } else {
          final existingIds = transactions.map((t) => t.id).toSet();
          transactions.addAll(
            newItems.where((t) => !existingIds.contains(t.id)),
          );
        }
        if (newItems.isEmpty || newItems.length < 15) {
          hasMoreTransactions.value = false;
        }
      }
    } catch (e) {
      debugPrint('[WalletController] fetchTransactions error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads next page of transactions (pagination)
  Future<void> loadMoreTransactions() async {
    final token = _auth.currentUser.value?.token;
    if (token == null || token.isEmpty) return;
    if (isLoadingMore.value || !hasMoreTransactions.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final response = await _api.getCoinTransactions(
        token: token,
        page: nextPage,
      );
      if (response.isSuccess && response.data != null) {
        final newItems = response.data!;
        if (newItems.isNotEmpty) {
          currentPage.value = nextPage;
          final existingIds = transactions.map((t) => t.id).toSet();
          transactions.addAll(
            newItems.where((t) => !existingIds.contains(t.id)),
          );
        }
        if (newItems.isEmpty || newItems.length < 15) {
          hasMoreTransactions.value = false;
        }
      } else {
        hasMoreTransactions.value = false;
      }
    } catch (e) {
      debugPrint('[WalletController] loadMoreTransactions error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Claims welcome bonus for current user via POST /wallet/claim-welcome-bonus
  Future<WelcomeBonusResponse?> claimWelcomeBonus() async {
    final user = _auth.currentUser.value;
    if (user == null || user.token.isEmpty) return null;

    final key = 'welcome_bonus_claimed_${user.id}';
    final alreadyClaimed = _storage.prefs.getBool(key) ?? false;
    if (alreadyClaimed) return null;

    isClaimingBonus.value = true;
    try {
      final response = await _api.claimWelcomeBonus(token: user.token);
      if (response.isSuccess && response.data != null) {
        final bonusData = response.data!;
        await _storage.prefs.setBool(key, true);

        // Update balance authoritatively from response via receiveCoins (no animation needed for welcome bonus modal)
        receiveCoins(
          bonusData.coinsAwarded,
          animate: false,
          newServerBalance: bonusData.balance,
        );

        // Refresh wallet data to pull latest balance and recent transactions
        await fetchWalletBalance();

        return bonusData;
      } else {
        // If already claimed on server, remember it locally
        if (response.message?.toLowerCase().contains('already') == true) {
          await _storage.prefs.setBool(key, true);
        }
        return null;
      }
    } catch (e) {
      debugPrint('[WalletController] claimWelcomeBonus error: $e');
      return null;
    } finally {
      isClaimingBonus.value = false;
    }
  }

  /// Checks and claims welcome bonus for newly registered users via POST /wallet/claim-welcome-bonus
  Future<void> claimWelcomeBonusIfEligible() async {
    final user = _auth.currentUser.value;
    if (user == null || user.token.isEmpty) return;

    final key = 'welcome_bonus_claimed_${user.id}';
    final alreadyClaimed = _storage.prefs.getBool(key) ?? false;
    if (alreadyClaimed) return;

    final bonusData = await claimWelcomeBonus();
    if (bonusData != null && bonusData.coinsAwarded > 0) {
      // Show celebratory popup with exact server-awarded coins (no hardcoding)
      Get.dialog(
        WelcomeBonusDialog(
          coins: bonusData.coinsAwarded,
          username: user.username,
        ),
        barrierDismissible: false,
      );
    }
  }

  /// Fetches shop items and updates user_balance directly from catalog response
  Future<void> fetchShopCatalog() async {
    isShopLoading.value = true;
    try {
      final token = _auth.currentUser.value?.token;
      final response = await _api.getShopCatalog(token: token);
      if (response.isSuccess && response.data != null) {
        final catalogData = response.data!;
        shopItems.assignAll(catalogData.items);
        if (catalogData.userBalance != null) {
          balance.value = catalogData.userBalance!;
        }
      } else {
        // Fallback default skins catalog
        shopItems.assignAll(_getDefaultShopItems());
      }
    } catch (e) {
      shopItems.assignAll(_getDefaultShopItems());
    } finally {
      isShopLoading.value = false;
    }
  }

  /// Purchases a shop item with coins
  Future<bool> purchaseShopItem(ShopItemModel item) async {
    if (!hasEnoughCoins(item.priceCoins)) {
      Get.snackbar(
        'insufficient_coins'.tr,
        'insufficient_coins_shop'.tr,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    }

    final token = _auth.currentUser.value?.token;
    if (token == null || token.isEmpty) {
      _auth.requireAuth(() {}, contextMessage: 'login_required_shop'.tr);
      return false;
    }

    isPurchasing.value = true;
    try {
      final response = await _api.purchaseShopItem(
        itemId: item.id,
        itemType: item.category,
        token: token,
      );
      if (response.isSuccess && response.data != null) {
        final purchaseData = response.data!;

        // Update balance directly from purchase response without refetching wallet or catalog
        if (purchaseData.newBalance != null) {
          balance.value = purchaseData.newBalance!;
        } else {
          balance.value = (balance.value - item.priceCoins).clamp(0, 999999999);
        }

        // Update local item owned status directly without refetching the catalog
        final idx = shopItems.indexWhere((e) => e.id == item.id);
        if (idx != -1) {
          shopItems[idx] = shopItems[idx].copyWith(isOwned: true);
        }

        final lang = Get.locale?.languageCode ?? 'fa';
        Get.snackbar(
          'success'.tr,
          'item_purchased_success'.trParams({'name': item.localizedName(lang)}),
          backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.9),
          colorText: Colors.black,
        );
        return true;
      } else {
        String errorMsg = response.message ?? 'error'.tr;
        if (response.statusCode == 409) {
          errorMsg = 'item_already_owned'.tr;
          final idx = shopItems.indexWhere((e) => e.id == item.id);
          if (idx != -1) {
            shopItems[idx] = shopItems[idx].copyWith(isOwned: true);
          }
        } else if (response.statusCode == 422 || response.statusCode == 400) {
          errorMsg = 'insufficient_coins_shop'.tr;
        }

        Get.snackbar(
          'error'.tr,
          errorMsg,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('[WalletController] purchase error: $e');
      Get.snackbar(
        'error'.tr,
        e.toString(),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isPurchasing.value = false;
    }
    return false;
  }

  /// Adds coins locally and triggers balance update (delegating to receiveCoins funnel)
  void addCoins(int amount) {
    receiveCoins(amount, animate: true);
  }

  /// Deducts coins locally (e.g. for league cycle entry)
  bool deductCoins(int amount) {
    if (balance.value >= amount) {
      balance.value -= amount;
      return true;
    }
    return false;
  }

  /// Reset all wallet reactive state on user logout or session expiration
  void reset() {
    balance.value = 0;
    displayBalance.value = 0;
    transactions.clear();
    currentPage.value = 1;
    hasMoreTransactions.value = true;
    isLoadingMore.value = false;
    isClaimingBonus.value = false;
    adRewardInfo.value = AdRewardInfoModel();
    secondsUntilNextAd.value = 0;
    _adCountdownTimer?.cancel();
    _adCountdownTimer = null;
    pendingCoinAnimation.value = 0;
    isCoinFlyActive.value = false;
    isCoinTargetPulsing.value = false;
    debugPrint('[WalletController] 🔄 Wallet reset to initial zero state.');
  }

  List<ShopItemModel> _getDefaultShopItems() {
    return [
      ShopItemModel(
        id: 'skin_cyber_neon',
        nameFa: 'اسکین سایبر نئون',
        nameEn: 'Cyber Neon Skin',
        descriptionFa: 'پوسته درخشان فیروزه‌ای و بنفش',
        descriptionEn: 'Glowing turquoise & purple neon skin',
        category: 'snake_skin',
        priceCoins: 200,
        isOwned: false,
      ),
      ShopItemModel(
        id: 'skin_golden_dragon',
        nameFa: 'اسکین اژدهای طلایی',
        nameEn: 'Golden Dragon Skin',
        descriptionFa: 'پوسته مجلل طلایی با افکت آتشین',
        descriptionEn: 'Luxurious golden skin with fire trail',
        category: 'snake_skin',
        priceCoins: 350,
        isOwned: false,
      ),
      ShopItemModel(
        id: 'skin_poison_emerald',
        nameFa: 'اسکین زهرآلود زمردی',
        nameEn: 'Poison Emerald Skin',
        descriptionFa: 'پوسته سبز درخشان با هاله سمی',
        descriptionEn: 'Glowing green toxic emerald skin',
        category: 'snake_skin',
        priceCoins: 150,
        isOwned: false,
      ),
    ];
  }
}
