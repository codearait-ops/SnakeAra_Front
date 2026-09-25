import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/utils/enums.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../../services/sound_service.dart';
import '../../game/models/game_mode_config.dart';
import '../../leaderboard/controllers/leaderboard_controller.dart';
import '../../leaderboard/views/widgets/leaderboard_header_bar.dart';
import '../../leaderboard/views/widgets/online_league_card.dart';
import '../../levels/controllers/level_controller.dart';
import '../../profile/views/player_profile_bottom_sheet.dart';
import '../controllers/menu_controller.dart' as my_menu;

class ModeDetailsView extends StatelessWidget {
  const ModeDetailsView({super.key});

  GameModeConfig _resolveConfig(dynamic args) {
    if (args is GameModeConfig) return args;
    if (args is Map) {
      final modeVal = args['mode'] ?? args['id'];
      if (modeVal != null) {
        final modeStr = modeVal.toString().toLowerCase().replaceAll('_', '');
        return availableGameModes.firstWhere(
          (m) =>
              m.id.toLowerCase().replaceAll('_', '') == modeStr ||
              m.mode.name.toLowerCase() == modeStr,
          orElse: () => availableGameModes.first,
        );
      }
    }
    if (args is String) {
      final modeStr = args.toLowerCase().replaceAll('_', '');
      return availableGameModes.firstWhere(
        (m) =>
            m.id.toLowerCase().replaceAll('_', '') == modeStr ||
            m.mode.name.toLowerCase() == modeStr,
        orElse: () => availableGameModes.first,
      );
    }
    if (args is GameMode) {
      return availableGameModes.firstWhere(
        (m) => m.mode == args,
        orElse: () => availableGameModes.first,
      );
    }
    return availableGameModes.first;
  }

