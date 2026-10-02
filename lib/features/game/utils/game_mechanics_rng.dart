import 'dart:math';
import 'package:flutter/foundation.dart';

/// Provides distinct RNG streams for deterministic gameplay sequences.
/// 
/// By providing a seed, this class creates isolated Random instances for different
/// game mechanics (Food, Obstacles, Bonus, Boss, Level). This ensures that if the
/// sequence of events changes (e.g. eating an apple before an obstacle spawns),
/// the streams do not offset each other and determinism is strictly preserved.
class GameMechanicsRng {
  final Random? food;
  final Random? obstacle;
  final Random? bonus;
  final Random? boss;
  final Random? level;

  GameMechanicsRng({int? seed})
      : food = seed != null ? Random(seed + 1000) : null,
        obstacle = seed != null ? Random(seed + 2000) : null,
        bonus = seed != null ? Random(seed + 3000) : null,
        boss = seed != null ? Random(seed + 4000) : null,
        level = seed != null ? Random(seed + 5000) : null {
    if (seed == null) {
      debugPrint('[GameMechanicsRng] WARNING: Initialized without a seed. RNG will not be deterministic.');
    } else {
      debugPrint('[GameMechanicsRng] Initialized with strict deterministic seed: $seed');
    }
  }
}
