import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../services/sound_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../game/controllers/game_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/cosmetics_models.dart';
import '../repositories/cosmetics_repository.dart';

import '../services/theme_cache_service.dart';

/// Central GetX controller managing Themes and Avatars (Cosmetics System).
class CosmeticsController extends GetxController {
  final CosmeticsRepository _repository;
  final StorageService _storage;
  final SoundService _sound;
  final ThemeCacheService _themeCache;

  CosmeticsController({
    CosmeticsRepository? repository,
    StorageService? storage,
    SoundService? sound,
    ThemeCacheService? themeCache,
  }) : _repository = repository ?? CosmeticsRepository(),
       _storage = storage ?? Get.find<StorageService>(),
       _sound = sound ?? Get.find<SoundService>(),
       _themeCache =
           themeCache ??
           (Get.isRegistered<ThemeCacheService>()
               ? Get.find<ThemeCacheService>()
               : Get.put(ThemeCacheService(), permanent: true));

  // --- Single Source of Truth Reactive Lists (Superset from /shop) ---
  final RxList<CosmeticTheme> allThemes = <CosmeticTheme>[].obs;
  final RxList<CosmeticAvatar> allAvatars = <CosmeticAvatar>[].obs;
  final RxList<CosmeticSnakeSkin> allSkins = <CosmeticSnakeSkin>[].obs;

  // --- Active Equipped Cosmetics ---
  final Rxn<CosmeticTheme> activeTheme = Rxn<CosmeticTheme>();
  final Rxn<CosmeticAvatar> activeAvatar = Rxn<CosmeticAvatar>();
  final Rxn<CosmeticSnakeSkin> activeSkin = Rxn<CosmeticSnakeSkin>();

  // --- Loading States ---
  final RxBool isLoading = false.obs;
  final RxBool isPurchasing = false.obs;

  // --- Computed Getters (Derived dynamically from allThemes & allAvatars & allSkins) ---

  /// Themes owned by the player or free by default
  List<CosmeticTheme> get ownedThemes => allThemes
      .where(
        (t) =>
            t.isOwned || t.isFree || t.status == 'owned' || t.status == 'free',
      )
      .toList();

  /// Themes locked in the shop that require purchase
  List<CosmeticTheme> get shopThemes => allThemes
      .where(
        (t) =>
            !t.isOwned &&
            !t.isFree &&
            t.status != 'owned' &&
            t.status != 'free',
      )
      .toList();

  /// Avatars owned by the player or free by default
  List<CosmeticAvatar> get ownedAvatars => allAvatars
      .where(
        (a) =>
            a.isOwned || a.isFree || a.status == 'owned' || a.status == 'free',
      )
      .toList();

  /// Avatars locked in the shop that require purchase
  List<CosmeticAvatar> get shopAvatars => allAvatars
      .where(
        (a) =>
            !a.isOwned &&
            !a.isFree &&
            a.status != 'owned' &&
            a.status != 'free',
      )
      .toList();

  /// Skins owned by the player or free by default
  List<CosmeticSnakeSkin> get ownedSkins => allSkins
      .where(
        (s) =>
            s.isOwned || s.isFree || s.status == 'owned' || s.status == 'free',
      )
      .toList();

  /// Skins locked in the shop that require purchase
  List<CosmeticSnakeSkin> get shopSkins => allSkins
      .where(
        (s) =>
            !s.isOwned &&
            !s.isFree &&
            s.status != 'owned' &&
            s.status != 'free',
      )
      .toList();

