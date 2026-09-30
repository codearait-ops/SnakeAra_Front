import 'dart:math';
import 'package:flutter/material.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import 'base_game_mode_handler.dart';

/// Handler for Crab Chase Mode.
class CrabChaseHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  double _crabChaseTimer = 0.0;
  int _lastDifficultyStage = 0;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _crabChaseTimer = 0.0;
    _lastDifficultyStage = 0;
    if (game.snake.segments.isNotEmpty) {
      game.crab.spawn(game.gridCols, game.gridRows, game.snake);
    }
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null || game.gameStatus.value != GameStatus.playing) return;

    _crabChaseTimer += dt;
    final int difficultyStage = (_crabChaseTimer / 90.0).floor();
    if (difficultyStage > _lastDifficultyStage) {
      _lastDifficultyStage = difficultyStage;
      game.crab.speedMultiplier = min(1.6, 1.0 + 0.15 * difficultyStage);
      game.sound.playLaserWarning(); // Using laser warning sound for level up
    }

    game.crab.update(dt, game.snake, game.gridCols, game.gridRows);

    // Check for cut timing
    if (game.crab.shouldApplyCutThisFrame()) {
      final hitIndex = game.crab.lastHitSegmentIndex;
      if (hitIndex > 0) {
        // Safety check
        final cutSegments = game.snake.sliceAt(hitIndex);
        if (cutSegments.isNotEmpty) {
          game.triggerSnakeSliced(cutSegments);

          // Check minimum snake length
          if (game.snake.segments.length < 3) {
            game.triggerGameOver(GameOverReason.crabCollision);
            return;
          }
        }
      }
    }

    // Check collision
    if (!game.crab.isAttacking) {
      final hitIndex = game.crab.checkCollision(game.snake, game.cellSize);
      if (hitIndex == 0) {
        // Head collision
        game.triggerGameOver(GameOverReason.crabCollision);
        return;
      } else if (hitIndex > 0) {
        // Body collision
        game.crab.triggerAttack(hitIndex);
      }
    }
  }

  @override
  void onFoodEaten(GridPos pos) {}

  @override
  ({int points, Color color}) getScoreForFood() {
    final game = _game;
    final apples = game?.applesEaten ?? 1;
    return (
      points: 10 + (apples - 1) * 5,
      color: const Color(0xFFFF5722), // Crab Chase Deep Orange
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
  void onGameOver() {}

  @override
  void onDestroy() {
    _game = null;
  }
}
