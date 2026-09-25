import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';

/// Configuration model representing metadata, styling, and status of a game mode.
class GameModeConfig {
  final GameMode mode;
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? iconAsset;
  final String imageAsset;
  final String patternAsset;
  final Color accentColor;
  final bool isAvailable;
  final String? badgeText;

  const GameModeConfig({
    required this.mode,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconAsset,
    required this.imageAsset,
    required this.patternAsset,
    required this.accentColor,
    this.isAvailable = true,
    this.badgeText,
  });

  /// Factory constructor to create a dedicated [GameModeConfig] for boss levels (1 to 5).
  factory GameModeConfig.forBoss(int bossIndex) {
    final clampedIndex = bossIndex.clamp(1, 5);
    final Color accent;
    final IconData icon;

    switch (clampedIndex) {
      case 1:
        accent = const Color(0xFFFFB300); // Amber / Guardian Gold
        icon = Icons.security_rounded;
        break;
      case 2:
        accent = const Color(0xFF00E5FF); // Neon Cyan / Laser Core
        icon = Icons.flash_on_rounded;
        break;
      case 3:
        accent = const Color(0xFFFF9100); // Construction Orange / Architect
        icon = Icons.architecture_rounded;
        break;
      case 4:
        accent = const Color(0xFFFF3D00); // Lava Flame / Inferno Sentinel
        icon = Icons.local_fire_department_rounded;
        break;
      case 5:
      default:
        accent = const Color(0xFFD500F9); // Electric Purple / Overlord
        icon = Icons.military_tech_rounded;
        break;
    }

    return GameModeConfig(
      mode: GameMode.level,
      id: 'boss_$clampedIndex',
      title: 'boss_${clampedIndex}_name',
      subtitle: 'boss_${clampedIndex}_sub',
      icon: icon,
      imageAsset: 'assets/image/banner/banner_level.png',
      patternAsset: 'assets/image/pattern/Level_pattern.png',
      accentColor: accent,
      badgeText: 'BOSS',
    );
  }

  /// Alias for accentColor
  Color get color => accentColor;

  String get titleTr {
    if (id.startsWith('boss_')) {
      final bossIndex = int.tryParse(id.replaceFirst('boss_', '')) ?? 1;
      return '${'boss_level'.tr}: ${'boss_${bossIndex}_name'.tr}';
    }
    switch (mode) {
      case GameMode.classic:
        return 'classic_mode'.tr;
      case GameMode.level:
        return 'level_mode'.tr;
      case GameMode.infection:
        return 'infection_mode'.tr;
      case GameMode.blindMemory:
        return 'blind_memory_mode'.tr;
      case GameMode.laser:
        return 'laser_mode'.tr;
      case GameMode.meltdown:
        return 'meltdown_mode'.tr;
      case GameMode.crabChase:
        return 'crab_chase_mode'.tr;
      case GameMode.casual:
        return 'casual_mode'.tr;
      default:
        return title;
    }
  }

  String get subtitleTr {
    if (id.startsWith('boss_')) {
      final bossIndex = int.tryParse(id.replaceFirst('boss_', '')) ?? 1;
      return 'boss_${bossIndex}_sub'.tr;
    }
    switch (mode) {
      case GameMode.classic:
        return 'classic_subtitle'.tr;
      case GameMode.level:
        return 'level_subtitle'.tr;
      case GameMode.infection:
        return 'infection_subtitle'.tr;
      case GameMode.blindMemory:
        return 'blind_memory_subtitle'.tr;
      case GameMode.laser:
        return 'laser_subtitle'.tr;
      case GameMode.meltdown:
        return 'meltdown_subtitle'.tr;
      case GameMode.crabChase:
        return 'crab_chase_subtitle'.tr;
      case GameMode.casual:
        return 'casual_subtitle'.tr;
      default:
        return subtitle;
    }
  }

