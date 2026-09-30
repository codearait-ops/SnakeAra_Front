import 'dart:math';
import 'package:flutter/material.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import '../models/game_particles.dart';
import 'base_game_mode_handler.dart';

/// Handler for Classic (Endless) Mode.
class ClassicModeHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    game.pear.despawn();
    game.pearsCount.value = 0;
    game.pearScore.value = 0;
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null) return;
    game.pear.update(dt);
  }

  @override
  void onFoodEaten(GridPos pos) {
    final game = _game;
    if (game == null) return;

    // Accelerate speed dynamically in Classic Mode (down to min limit 70ms)
    if (game.applesEaten % 5 == 0 && game.speed > 70) {
      game.speed = max(70, game.speed - 10);
    }

    // Every 5 apples eaten, spawn a Pear alongside the 6th apple!
    if (game.applesEaten % 5 == 0) {
      game.pear.spawn(
        game.gridCols,
        game.gridRows,
        game.snake.segments,
        game.obstacles.obstacles,
        game.food.position,
        game.mechanicsRng.bonus ?? Random(),
      );
    }
  }

  @override
  void onStep(GridPos head) {
    final game = _game;
    if (game == null) return;

    // Pear collision
    if (game.pear.isActive && head == game.pear.position) {
      game.snake.grow();
      final bonusScore = (50 + game.pear.timeProgress * 50).round();
      game.score.value += bonusScore;
      game.pearsCount.value++;
      game.pearScore.value += bonusScore;
      game.floatingTexts.add(
        FloatingTextParticle(
          text: '+$bonusScore',
          x: game.pear.position!.x.toDouble() + 0.5,
          y: game.pear.position!.y.toDouble() + 0.5,
          color: const Color(0xFFFFD700),
        ),
      );

      game.logPearEaten(bonusScore);
      game.triggerEatEffect();
      game.sound.playEatApple();
      game.pear.despawn();
    }
  }

  @override
  ({int points, Color color}) getScoreForFood() {
    return (
      points: 10,
      color: kPrimaryColor, // Classic Theme Green (0xFF00E676)
    );
  }

  @override
  bool checkCustomCollision(GridPos nextHead) {
    // Classic mode uses standard self-collision
    return false;
  }

  @override
  bool onTimeExpired() => false;

  @override
  bool handleDirectionChange(Direction? queuedDir) => false;

  @override
  double modifySpeed(double baseSpeed) => baseSpeed;

  @override
  void onGameOver() {
    _game?.pear.despawn();
  }

  @override
  void onDestroy() {
    _game?.pear.despawn();
    _game = null;
  }
}
