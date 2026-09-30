import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import '../models/game_particles.dart';
import 'base_game_mode_handler.dart';

/// Handler for Meltdown Mode.
class MeltdownModeHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  double _appleTimer = 5.0;
  int _explosionsCount = 0;
  static const double maxTimer = 5.0;
  bool _bonusAwarded = false;
  final List<ExplosionEffect> _explosions = [];

  double get appleTimer => _appleTimer;
  double get maxTimerValue => maxTimer;
  bool get bonusAwarded => _bonusAwarded;
  List<ExplosionEffect> get explosions => _explosions;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _appleTimer = maxTimer;
    _explosionsCount = 0;
    _bonusAwarded = false;
    _explosions.clear();
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null || game.gameStatus.value != GameStatus.playing) return;

    _appleTimer -= dt;
    if (_appleTimer <= 0) {
      _appleTimer = maxTimer;
      _explosionsCount++;

      // 1. Instant visual explosion
      _explosions.add(ExplosionEffect(game.food.position, 0.6, 0.6));

      // 2. Explode! Bypass safety zone so crater is definitely created
      game.obstacles.addObstacle(
        game.food.position,
        gridWidth: game.gridCols,
        gridHeight: game.gridRows,
        ignoreSafetyZone: true,
      );

      game.logCraterSpawned(
        row: game.food.position.y,
        col: game.food.position.x,
      );

      game.triggerShake();
      game.sound.playLaserWarning(); // Explosion sound
      game.speed = max(157, 220 - (_explosionsCount * 4));

      // 3. Respawn food
      game.food.spawn(
        game.gridCols,
        game.gridRows,
        game.snake.segments,
        game.obstacles.obstacles,
        game.mechanicsRng.food ?? Random(),
      );
    }

    // Update explosions
    for (int i = _explosions.length - 1; i >= 0; i--) {
      _explosions[i].life -= dt;
      if (_explosions[i].life <= 0) {
        _explosions.removeAt(i);
      }
    }
  }

  @override
  void onFoodEaten(GridPos pos) {
    final game = _game;
    if (game == null) return;

    // Reset apple timer
    _appleTimer = maxTimer;
  }

  @override
  ({int points, Color color}) getScoreForFood() {
    final game = _game;
    final apples = game?.applesEaten ?? 1;
    final addedPoints = 10 + (apples - 1) * 5;

    // Last Second Bonus
    _bonusAwarded = _appleTimer <= 1.0;
    if (_bonusAwarded && game != null) {
      final bonus = 50;
      game.score.value += bonus;
      game.floatingTexts.add(
        FloatingTextParticle(
          text: 'perfect_timing_floating'.trParams({'bonus': '$bonus'}),
          x: game.food.position.x.toDouble() + 0.5,
          y: game.food.position.y.toDouble() - 0.5, // slightly above
          color: const Color(0xFFC6FF00),
          vy: -1.0,
          maxLife: 2.0,
        ),
      );
    }

    return (
      points: addedPoints,
      color: const Color(0xFFC6FF00), // Neon Yellow-Green
    );
  }

  @override
  bool checkCustomCollision(GridPos nextHead) => false;

  @override
  void onStep(GridPos head) {}

  @override
  bool onTimeExpired() => false;

  @override
  bool handleDirectionChange(Direction? queuedDir) => false;

  @override
  double modifySpeed(double baseSpeed) => baseSpeed;

  @override
  void onGameOver() {
    _explosions.clear();
  }

  @override
  void onDestroy() {
    _explosions.clear();
    _game = null;
  }
}