  String get rulesTr {
    if (id.startsWith('boss_')) {
      final bossIndex = int.tryParse(id.replaceFirst('boss_', '')) ?? 1;
      final objText = 'boss_${bossIndex}_obj'.tr;
      final warnText = 'boss_${bossIndex}_warn'.tr;
      return '🎯 ${'objective'.tr}:\n$objText\n\n⚠️ ${'warning'.tr}:\n$warnText';
    }
    switch (mode) {
      case GameMode.classic:
        return 'classic_rules'.tr;
      case GameMode.level:
        return 'level_rules'.tr;
      case GameMode.infection:
        return 'infection_rules'.tr;
      case GameMode.blindMemory:
        return 'blind_memory_rules'.tr;
      case GameMode.laser:
        return 'laser_rules'.tr;
      case GameMode.meltdown:
        return 'meltdown_rules'.tr;
      case GameMode.crabChase:
        return 'crab_chase_rules'.tr;
      case GameMode.casual:
        return 'casual_rules'.tr;
      default:
        return 'No rules defined yet.'.tr;
    }
  }

  /// Get pattern asset path for a specific mode string ID
  static String getPatternForMode(String modeId) {
    switch (modeId.toLowerCase().replaceAll('_', '')) {
      case 'classic':
        return 'assets/image/pattern/Classic_pattern.png';
      case 'level':
        return 'assets/image/pattern/Level_pattern.png';
      case 'infection':
        return 'assets/image/pattern/Infection_pattern.png';
      case 'blindmemory':
        return 'assets/image/pattern/BlindMemory_pattern.png';
      case 'laser':
      case 'lasercore':
        return 'assets/image/pattern/Laser_pattern.png';
      case 'meltdown':
        return 'assets/image/pattern/Meltdown_pattern.png';
      case 'crab':
      case 'crabchase':
        return 'assets/image/pattern/crab_pattern.png';
      case 'casual':
      case 'adventure':
        return 'assets/image/pattern/Adventure_pattern.png';
      default:
        return 'assets/image/pattern/Classic_pattern.png';
    }
  }

  /// Get icon asset path for a specific mode string ID
  static String getIconAssetForMode(String modeId) {
    switch (modeId.toLowerCase().replaceAll('_', '')) {
      case 'classic':
        return 'assets/image/ModeIcon/Classic.png';
      case 'level':
        return 'assets/image/ModeIcon/LevelMode.png';
      case 'infection':
        return 'assets/image/ModeIcon/Infection.png';
      case 'blindmemory':
        return 'assets/image/ModeIcon/BlindMemory.png';
      case 'laser':
      case 'lasercore':
        return 'assets/image/ModeIcon/LaserCore.png';
      case 'meltdown':
        return 'assets/image/ModeIcon/Meltdown.png';
      case 'crab':
      case 'crabchase':
        return 'assets/image/ModeIcon/CrabChase.png';
      case 'casual':
      case 'adventure':
        return 'assets/image/ModeIcon/Adventure.png';
      default:
        return 'assets/image/ModeIcon/Classic.png';
    }
  }

  /// Get accent color for a specific mode string ID
  static Color getColorForMode(String modeId) {
    switch (modeId.toLowerCase().replaceAll('_', '')) {
      case 'classic':
        return kPrimaryColor;
      case 'level':
        return kGoldColor;
      case 'infection':
        return const Color(0xFFFF1744);
      case 'blindmemory':
        return const Color(0xFF00E5FF);
      case 'laser':
      case 'lasercore':
        return const Color(0xFFFF9100);
      case 'meltdown':
        return const Color(0xFFC6FF00);
      case 'crab':
      case 'crabchase':
        return const Color(0xFFFF5722);
      case 'casual':
        return const Color(0xFFA855F7); // Vibrant Fantasy Purple
      default:
        return kPrimaryColor;
    }
  }

  /// Find GameModeConfig by any mode string (e.g. 'laser_core', 'laser', 'blind_memory', 'blindMemory')
  static GameModeConfig? findByModeString(String modeStr) {
    final norm = modeStr.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    for (final cfg in availableGameModes) {
      final cfgNorm =
          cfg.id.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
      final modeNorm = cfg.mode.name.toLowerCase();
      if (cfgNorm == norm || modeNorm == norm) return cfg;
      if ((norm == 'lasercore' || norm == 'laser') &&
          (cfgNorm == 'laser' || cfgNorm == 'lasercore')) {
        return cfg;
      }
      if ((norm == 'blindmemory' || norm == 'blind' || norm == 'memory') &&
          (cfgNorm == 'blindmemory')) {
        return cfg;
      }
      if ((norm == 'crabchase' || norm == 'crab') &&
          (cfgNorm == 'crabchase' || cfgNorm == 'crab')) {
        return cfg;
      }
      if ((norm == 'casual' || norm == 'adventure') &&
          (cfgNorm == 'casual' || cfgNorm == 'adventure')) {
        return cfg;
      }
    }
    return null;
  }
}

