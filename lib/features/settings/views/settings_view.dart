import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../cosmetics/controllers/cosmetics_controller.dart';
import '../../cosmetics/models/cosmetics_models.dart';
import '../../game/models/board_skin.dart';
import '../../game/models/snake_skin.dart';
import '../../league/controllers/league_controller.dart';
import '../../shop/views/skin_shop_view.dart';
import '../controllers/settings_controller.dart';

/// Dark neon-styled Settings screen for configuring audio, controls, and app preferences.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(titleText: 'settings_title'.tr),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), Color(0xFF0A0E14)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            FloatingAppBar.preferredTotalHeight(context) + 12,
            20,
            24,
          ),
          children: [
            // --- Language Section ---
            _buildSectionHeader('language_settings'.tr),
            const SizedBox(height: 10),
            _buildLanguageSelector(controller),

            const SizedBox(height: 28),

            // --- Skins & Appearance Section (Snake & Board) ---
            _buildSectionHeader('appearance_settings'.tr),
            const SizedBox(height: 10),
            _buildSkinSelector(controller),
            const SizedBox(height: 14),
            _buildBoardSkinSelector(controller),

            const SizedBox(height: 28),

            // --- Audio Section ---
            _buildSectionHeader('audio_settings'.tr),
            const SizedBox(height: 10),
            Obx(
              () => _buildSwitchTile(
                title: 'sound_effects'.tr,
                subtitle: 'sfx_sub'.tr,
                icon: Icons.volume_up_rounded,
                value: controller.soundEffectsEnabled.value,
                onChanged: (val) => controller.toggleSoundEffects(val),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => _buildSwitchTile(
                title: 'background_music'.tr,
                subtitle: 'bg_music_sub'.tr,
                icon: Icons.music_note_rounded,
                value: controller.bgMusicEnabled.value,
                onChanged: (val) => controller.toggleBgMusic(val),
              ),
            ),

            const SizedBox(height: 28),

            // --- Gameplay & Controls Section ---
            _buildSectionHeader('gameplay_settings'.tr),
            const SizedBox(height: 10),
            Obx(
              () => _buildSwitchTile(
                title: 'vibration'.tr,
                subtitle: 'vibration_sub'.tr,
                icon: Icons.vibration_rounded,
                value: controller.vibrationEnabled.value,
                onChanged: (val) => controller.toggleVibration(val),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => _buildSwitchTile(
                title: 'show_joystick'.tr,
                subtitle: 'joystick_sub'.tr,
                icon: Icons.gamepad_rounded,
                value: controller.showJoystickEnabled.value,
                onChanged: (val) => controller.toggleShowJoystick(val),
              ),
            ),

            const SizedBox(height: 28),

            // --- Weekend League Section (§1.3) — hidden for guests ---
            Obx(() {
              final isLoggedIn = Get.isRegistered<AuthController>() &&
                  Get.find<AuthController>().isLoggedIn.value;
              if (!isLoggedIn) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('weekend_league_title'.tr),
                  const SizedBox(height: 10),
                  _buildLeagueAutoEnrollTile(),
                  const SizedBox(height: 28),
                ],
              );
            }),

            // --- About & App Info Section ---
            _buildSectionHeader('about_system'.tr),
            const SizedBox(height: 10),
            _buildInfoCard(
              title: 'app_title'.tr,
              subtitle: 'Version 1.0.0 • Build 2026.1',
              icon: Icons.info_outline_rounded,
              trailingText: 'v1.0.0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(SettingsController controller) {
    return Obx(() {
      final currentLang = controller.currentLanguage.value;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF21262D)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildLangOption(
                label: 'english'.tr,
                code: 'en',
                isSelected: currentLang == 'en',
                onTap: () => controller.changeLanguage('en'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLangOption(
                label: 'persian'.tr,
                code: 'fa',
                isSelected: currentLang == 'fa',
                onTap: () => controller.changeLanguage('fa'),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLangOption({
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.15)
              : const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : const Color(0xFF30363D),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? kPrimaryColor : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinSelector(SettingsController controller) {
    final cosmetics = Get.isRegistered<CosmeticsController>()
        ? Get.find<CosmeticsController>()
        : null;
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    return Obx(() {
      final isGuest = !(auth?.isLoggedIn.value ?? false);
      final currentSkinId = controller.selectedSkinId.value;

      // --- Guest Mode: show locked banner ---
      if (isGuest) {
        return _buildLockedCosmeticsCard(
          title: 'snake_skin_title'.tr,
          subtitle: 'snake_skin_sub'.tr,
          icon: Icons.style_rounded,
        );
      }

      // Use server skins if available, otherwise fall back to static list
      final serverSkins = cosmetics?.allSkins ?? [];
      final hasServerSkins = serverSkins.isNotEmpty;
      final sortedServerSkins = List<CosmeticSnakeSkin>.from(serverSkins)
        ..sort((a, b) {
          final aOwned = a.hasAccess ? 0 : 1;
          final bOwned = b.hasAccess ? 0 : 1;
          return aOwned.compareTo(bOwned);
        });

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF21262D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'snake_skin_title'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'snake_skin_sub'.tr,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (!hasServerSkins)
              // Fallback: static skins while loading
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SnakeSkins.allSkins.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final skin = SnakeSkins.allSkins[index];
                    final isSelected = currentSkinId == skin.id;

                    return GestureDetector(
                      onTap: () => controller.selectSkin(skin.id),
                      child: _buildSkinCard(
                        skinId: skin.id,
                        isSelected: isSelected,
                        isOwned: true,
                        primaryColor: skin.primaryColor,
                        glowColor: skin.glowColor,
                        headColor: skin.headColor,
                        tailColor: skin.tailColor,
                        gradientColors: skin.gradientColors,
                        name: skin.name,
                        price: 0,
                      ),
                    );
                  },
                ),
              )
            else
              // Server-driven skins (owned first)
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedServerSkins.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final skin = sortedServerSkins[index];
                    final isOwned = skin.hasAccess;
                    final isSelected = isOwned && currentSkinId == skin.skinKey;
                    final lang = Get.locale?.languageCode ?? 'fa';

                    return GestureDetector(
                      onTap: () {
                        if (isOwned) {
                          controller.selectSkin(skin.skinKey);
                          cosmetics?.equipSkin(skin);
                        } else {
                          // Navigate to shop to purchase
                          Get.to(() => const SkinShopView());
                        }
                      },
                      child: _buildSkinCard(
                        skinId: skin.skinKey,
                        isSelected: isSelected,
                        isOwned: isOwned,
                        primaryColor: skin.primaryColor,
                        glowColor: skin.glowColor,
                        headColor: skin.headColor,
                        tailColor: skin.tailColor,
                        gradientColors: skin.gradientColors,
                        name: skin.localizedName(lang),
                        price: skin.price,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }


  /// Locked cosmetics placeholder shown when the user is in guest mode.
  Widget _buildLockedCosmeticsCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => auth?.requireAuth(
              () {},
              contextMessage: 'login_required_cosmetics'.tr,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kPrimaryColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: kPrimaryColor.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'cosmetics_locked_guest'.tr.isNotEmpty
                        ? 'cosmetics_locked_guest'.tr
                        : 'برای شخصی‌سازی، وارد حساب کاربری شوید',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPrimaryColor.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCard({
    required String skinId,
    required bool isSelected,
    required bool isOwned,
    required Color primaryColor,
    required Color glowColor,
    required Color headColor,
    required Color tailColor,
    List<Color>? gradientColors,
    required String name,
    required int price,
  }) {
    final isGradient = gradientColors != null && gradientColors.isNotEmpty;


    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : (isOwned ? const Color(0xFF0D1117) : const Color(0xFF080B0F)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isOwned ? const Color(0xFF30363D) : const Color(0xFF21262D)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Color / Gradient Preview Circle with lock overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isGradient
                      ? LinearGradient(colors: gradientColors!)
                      : LinearGradient(colors: [headColor, tailColor]),
                  border: Border.all(color: Colors.white30, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: isSelected && isOwned
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              if (!isOwned)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: Color(0xFFFFD700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isOwned ? Colors.white60 : Colors.white38),
              fontSize: 11,
              height: 1.2,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (!isOwned && price > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 9,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$price',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'active'.tr.isNotEmpty ? 'active'.tr : 'Active',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }


  Widget _buildBoardSkinSelector(SettingsController controller) {
    final cosmetics = Get.isRegistered<CosmeticsController>()
        ? Get.find<CosmeticsController>()
        : null;
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    if (cosmetics == null) return const SizedBox.shrink();

    return Obx(() {
      // --- Guest Mode: show locked banner ---
      final isGuest = !(auth?.isLoggedIn.value ?? false);
      if (isGuest) {
        return _buildLockedCosmeticsCard(
          title: 'board_skin_title'.tr,
          subtitle: 'board_skin_sub'.tr,
          icon: Icons.grid_view_rounded,
        );
      }

      final rawThemes = cosmetics.allThemes.isNotEmpty
          ? cosmetics.allThemes
          : cosmetics.ownedThemes;
      final themesList = List<CosmeticTheme>.from(rawThemes)
        ..sort((a, b) {
          final aOwned = a.hasAccess ? 0 : 1;
          final bOwned = b.hasAccess ? 0 : 1;
          return aOwned.compareTo(bOwned);
        });
      final activeTheme = cosmetics.activeTheme.value;
      final activeKey = activeTheme?.themeKey.toLowerCase() ?? 'space';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF21262D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'board_skin_title'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'board_skin_sub'.tr,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (themesList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Loading themes...',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              )
            else
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: themesList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final theme = themesList[index];
                    final isOwned = theme.hasAccess;
                    final isSelected = isOwned &&
                        (activeKey == theme.themeKey.toLowerCase());
                    final accentColor = BoardSkins.getAccentColor(
                      theme.themeKey,
                    );

                    return GestureDetector(
                      onTap: () {
                        if (isOwned) {
                          cosmetics.equipTheme(theme);
                          controller.selectBoardSkin(theme.themeKey);
                        } else {
                          // Unowned / locked item -> Navigate to Shop
                          Get.to(() => const SkinShopView());
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 106,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : (isOwned
                                  ? const Color(0xFF0D1117)
                                  : const Color(0xFF080B0F)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : (isOwned
                                    ? const Color(0xFF30363D)
                                    : const Color(0xFF21262D)),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dynamic Theme Thumbnail Preview (with Lock overlay if unowned)
                            _buildThemeThumbnail(
                              theme,
                              accentColor,
                              isOwned: isOwned,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              theme.localizedName(
                                Get.locale?.languageCode ?? 'fa',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isOwned
                                        ? Colors.white70
                                        : Colors.white38),
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isOwned)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 9,
                                      color: Color(0xFFFFD700),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      theme.price > 0
                                          ? '${theme.price}'
                                          : 'shop'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'active'.tr.isNotEmpty
                                      ? 'active'.tr
                                      : 'Active',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildThemeThumbnail(
    CosmeticTheme theme,
    Color accentColor, {
    required bool isOwned,
  }) {
    final previewUrl = theme.previewUrl.isNotEmpty
        ? theme.previewUrl
        : (theme.modes.isNotEmpty ? theme.modes.values.first : '');

    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0x35FFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOwned
              ? accentColor.withValues(alpha: 0.4)
              : Colors.white12,
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (previewUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: previewUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: accentColor.withValues(alpha: 0.3)),
                errorWidget: (_, __, ___) =>
                    Container(color: accentColor.withValues(alpha: 0.3)),
              )
            else
              Container(
                color: accentColor.withValues(alpha: 0.3),
                child: Icon(
                  Icons.palette_rounded,
                  color: accentColor,
                  size: 16,
                ),
              ),
            if (!isOwned)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFFFD700),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF21262D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        activeColor: kPrimaryColor,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String trailingText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailingText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueAutoEnrollTile() {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    // Hidden in guest mode — league enrollment requires an account
    if (!(auth?.isLoggedIn.value ?? false)) return const SizedBox.shrink();

    final leagueController = Get.isRegistered<LeagueController>()
        ? Get.find<LeagueController>()
        : Get.put(LeagueController());

    return Obx(() {
      return _buildSwitchTile(
        title: 'auto_enroll_label'.tr,
        subtitle: 'auto_enroll_sub'.tr,
        icon: Icons.autorenew_rounded,
        value: leagueController.autoEnrollEnabled.value,
        onChanged: (val) => leagueController.toggleAutoEnroll(val),
      );
    });
  }
}
