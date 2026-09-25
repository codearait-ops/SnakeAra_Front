import 'package:flutter/material.dart';
import '../../../app/core/utils/enums.dart';
import '../../cosmetics/models/cosmetics_models.dart';

/// Style variants for ground/board themes.
enum BoardStyle { checkerboard, gradient, dotMatrix, neonGrid, textured }

/// Configuration model representing a Ground / Board Skin (Grid colors, gradients & styling).
class BoardSkin {
  final String id;
  final String name;
  final BoardStyle style;
  final Color lightTileColor;
  final Color darkTileColor;
  final Color fillColor;
  final Color borderColor;
  final Color accentColor;
  final List<Color>? gradientColors;
  final bool isRadialGradient;
  final Color? gridLineColor;
  final String? cachedImagePath;
  final String? remoteImageUrl;
  final Rect? gridSourceRect;
  final bool showCheckerOverlay;
  final bool isAvailable;

  const BoardSkin({
    required this.id,
    required this.name,
    this.style = BoardStyle.textured,
    required this.lightTileColor,
    required this.darkTileColor,
    required this.fillColor,
    required this.borderColor,
    required this.accentColor,
    this.gradientColors,
    this.isRadialGradient = false,
    this.gridLineColor,
    this.cachedImagePath,
    this.remoteImageUrl,
    this.gridSourceRect,
    this.showCheckerOverlay = true,
    this.isAvailable = true,
  });

  bool get isGradient =>
      style == BoardStyle.gradient &&
      gradientColors != null &&
      gradientColors!.isNotEmpty;

  bool get isTextured =>
      style == BoardStyle.textured &&
      ((cachedImagePath != null && cachedImagePath!.isNotEmpty) ||
          (remoteImageUrl != null && remoteImageUrl!.isNotEmpty));
}

/// Helper & resolver for dynamic Board Skins (Themes) across game modes.
class BoardSkins {
  /// Maps a GameMode to its standard cosmetic mode key
  static String getModeKey(GameMode mode) {
    switch (mode) {
      case GameMode.casual:
        return 'adventure';
      case GameMode.classic:
        return 'classic';
      case GameMode.crabChase:
        return 'crab';
      case GameMode.infection:
        return 'infection';
      case GameMode.laser:
        return 'laser';
      case GameMode.level:
        return 'level';
      case GameMode.meltdown:
        return 'meltdown';
      case GameMode.blindMemory:
        return 'memory';
      case GameMode.custom:
        return 'classic';
    }
  }

  /// Resolves the dynamic accent color based on theme key
  static Color getAccentColor(String themeKey) {
    switch (themeKey.toLowerCase()) {
      case 'space':
        return const Color(0xFFC77DFF);
      case 'sea':
        return const Color(0xFF00B0FF);
      case 'ancient':
        return const Color(0xFFFFB300);
      case 'forest':
        return const Color(0xFF00E676);
      default:
        return const Color(0xFF00E676);
    }
  }

  /// Dynamically constructs a BoardSkin configuration for a given Theme and GameMode.
  /// Purely data-driven; no bundled assets are referenced.
  static BoardSkin getSkinForThemeAndMode({
    required String themeKey,
    required GameMode mode,
    CosmeticTheme? cosmeticTheme,
    String? cachedImagePath,
  }) {
    final modeKey = getModeKey(mode);
    final accent = getAccentColor(themeKey);
    final remoteUrl = cosmeticTheme?.getModeUrl(modeKey);

    return BoardSkin(
      id: themeKey,
      name: cosmeticTheme?.nameFa.isNotEmpty == true
          ? cosmeticTheme!.nameFa
          : 'theme_$themeKey',
      style: BoardStyle.textured,
      cachedImagePath: cachedImagePath,
      remoteImageUrl: remoteUrl,
      lightTileColor: const Color(0x14FFFFFF),
      darkTileColor: const Color(0x04FFFFFF),
      fillColor: Colors.transparent,
      borderColor: const Color(0x35FFFFFF),
      accentColor: accent,
      gridLineColor: const Color(0x1EFFFFFF),
      showCheckerOverlay: true,
      isAvailable: true,
    );
  }

  /// Returns default dynamic board skin for standard game modes.
  static BoardSkin getSkinForMode(GameMode mode) {
    return getSkinForThemeAndMode(
      themeKey: 'space',
      mode: mode,
    );
  }
}