/// Extensible central registry of available game modes.
final List<GameModeConfig> availableGameModes = [
  const GameModeConfig(
    mode: GameMode.casual,
    id: 'casual',
    title: 'SNAKE ADVENTURE',
    subtitle: 'Explore the magical garden with fun power-ups! ✨',
    icon: Icons.explore_rounded,
    iconAsset: 'assets/image/ModeIcon/Adventure.png',
    imageAsset: 'assets/image/ModeCard/SnakeAdventure.jpg',
    patternAsset: 'assets/image/pattern/Adventure_pattern.png',
    accentColor: Color(0xFFA855F7),
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.level,
    id: 'level',
    title: 'LEVEL MODE',
    subtitle: '50 challenging levels; prove your skill through the obstacles.',
    icon: Icons.emoji_events_rounded,
    iconAsset: 'assets/image/ModeIcon/LevelMode.png',
    imageAsset: 'assets/image/ModeCard/LevelMode.jpg',
    patternAsset: 'assets/image/pattern/Level_pattern.png',
    accentColor: kGoldColor,
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.classic,
    id: 'classic',
    title: 'CLASSIC MODE',
    subtitle: 'Beat the global leaderboard.',
    icon: Icons.bolt_rounded,
    iconAsset: 'assets/image/ModeIcon/Classic.png',
    imageAsset: 'assets/image/ModeCard/ClassicMode.jpg',
    patternAsset: 'assets/image/pattern/Classic_pattern.png',
    accentColor: kPrimaryColor,
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.laser,
    id: 'laser',
    title: '⚡ LASER CORE',
    subtitle: 'Dodge deadly beams... don\'t get sliced!',
    icon: Icons.flash_on_rounded,
    iconAsset: 'assets/image/ModeIcon/LaserCore.png',
    imageAsset: 'assets/image/ModeCard/LaserCore.jpg',
    patternAsset: 'assets/image/pattern/Laser_pattern.png',
    accentColor: Color(0xFFFF9100),
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.infection,
    id: 'infection',
    title: '🧬 INFECTION',
    subtitle: 'The parasite consumes... You can\'t cure it, only delay it.',
    icon: Icons.coronavirus_rounded,
    iconAsset: 'assets/image/ModeIcon/Infection.png',
    imageAsset: 'assets/image/ModeCard/Infection.jpg',
    patternAsset: 'assets/image/pattern/Infection_pattern.png',
    accentColor: Color(0xFFFF1744),
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.blindMemory,
    id: 'blindMemory',
    title: '🧠 BLIND MEMORY',
    subtitle: 'Memory hides the body... remember your moves.',
    icon: Icons.psychology_rounded,
    iconAsset: 'assets/image/ModeIcon/BlindMemory.png',
    imageAsset: 'assets/image/ModeCard/BlindMemory.jpg',
    patternAsset: 'assets/image/pattern/BlindMemory_pattern.png',
    accentColor: Color(0xFF00E5FF),
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.meltdown,
    id: 'meltdown',
    title: '☢ MELTDOWN',
    subtitle: 'Nuclear pressure is rising.',
    icon: Icons.warning_amber_rounded,
    iconAsset: 'assets/image/ModeIcon/Meltdown.png',
    imageAsset: 'assets/image/ModeCard/Meltdown.jpg',
    patternAsset: 'assets/image/pattern/Meltdown_pattern.png',
    accentColor: Color(0xFFC6FF00), // Neon Yellow-Green
    isAvailable: true,
  ),
  const GameModeConfig(
    mode: GameMode.crabChase,
    id: 'crabChase',
    title: '🦀 CRAB CHASE',
    subtitle: 'Survive the relentless hunter.',
    icon: Icons.pest_control_rounded,
    iconAsset: 'assets/image/ModeIcon/CrabChase.png',
    imageAsset: 'assets/image/ModeCard/CrabChase.jpg',
    patternAsset: 'assets/image/pattern/crab_pattern.png',
    accentColor: Color(0xFFFF5722), // Deep Orange
    isAvailable: true,
  ),
];
