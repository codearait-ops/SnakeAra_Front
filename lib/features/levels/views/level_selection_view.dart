import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../../services/sound_service.dart';
import '../controllers/level_controller.dart';

/// Chapter-based level selection screen organizing 100 levels into
/// 10 themed chapters with progress indicators and 5x2 level grids.
class LevelSelectionView extends StatelessWidget {
  const LevelSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final levelController = Get.find<LevelController>();
    final sound = Get.find<SoundService>();

    return Scaffold(
      appBar: FloatingAppBar(
        titleText: 'level_select'.tr,
        accentColor: kGoldColor,
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
          final lastUnlocked = levelController.lastUnlockedLevel.value;
          final totalChapters = levelController.totalChapters;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Overall Progress Summary Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _ProgressSummaryHeader(
                    unlockedLevels: lastUnlocked.clamp(1, 100),
                    totalLevels: levelController.totalLevels,
                  ),
                ),
              ),

              // Chapters List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chapterIndex = index + 1; // 1 to 10
                    final chapterTitleKey = levelController.getChapterTitleKey(chapterIndex);
                    final isChapterUnlocked = levelController.isChapterUnlocked(chapterIndex);
                    final unlockedCount = levelController.getChapterUnlockedCount(chapterIndex);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chapter Header Card
                        _ChapterHeader(
                          chapterNumber: chapterIndex,
                          title: chapterTitleKey.tr,
                          unlockedCount: unlockedCount,
                          totalCount: 10,
                          isUnlocked: isChapterUnlocked,
                        ),

                        // Chapter Grid (5 columns x 2 rows)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: 10,
                            itemBuilder: (context, levelOffset) {
                              final level = (chapterIndex - 1) * 10 + (levelOffset + 1);
                              final isUnlocked = level <= lastUnlocked;
                              final isCurrentLevel = level == lastUnlocked && level < 100;
                              final isCompleted = levelController.isLevelCompleted(level);

                              return _LevelCell(
                                level: level,
                                isUnlocked: isUnlocked,
                                isCompleted: isCompleted,
                                isCurrentLevel: isCurrentLevel,
                                onTap: isUnlocked
                                    ? () {
                                        sound.playButtonTap();
                                        levelController.selectLevel(level);
                                        Get.toNamed('/game', arguments: level);
                                      }
                                    : null,
                              );
                            },
                          ),
                        ),

                        // Styled Chapter Divider between chapters
                        if (chapterIndex < totalChapters) ...[
                          const SizedBox(height: 12),
                          const _ChapterDivider(),
                          const SizedBox(height: 12),
                        ] else ...[
                          const SizedBox(height: 24),
                        ],
                      ],
                    );
                  },
                  childCount: totalChapters,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Overall progress banner at the top of the level select view.
class _ProgressSummaryHeader extends StatelessWidget {
  final int unlockedLevels;
  final int totalLevels;

  const _ProgressSummaryHeader({
    required this.unlockedLevels,
    required this.totalLevels,
  });

  @override
  Widget build(BuildContext context) {
    final progressFraction = unlockedLevels / totalLevels;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                        color: kPrimaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: kPrimaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'select_level_sub'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$unlockedLevels / $totalLevels',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontSize: 13,
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
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chapter header with title, chapter badge, and completion count.
class _ChapterHeader extends StatelessWidget {
  final int chapterNumber;
  final String title;
  final int unlockedCount;
  final int totalCount;
  final bool isUnlocked;

  const _ChapterHeader({
    required this.chapterNumber,
    required this.title,
    required this.unlockedCount,
    required this.totalCount,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF161B22) : const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF30363D) : const Color(0xFF21262D),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Chapter badge tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
                        )
                      : null,
                  color: isUnlocked ? null : const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${'chapter'.tr} $chapterNumber',
                  style: TextStyle(
                    color: isUnlocked ? Colors.black : Colors.white38,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Chapter title
              Text(
                title,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Chapter completion badge
          Row(
            children: [
              Icon(
                isUnlocked
                    ? (unlockedCount == totalCount
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_fill_rounded)
                    : Icons.lock_rounded,
                size: 16,
                color: isUnlocked
                    ? (unlockedCount == totalCount ? const Color(0xFF4CAF50) : kPrimaryColor)
                    : Colors.white24,
              ),
              const SizedBox(width: 6),
              Text(
                '$unlockedCount/$totalCount',
                style: TextStyle(
                  color: isUnlocked ? Colors.white70 : Colors.white24,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decorative horizontal line separator between chapters (══════════════).
class _ChapterDivider extends StatelessWidget {
  const _ChapterDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF30363D)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '❖',
                  style: TextStyle(color: kPrimaryColor, fontSize: 10),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF30363D), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single level cell in the chapter grid.
class _LevelCell extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrentLevel;
  final VoidCallback? onTap;

  const _LevelCell({
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrentLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBoss = level % 10 == 0;
    final bossColor = level == 50 ? const Color(0xFFFF1744) : kGoldColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isCurrentLevel
                  ? (isBoss ? bossColor.withValues(alpha: 0.2) : kPrimaryColor.withValues(alpha: 0.15))
                  : (isBoss ? bossColor.withValues(alpha: 0.08) : const Color(0xFF161B22)))
              : const Color(0xFF0A0E14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? (isCurrentLevel
                    ? (isBoss ? bossColor : kPrimaryColor)
                    : (isBoss
                        ? bossColor.withValues(alpha: 0.6)
                        : (isCompleted ? const Color(0xFF30363D) : const Color(0xFF21262D))))
                : (isBoss ? bossColor.withValues(alpha: 0.2) : const Color(0xFF161B22)),
            width: isCurrentLevel ? 2.5 : (isBoss ? 1.5 : 1),
          ),
          boxShadow: isUnlocked && (isCurrentLevel || isBoss)
              ? [
                  BoxShadow(
                    color: (isBoss ? bossColor : kPrimaryColor).withValues(alpha: isCurrentLevel ? 0.35 : 0.15),
                    blurRadius: isCurrentLevel ? 12 : 6,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBoss) ...[
              const Text('👑', style: TextStyle(fontSize: 10)),
              const SizedBox(height: 1),
            ],
            Text(
              '$level',
              style: TextStyle(
                color: isUnlocked
                    ? (isBoss ? bossColor : (isCurrentLevel ? kPrimaryColor : Colors.white))
                    : (isBoss ? bossColor.withValues(alpha: 0.4) : Colors.white24),
                fontSize: isBoss ? 16 : 18,
                fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            if (isCompleted)
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 13,
              )
            else if (isCurrentLevel)
              Icon(
                Icons.play_arrow_rounded,
                color: isBoss ? bossColor : kPrimaryColor,
                size: 14,
              )
            else
              Icon(
                Icons.lock_outlined,
                color: isUnlocked
                    ? (isBoss ? bossColor.withValues(alpha: 0.5) : kPrimaryColor.withValues(alpha: 0.4))
                    : Colors.white12,
                size: 13,
              ),
          ],
        ),
      ),
    );
  }
}
