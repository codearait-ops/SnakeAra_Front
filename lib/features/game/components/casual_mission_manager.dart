import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/casual_mode_models.dart';

/// Manager for generating, updating, and rewarding Casual Mode missions.
///
/// Features:
/// - Exactly one active mission at a time.
/// - Weighted random generation with recent-history avoidance across all 6 mission families.
/// - Event-driven progress tracking on apple eaten.
/// - Progress persistence across power-up expirations.
/// - +10 coin rewards on completion.
/// - 20-second cooldown between completed missions with countdown feedback.
/// - Fully independent from Power-Up spawning.
class CasualMissionManager {
  final Rx<CasualMission?> activeMissionRx = Rx<CasualMission?>(null);
  final RxDouble cooldownRemainingRx = 0.0.obs;
  final RxBool hasMissionCompletedCelebration = false.obs;

  CasualMission? get activeMission => activeMissionRx.value;
  double get cooldownRemaining => cooldownRemainingRx.value;
  bool get isCoolingDown => cooldownRemainingRx.value > 0;

  final List<CasualMissionType> _recentMissionTypes = [];
  final Random _rng = Random();
  int _missionCounter = 0;

  /// Callback for optimistic coin reward UI animation when a mission is completed.
  void Function(int coins)? onRewardCoins;

  /// Callback when a mission completes (plays sound/haptic).
  VoidCallback? onMissionCompleted;

  /// Callback to log casual_mission_completed event for server verification.
  void Function(CasualMission mission)? onLogMissionCompleted;

  /// Initialize or reset the mission manager state.
  void init({
    void Function(int coins)? onRewardCoins,
    VoidCallback? onMissionCompleted,
    void Function(CasualMission mission)? onLogMissionCompleted,
  }) {
    this.onRewardCoins = onRewardCoins;
    this.onMissionCompleted = onMissionCompleted;
    this.onLogMissionCompleted = onLogMissionCompleted;
    _recentMissionTypes.clear();
    _missionCounter = 0;
    cooldownRemainingRx.value = 0.0;
    hasMissionCompletedCelebration.value = false;

    // Generate the initial mission immediately
    _generateNextMission();
  }

  /// Update loop per frame (advances cooldown timer).
  void update(double dt) {
    if (cooldownRemainingRx.value > 0) {
      cooldownRemainingRx.value -= dt;
      if (cooldownRemainingRx.value <= 0) {
        cooldownRemainingRx.value = 0.0;
        _generateNextMission();
      }
    }
  }

  /// Event listener called whenever an apple is eaten.
  /// Checks whether the active mission matches the current power-up state and increments progress.
  void onAppleEaten(PowerUpType? activePowerUp) {
    final mission = activeMissionRx.value;
    if (mission == null || mission.isCompleted) return;

    bool qualifies = false;
    switch (mission.type) {
      case CasualMissionType.eatApples:
        qualifies = true; // Any apple counts
        break;
      case CasualMissionType.eatWithMagnet:
        qualifies = activePowerUp == PowerUpType.magnet;
        break;
      case CasualMissionType.eatWithTurbo:
        qualifies = activePowerUp == PowerUpType.turbo;
        break;
      case CasualMissionType.eatWithIce:
        qualifies = activePowerUp == PowerUpType.ice;
        break;
      case CasualMissionType.eatDuringAppleRain:
        qualifies = activePowerUp == PowerUpType.appleRain;
        break;
      case CasualMissionType.eatWithGhost:
        qualifies = activePowerUp == PowerUpType.ghost;
        break;
    }

    if (qualifies) {
      mission.currentProgress++;
      activeMissionRx.refresh();

      if (mission.currentProgress >= mission.target) {
        _completeMission(mission);
      }
    }
  }

  /// Handle mission completion: award coins and start 20s cooldown.
  void _completeMission(CasualMission mission) {
    mission.isCompleted = true;
    activeMissionRx.refresh();
    hasMissionCompletedCelebration.value = true;

    // Optimistic UI preview (+10 coins floating particle) and sound
    onRewardCoins?.call(mission.rewardCoins);
    onMissionCompleted?.call();

    // Log event for backend verification in POST /score/submit
    onLogMissionCompleted?.call(mission);

    // Reset celebration pulse after short delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      hasMissionCompletedCelebration.value = false;
    });

    // Start 20-second cooldown before next mission
    activeMissionRx.value = null;
    cooldownRemainingRx.value = CasualModeConfig.missionCooldown;
  }

  /// Generate next mission using weighted random & recent history to avoid repetitive missions.
  void _generateNextMission() {
    _missionCounter++;
    final allTypes = CasualMissionType.values.toList();

    // Filter out recently used types (keep history of last 2)
    final candidateTypes = allTypes
        .where((t) => !_recentMissionTypes.contains(t))
        .toList();

    final selectedType = candidateTypes.isNotEmpty
        ? candidateTypes[_rng.nextInt(candidateTypes.length)]
        : allTypes[_rng.nextInt(allTypes.length)];

    // Update recent history
    _recentMissionTypes.add(selectedType);
    if (_recentMissionTypes.length > 2) {
      _recentMissionTypes.removeAt(0);
    }

    // Pick a random target from configured pool
    final targetPool = CasualModeConfig.appleTargetPool;
    final target = targetPool[_rng.nextInt(targetPool.length)];

    activeMissionRx.value = CasualMission(
      id: 'casual_mission_$_missionCounter',
      type: selectedType,
      target: target,
      currentProgress: 0,
      rewardCoins: CasualModeConfig.missionRewardCoins,
      isCompleted: false,
    );
  }
}
