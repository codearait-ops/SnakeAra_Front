import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';

/// Centralized configuration constants for Casual Mode.
class CasualModeConfig {
  /// Duration in seconds for all power-ups.
  static const double powerUpDuration = 8.0;

  /// Minimum delay in seconds before spawning next power-up.
  static const double powerUpSpawnMinDelay = 5.0;

  /// Maximum delay in seconds before spawning next power-up.
  static const double powerUpSpawnMaxDelay = 8.0;

  /// Cooldown in seconds between completed mission and next mission spawn.
  static const double missionCooldown = 20.0;

  /// Reward in coins for completing any casual mission.
  static const int missionRewardCoins = 10;

  /// Minimum snake length in segments (snake cannot be cut below this).
  static const int minSnakeLength = 3;

  /// Speed multiplier when Turbo power-up is active (faster).
  static const double turboSpeedMultiplier = 1.65;

  /// Slide inertia steps for Ice power-up.
  static const int iceSlideSteps = 2;

  /// Grid attraction radius in cells for Magnet power-up.
  static const double magnetRadius = 3.5;

  /// Duration in seconds for Apple Rain event.
  static const double appleRainDuration = 8.0;

  /// Maximum simultaneous rain apples placed during Apple Rain.
  static const int appleRainMaxApples = 5;

  /// Candidate target values for generated missions based on difficulty (max 5 apples).
  static const List<int> appleTargetPool = [2, 3, 4, 5];
}

/// The 5 distinct power-up types in Casual Mode.
enum PowerUpType {
  magnet,
  turbo,
  ice,
  appleRain,
  ghost;

  String get displayNameTr {
    switch (this) {
      case PowerUpType.magnet:
        return 'powerup_magnet'.tr;
      case PowerUpType.turbo:
        return 'powerup_turbo'.tr;
      case PowerUpType.ice:
        return 'powerup_ice'.tr;
      case PowerUpType.appleRain:
        return 'powerup_apple_rain'.tr;
      case PowerUpType.ghost:
        return 'powerup_ghost'.tr;
    }
  }

  String get emoji {
    switch (this) {
      case PowerUpType.magnet:
        return '🧲';
      case PowerUpType.turbo:
        return '⚡';
      case PowerUpType.ice:
        return '🧊';
      case PowerUpType.appleRain:
        return '🌧️';
      case PowerUpType.ghost:
        return '👻';
    }
  }

  Color get color {
    switch (this) {
      case PowerUpType.magnet:
        return const Color(0xFFFF4081); // Vibrant Pink / Magenta
      case PowerUpType.turbo:
        return const Color(0xFFFFD600); // Electric Yellow
      case PowerUpType.ice:
        return const Color(0xFF00E5FF); // Neon Cyan / Ice Blue
      case PowerUpType.appleRain:
        return const Color(0xFFFF5722); // Vibrant Orange-Red
      case PowerUpType.ghost:
        return const Color(0xFFB388FF); // Ethereal Purple / Lavender
    }
  }
}

/// Active power-up item placed on the grid.
class PowerUpItem {
  final GridPos position;
  final PowerUpType type;
  double animationTimer = 0.0;

  PowerUpItem({
    required this.position,
    required this.type,
  });
}

/// Families of casual missions.
enum CasualMissionType {
  eatApples,
  eatWithMagnet,
  eatWithTurbo,
  eatWithIce,
  eatDuringAppleRain,
  eatWithGhost;

  PowerUpType? get requiredPowerUp {
    switch (this) {
      case CasualMissionType.eatApples:
        return null;
      case CasualMissionType.eatWithMagnet:
        return PowerUpType.magnet;
      case CasualMissionType.eatWithTurbo:
        return PowerUpType.turbo;
      case CasualMissionType.eatWithIce:
        return PowerUpType.ice;
      case CasualMissionType.eatDuringAppleRain:
        return PowerUpType.appleRain;
      case CasualMissionType.eatWithGhost:
        return PowerUpType.ghost;
    }
  }

  String get iconEmoji {
    switch (this) {
      case CasualMissionType.eatApples:
        return '🍎';
      case CasualMissionType.eatWithMagnet:
        return '🧲';
      case CasualMissionType.eatWithTurbo:
        return '⚡';
      case CasualMissionType.eatWithIce:
        return '🧊';
      case CasualMissionType.eatDuringAppleRain:
        return '🌧️';
      case CasualMissionType.eatWithGhost:
        return '👻';
    }
  }
}

/// Data model representing an active or completed casual mission.
class CasualMission {
  final String id;
  final CasualMissionType type;
  final int target;
  int currentProgress;
  final int rewardCoins;
  bool isCompleted;

  CasualMission({
    required this.id,
    required this.type,
    required this.target,
    this.currentProgress = 0,
    this.rewardCoins = CasualModeConfig.missionRewardCoins,
    this.isCompleted = false,
  });

  /// Progress ratio from 0.0 to 1.0.
  double get progressRatio =>
      target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 0.0;

  /// Localized description of the mission objective.
  String get descriptionTr {
    switch (type) {
      case CasualMissionType.eatApples:
        return 'mission_eat_apples'.trParams({'target': '$target'});
      case CasualMissionType.eatWithMagnet:
        return 'mission_eat_magnet'.trParams({'target': '$target'});
      case CasualMissionType.eatWithTurbo:
        return 'mission_eat_turbo'.trParams({'target': '$target'});
      case CasualMissionType.eatWithIce:
        return 'mission_eat_ice'.trParams({'target': '$target'});
      case CasualMissionType.eatDuringAppleRain:
        return 'mission_eat_apple_rain'.trParams({'target': '$target'});
      case CasualMissionType.eatWithGhost:
        return 'mission_eat_ghost'.trParams({'target': '$target'});
    }
  }
}
