import 'package:flutter/material.dart';

/// Grid dimensions
const int kGridSize = 20; // 20x20 cells
const int kAppleTarget = 10; // Apples needed to complete a level

/// App colors
const Color kPrimaryColor = Color(0xFF00E676);
const Color kSecondaryColor = Color(0xFF2979FF);
const Color kSnakeHeadColor = Color(0xFF00E676);
const Color kFoodColor = Color(0xFFFF1744);
const Color kFoodGlowColor = Color(0xFFFF5252);
const Color kBackgroundColor = Color(0xFF0D1117);
const Color kGridLineColor = Color(0xFF1A1F2E);
const Color kNeonGlowColor = Color(0xFF00E676);
const Color kGameOverRed = Color(0xFFFF1744);
const Color kGoldColor = Color(0xFFFFD700);
const Color kObstacleColor = Color(0xFF30363D);
const Color kObstacleBorderColor = Color(0xFF484F58);

/// API Configuration
const String kBaseUrl =
    'https://snake.codeara.net/api'; // Server backend API URL
const String kSecurityTokenPrefix = 'CodearaSecret';

/// SharedPreferences keys
const String kLevelProgressKey = 'level_progress'; // stores last unlocked level
const String kUserTokenKey = 'user_token';
const String kUsernameKey = 'saved_username';
const String kSecurityTokenMidfix = 'AntiCheatKey';
const String kAvatarIdKey = 'saved_avatar_id';
const String kUserIdKey = 'saved_user_id';

/// Default unified avatar palette (clean white with complementary slate accent)
const Color kAvatarPrimaryColor = Color(0xFF0F5A47);
const Color kAvatarSecondaryColor = Color(0xFF1E8267);
const Color kAvatarComplementaryColor = kAvatarSecondaryColor;
const String kSecurityTokenSuffix = '2026@Safe';

/// Preset Avatar descriptor and metadata
class PresetAvatar {
  static const Color defaultPrimary = kAvatarPrimaryColor;
  static const Color defaultSecondary = kAvatarSecondaryColor;

  final String id;
  final String name;
  final String title;
  final IconData icon;
  final String? imageUrl;

  const PresetAvatar({
    required this.id,
    required this.name,
    required this.title,
    required this.icon,
    this.imageUrl,
  });

  /// Unified avatar primary color (White)
  Color get primaryColor => defaultPrimary;

  /// Unified avatar complementary color (Slate)
  Color get secondaryColor => defaultSecondary;
}

const List<PresetAvatar> kPresetAvatars = [
  PresetAvatar(
    id: 'avatar_1',
    name: 'Cyber Runner',
    title: 'Neon Operative',
    icon: Icons.face_5_rounded,
  ),
  PresetAvatar(
    id: 'avatar_2',
    name: 'Viper Agent',
    title: 'Tactical Recon',
    icon: Icons.person_4_rounded,
  ),
  PresetAvatar(
    id: 'avatar_3',
    name: 'Golden Champion',
    title: 'League Veteran',
    icon: Icons.workspace_premium_rounded,
  ),
  PresetAvatar(
    id: 'avatar_4',
    name: 'Shadow Assassin',
    title: 'Stealth Infiltrator',
    icon: Icons.security_rounded,
  ),
  PresetAvatar(
    id: 'avatar_5',
    name: 'Neon Titan',
    title: 'Cyber General',
    icon: Icons.face_6_rounded,
  ),
  PresetAvatar(
    id: 'avatar_6',
    name: 'Cosmic Hydra',
    title: 'Void Strategist',
    icon: Icons.psychology_rounded,
  ),
  PresetAvatar(
    id: 'avatar_7',
    name: 'Custom Photo',
    title: 'Upload Avatar',
    icon: Icons.add_rounded,
  ),
];

/// Helper to find avatar by ID (supports legacy avatar names)
PresetAvatar getAvatarById(String? id) {
  if (id == 'avatar_cobra') return kPresetAvatars[0];
  if (id == 'avatar_viper') return kPresetAvatars[1];
  if (id == 'avatar_python') return kPresetAvatars[2];
  if (id == 'avatar_mamba') return kPresetAvatars[3];
  if (id == 'avatar_anaconda') return kPresetAvatars[4];
  if (id == 'avatar_hydra') return kPresetAvatars[5];

  return kPresetAvatars.firstWhere(
    (a) => a.id == id,
    orElse: () => kPresetAvatars.first,
  );
}

/// Position helper for grid coordinates
class GridPos {
  final int x;
  final int y;

  const GridPos(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}

/// Cumulative XP required to reach [level] according to the backend XP progression table.
/// Level 1: 0
/// Level 2: 300
/// Level 3: 700
/// Level 4: 1200
/// Level 5: 1800
/// Level 6: 2500
/// Level 7: 3300
/// Level 8: 4200
/// Level 9: 5200
int getBaseXpForLevel(int level) {
  if (level <= 1) return 0;
  final n = level - 1;
  return 200 * n + 50 * n * (n + 1);
}

/// Structured progress information within the current level.
class LevelProgressInfo {
  final int currentLevelXp; // XP earned within current level (e.g. 9)
  final int levelSpan; // Total XP span of current level (e.g. 1000)
  final double progress; // Normalized progress 0.0 to 1.0 (e.g. 0.009)

  const LevelProgressInfo({
    required this.currentLevelXp,
    required this.levelSpan,
    required this.progress,
  });
}

/// Calculates progress specifically within the current level so progress starts at 0% upon level up.
LevelProgressInfo calculateLevelProgress({
  required int xp,
  required int level,
  int? nextLevelXp,
}) {
  final baseXp = getBaseXpForLevel(level);
  final targetXp = (nextLevelXp != null && nextLevelXp > baseXp)
      ? nextLevelXp
      : getBaseXpForLevel(level + 1);
  final span = (targetXp - baseXp > 0) ? (targetXp - baseXp) : 1000;
  final currentLevelXp = (xp - baseXp).clamp(0, span);
  final progress = (currentLevelXp / span).clamp(0.0, 1.0);

  return LevelProgressInfo(
    currentLevelXp: currentLevelXp,
    levelSpan: span,
    progress: progress,
  );
}
