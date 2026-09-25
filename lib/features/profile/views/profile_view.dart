import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snake_game/features/auth/controllers/auth_controller.dart';
import 'package:snake_game/features/cosmetics/controllers/cosmetics_controller.dart';
import 'package:snake_game/features/cosmetics/models/cosmetics_models.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../auth/widgets/auth_dialog.dart';
import '../../auth/widgets/avatar_xp_ring.dart';
import '../../game/models/game_mode_config.dart';
import '../../hall_of_fame/models/hall_of_fame_models.dart';
import '../controllers/profile_controller.dart';
import '../widgets/game_mode_donut_chart.dart';
import '../../league/models/league_tier_models.dart';
import '../../menu/controllers/menu_controller.dart' as menu;
import '../../settings/controllers/settings_controller.dart';
import '../../wallet/widgets/wallet_badge_widget.dart';

/// Redesigned Compact & Unified Profile View with 3 distinct Honor sections:
/// 1. Weekly League Honors (افتخارات لیگ هفتگی)
/// 2. Daily Challenge Honors (افتخارات چالش‌های روزانه)
/// 3. Best in Specific Modes except Level Mode (افتخارات بهترین در مودهای خاص)
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        titleText: 'player_profile'.tr,
        actions: [
          Obx(() {
            final isLoggedIn = controller.authController.isLoggedIn.value;
            if (!isLoggedIn) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditProfileDialog(
                    context,
                    controller.authController,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  tooltip: 'edit_profile'.tr,
                ),
                IconButton(
                  onPressed: () => _showLogoutConfirmDialog(
                    context,
                    controller.authController,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFF5252),
                    size: 20,
                  ),
                  tooltip: 'logout'.tr,
                ),
              ],
            );
          }),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162238), Color(0xFF0D1117), Color(0xFF0A0E14)],
            stops: [0.0, 0.28, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: FloatingAppBar.preferredTotalHeight(context) + 4,
              ),

              // Tab Selector (پروفایل و رکوردهای من | تالار افتخارات لیگ)
              _buildTabBar(controller),

              // Main Body
              Expanded(
                child: Obx(() {
                  final isLoggedIn = controller.authController.isLoggedIn.value;
                  if (!isLoggedIn) {
                    return _buildGuestLockedView(context, controller);
                  }

                  if (controller.isLoadingProfile.value) {
                    return const Center(
                      child: AppLoadingWidget(size: 44, color: kPrimaryColor),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty &&
                      controller.fullProfile.value == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.errorMessage.value,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => controller.refreshProfile(),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text('retry'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (controller.selectedTabIndex.value == 0) {
                    // TAB 0: My Profile & Personal Records
                    return RefreshIndicator(
                      onRefresh: () => controller.refreshProfile(),
                      color: kPrimaryColor,
                      backgroundColor: const Color(0xFF161B22),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Compact User Header Card
                            _buildCompactUserCard(context, controller),

                            const SizedBox(height: 16),

                            // 2. My Personal Best Records (رکوردهای شخصی من در مودها)
                            _buildSectionHeader(
                              icon: Icons.military_tech_rounded,
                              title: 'my_personal_records'.tr,
                              accentColor: const Color(0xFF00E5FF),
                            ),
                            const SizedBox(height: 8),
                            _buildSpecialModeHonors(controller),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // TAB 1: League Hall of Fame & Honors
                    return RefreshIndicator(
                      onRefresh: () => controller.refreshProfile(),
                      color: Colors.amber,
                      backgroundColor: const Color(0xFF161B22),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. My League Medals & Trophies (ویترین افتخارات و مدال‌های من در لیگ)
                            _buildSectionHeader(
                              icon: Icons.workspace_premium_rounded,
                              title: 'my_league_medals'.tr,
                              accentColor: Colors.amber,
                            ),
                            const SizedBox(height: 8),
                            _buildWeeklyLeagueHonors(controller),

                            const SizedBox(height: 18),

                            // 2. Daily Challenge Honors (چالش‌های روزانه انجام‌شده)
                            _buildSectionHeader(
                              icon: Icons.verified_rounded,
                              title: 'daily_challenges_completed'.tr,
                              accentColor: Colors.orangeAccent,
                            ),
                            const SizedBox(height: 8),
                            _buildDailyChallengeHonors(controller),

                            const SizedBox(height: 18),

                            // 3. Past Seasons League History (تالار قهرمانان فصل‌های گذشته)
                            _buildSectionHeader(
                              icon: Icons.emoji_events_rounded,
                              title: 'past_seasons_hall'.tr,
                              accentColor: const Color(0xFF00E5FF),
                            ),
                            const SizedBox(height: 8),
                            _buildPastSeasonsHistory(controller),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sleek Animated Tab Switcher (پروفایل و رکوردهای من | تالار افتخارات لیگ)
  Widget _buildTabBar(ProfileController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(3),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Obx(() {
        final currentTab = controller.selectedTabIndex.value;
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedTabIndex.value = 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: currentTab == 0 ? kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 15,
                          color: currentTab == 0
                              ? Colors.black
                              : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'my_profile_tab'.tr,
                          style: TextStyle(
                            color: currentTab == 0
                                ? Colors.black
                                : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedTabIndex.value = 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: currentTab == 1 ? Colors.amber : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 15,
                          color: currentTab == 1
                              ? Colors.black
                              : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'league_hall_tab'.tr,
                          style: TextStyle(
                            color: currentTab == 1
                                ? Colors.black
                                : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// SECTION: Past Seasons League History & Podium
  Widget _buildPastSeasonsHistory(ProfileController controller) {
    return Obx(() {
      final seasons = controller.hallOfFameSeasons;

      if (controller.isLoadingHallOfFame.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: AppLoadingWidget.gold(size: 32)),
        );
      }

      if (seasons.isEmpty) {
        return _buildEmptyHonorTile(
          icon: Icons.emoji_events_outlined,
          message: 'no_league_history'.tr,
        );
      }

      return Column(
        children: seasons.map((entry) {
          return GestureDetector(
            onTap: () => Get.toNamed('/season-detail', arguments: entry.season),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${'season'.tr} ${entry.season}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (entry.goldPlayer != null)
                    _buildPodiumWinnerRow(
                      player: entry.goldPlayer!,
                      score: entry.goldScore,
                      medalAsset: 'assets/image/medal/gold.png',
                      medalColor: Colors.amber,
                    ),
                  if (entry.silverPlayer != null) ...[
                    const SizedBox(height: 6),
                    _buildPodiumWinnerRow(
                      player: entry.silverPlayer!,
                      score: entry.silverScore,
                      medalAsset: 'assets/image/medal/silver.png',
                      medalColor: const Color(0xFFE0E0E0),
                    ),
                  ],
                  if (entry.bronzePlayer != null) ...[
                    const SizedBox(height: 6),
                    _buildPodiumWinnerRow(
                      player: entry.bronzePlayer!,
                      score: entry.bronzeScore,
                      medalAsset: 'assets/image/medal/bronze.png',
                      medalColor: const Color(0xFFCD7F32),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  /// Compact Podium Row for Hall of Fame seasons
  Widget _buildPodiumWinnerRow({
    required HallOfFamePlayer player,
    required int score,
    required String medalAsset,
    required Color medalColor,
  }) {
    return Row(
      children: [
        Image.asset(
          medalAsset,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.workspace_premium_rounded,
            color: medalColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            player.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$score ${'pts'.tr}',
          style: TextStyle(
            color: medalColor,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Compact User Header Card
  Widget _buildCompactUserCard(
    BuildContext context,
    ProfileController controller,
  ) {
    final auth = controller.authController;
    final menuCtrl = Get.isRegistered<menu.MenuController>()
        ? Get.find<menu.MenuController>()
        : null;
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;

    return Obx(() {
      final isRtl = settings != null
          ? (settings.currentLanguage.value.toLowerCase() == 'fa' ||
                settings.currentLanguage.value.toLowerCase() == 'ar')
          : (Get.locale?.languageCode.toLowerCase() == 'fa' ||
                Directionality.of(context) == TextDirection.rtl);
      final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

      final user = auth.currentUser.value;
      final cosmetics = Get.isRegistered<CosmeticsController>()
          ? Get.find<CosmeticsController>()
          : null;
      final effectiveAvatarId = user?.avatarId ?? auth.selectedAvatarId.value;
      final cosmeticAvatar = cosmetics?.getAvatarById(effectiveAvatarId);
      final avatar = getAvatarById(effectiveAvatarId);
      final effectiveTitle =
          (cosmeticAvatar != null &&
              cosmeticAvatar.name.isNotEmpty &&
              cosmeticAvatar.name != 'Avatar')
          ? cosmeticAvatar.name
          : avatar.title;

      final level = controller.playerLevel.value;
      final xp = controller.playerXp.value;
      final nextXp = controller.xpForNextLevel.value;
      final progress = controller.levelProgress.value;

      final summary =
          menuCtrl?.leagueSummary.value ??
          menuCtrl?.dashboard.value?.leagueSummary;
      final tier = summary != null ? summary.leagueTier : LeagueTier.bronze;
      final rank = summary?.rank;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Large Avatar outside of the box, horizontally centered
          Center(
            child: AvatarXpRing(
              avatar: avatar,
              cosmeticAvatar: cosmeticAvatar,
              primaryColor: kAvatarPrimaryColor,
              secondaryColor: kAvatarSecondaryColor,
              level: level,
              progress: progress,
              size: 104,
              customImagePath: auth.customAvatarPath.value,
              onTap: () => _showEditProfileDialog(context, auth),
            ),
          ),

          const SizedBox(height: 8),

          // XP Counter & Title right underneath Avatar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kAvatarPrimaryColor.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: kAvatarPrimaryColor.withValues(alpha: 0.12),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: kAvatarPrimaryColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$effectiveTitle  •  ${controller.currentLevelXp.value} / ${controller.currentLevelSpan.value} XP',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. The Box / Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Directionality(
              textDirection: textDirection,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Rank image (Clean, no name underneath)
                  Tooltip(
                    message: tier.displayNameTr,
                    child: Image.asset(
                      tier.assetPath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(tier.icon, color: tier.color, size: 40),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 2. Username & Bio attached right next to rank image
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Player',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user?.bio != null &&
                            user!.bio!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.bio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 3. Opposite side: Home-style Coin Box
                  const WalletBadgeWidget(showAddButton: true),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Helper function to pick an image from gallery and open ImageCropper
  Future<String?> _pickAndCropAvatarImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (pickedFile == null) return null;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '',
            cropStyle: CropStyle.circle,
            toolbarColor: const Color(0xFF0D1117),
            statusBarColor: const Color(0xFF0D1117),
            backgroundColor: const Color(0xFF0D1117),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: kPrimaryColor,
            cropFrameColor: const Color(0x33FFFFFF),
            dimmedLayerColor: Colors.black54,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
            showCropGrid: false,
          ),
          IOSUiSettings(
            title: '',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            resetButtonHidden: true,
            rotateButtonsHidden: true,
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      return null;
    }
  }

  /// Dialog to edit profile (Username, Avatar, Email, Bio, Current Password, New Password)
  void _showEditProfileDialog(BuildContext context, AuthController auth) {
    final currentUser = auth.currentUser.value;
    final usernameController = TextEditingController(
      text: currentUser?.username ?? '',
    );
    final emailController = TextEditingController(
      text: currentUser?.email ?? '',
    );
    final bioController = TextEditingController(text: currentUser?.bio ?? '');
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final selectedAvatarId =
        (currentUser?.avatarId ?? auth.selectedAvatarId.value).obs;
    final tempCustomImagePath = auth.customAvatarPath.value.obs;
    final isUpdating = false.obs;
    final showCurrentPassword = false.obs;
    final showNewPassword = false.obs;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: kPrimaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'edit_profile'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'edit_profile_sub'.tr,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Avatar Selection Section with titles below
              Text(
                'select_avatar'.tr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final cosmetics = Get.isRegistered<CosmeticsController>()
                      ? Get.find<CosmeticsController>()
                      : null;

                  return SizedBox(
                    height: 92,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Obx(() {
                        final rawAvatars =
                            cosmetics?.allAvatars ?? <CosmeticAvatar>[];
                        final dynamicAvatars =
                            List<CosmeticAvatar>.from(rawAvatars)
                              ..sort((a, b) {
                                final aOwned = a.hasAccess ? 0 : 1;
                                final bOwned = b.hasAccess ? 0 : 1;
                                return aOwned.compareTo(bOwned);
                              });
                        final useDynamic = dynamicAvatars.isNotEmpty;
                        final count = useDynamic
                            ? (dynamicAvatars.length + 1)
                            : kPresetAvatars.length;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(count, (index) {
                            // Custom photo option is placed as the last item when dynamic, or avatar_7 in preset
                            final isCustomOption = useDynamic
                                ? (index == dynamicAvatars.length)
                                : (kPresetAvatars[index].id == 'avatar_7');

                            final String avatarId;
                            final String avatarTitle;
                            final String? avatarImgUrl;
                            final bool isLocked;
                            CosmeticAvatar? cosmeticItem;

                            if (isCustomOption) {
                              avatarId = 'avatar_7';
                              avatarTitle = 'upload'.tr.isNotEmpty
                                  ? 'upload'.tr
                                  : 'Upload';
                              avatarImgUrl = null;
                              isLocked = false;
                            } else if (useDynamic) {
                              final da = dynamicAvatars[index];
                              cosmeticItem = da;
                              avatarId =
                                  (da.itemId?.toString().isNotEmpty == true)
                                  ? da.itemId.toString()
                                  : da.id.toString();
                              avatarTitle = da.name;
                              avatarImgUrl = da.imageUrl;
                              isLocked = !da.hasAccess;
                            } else {
                              final pa = kPresetAvatars[index];
                              avatarId = pa.id;
                              avatarTitle = pa.title;
                              avatarImgUrl = pa.imageUrl;
                              isLocked =
                                  pa.id != 'avatar_1' && pa.id != 'avatar_2';
                            }

                            final currentSel = selectedAvatarId.value
                                .trim()
                                .toLowerCase();
                            final isSelected =
                                currentSel == avatarId.trim().toLowerCase() ||
                                (cosmeticItem != null &&
                                    (cosmeticItem.id
                                                .toString()
                                                .trim()
                                                .toLowerCase() ==
                                            currentSel ||
                                        cosmeticItem.itemId
                                                ?.toString()
                                                .trim()
                                                .toLowerCase() ==
                                            currentSel));

                            final hasCustomImage =
                                isCustomOption &&
                                tempCustomImagePath.value.isNotEmpty &&
                                File(tempCustomImagePath.value).existsSync();

                            return GestureDetector(
                              onTap: () async {
                                if (isLocked) {
                                  Get.back();
                                  Get.toNamed('/shop');
                                  Get.snackbar(
                                    'locked_avatar_title'.tr.isNotEmpty
                                        ? 'locked_avatar_title'.tr
                                        : 'آواتار قفل است',
                                    'locked_avatar_shop_msg'.tr.isNotEmpty
                                        ? 'locked_avatar_shop_msg'.tr
                                        : 'برای تهیه و آنلاک این آواتار به فروشگاه منتقل شدید.',
                                    backgroundColor: const Color(0xFF161B22),
                                    colorText: Colors.white,
                                    icon: const Icon(
                                      Icons.shopping_bag_rounded,
                                      color: Color(0xFFFFD54F),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  );
                                  return;
                                }

                                if (isCustomOption) {
                                  final croppedPath =
                                      await _pickAndCropAvatarImage();
                                  if (croppedPath != null) {
                                    tempCustomImagePath.value = croppedPath;
                                    selectedAvatarId.value = 'avatar_7';
                                  } else if (tempCustomImagePath
                                      .value
                                      .isNotEmpty) {
                                    selectedAvatarId.value = 'avatar_7';
                                  }
                                } else {
                                  selectedAvatarId.value = avatarId;
                                  tempCustomImagePath.value = '';
                                  if (cosmeticItem != null) {
                                    cosmetics?.equipAvatar(cosmeticItem);
                                  }
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? kAvatarPrimaryColor
                                              : (isLocked
                                                    ? Colors.white.withValues(
                                                        alpha: 0.12,
                                                      )
                                                    : Colors.transparent),
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: kAvatarPrimaryColor
                                                      .withValues(alpha: 0.45),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (isCustomOption && !hasCustomImage)
                                            CustomPaint(
                                              painter: _DashedCirclePainter(
                                                color: isSelected
                                                    ? kAvatarPrimaryColor
                                                    : Colors.white38,
                                                strokeWidth: 1.5,
                                                gapAngle: 0.25,
                                              ),
                                              child: SizedBox(
                                                width: 44,
                                                height: 44,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.add_rounded,
                                                    color: isSelected
                                                        ? kAvatarPrimaryColor
                                                        : Colors.white70,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            CircleAvatar(
                                              backgroundColor:
                                                  kAvatarSecondaryColor
                                                      .withValues(
                                                        alpha: isLocked
                                                            ? 0.08
                                                            : 0.2,
                                                      ),
                                              radius: 20,
                                              child: hasCustomImage
                                                  ? ClipOval(
                                                      child: Image.file(
                                                        File(
                                                          tempCustomImagePath
                                                              .value,
                                                        ),
                                                        fit: BoxFit.cover,
                                                        width: 40,
                                                        height: 40,
                                                      ),
                                                    )
                                                  : (avatarImgUrl != null &&
                                                        avatarImgUrl.isNotEmpty)
                                                  ? ClipOval(
                                                      child: CachedNetworkImage(
                                                        imageUrl: avatarImgUrl,
                                                        fit: BoxFit.cover,
                                                        width: 40,
                                                        height: 40,
                                                        placeholder: (_, __) =>
                                                            const Icon(
                                                              Icons
                                                                  .person_rounded,
                                                              color:
                                                                  kAvatarPrimaryColor,
                                                              size: 20,
                                                            ),
                                                        errorWidget:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => const Icon(
                                                              Icons
                                                                  .person_rounded,
                                                              color:
                                                                  kAvatarPrimaryColor,
                                                              size: 20,
                                                            ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person_rounded,
                                                      color: isLocked
                                                          ? kAvatarSecondaryColor
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                )
                                                          : (isSelected
                                                                ? kAvatarPrimaryColor
                                                                : kAvatarSecondaryColor),
                                                      size: 20,
                                                    ),
                                            ),

                                          // Lock overlay badge for unpurchased items
                                          if (isLocked)
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(
                                                  alpha: 0.60,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.lock_rounded,
                                                  color: Color(0xFFFFD54F),
                                                  size: 16,
                                                ),
                                              ),
                                            ),

                                          // Active Checkmark Badge for Selected item
                                          if (isSelected && !isLocked)
                                            Positioned(
                                              bottom: -1,
                                              right: -1,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  1.5,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF161B22),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle_rounded,
                                                  color: kAvatarPrimaryColor,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isLocked) ...[
                                          const Icon(
                                            Icons.lock_rounded,
                                            color: Color(0xFFFFD54F),
                                            size: 9,
                                          ),
                                          const SizedBox(width: 2),
                                        ],
                                        Text(
                                          avatarTitle,
                                          style: TextStyle(
                                            color: isSelected
                                                ? kAvatarPrimaryColor
                                                : (isLocked
                                                      ? Colors.white38
                                                      : Colors.white60),
                                            fontSize: 9.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Username Field
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'username'.tr,
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: kPrimaryColor,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Email Field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'email'.tr,
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF9E9E9E),
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bio Field (Limited to 150 chars)
              TextField(
                controller: bioController,
                maxLength: 150,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'bio'.tr,
                  hintText: 'bio_hint'.tr,
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  counterStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                  prefixIcon: const Icon(
                    Icons.notes_rounded,
                    color: Colors.purpleAccent,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.purpleAccent),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Current Password Field
              Obx(() {
                return TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrentPassword.value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'current_password'.tr,
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrentPassword.value
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () => showCurrentPassword.toggle(),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              // New Password Field
              Obx(() {
                return TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword.value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'new_password'.tr,
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.key_rounded,
                      color: Color(0xFF00E5FF),
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPassword.value
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () => showNewPassword.toggle(),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF30363D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      return ElevatedButton(
                        onPressed: isUpdating.value
                            ? null
                            : () async {
                                final newUsername = usernameController.text
                                    .trim();
                                final emailText = emailController.text.trim();
                                final bioText = bioController.text.trim();
                                final currentPass = currentPasswordController
                                    .text
                                    .trim();
                                final newPass = newPasswordController.text
                                    .trim();

                                if (newUsername.isEmpty) {
                                  Get.snackbar(
                                    'error'.tr,
                                    'Username cannot be empty',
                                  );
                                  return;
                                }

                                isUpdating.value = true;

                                File? fileToUpload;
                                if (selectedAvatarId.value == 'avatar_7' &&
                                    tempCustomImagePath.value.isNotEmpty) {
                                  fileToUpload = File(
                                    tempCustomImagePath.value,
                                  );
                                }

                                final result = await auth.updateFullProfile(
                                  username: newUsername,
                                  avatarId: selectedAvatarId.value,
                                  avatar: fileToUpload,
                                  email: emailText.isNotEmpty
                                      ? emailText
                                      : null,
                                  bio: bioText.isNotEmpty ? bioText : null,
                                  currentPassword: currentPass.isNotEmpty
                                      ? currentPass
                                      : null,
                                  newPassword: newPass.isNotEmpty
                                      ? newPass
                                      : null,
                                );
                                isUpdating.value = false;

                                if (result != null) {
                                  Get.back();
                                  Get.snackbar('success'.tr, result);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: isUpdating.value
                            ? const AppLoadingWidget.small(
                                size: 16,
                                color: Colors.black,
                              )
                            : Text(
                                'save_changes'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmDialog(BuildContext context, AuthController auth) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF1744),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'logout_confirm_title'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'logout_confirm_msg'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        auth.logout();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'logout'.tr,
                        style: const TextStyle(
                          color: Color(0xFFFF1744),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact Section Header
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// SECTION 1: Weekly League Honors (افتخارات لیگ هفتگی)
  Widget _buildWeeklyLeagueHonors(ProfileController controller) {
    return Obx(() {
      final history = controller.leagueHistory;
      final playerMedals = controller.playerMedals;

      int goldCount = playerMedals.where((m) => m.medalType == 'gold').length;
      int silverCount = playerMedals
          .where((m) => m.medalType == 'silver')
          .length;
      int bronzeCount = playerMedals
          .where((m) => m.medalType == 'bronze')
          .length;

      if (goldCount == 0 && silverCount == 0 && bronzeCount == 0) {
        for (final entry in history) {
          if (entry.rank == 1) {
            goldCount++;
          } else if (entry.rank == 2) {
            silverCount++;
          } else if (entry.rank == 3) {
            bronzeCount++;
          }

          for (final m in entry.medals) {
            if (m.medalType == 'gold') goldCount++;
            if (m.medalType == 'silver') silverCount++;
            if (m.medalType == 'bronze') bronzeCount++;
          }
        }
      }

      return Column(
        children: [
          // 3 Medal Cards (Gold, Silver, Bronze)
          Row(
            children: [
              Expanded(
                child: _buildMedalCard(
                  title: 'gold_medal'.tr,
                  imagePath: 'assets/image/medal/gold.png',
                  fallbackIcon: Icons.workspace_premium_rounded,
                  count: goldCount,
                  accentColor: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMedalCard(
                  title: 'silver_medal'.tr,
                  imagePath: 'assets/image/medal/silver.png',
                  fallbackIcon: Icons.workspace_premium_rounded,
                  count: silverCount,
                  accentColor: const Color(0xFFE0E0E0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMedalCard(
                  title: 'bronze_medal'.tr,
                  imagePath: 'assets/image/medal/bronze.png',
                  fallbackIcon: Icons.workspace_premium_rounded,
                  count: bronzeCount,
                  accentColor: const Color(0xFFCD7F32),
                ),
              ),
            ],
          ),

          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...history.take(3).map((entry) {
              final isTopRank = entry.rank > 0 && entry.rank <= 3;
              final rankColor = entry.rank == 1
                  ? Colors.amber
                  : entry.rank == 2
                  ? const Color(0xFFE0E0E0)
                  : entry.rank == 3
                  ? const Color(0xFFCD7F32)
                  : Colors.white54;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTopRank
                        ? rankColor.withValues(alpha: 0.4)
                        : const Color(0xFF21262D),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${entry.rank}',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'season'.tr} ${entry.season}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${entry.finalScore.toStringAsFixed(1)} ${'pts'.tr}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.medals.isNotEmpty)
                      Row(
                        children: entry.medals
                            .where(
                              (m) =>
                                  m.medalType == 'gold' ||
                                  m.medalType == 'silver' ||
                                  m.medalType == 'bronze',
                            )
                            .map((m) {
                              final asset = m.medalType == 'gold'
                                  ? 'assets/image/medal/gold.png'
                                  : m.medalType == 'silver'
                                  ? 'assets/image/medal/silver.png'
                                  : m.medalType == 'bronze'
                                  ? 'assets/image/medal/bronze.png'
                                  : null;
                              final mColor = m.medalType == 'gold'
                                  ? Colors.amber
                                  : m.medalType == 'silver'
                                  ? const Color(0xFFE0E0E0)
                                  : const Color(0xFFCD7F32);
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: asset != null
                                    ? Image.asset(
                                        asset,
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.contain,
                                      )
                                    : Icon(
                                        Icons.workspace_premium_rounded,
                                        color: mColor,
                                        size: 18,
                                      ),
                              );
                            })
                            .toList(),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      );
    });
  }

  /// Single Medal Display Card (Gold, Silver, Bronze)
  Widget _buildMedalCard({
    required String title,
    required String? imagePath,
    required IconData fallbackIcon,
    required int count,
    required Color accentColor,
  }) {
    final bool isEarned = count > 0;

    Widget buildImageOrFallback({required bool active}) {
      if (imagePath == null) {
        return _buildFallbackIcon(fallbackIcon, accentColor, active);
      }
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(fallbackIcon, accentColor, active),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned
              ? accentColor.withValues(alpha: 0.5)
              : const Color(0xFF21262D),
          width: isEarned ? 1.5 : 1.0,
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isEarned
                          ? buildImageOrFallback(active: true)
                          : ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0.35,
                                0,
                              ]),
                              child: buildImageOrFallback(active: false),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 2,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEarned ? Colors.white : Colors.white38,
                      fontSize: 9.5,
                      fontWeight: isEarned ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            // Count badge if count > 1
            if (count > 1)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    'x$count',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Fallback icon widget when image asset is not available
  Widget _buildFallbackIcon(IconData icon, Color color, bool isEarned) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isEarned ? 0.2 : 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(icon, color: isEarned ? color : Colors.white24, size: 24),
      ),
    );
  }

  /// Daily Challenges Completed Counter (تعداد چالش‌های روزانه انجام‌شده)
  Widget _buildDailyChallengeHonors(ProfileController controller) {
    return Obx(() {
      final user = controller.authController.currentUser.value;
      final profile = controller.userProfile.value;

      int completedCount = controller.missionsCompletedTotal.value;
      if (completedCount <= 0 &&
          controller.fullProfile.value?.missionsCompletedTotal != null &&
          controller.fullProfile.value!.missionsCompletedTotal > 0) {
        completedCount = controller.fullProfile.value!.missionsCompletedTotal;
      }

      if (completedCount <= 0) {
        if (profile != null && profile.dailyChallengeMedals.isNotEmpty) {
          final raw =
              profile.dailyChallengeMedals['completed_count'] ??
              profile.dailyChallengeMedals['missions_completed_total'] ??
              profile.dailyChallengeMedals['completed_missions'] ??
              profile.dailyChallengeMedals['total_medals'] ??
              ((profile.dailyChallengeMedals['gold'] ?? 0) +
                  (profile.dailyChallengeMedals['silver'] ?? 0) +
                  (profile.dailyChallengeMedals['bronze'] ?? 0));
          completedCount = raw is num
              ? raw.toInt()
              : (int.tryParse(raw.toString()) ?? 0);
        } else if (user?.dailyChallengeMedals != null) {
          completedCount = user!.totalDailyMedals;
        }
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.orangeAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'daily_challenges_completed'.tr,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$completedCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.black87,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// SECTION 3: Best in Specific Modes EXCEPT Level Mode (افتخارات بهترین در مودهای خاص)
  Widget _buildSpecialModeHonors(ProfileController controller) {
    return Obx(() {
      // Filter out Level Mode per user request
      final specialModes = availableGameModes
          .where((m) => m.mode != GameMode.level)
          .toList();

      // Build play counts map from authoritative modeRecords if available
      final fullRecords = controller.fullProfile.value?.modeRecords;
      final donutPlayCounts = <String, int>{};
      if (fullRecords != null && fullRecords.isNotEmpty) {
        for (final rec in fullRecords) {
          if (rec.playCount > 0) {
            donutPlayCounts[rec.gameMode] = rec.playCount;
          }
        }
      } else {
        donutPlayCounts.addAll(
          Map<String, int>.from(controller.modePlayCounts)
            ..remove('level')
            ..removeWhere((_, v) => v <= 0),
        );
      }
      final hasPlayCounts = donutPlayCounts.values.any((c) => c > 0);

      final selectedMode = controller.selectedSpecialMode.value;

      return Column(
        children: [
          if (hasPlayCounts) ...[
            GameModeDonutChart(
              playCounts: donutPlayCounts,
              size: 165,
              selectedModeId: selectedMode.isNotEmpty ? selectedMode : null,
              onModeSelected: (modeId) {
                controller.selectedSpecialMode.value = modeId ?? '';
              },
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: specialModes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final config = specialModes[index];
                final score = controller.getModeScore(config.id, config.mode);
                final playCount = controller.getModePlayCount(
                  config.id,
                  config.mode,
                );
                final isInfection = config.mode == GameMode.infection;

                final String displayRecord;
                if (isInfection) {
                  final mins = (score ~/ 60).toString().padLeft(2, '0');
                  final secs = (score % 60).toString().padLeft(2, '0');
                  displayRecord = '$mins:$secs';
                } else {
                  displayRecord = '$score';
                }

                String shortTitle = config.titleTr
                    .replaceAll(
                      RegExp(
                        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
                        unicode: true,
                      ),
                      '',
                    )
                    .replaceAll('حالت ', '')
                    .replaceAll(' MODE', '')
                    .trim();

                final selectedConfig = selectedMode.isNotEmpty
                    ? GameModeConfig.findByModeString(selectedMode)
                    : null;
                final isSelected = selectedConfig != null
                    ? (selectedConfig.id == config.id ||
                          selectedConfig.mode == config.mode)
                    : false;

                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      controller.selectedSpecialMode.value = '';
                    } else {
                      controller.selectedSpecialMode.value = config.id;
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 98,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? config.accentColor.withValues(alpha: 0.18)
                          : const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? config.accentColor
                            : config.accentColor.withValues(alpha: 0.3),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: config.accentColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mode Logo with soft glowing circle
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: config.accentColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: config.accentColor.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child:
                              (config.iconAsset != null &&
                                  config.iconAsset!.isNotEmpty)
                              ? Image.asset(
                                  config.iconAsset!,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (_, __, ___) => Icon(
                                    config.icon,
                                    color: config.accentColor,
                                    size: 22,
                                  ),
                                )
                              : Icon(
                                  config.icon,
                                  color: config.accentColor,
                                  size: 22,
                                ),
                        ),
                        // Mode Title
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              shortTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        // Best Score Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: config.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: config.accentColor.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              displayRecord,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: config.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Play Count
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            playCount > 0 ? '$playCount بازی' : 'بدون بازی',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: playCount > 0
                                  ? Colors.white54
                                  : Colors.white24,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  /// Compact empty state placeholder
  Widget _buildEmptyHonorTile({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Guest Locked Screen when user is not logged in
  Widget _buildGuestLockedView(
    BuildContext context,
    ProfileController controller,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withValues(alpha: 0.1),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: kPrimaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'profile_locked'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'profile_locked_sub'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => Get.dialog(const AuthDialog()),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text('login_or_register'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for dashed circle border around custom avatar upload button
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gapAngle; // Gap angle in radians or fraction

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gapAngle = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const totalDashes = 10;
    const double sweepAngle = (2 * 3.141592653589793 / totalDashes);
    final double dashAngle = sweepAngle * 0.65;

    for (int i = 0; i < totalDashes; i++) {
      final double startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