  @override
  Widget build(BuildContext context) {
    final GameModeConfig config = _resolveConfig(Get.arguments);
    final controller = Get.find<my_menu.MenuController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        backgroundColor: Colors.transparent,
        borderColor: config.accentColor.withValues(alpha: 0.35),
        accentColor: config.accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () => _showRules(config),
            tooltip: 'rules'.tr,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background Gradient Base
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    config.accentColor.withValues(alpha: 0.22),
                    const Color(0xFF0D1117),
                    const Color(0xFF06090E),
                  ],
                ),
              ),
            ),
          ),

          // 2. Mode Pattern Overlay on top of Header Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 330,
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                config.patternAsset,
                fit: BoxFit.cover,
                color: config.accentColor,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Mode Icon and Title with glowing circular halo
                  Hero(
                    tag: 'mode_icon_${config.id}',
                    child: Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: config.accentColor.withValues(alpha: 0.14),
                        border: Border.all(
                          color: config.accentColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: config.accentColor.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: config.iconAsset != null
                          ? Image.asset(
                              config.iconAsset!,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              config.icon,
                              size: 48,
                              color: config.accentColor,
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    config.titleTr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: config.accentColor.withValues(alpha: 0.6),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    config.subtitleTr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Giant PLAY Button
                  _PlayButton(
                    config: config,
                    onPressed: () => controller.launchMode(config),
                  ),
                  const SizedBox(height: 46),

                  // Mode Content: Level list for Level Mode, Leaderboard for Endless/Arcade Modes
                  Expanded(
                    child: config.mode == GameMode.level
                        ? _LevelModeSelectionList(config: config)
                        : _ModeLeaderboard(config: config),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRules(GameModeConfig config) {
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: config.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'rules'.tr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 24),
                Text(
                  config.rulesTr,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'got_it'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final GameModeConfig config;
  final VoidCallback onPressed;

  const _PlayButton({required this.config, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              config.accentColor,
              config.accentColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: config.accentColor.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
            const SizedBox(width: 8),
            Text(
              'play'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Level Selection Chapters & Grids for Level Mode
class _LevelModeSelectionList extends StatelessWidget {
  final GameModeConfig config;
  const _LevelModeSelectionList({required this.config});

  @override
  Widget build(BuildContext context) {
    final levelController = Get.find<LevelController>();
    final sound = Get.find<SoundService>();

    return Obx(() {
      final lastUnlocked = levelController.lastUnlockedLevel.value;
      final totalChapters = levelController.totalChapters;
      final totalLevels = levelController.totalLevels;
      final progressFraction = (lastUnlocked / totalLevels).clamp(0.0, 1.0);

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: totalChapters + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Overall Progress Summary Header
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF30363D)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: config.accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.emoji_events_rounded,
                                color: config.accentColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'select_level_sub'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: config.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: config.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$lastUnlocked / $totalLevels',
                          style: TextStyle(
                            color: config.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF21262D),
                      valueColor: AlwaysStoppedAnimation<Color>(config.accentColor),
                    ),
                  ),
                ],
              ),
            );
          }

          final chapterIndex = index; // 1 to 10
          final chapterTitleKey = levelController.getChapterTitleKey(chapterIndex);
          final isChapterUnlocked = levelController.isChapterUnlocked(chapterIndex);
          final unlockedCount = levelController.getChapterUnlockedCount(chapterIndex);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isChapterUnlocked
                  ? const Color(0xFF161B22).withValues(alpha: 0.7)
                  : const Color(0xFF0D1117).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isChapterUnlocked
                    ? config.accentColor.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chapter Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isChapterUnlocked
                              ? config.accentColor.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${'chapter'.tr} $chapterIndex',
                          style: TextStyle(
                            color: isChapterUnlocked ? config.accentColor : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          chapterTitleKey.tr,
                          style: TextStyle(
                            color: isChapterUnlocked ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$unlockedCount / 10',
                        style: TextStyle(
                          color: isChapterUnlocked ? Colors.white60 : Colors.white24,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                // 5x2 Levels Grid
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, levelOffset) {
                      final level = (chapterIndex - 1) * 10 + (levelOffset + 1);
                      final isUnlocked = level <= lastUnlocked;
                      final isCurrentLevel = level == lastUnlocked && level < 100;
                      final isCompleted = level < lastUnlocked;
                      final isBoss = level % 10 == 0;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isUnlocked
                              ? () {
                                  sound.playButtonTap();
                                  levelController.selectLevel(level);
                                  Get.toNamed('/game', arguments: level);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isCurrentLevel
                                  ? config.accentColor.withValues(alpha: 0.25)
                                  : isCompleted
                                      ? const Color(0xFF21262D)
                                      : isUnlocked
                                          ? const Color(0xFF161B22)
                                          : const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrentLevel
                                    ? config.accentColor
                                    : isCompleted
                                        ? config.accentColor.withValues(alpha: 0.5)
                                        : isUnlocked
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : Colors.white.withValues(alpha: 0.05),
                                width: isCurrentLevel ? 2.0 : 1.0,
                              ),
                              boxShadow: isCurrentLevel
                                  ? [
                                      BoxShadow(
                                        color: config.accentColor.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isUnlocked
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isBoss)
                                          const Icon(
                                            Icons.stars_rounded,
                                            color: Color(0xFFFFD700),
                                            size: 13,
                                          ),
                                        Text(
                                          '$level',
                                          style: TextStyle(
                                            color: isCurrentLevel
                                                ? config.accentColor
                                                : isCompleted
                                                    ? Colors.white
                                                    : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isCompleted)
                                          const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF00E676),
                                            size: 11,
                                          ),
                                      ],
                                    )
                                  : Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white.withValues(alpha: 0.2),
                                      size: 13,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _ModeLeaderboard extends StatefulWidget {
  final GameModeConfig config;
  const _ModeLeaderboard({required this.config});

  @override
  State<_ModeLeaderboard> createState() => _ModeLeaderboardState();
}

class _ModeLeaderboardState extends State<_ModeLeaderboard> {
  late final LeaderboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      LeaderboardController(initialMode: widget.config.id),
      tag: widget.config.id,
    );
  }

  @override
  void didUpdateWidget(covariant _ModeLeaderboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.id != widget.config.id) {
      controller.selectMode(widget.config.id);
    }
  }

  @override
  void dispose() {
    Get.delete<LeaderboardController>(tag: widget.config.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.modesEntries;
      final isLoading = controller.isLoadingModes.value;

      if (isLoading) {
        return const Center(
          child: AppLoadingWidget(size: 32),
        );
      }

      if (entries.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'no_records_yet'.tr,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return Column(
        children: [
          LeaderboardHeaderBar(
            accentColor: widget.config.accentColor,
            isTime: widget.config.id == 'infection',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              cacheExtent: 180,
              padding: const EdgeInsets.only(top: 2, bottom: 24),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return OnlineLeagueCard(
                  entry: entry,
                  accentColor: widget.config.accentColor,
                  modeId: widget.config.id,
                  onTap: entry.userId > 0
                      ? () => openPlayerProfileBottomSheet(context, entry.userId)
                      : null,
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
