import 'package:flutter/material.dart';
import '../../cosmetics/models/cosmetics_models.dart';

/// Configuration model representing a Snake Skin (Colors & Gradient styling).
class SnakeSkin {
  final String id;
  final String name;
  final Color headColor;
  final Color tailColor;
  final Color glowColor;
  final List<Color>? gradientColors; // For multi-color gradient skins

  const SnakeSkin({
    required this.id,
    required this.name,
    required this.headColor,
    required this.tailColor,
    required this.glowColor,
    this.gradientColors,
  });

  /// Factory constructor to map directly from server-driven [CosmeticSnakeSkin].
  factory SnakeSkin.fromCosmetic(CosmeticSnakeSkin cosmetic) {
    return SnakeSkin(
      id: cosmetic.skinKey,
      name: cosmetic.nameEn.isNotEmpty ? cosmetic.nameEn : cosmetic.skinKey,
      headColor: cosmetic.headColor,
      tailColor: cosmetic.tailColor,
      glowColor: cosmetic.glowColor,
      gradientColors: cosmetic.gradientColors,
    );
  }

  /// Factory constructor to build directly from color values/hex strings.
  factory SnakeSkin.fromColors({
    required String id,
    required String name,
    required dynamic headHex,
    required dynamic tailHex,
    required dynamic glowHex,
    List<dynamic>? gradientHexes,
  }) {
    return SnakeSkin(
      id: id,
      name: name,
      headColor: parseHexColor(headHex, fallback: const Color(0xFF69F0AE)),
      tailColor: parseHexColor(tailHex, fallback: const Color(0xFF004D40)),
      glowColor: parseHexColor(glowHex, fallback: const Color(0xFF00E676)),
      gradientColors: gradientHexes?.map((c) => parseHexColor(c)).toList(),
    );
  }

  /// Primary color for UI previews.
  Color get primaryColor => gradientColors?.first ?? headColor;

  /// Whether this skin uses a multi-color gradient.
  bool get isGradient => gradientColors != null && gradientColors!.isNotEmpty;

  /// Calculate exact segment color at progress [t] (0.0 = head, 1.0 = tail).
  Color getColorAt(double t) {
    if (isGradient) {
      final list = gradientColors!;
      if (list.length == 1) return list.first;
      final scaledT = t * (list.length - 1);
      final index = scaledT.floor().clamp(0, list.length - 2);
      final remainder = scaledT - index;
      return Color.lerp(list[index], list[index + 1], remainder)!;
    }
    return Color.lerp(headColor, tailColor, t)!;
  }
}

/// Central registry of presets for Snake Skins (Solid & Gradient themes).
class SnakeSkins {
  static const SnakeSkin neonGreen = SnakeSkin(
    id: 'neon_green',
    name: 'Emerald Neon',
    headColor: Color(0xFF69F0AE),
    tailColor: Color(0xFF004D40),
    glowColor: Color(0xFF00E676),
  );

  static const SnakeSkin cyberBlue = SnakeSkin(
    id: 'cyber_blue',
    name: 'Cyber Cyan',
    headColor: Color(0xFF40C4FF),
    tailColor: Color(0xFF01579B),
    glowColor: Color(0xFF00B0FF),
  );

  static const SnakeSkin goldenFire = SnakeSkin(
    id: 'golden_fire',
    name: 'Golden Fire',
    headColor: Color(0xFFFFD54F),
    tailColor: Color(0xFFE65100),
    glowColor: Color(0xFFFFB300),
  );

  static const SnakeSkin purpleGlow = SnakeSkin(
    id: 'purple_glow',
    name: 'Neon Violet',
    headColor: Color(0xFFE040FB),
    tailColor: Color(0xFF4A148C),
    glowColor: Color(0xFFD500F9),
  );

  static const SnakeSkin rubyRed = SnakeSkin(
    id: 'ruby_red',
    name: 'Ruby Crimson',
    headColor: Color(0xFFFF5252),
    tailColor: Color(0xFF880E4F),
    glowColor: Color(0xFFFF1744),
  );

  // --- Gradient Skins (Multi-color Gradients) ---
  static const SnakeSkin rainbowGradient = SnakeSkin(
    id: 'rainbow',
    name: 'Rainbow Aura',
    headColor: Color(0xFFFF5252),
    tailColor: Color(0xFF7C4DFF),
    glowColor: Color(0xFFFF4081),
    gradientColors: [
      Color(0xFFFF5252),
      Color(0xFFFFD54F),
      Color(0xFF69F0AE),
      Color(0xFF40C4FF),
      Color(0xFFE040FB),
    ],
  );

  static const SnakeSkin sunsetGradient = SnakeSkin(
    id: 'sunset',
    name: 'Sunset Gradient',
    headColor: Color(0xFFFF6E40),
    tailColor: Color(0xFF651FFF),
    glowColor: Color(0xFFFF4081),
    gradientColors: [
      Color(0xFFFFD700),
      Color(0xFFFF5252),
      Color(0xFFE040FB),
      Color(0xFF651FFF),
    ],
  );

  static final List<SnakeSkin> allSkins = [
    neonGreen,
    cyberBlue,
    goldenFire,
    purpleGlow,
    rubyRed,
    rainbowGradient,
    sunsetGradient,
  ];

  static SnakeSkin getById(String id) {
    return allSkins.firstWhere(
      (s) => s.id == id,
      orElse: () => neonGreen,
    );
  }
}
