import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../cosmetics/controllers/cosmetics_controller.dart';
import '../../cosmetics/models/cosmetics_models.dart';
import '../../game/models/board_skin.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../../wallet/widgets/wallet_badge_widget.dart';

/// Comprehensive Cosmetics & Themes Shop view on a single unified scrollable page.
/// Displays only locked / purchasable items with interactive Fullscreen Multi-Mode Theme Preview.
class SkinShopView extends StatefulWidget {
  const SkinShopView({super.key});

  @override
  State<SkinShopView> createState() => _SkinShopViewState();
}

class _SkinShopViewState extends State<SkinShopView> {
  late final CosmeticsController _cosmeticsController;
  late final WalletController _walletController;

  @override
  void initState() {
    super.initState();
    _cosmeticsController = Get.isRegistered<CosmeticsController>()
        ? Get.find<CosmeticsController>()
        : Get.put(CosmeticsController());
    _walletController = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : Get.put(WalletController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cosmeticsController.fetchCatalog();
        _walletController.fetchWalletBalance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'fa';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'skin_shop_title'.tr,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: WalletBadgeWidget(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), Color(0xFF0A0E14)],
          ),
        ),
        child: Obx(() {
          // Filter out free and already owned / purchased items
          final shopThemes = _cosmeticsController.shopThemes;
          final shopAvatars = _cosmeticsController.shopAvatars;
          final shopSkins = _cosmeticsController.shopSkins;
          final isLoading = _cosmeticsController.isLoading.value;

          if (isLoading &&
              _cosmeticsController.allThemes.isEmpty &&
              _cosmeticsController.allAvatars.isEmpty &&
              _cosmeticsController.allSkins.isEmpty) {
            return const Center(child: AppLoadingWidget.gold(size: 36));
          }

          return RefreshIndicator(
            onRefresh: () =>
                _cosmeticsController.fetchCatalog(forceRefresh: true),
            color: const Color(0xFFFFD700),
            backgroundColor: const Color(0xFF161B22),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Top spacing for FloatingAppBar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: FloatingAppBar.preferredTotalHeight(context) + 12,
                  ),
                ),

                // =============================================================
                // SECTION 1: THEMES
                // =============================================================
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'board_skin_title'.tr.isNotEmpty
                        ? 'board_skin_title'.tr
                        : 'Board Themes',
                    subtitle: 'board_skin_sub'.tr.isNotEmpty
                        ? 'board_skin_sub'.tr
                        : 'Choose and unlock board themes',
                    icon: Icons.palette_rounded,
                    accentColor: const Color(0xFF00E676),
                  ),
                ),

                if (shopThemes.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildSimpleEmptyText(
                      'no_items_in_shop'.tr.isNotEmpty
                          ? 'no_items_in_shop'.tr
                          : 'No items currently available for purchase.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final theme = shopThemes[index];
                        final accentColor = BoardSkins.getAccentColor(
                          theme.themeKey,
                        );

                        return _buildThemeCard(theme, accentColor, lang);
                      }, childCount: shopThemes.length),
                    ),
                  ),

                // =============================================================
                // SECTION 2: AVATARS
                // =============================================================
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'avatars_title'.tr.isNotEmpty
                        ? 'avatars_title'.tr
                        : 'Profile Avatars',
                    subtitle: 'choose_profile_avatar'.tr.isNotEmpty
                        ? 'choose_profile_avatar'.tr
                        : 'Choose your active profile avatar',
                    icon: Icons.face_rounded,
                    accentColor: const Color(0xFFFFD700),
                  ),
                ),

                if (shopAvatars.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildSimpleEmptyText(
                      'no_items_in_shop'.tr.isNotEmpty
                          ? 'no_items_in_shop'.tr
                          : 'No items currently available for purchase.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final avatar = shopAvatars[index];
                        return _buildAvatarCard(avatar, lang);
                      }, childCount: shopAvatars.length),
                    ),
                  ),
                // =============================================================
                // SECTION 3: SNAKE SKINS
                // =============================================================
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'snake_skin_title'.tr.isNotEmpty
                        ? 'snake_skin_title'.tr
                        : 'Snake Skins',
                    subtitle: 'snake_skin_sub'.tr.isNotEmpty
                        ? 'snake_skin_sub'.tr
                        : 'Customize your snake appearance',
                    icon: Icons.auto_awesome_rounded,
                    accentColor: const Color(0xFF00E676),
                  ),
                ),

                if (shopSkins.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildSimpleEmptyText(
                      'no_items_in_shop'.tr.isNotEmpty
                          ? 'no_items_in_shop'.tr
                          : 'No snake skins available.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final skin = shopSkins[index];
                        return _buildSnakeSkinCard(skin, lang);
                      }, childCount: shopSkins.length),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Section Header with glowing icon, title, and subtitle
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Simple unstyled text displayed when no items are available in a section
  Widget _buildSimpleEmptyText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Text(
        message,
        style: GoogleFonts.vazirmatn(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  // ===========================================================================
  // THEME CARD
  // ===========================================================================

  Widget _buildThemeCard(CosmeticTheme theme, Color accentColor, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Preview Image Container with Center Eye Overlay
            Expanded(
              child: GestureDetector(
                onTap: () => _openThemePreviewDialog(theme, lang),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: theme.previewUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: theme.previewUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                  child: AppLoadingWidget.gold(size: 20),
                                ),
                                errorWidget: (_, __, ___) =>
                                    _buildThemeFallbackIcon(accentColor),
                              )
                            : _buildThemeFallbackIcon(accentColor),
                      ),
                    ),

                    // Centered Dark Overlay with Eye Icon and Preview Label
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'item_preview'.tr.isNotEmpty
                                    ? 'item_preview'.tr
                                    : 'Preview',
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              theme.localizedName(lang),
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Category Subtitle
            Text(
              'board_skin_title'.tr,
              style: GoogleFonts.vazirmatn(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 10),

            // Buy Action Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => _confirmPurchaseTheme(theme, lang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'coins_count_label'.trParams({'count': '${theme.price}'}),
                      style: GoogleFonts.vazirmatn(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeFallbackIcon(Color accentColor) {
    return Container(
      color: accentColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.palette_rounded, color: accentColor, size: 36),
      ),
    );
  }

  // ===========================================================================
  // AVATAR CARD
  // ===========================================================================

  Widget _buildAvatarCard(CosmeticAvatar avatar, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Preview Icon with Center Eye Overlay
            Expanded(
              child: GestureDetector(
                onTap: () => _showAvatarPreview(avatar, lang),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              avatar.primaryColor,
                              avatar.secondaryColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: avatar.primaryColor.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0D1117),
                          ),
                          child: ClipOval(
                            child: avatar.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatar.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Icon(
                                      Icons.person_rounded,
                                      color: avatar.primaryColor,
                                      size: 36,
                                    ),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      color: avatar.primaryColor,
                                      size: 36,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: avatar.primaryColor,
                                    size: 36,
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Centered Eye Icon Overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: avatar.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              avatar.name,
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Subtitle
            Text(
              avatar.title.isNotEmpty ? avatar.title : 'avatar_title'.tr,
              style: GoogleFonts.vazirmatn(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Buy Action Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => _confirmPurchaseAvatar(avatar, lang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'coins_count_label'.trParams({
                        'count': '${avatar.price}',
                      }),
                      style: GoogleFonts.vazirmatn(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SNAKE SKIN CARD
  // ===========================================================================

  Widget _buildSnakeSkinCard(CosmeticSnakeSkin skin, String lang) {
    final isOwned = skin.hasAccess;
    final accentColor = skin.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwned
              ? accentColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
          width: isOwned ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isOwned
                ? skin.glowColor.withValues(alpha: 0.15)
                : Colors.black45,
            blurRadius: isOwned ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Snake Skin Color Preview (with Eye Overlay & tap for Preview Dialog)
            Expanded(
              child: GestureDetector(
                onTap: () => _showSnakeSkinPreview(skin, lang),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: skin.isGradient
                              ? LinearGradient(
                                  colors: skin.gradientColors!,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [skin.headColor, skin.tailColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: skin.glowColor.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: skin.isGradient
                                  ? LinearGradient(
                                      colors: skin.gradientColors!.reversed.toList(),
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [skin.tailColor, skin.headColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: isOwned
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 22,
                                  )
                                : Icon(
                                    Icons.lock_rounded,
                                    color: const Color(0xFFFFD700),
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),

                      // Centered Eye Icon Overlay
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: skin.glowColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              skin.localizedName(lang),
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Subtitle / Type
            Text(
              isOwned
                  ? ('owned'.tr.isNotEmpty ? 'owned'.tr : 'Owned')
                  : ('snake_skin_title'.tr.isNotEmpty
                      ? 'snake_skin_title'.tr
                      : 'Snake Skin'),
              style: GoogleFonts.vazirmatn(
                color: isOwned ? accentColor : Colors.white54,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 10),

            // Action Button: Equip (owned) or Buy
            SizedBox(
              width: double.infinity,
              height: 36,
              child: isOwned
                  ? Obx(() {
                      final activeSkinKey =
                          _cosmeticsController.activeSkin.value?.skinKey ?? '';
                      final isActive = activeSkinKey == skin.skinKey;

                      return ElevatedButton(
                        onPressed: isActive
                            ? null
                            : () {
                                _cosmeticsController.equipSkin(skin);
                                // Also sync SettingsController reactive state if registered
                                if (Get.isRegistered<SettingsController>()) {
                                  Get.find<SettingsController>().selectSkin(
                                    skin.skinKey,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? accentColor.withValues(alpha: 0.2)
                              : accentColor,
                          foregroundColor: isActive ? accentColor : Colors.black,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: isActive
                                ? BorderSide(color: accentColor, width: 1.5)
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          isActive
                              ? ('active'.tr.isNotEmpty ? 'active'.tr : 'Active ✓')
                              : ('equip'.tr.isNotEmpty ? 'equip'.tr : 'Equip'),
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    })
                  : ElevatedButton(
                      onPressed: () => _confirmPurchaseSkin(skin, lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            size: 14,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'coins_count_label'
                                .trParams({'count': '${skin.price}'}),
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PREVIEW DIALOG OPENERS
  // ===========================================================================

  void _openThemePreviewDialog(CosmeticTheme theme, String lang) {

    Get.dialog(
      _ThemePreviewDialog(
        theme: theme,
        lang: lang,
        onPurchase: () => _confirmPurchaseTheme(theme, lang),
      ),
    );
  }

  void _showAvatarPreview(CosmeticAvatar avatar, String lang) {
    final price = avatar.price;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: avatar.primaryColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: avatar.primaryColor.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: avatar.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.face_rounded,
                        color: avatar.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avatar.name,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'preview_avatar_title'.tr,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF21262D), height: 1),

              // Large Glowing Avatar Display Area
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [avatar.primaryColor, avatar.secondaryColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: avatar.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0D1117),
                        ),
                        child: ClipOval(
                          child: avatar.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatar.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Icon(
                                    Icons.person_rounded,
                                    color: avatar.primaryColor,
                                    size: 54,
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.person_rounded,
                                    color: avatar.primaryColor,
                                    size: 54,
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  color: avatar.primaryColor,
                                  size: 54,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      avatar.name,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (avatar.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: avatar.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: avatar.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          avatar.title,
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: avatar.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions (Cancel / Buy)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF30363D)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'back'.tr.isNotEmpty ? 'back'.tr : 'Back',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          _confirmPurchaseAvatar(avatar, lang);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'coins_count_label'.trParams({'count': '$price'}),
                              style: GoogleFonts.vazirmatn(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnakeSkinPreview(CosmeticSnakeSkin skin, String lang) {
    final isOwned = skin.hasAccess;
    final price = skin.price;
    final accentColor = skin.primaryColor;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: skin.glowColor.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skin.localizedName(lang),
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'preview_snake_skin_title'.tr,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF21262D), height: 1),

              // Preview Showcase: In-Game Authentic Snake on Grid Board with Apple
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    // Mini in-game board with animated slithering snake & apple
                    Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: const Color(0xFF090D12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: skin.glowColor.withValues(alpha: 0.22),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _SnakeSkinGamePreviewWidget(skin: skin),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Skin Name
                    Text(
                      skin.localizedName(lang),
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Color Type Badge (Gradient vs Solid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        skin.isGradient
                            ? (lang == 'fa' ? 'گرادیان چندرنگ' : 'Gradient')
                            : (lang == 'fa' ? 'تک‌رنگ درخشان' : 'Solid Neon'),
                        style: GoogleFonts.vazirmatn(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions (Back / Buy or Equip)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF30363D)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'back'.tr.isNotEmpty ? 'back'.tr : 'Back',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: isOwned
                          ? Obx(() {
                              final activeSkinKey =
                                  _cosmeticsController.activeSkin.value?.skinKey ?? '';
                              final isActive = activeSkinKey == skin.skinKey;

                              return ElevatedButton(
                                onPressed: isActive
                                    ? null
                                    : () {
                                        Get.back();
                                        _cosmeticsController.equipSkin(skin);
                                        if (Get.isRegistered<SettingsController>()) {
                                          Get.find<SettingsController>().selectSkin(
                                            skin.skinKey,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive
                                      ? accentColor.withValues(alpha: 0.2)
                                      : accentColor,
                                  foregroundColor:
                                      isActive ? accentColor : Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isActive
                                        ? BorderSide(
                                            color: accentColor,
                                            width: 1.5,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  isActive
                                      ? ('active'.tr.isNotEmpty
                                          ? 'active'.tr
                                          : 'Active ✓')
                                      : ('equip'.tr.isNotEmpty
                                          ? 'equip'.tr
                                          : 'Equip'),
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            })
                          : ElevatedButton(
                              onPressed: () {
                                Get.back();
                                _confirmPurchaseSkin(skin, lang);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'coins_count_label'
                                        .trParams({'count': '$price'}),
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PURCHASE CONFIRMATION DIALOGS (REDESIGNED)
  // ===========================================================================

  void _confirmPurchaseTheme(CosmeticTheme theme, String lang) {
    final accentColor = BoardSkins.getAccentColor(theme.themeKey);
    final previewImage = theme.previewUrl.isNotEmpty
        ? theme.previewUrl
        : (theme.modes.isNotEmpty ? theme.modes.values.first : '');

    Get.dialog(
      _PurchaseConfirmDialog(
        title: 'confirm_purchase_title'.tr.isNotEmpty
            ? 'confirm_purchase_title'.tr
            : 'Confirm Purchase',
        itemBadge: 'theme_item_badge'.tr.isNotEmpty
            ? 'theme_item_badge'.tr
            : 'Board Theme',
        itemName: theme.localizedName(lang),
        imageUrl: previewImage,
        typeIcon: Icons.palette_rounded,
        accentColor: accentColor,
        price: theme.price,
        isAvatar: false,
        onConfirm: () async {
          final targetId = theme.itemId ?? theme.id ?? theme.themeKey;
          final success = await _cosmeticsController.purchaseItem(
            itemId: targetId,
            itemType: 'theme',
            priceCoins: theme.price,
          );
          return success;
        },
      ),
    );
  }

  void _confirmPurchaseAvatar(CosmeticAvatar avatar, String lang) {
    Get.dialog(
      _PurchaseConfirmDialog(
        title: 'confirm_purchase_title'.tr.isNotEmpty
            ? 'confirm_purchase_title'.tr
            : 'Confirm Purchase',
        itemBadge: 'avatar_item_badge'.tr.isNotEmpty
            ? 'avatar_item_badge'.tr
            : 'Profile Avatar',
        itemName: avatar.name,
        itemSubtitle: avatar.title.isNotEmpty
            ? avatar.title
            : 'avatar_title'.tr,
        imageUrl: avatar.imageUrl,
        typeIcon: Icons.face_rounded,
        accentColor: avatar.primaryColor,
        secondaryColor: avatar.secondaryColor,
        price: avatar.price,
        isAvatar: true,
        onConfirm: () async {
          final targetId = avatar.itemId ?? avatar.id;
          final success = await _cosmeticsController.purchaseItem(
            itemId: targetId,
            itemType: 'avatar',
            priceCoins: avatar.price,
          );
          return success;
        },
      ),
    );
  }

  void _confirmPurchaseSkin(CosmeticSnakeSkin skin, String lang) {
    Get.dialog(
      _PurchaseConfirmDialog(
        title: 'confirm_purchase_title'.tr.isNotEmpty
            ? 'confirm_purchase_title'.tr
            : 'Confirm Purchase',
        itemBadge: 'snake_skin_title'.tr.isNotEmpty
            ? 'snake_skin_title'.tr
            : 'Snake Skin',
        itemName: skin.localizedName(lang),
        imageUrl: skin.previewUrl,
        typeIcon: Icons.auto_awesome_rounded,
        accentColor: skin.primaryColor,
        secondaryColor: skin.headColor,
        price: skin.price,
        isAvatar: false,
        customPreview: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: skin.isGradient
                ? LinearGradient(
                    colors: skin.gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [skin.headColor, skin.tailColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: skin.glowColor.withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: skin.isGradient
                    ? LinearGradient(
                        colors: skin.gradientColors!.reversed.toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [skin.tailColor, skin.headColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        onConfirm: () async {
          final targetId = skin.effectiveItemId;
          final success = await _cosmeticsController.purchaseItem(
            itemId: targetId,
            itemType: 'snake_skin',
            priceCoins: skin.price,
          );
          return success;
        },
      ),
    );
  }
}

// =============================================================================
// REDESIGNED PREMIUM PURCHASE CONFIRMATION DIALOG
// =============================================================================

class _PurchaseConfirmDialog extends StatefulWidget {
  final String title;
  final String itemBadge;
  final String itemName;
  final String? itemSubtitle;
  final String imageUrl;
  final IconData typeIcon;
  final Color accentColor;
  final Color? secondaryColor;
  final int price;
  final bool isAvatar;
  final Widget? customPreview;
  final Future<bool> Function() onConfirm;

  const _PurchaseConfirmDialog({
    required this.title,
    required this.itemBadge,
    required this.itemName,
    this.itemSubtitle,
    required this.imageUrl,
    required this.typeIcon,
    required this.accentColor,
    this.secondaryColor,
    required this.price,
    this.isAvatar = false,
    this.customPreview,
    required this.onConfirm,
  });

  @override
  State<_PurchaseConfirmDialog> createState() => _PurchaseConfirmDialogState();
}

class _PurchaseConfirmDialogState extends State<_PurchaseConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final wallet = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Obx(() {
        final currentBalance =
            wallet?.displayBalance.value ?? wallet?.balance.value ?? 0;
        final hasEnough = currentBalance >= widget.price;
        final balanceAfter = currentBalance - widget.price;

        return Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B2129), Color(0xFF10141A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.2),
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          widget.typeIcon,
                          color: widget.accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.vazirmatn(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.itemBadge,
                              style: GoogleFonts.vazirmatn(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : () => Get.back(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white60,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF21262D), height: 1),

                // 2. Showcase Item Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: widget.isAvatar
                        ? Row(
                            children: [
                              // Avatar Ring
                              Container(
                                width: 62,
                                height: 62,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.accentColor,
                                      widget.secondaryColor ??
                                          widget.accentColor,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accentColor.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0D1117),
                                  ),
                                  child: ClipOval(
                                    child: widget.imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: widget.imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Icon(
                                              Icons.person_rounded,
                                              color: widget.accentColor,
                                              size: 30,
                                            ),
                                            errorWidget: (_, __, ___) => Icon(
                                              Icons.person_rounded,
                                              color: widget.accentColor,
                                              size: 30,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            color: widget.accentColor,
                                            size: 30,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.itemName,
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (widget.itemSubtitle != null &&
                                        widget.itemSubtitle!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.itemSubtitle!,
                                        style: GoogleFonts.vazirmatn(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Thumbnail Box / Custom Preview
                              widget.customPreview != null
                                  ? widget.customPreview!
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: widget.accentColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.accentColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: widget.imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: widget.imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Center(
                                                  child: AppLoadingWidget.gold(
                                                    size: 20,
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                      color: widget.accentColor
                                                          .withValues(alpha: 0.15),
                                                      child: Icon(
                                                        widget.typeIcon,
                                                        color: widget.accentColor,
                                                        size: 28,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: widget.accentColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                                child: Icon(
                                                  widget.typeIcon,
                                                  color: widget.accentColor,
                                                  size: 28,
                                                ),
                                              ),
                                      ),
                                    ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.itemName,
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.accentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: widget.accentColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        widget.itemBadge,
                                        style: GoogleFonts.vazirmatn(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: widget.accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // 3. Financial Breakdown Sheet
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Item Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'item_price_label'.tr.isNotEmpty
                                  ? 'item_price_label'.tr
                                  : 'Item Price',
                              style: GoogleFonts.vazirmatn(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  size: 15,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'coins_count_label'.trParams({
                                    'count': '${widget.price}',
                                  }),
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFD700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 16,
                        ),

                        // Row 2: User Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'your_balance_label'.tr.isNotEmpty
                                  ? 'your_balance_label'.tr
                                  : 'Your Balance',
                              style: GoogleFonts.vazirmatn(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 14,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'coins_count_label'.trParams({
                                    'count': '$currentBalance',
                                  }),
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 16,
                        ),

                        // Row 3: Remaining Balance / Deficit Warning
                        if (hasEnough)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'balance_after_label'.tr.isNotEmpty
                                    ? 'balance_after_label'.tr
                                    : 'Balance After',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: Color(0xFF00E676),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'coins_count_label'.trParams({
                                      'count': '$balanceAfter',
                                    }),
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00E676),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF5252,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF5252,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Color(0xFFFF5252),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'deficit_label'.trParams({
                                      'count':
                                          '${widget.price - currentBalance}',
                                    }),
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5252),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color(0xFF30363D)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'cancel'.tr.isNotEmpty ? 'cancel'.tr : 'Cancel',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm / Buy Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (!hasEnough || _isLoading)
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  final success = await widget.onConfirm();
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                    if (success) {
                                      Get.back();
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasEnough
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF21262D),
                            foregroundColor: hasEnough
                                ? Colors.black
                                : Colors.white38,
                            disabledBackgroundColor: const Color(0xFF21262D),
                            disabledForegroundColor: Colors.white30,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: hasEnough ? 4 : 0,
                            shadowColor: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      hasEnough
                                          ? Icons.shopping_cart_checkout_rounded
                                          : Icons.lock_outline_rounded,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      hasEnough
                                          ? ('confirm_pay_btn'.tr.isNotEmpty
                                                ? 'confirm_pay_btn'.tr
                                                : 'Confirm & Pay')
                                          : ('insufficient_coins'.tr.isNotEmpty
                                                ? 'insufficient_coins'.tr
                                                : 'Insufficient Coins'),
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// STATEFUL THEME MULTI-MODE PREVIEW DIALOG
// =============================================================================

class _ThemePreviewDialog extends StatefulWidget {
  final CosmeticTheme theme;
  final String lang;
  final VoidCallback onPurchase;

  const _ThemePreviewDialog({
    required this.theme,
    required this.lang,
    required this.onPurchase,
  });

  @override
  State<_ThemePreviewDialog> createState() => _ThemePreviewDialogState();
}

class _ThemePreviewDialogState extends State<_ThemePreviewDialog> {
  late final PageController _pageController;
  late final List<MapEntry<String, String>> _modesList;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _modesList = [];
    if (widget.theme.modes.isNotEmpty) {
      widget.theme.modes.forEach((k, v) {
        if (v.isNotEmpty) {
          _modesList.add(MapEntry(k, v));
        }
      });
    }

    if (_modesList.isEmpty) {
      if (widget.theme.previewUrl.isNotEmpty) {
        _modesList.add(MapEntry('classic', widget.theme.previewUrl));
      } else {
        _modesList.add(const MapEntry('classic', ''));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        _modesList.length - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < _modesList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getModeDisplayName(String modeKey) {
    switch (modeKey.toLowerCase()) {
      case 'classic':
        return 'classic_mode'.tr;
      case 'level':
      case 'levels':
        return 'level_mode'.tr;
      case 'infection':
        return 'infection_mode'.tr;
      case 'blind_memory':
      case 'blind':
      case 'memory':
        return 'blind_memory_mode'.tr;
      case 'laser':
      case 'laser_core':
        return 'laser_mode'.tr;
      case 'meltdown':
        return 'meltdown_mode'.tr;
      case 'crab_chase':
      case 'crab':
        return 'crab_chase_mode'.tr;
      case 'casual':
      case 'adventure':
        return 'casual_mode'.tr;
      default:
        if (modeKey.isEmpty) return 'theme_preview'.tr;
        return modeKey.replaceAll('_', ' ').capitalizeFirst ?? modeKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = BoardSkins.getAccentColor(widget.theme.themeKey);
    final price = widget.theme.price;

    final currentEntry = _modesList.isNotEmpty
        ? _modesList[_currentIndex.clamp(0, _modesList.length - 1)]
        : const MapEntry('classic', '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.theme.localizedName(widget.lang),
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'preview_theme_title'.tr,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF21262D), height: 1),

              // Large Theme Mode Image Preview Area (Tall Height + BoxFit.contain for complete uncropped visibility)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Mode Background Images (PageView with BoxFit.contain and InteractiveViewer for complete view)
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _modesList.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final item = _modesList[index];
                            final url = item.value;

                            return InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 3.5,
                              child: Center(
                                child: url.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (_, __) => Center(
                                          child: AppLoadingWidget.gold(
                                            size: 32,
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            _buildThemeFallback(accentColor),
                                      )
                                    : _buildThemeFallback(accentColor),
                              ),
                            );
                          },
                        ),

                        // Subtle Vignette Overlay on top and bottom edges (leaving center image completely crystal clear)
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.25),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                                stops: const [0.0, 0.12, 0.82, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Left Screen Arrow Button (Previous)
                        // Positioned(
                        //   left: 8,
                        //   top: 0,
                        //   bottom: 0,
                        //   child: Center(
                        //     child: Material(
                        //       color: Colors.transparent,
                        //       child: InkWell(
                        //         onTap: _goToPrevious,
                        //         borderRadius: BorderRadius.circular(22),
                        //         child: Container(
                        //           padding: const EdgeInsets.all(9),
                        //           decoration: BoxDecoration(
                        //             color: Colors.black.withValues(alpha: 0.75),
                        //             shape: BoxShape.circle,
                        //             border: Border.all(
                        //               color: Colors.white30,
                        //               width: 1.2,
                        //             ),
                        //             boxShadow: const [
                        //               BoxShadow(
                        //                 color: Colors.black87,
                        //                 blurRadius: 8,
                        //               ),
                        //             ],
                        //           ),
                        //           child: const Icon(
                        //             Icons.chevron_left_rounded,
                        //             color: Colors.white,
                        //             size: 24,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        // Right Screen Arrow Button (Next)
                        // Positioned(
                        //   right: 8,
                        //   top: 0,
                        //   bottom: 0,
                        //   child: Center(
                        //     child: Material(
                        //       color: Colors.transparent,
                        //       child: InkWell(
                        //         onTap: _goToNext,
                        //         borderRadius: BorderRadius.circular(22),
                        //         child: Container(
                        //           padding: const EdgeInsets.all(9),
                        //           decoration: BoxDecoration(
                        //             color: Colors.black.withValues(alpha: 0.75),
                        //             shape: BoxShape.circle,
                        //             border: Border.all(
                        //               color: Colors.white30,
                        //               width: 1.2,
                        //             ),
                        //             boxShadow: const [
                        //               BoxShadow(
                        //                 color: Colors.black87,
                        //                 blurRadius: 8,
                        //               ),
                        //             ],
                        //           ),
                        //           child: const Icon(
                        //             Icons.chevron_right_rounded,
                        //             color: Colors.white,
                        //             size: 24,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        // Mode Name and Index Badge at the bottom of the image
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF161B22,
                                ).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sports_esports_rounded,
                                    color: accentColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getModeDisplayName(currentEntry.key),
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      '${_currentIndex + 1} / ${_modesList.length}',
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Mode Navigation Bar with Previous & Next Text Buttons + Indicator Dots
              if (_modesList.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      TextButton.icon(
                        onPressed: _goToPrevious,
                        // icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        label: Text(
                          'prev_btn'.tr.isNotEmpty ? 'prev_btn'.tr : 'Previous',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                      ),
                      // Mode selector indicator dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_modesList.length, (idx) {
                          final isSelected = idx == _currentIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2.5,
                              ),
                              width: isSelected ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                      // Next Button
                      TextButton.icon(
                        onPressed: _goToNext,
                        label: Text(
                          'next_btn'.tr.isNotEmpty ? 'next_btn'.tr : 'Next',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 6),

              // Actions (Back / Buy)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF30363D)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'back'.tr.isNotEmpty ? 'back'.tr : 'Back',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          widget.onPurchase();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'coins_count_label'.trParams({'count': '$price'}),
                              style: GoogleFonts.vazirmatn(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeFallback(Color accentColor) {
    return Container(
      color: accentColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.palette_rounded, color: accentColor, size: 44),
      ),
    );
  }
}

// =============================================================================
// IN-GAME AUTHENTIC SNAKE SKIN PREVIEW WIDGET
// =============================================================================

class _SnakeSkinGamePreviewWidget extends StatefulWidget {
  final CosmeticSnakeSkin skin;

  const _SnakeSkinGamePreviewWidget({required this.skin});

  @override
  State<_SnakeSkinGamePreviewWidget> createState() =>
      _SnakeSkinGamePreviewWidgetState();
}

class _SnakeSkinGamePreviewWidgetState
    extends State<_SnakeSkinGamePreviewWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SnakeSkinGamePreviewPainter(
            skin: widget.skin,
            progress: _animController.value,
          ),
        );
      },
    );
  }
}

class _SnakeSkinGamePreviewPainter extends CustomPainter {
  final CosmeticSnakeSkin skin;
  final double progress; // 0.0 -> 1.0

  _SnakeSkinGamePreviewPainter({
    required this.skin,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // -------------------------------------------------------------------------
    // 1. In-game Checkerboard Grid & Border
    // -------------------------------------------------------------------------
    const int cols = 12;
    const int rows = 7;
    final double cellW = w / cols;
    final double cellH = h / rows;
    final double cellSize = cellW < cellH ? cellW : cellH;

    final double boardW = cols * cellSize;
    final double boardH = rows * cellSize;
    final double ox = (w - boardW) / 2;
    final double oy = (h - boardH) / 2;

    final paintTileLight = Paint()..color = const Color(0xFF131A22);
    final paintTileDark = Paint()..color = const Color(0xFF0D1218);
    final paintGridLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final isEven = (r + c) % 2 == 0;
        final rect = Rect.fromLTWH(
          ox + c * cellSize,
          oy + r * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, isEven ? paintTileLight : paintTileDark);
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.transparent
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // Grid lines
    for (int c = 0; c <= cols; c++) {
      final x = ox + c * cellSize;
      canvas.drawLine(Offset(x, oy), Offset(x, oy + boardH), paintGridLine);
    }
    for (int r = 0; r <= rows; r++) {
      final y = oy + r * cellSize;
      canvas.drawLine(Offset(ox, y), Offset(ox + boardW, y), paintGridLine);
    }

    // Board subtle border
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, boardW, boardH),
      Paint()
        ..color = skin.glowColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // -------------------------------------------------------------------------
    // 2. In-Game Apple (Food) with Pulsing Glow & 🍎 Emoji
    // -------------------------------------------------------------------------
    final double appleCol = 9.5;
    final double appleRow = 3.5;
    final double ax = ox + appleCol * cellSize;
    final double ay = oy + appleRow * cellSize;

    final double pulseScale =
        1.0 + 0.15 * math.sin(progress * 2 * math.pi * 2.0);
    final double appleRadius = cellSize * 0.42 * pulseScale;

    // Food outer glow (matches snake_game _foodOuterGlowPaint & _foodSecondaryGlowPaint)
    final appleGlowPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(ax, ay), appleRadius * 1.8, appleGlowPaint);

    final appleAuraPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(ax, ay), cellSize * 0.45, appleAuraPaint);

    final applePainter = TextPainter(
      text: TextSpan(
        text: '🍎',
        style: TextStyle(fontSize: cellSize * 0.72),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(ax, ay);
    if (pulseScale != 1.0) {
      canvas.scale(pulseScale, pulseScale);
    }
    applePainter.paint(
      canvas,
      Offset(-applePainter.width / 2, -applePainter.height / 2),
    );
    canvas.restore();

    // -------------------------------------------------------------------------
    // 3. In-Game Snake Body Segments (Tail to Head)
    // -------------------------------------------------------------------------
    const int segmentCount = 9;
    final double bodyRadius = cellSize * 0.38;
    final double headRadius = cellSize * 0.48;

    final List<Offset> segmentPositions = [];
    final double headBaseX = ox + 6.8 * cellSize;
    final double headBaseY = oy + 3.5 * cellSize;

    final double wavePhase = progress * 2 * math.pi;

    for (int i = 0; i < segmentCount; i++) {
      // Slithering snake wave along horizontal axis towards the apple on the right
      final double segX = headBaseX - (i * cellSize * 0.68);
      // Gentle sine undulation
      final double waveOffset =
          math.sin(wavePhase - (i * 0.75)) * (cellSize * 0.45);
      final double segY = headBaseY + waveOffset;
      segmentPositions.add(Offset(segX, segY));
    }

    // Paint Paints
    final glowPaint = Paint();
    final bodyPaint = Paint();
    final shinePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.14);

    // Draw body segments (tail -> segment 1) exactly as in snake_game.dart
    for (int i = segmentCount - 1; i >= 1; i--) {
      final pos = segmentPositions[i];
      final double t = i / (segmentCount - 1);
      final Color color = skin.getColorAt(t);

      // Glow circle
      glowPaint.color = skin.glowColor.withValues(alpha: 0.22);
      canvas.drawCircle(pos, bodyRadius * 1.35, glowPaint);

      // Body solid fill
      bodyPaint.color = color;
      canvas.drawCircle(pos, bodyRadius, bodyPaint);

      // Segment shine highlight (identical to _snakeShinePaint in game engine)
      canvas.drawCircle(
        Offset(pos.dx - bodyRadius * 0.2, pos.dy - bodyRadius * 0.2),
        bodyRadius * 0.35,
        shinePaint,
      );
    }

    // -------------------------------------------------------------------------
    // 4. In-Game Snake Head with Radial Gradient, Glow & Eyes
    // -------------------------------------------------------------------------
    final headPos = segmentPositions.first;
    final hx = headPos.dx;
    final hy = headPos.dy;

    // Head glow
    final headGlowPaint = Paint()
      ..color = skin.glowColor.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(hx, hy), headRadius * 1.5, headGlowPaint);

    // Radial gradient head paint (matches snake_game.dart line 1419-1425)
    final headColor1 = skin.headColor;
    final headColor2 = skin.getColorAt(0.2);
    final headPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(hx, hy),
        headRadius,
        [headColor1, headColor2],
        const [0.0, 0.85],
      );
    canvas.drawCircle(Offset(hx, hy), headRadius, headPaint);

    // Eyes oriented towards movement direction (Right)
    final double eyeRadius = headRadius * 0.23;
    final double pupilRadius = eyeRadius * 0.55;
    final double offsetForward = headRadius * 0.32;
    final double offsetSide = headRadius * 0.38;

    final eyeWhitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final eyePupilPaint = Paint()..color = const Color(0xFF1A1A2E);

    // Top Eye
    final eye1 = Offset(hx + offsetForward, hy - offsetSide);
    canvas.drawCircle(eye1, eyeRadius, eyeWhitePaint);
    canvas.drawCircle(
      Offset(eye1.dx + eyeRadius * 0.25, eye1.dy),
      pupilRadius,
      eyePupilPaint,
    );

    // Bottom Eye
    final eye2 = Offset(hx + offsetForward, hy + offsetSide);
    canvas.drawCircle(eye2, eyeRadius, eyeWhitePaint);
    canvas.drawCircle(
      Offset(eye2.dx + eyeRadius * 0.25, eye2.dy),
      pupilRadius,
      eyePupilPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SnakeSkinGamePreviewPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.skin != skin;
  }
}