  @override
  void onInit() {
    super.onInit();
    _loadSavedActiveCosmetics();
    _seedDefaultAvatarsIfEmpty();

    // Reactively refresh shop catalog when auth state transitions to logged in
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      ever(auth.isLoggedIn, (isLogged) {
        if (isLogged) {
          fetchCatalog(forceRefresh: true);
        }
      });
      // Only fetch on init if already logged in — guests skip the network call
      if (auth.isLoggedIn.value) {
        fetchCatalog();
      }
    }
    // If AuthController is not yet registered, skip catalog fetch
    // (will be triggered once auth is initialized via ever() or manual call)
  }

  /// Restores active theme, avatar, and skin from local storage on boot
  void _loadSavedActiveCosmetics() {
    final savedThemeKey = _storage.getSelectedBoardSkinId();
    final savedAvatarId = _storage.getSavedAvatarId();
    final savedSkinId = _storage.getSelectedSkinId();

    // Initial fallback if catalog is not yet loaded
    if (activeTheme.value == null) {
      activeTheme.value = CosmeticTheme(
        id: savedThemeKey,
        themeKey: savedThemeKey,
        nameFa: savedThemeKey,
        nameEn: savedThemeKey,
        isFree: true,
        isOwned: true,
        status: 'owned',
        previewUrl: '',
        modes: const {},
      );
    }

    if (activeAvatar.value == null) {
      activeAvatar.value = CosmeticAvatar(
        id: savedAvatarId,
        name: 'Avatar',
        primaryColor: kAvatarPrimaryColor,
        secondaryColor: kAvatarSecondaryColor,
        imageUrl: '',
        isFree: true,
        isOwned: true,
        status: 'owned',
      );
    }

    // Fallback skin from saved skin key (neon_green is always free)
    if (activeSkin.value == null) {
      activeSkin.value = CosmeticSnakeSkin(
        id: savedSkinId,
        skinKey: savedSkinId,
        nameFa: savedSkinId,
        nameEn: savedSkinId,
        isFree: true,
        isOwned: true,
        status: 'owned',
        headColor: const Color(0xFF69F0AE),
        tailColor: const Color(0xFF004D40),
        glowColor: const Color(0xFF00E676),
      );
    }
  }

  /// Seeds default preset avatars into allAvatars if initially empty
  void _seedDefaultAvatarsIfEmpty() {
    if (allAvatars.isEmpty) {
      allAvatars.assignAll(
        kPresetAvatars
            .where((p) => p.id != 'avatar_7')
            .map(
              (p) => CosmeticAvatar(
                id: p.id,
                name: p.name,
                title: p.title,
                primaryColor: p.primaryColor,
                secondaryColor: p.secondaryColor,
                imageUrl: p.imageUrl ?? '',
                isFree: p.id == 'avatar_1' || p.id == 'avatar_2',
                isOwned: p.id == 'avatar_1' || p.id == 'avatar_2',
                status: (p.id == 'avatar_1' || p.id == 'avatar_2')
                    ? 'free'
                    : 'locked',
              ),
            )
            .toList(),
      );
    }
  }

  /// Syncs active theme, avatar, and skin references against the populated catalog
  void _syncActiveCosmetics() {
    final savedThemeKey = _storage.getSelectedBoardSkinId();
    final matchingTheme = allThemes.firstWhereOrNull(
      (t) =>
          t.themeKey.toLowerCase() == savedThemeKey.toLowerCase() ||
          t.id.toString() == savedThemeKey,
    );
    if (matchingTheme != null &&
        (matchingTheme.isOwned ||
            matchingTheme.isFree ||
            matchingTheme.status == 'owned' ||
            matchingTheme.status == 'free')) {
      activeTheme.value = matchingTheme;
      _themeCache.preWarmTheme(matchingTheme);
    } else if (ownedThemes.isNotEmpty) {
      activeTheme.value = ownedThemes.first;
      _storage.saveSelectedBoardSkinId(ownedThemes.first.themeKey);
      _themeCache.preWarmTheme(ownedThemes.first);
    }

    final savedAvatarId = _storage.getSavedAvatarId();
    final matchingAvatar = allAvatars.firstWhereOrNull(
      (a) =>
          a.id.toString() == savedAvatarId ||
          a.itemId?.toString() == savedAvatarId,
    );
    if (matchingAvatar != null &&
        (matchingAvatar.isOwned ||
            matchingAvatar.isFree ||
            matchingAvatar.status == 'owned' ||
            matchingAvatar.status == 'free')) {
      activeAvatar.value = matchingAvatar;
    } else if (ownedAvatars.isNotEmpty) {
      activeAvatar.value = ownedAvatars.first;
      _storage.saveAvatarId(ownedAvatars.first.id.toString());
    }

    // Sync active snake skin from storage
    final savedSkinId = _storage.getSelectedSkinId();
    final matchingSkin = allSkins.firstWhereOrNull(
      (s) =>
          s.skinKey.toLowerCase() == savedSkinId.toLowerCase() ||
          s.id.toString() == savedSkinId,
    );
    if (matchingSkin != null && matchingSkin.hasAccess) {
      activeSkin.value = matchingSkin;
    } else if (ownedSkins.isNotEmpty) {
      activeSkin.value = ownedSkins.first;
      _storage.saveSelectedSkinId(ownedSkins.first.skinKey);
    }

    if (Get.isRegistered<GameController>()) {
      Get.find<GameController>().snakeGame.refreshBoardSkin();
    }
  }

  /// Fetches the complete cosmetics catalog from GET /shop
  Future<void> fetchCatalog({bool forceRefresh = false}) async {
    if (isLoading.value && !forceRefresh) return;
    isLoading.value = true;

    try {
      String? token;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        token = auth.currentUser.value?.token;
      }
      if (token == null || token.isEmpty) {
        token = _storage.cachedUserToken ?? await _storage.getUserToken();
      }

      final catalog = await _repository.getShopCatalog(token: token);
      if (catalog != null) {
        if (catalog.themes.isNotEmpty) {
          allThemes.assignAll(catalog.themes);
        }
        if (catalog.avatars.isNotEmpty) {
          allAvatars.assignAll(catalog.avatars);
        }
        if (catalog.skins.isNotEmpty) {
          allSkins.assignAll(catalog.skins);
        }
        _syncActiveCosmetics();
      }
    } catch (e) {
      debugPrint('[CosmeticsController] Error fetching shop catalog: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Merges owned cosmetics from GET /home/dashboard into allThemes, allAvatars, and allSkins via UPSERT
  void mergeDashboardCosmetics({
    required List<CosmeticTheme> themes,
    required List<CosmeticAvatar> avatars,
    List<CosmeticSnakeSkin> skins = const [],
  }) {
    if (themes.isNotEmpty) {
      for (final dt in themes) {
        final targetKey = dt.themeKey.trim().toLowerCase();
        final targetId = dt.id?.toString().trim();

        // 1. Find existing theme by themeKey or ID
        final idx = allThemes.indexWhere((t) {
          final tKey = t.themeKey.trim().toLowerCase();
          final tId = t.id?.toString().trim();
          return (targetKey.isNotEmpty && tKey == targetKey) ||
              (targetId != null && targetId.isNotEmpty && tId == targetId);
        });

        if (idx != -1) {
          // UPDATE: Update ownership, status, and latest mode URLs without creating duplicates
          allThemes[idx] = allThemes[idx].copyWith(
            isOwned: true,
            status: 'owned',
            modes: dt.modes.isNotEmpty ? dt.modes : allThemes[idx].modes,
            previewUrl: dt.previewUrl.isNotEmpty
                ? dt.previewUrl
                : allThemes[idx].previewUrl,
            nameFa: dt.nameFa.isNotEmpty ? dt.nameFa : allThemes[idx].nameFa,
            nameEn: dt.nameEn.isNotEmpty ? dt.nameEn : allThemes[idx].nameEn,
          );
        } else {
          // INSERT: Append newly unlocked theme not yet in catalog list
          allThemes.add(dt.copyWith(isOwned: true, status: 'owned'));
        }
      }
    }

    if (avatars.isNotEmpty) {
      for (final da in avatars) {
        final targetId = da.id.toString().trim().toLowerCase();
        final targetItemId = da.itemId?.toString().trim();

        // 2. Find existing avatar by id or itemId or imageUrl
        final idx = allAvatars.indexWhere((a) {
          final aId = a.id.toString().trim().toLowerCase();
          final aItemId = a.itemId?.toString().trim();
          final aImg = a.imageUrl.trim();
          final daImg = da.imageUrl.trim();

          return aId == targetId ||
              (targetItemId != null &&
                  targetItemId.isNotEmpty &&
                  aItemId == targetItemId) ||
              (daImg.isNotEmpty && aImg.isNotEmpty && aImg == daImg);
        });

        if (idx != -1) {
          // UPDATE: Update ownership and status in-place
          allAvatars[idx] = allAvatars[idx].copyWith(
            isOwned: true,
            status: 'owned',
            imageUrl: da.imageUrl.isNotEmpty
                ? da.imageUrl
                : allAvatars[idx].imageUrl,
            name: da.name.isNotEmpty && da.name != 'Avatar'
                ? da.name
                : allAvatars[idx].name,
            title: da.title.isNotEmpty ? da.title : allAvatars[idx].title,
          );
        } else {
          // INSERT: Append newly unlocked avatar
          allAvatars.add(da.copyWith(isOwned: true, status: 'owned'));
        }
      }
    }

    // 3. Merge skins from /home/dashboard (owned/free skins)
    if (skins.isNotEmpty) {
      for (final ds in skins) {
        final targetKey = ds.skinKey.trim().toLowerCase();
        final targetId = ds.id?.toString().trim();

        final idx = allSkins.indexWhere((s) {
          final sKey = s.skinKey.trim().toLowerCase();
          final sId = s.id?.toString().trim();
          return (targetKey.isNotEmpty && sKey == targetKey) ||
              (targetId != null && targetId.isNotEmpty && sId == targetId);
        });

        if (idx != -1) {
          allSkins[idx] = allSkins[idx].copyWith(
            isOwned: true,
            status: 'owned',
            nameFa: ds.nameFa.isNotEmpty ? ds.nameFa : allSkins[idx].nameFa,
            nameEn: ds.nameEn.isNotEmpty ? ds.nameEn : allSkins[idx].nameEn,
          );
        } else {
          allSkins.add(ds.copyWith(isOwned: true, status: 'owned'));
        }
      }
    }

    _syncActiveCosmetics();
  }

  /// Equips a Theme globally across all 8 game modes
  void equipTheme(CosmeticTheme theme) {
    activeTheme.value = theme;
    _storage.saveSelectedBoardSkinId(theme.themeKey);

    // Trigger parallel download / caching of all 8 mode backgrounds if not yet cached
    _themeCache.preWarmTheme(theme, showLoading: true);

    // Refresh Flame / Game rendering layer if active
    if (Get.isRegistered<GameController>()) {
      Get.find<GameController>().snakeGame.refreshBoardSkin();
    }

    _sound.playButtonTap();
  }

  /// Equips a Snake Skin and persists the selection.
  /// `SettingsController.selectSkin()` also calls `refreshSkin()` on snake_game,
  /// so here we only update the reactive state and storage.
  void equipSkin(CosmeticSnakeSkin skin) {
    activeSkin.value = skin;
    _storage.saveSelectedSkinId(skin.skinKey);

    // Delegate actual game refresh to SettingsController if available,
    // otherwise call refreshSkin() directly on snake_game
    if (Get.isRegistered<GameController>()) {
      Get.find<GameController>().snakeGame.refreshSkin();
    }

    _sound.playButtonTap();
  }

  /// Resolves the cached local file path for a theme mode variant
  String? getCachedThemeAssetPath(String themeKey, String mode) {
    return _themeCache.getCachedThemeFilePath(themeKey, mode);
  }

  /// Equips an Avatar globally
  void equipAvatar(CosmeticAvatar avatar) {
    activeAvatar.value = avatar;
    _storage.saveAvatarId(avatar.id.toString());

    // Sync with AuthController if registered
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      auth.setAvatar(avatar.id.toString());
      if (auth.currentUser.value != null) {
        auth.currentUser.value = auth.currentUser.value!.copyWith(
          avatarId: avatar.id.toString(),
          avatarUrl: avatar.imageUrl,
        );
      }
    }

    _sound.playButtonTap();
  }

  /// Purchases a cosmetic item (theme or avatar) with coins.
  /// Mutates item status in-place (isOwned = true, status = 'owned', isPurchased = true)
  /// so computed getters automatically re-evaluate and transfer the item from shop to owned.
  Future<bool> purchaseItem({
    required dynamic itemId,
    required String itemType,
    required int priceCoins,
  }) async {
    // 1. Client-side Coin Balance Check
    final wallet = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : null;

    if (wallet != null && !wallet.hasEnoughCoins(priceCoins)) {
      Get.snackbar(
        'insufficient_coins'.tr.isNotEmpty
            ? 'insufficient_coins'.tr
            : 'Insufficient Coins',
        'insufficient_coins_shop'.tr.isNotEmpty
            ? 'insufficient_coins_shop'.tr
            : 'You do not have enough coins to purchase this item.',
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    }

    // 2. Authentication Check
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final token = auth?.currentUser.value?.token;

    if (token == null || token.isEmpty) {
      auth?.requireAuth(() {}, contextMessage: 'login_required_shop'.tr);
      return false;
    }

    isPurchasing.value = true;

    try {
      final result = await _repository.purchase(
        itemId: itemId,
        itemType: itemType,
        token: token,
      );

      if (result != null && result.success) {
        // 3. Update Coin Balance directly without full wallet refetch
        if (wallet != null) {
          if (result.newBalance != null) {
            wallet.balance.value = result.newBalance!;
          } else {
            wallet.balance.value = (wallet.balance.value - priceCoins).clamp(
              0,
              999999999,
            );
          }
        }

        // 4. CRITICAL: In-Place Mutation of BOTH isOwned = true AND status = 'owned'
        if (itemType == 'theme' || itemType == 'board_theme') {
          final idx = allThemes.indexWhere(
            (t) =>
                t.id == itemId ||
                t.itemId == itemId ||
                t.themeKey.toLowerCase() == itemId.toString().toLowerCase(),
          );
          if (idx != -1) {
            allThemes[idx] = allThemes[idx].copyWith(
              isOwned: true,
              isPurchased: true,
              status: 'owned',
            );
          }
        } else if (itemType == 'avatar') {
          final idx = allAvatars.indexWhere(
            (a) =>
                a.id == itemId ||
                a.itemId == itemId ||
                a.id.toString() == itemId.toString(),
          );
          if (idx != -1) {
            allAvatars[idx] = allAvatars[idx].copyWith(
              isOwned: true,
              isPurchased: true,
              status: 'owned',
            );
          }
        } else if (itemType == 'snake_skin') {
          // Update skin ownership in-place
          final idx = allSkins.indexWhere(
            (s) =>
                s.id == itemId ||
                s.itemId == itemId ||
                s.skinKey.toLowerCase() == itemId.toString().toLowerCase(),
          );
          if (idx != -1) {
            allSkins[idx] = allSkins[idx].copyWith(
              isOwned: true,
              isPurchased: true,
              status: 'owned',
            );
          }
        }

        Get.snackbar(
          'purchase_success_title'.tr.isNotEmpty
              ? 'purchase_success_title'.tr
              : 'Purchased!',
          'purchase_success_msg'.tr.isNotEmpty
              ? 'purchase_success_msg'.tr
              : 'Item unlocked and added to your collection.',
          backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.9),
          colorText: Colors.black,
        );

        return true;
      } else {
        Get.snackbar(
          'purchase_failed_title'.tr.isNotEmpty
              ? 'purchase_failed_title'.tr
              : 'Purchase Failed',
          result?.message ?? 'Failed to complete purchase.',
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr.isNotEmpty ? 'error'.tr : 'Error',
        e.toString(),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Helper to lookup a theme by themeKey
  CosmeticTheme? getThemeByKey(String key) {
    return allThemes.firstWhereOrNull(
      (t) =>
          t.themeKey.toLowerCase() == key.toLowerCase() ||
          t.id.toString() == key,
    );
  }

  /// Helper to lookup an avatar by ID
  CosmeticAvatar? getAvatarById(dynamic id) {
    return allAvatars.firstWhereOrNull(
      (a) =>
          a.id.toString() == id.toString() ||
          a.itemId?.toString() == id.toString(),
    );
  }

  /// Helper to lookup a snake skin by skin key
  CosmeticSnakeSkin? getSkinByKey(String key) {
    return allSkins.firstWhereOrNull(
      (s) =>
          s.skinKey.toLowerCase() == key.toLowerCase() ||
          s.id.toString() == key,
    );
  }
}
