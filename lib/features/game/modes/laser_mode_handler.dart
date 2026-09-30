import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import 'base_game_mode_handler.dart';

/// Handler for Laser Mode.
class LaserModeHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  double _laserTimer = 0.0;
  Timer? _laserActiveTimer;
  Timer? _laserClearTimer;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _laserTimer = 0.0;
    cancelTimers();
  }

  void cancelTimers() {
    _laserActiveTimer?.cancel();
    _laserActiveTimer = null;
    _laserClearTimer?.cancel();
    _laserClearTimer = null;

    final game = _game;
    if (game != null) {
      game.warningLaserRow.value = -1;
      game.warningLaserCol.value = -1;
      game.activeLaserRow.value = -1;
      game.activeLaserCol.value = -1;
    }
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null || game.gameStatus.value != GameStatus.playing) return;

    // Continuous Laser Collision & Slicing Detection (every frame)
    if (game.activeLaserRow.value >= 0) {
      final targetY = game.activeLaserRow.value;
      if (game.snake.head.y == targetY) {
        game.triggerGameOver(GameOverReason.laserHeadHit);
        return;
      } else {
        for (int i = 1; i < game.snake.segments.length; i++) {
          if (game.snake.segments[i].y == targetY) {
            final cutSegments = game.snake.sliceAt(i);
            if (cutSegments.isNotEmpty) {
              game.triggerSnakeSliced(cutSegments);
            }
            break;
          }
        }
      }
    }
    if (game.activeLaserCol.value >= 0) {
      final targetX = game.activeLaserCol.value;
      if (game.snake.head.x == targetX) {
        game.triggerGameOver(GameOverReason.laserHeadHit);
        return;
      } else {
        for (int i = 1; i < game.snake.segments.length; i++) {
          if (game.snake.segments[i].x == targetX) {
            final cutSegments = game.snake.sliceAt(i);
            if (cutSegments.isNotEmpty) {
              game.triggerSnakeSliced(cutSegments);
            }
            break;
          }
        }
      }
    }

    _laserTimer += dt;
    const laserSpawnInterval = 5.0; // Spawns every 5 seconds as requested

    if (_laserTimer >= laserSpawnInterval) {
      _laserTimer = 0.0;
      final rand = game.mechanicsRng.boss ?? Random();
      final isRow = rand.nextBool();
      final idx = rand.nextInt(18) + 1;

      if (isRow) {
        game.warningLaserRow.value = idx;
        game.warningLaserCol.value = -1;
      } else {
        game.warningLaserCol.value = idx;
        game.warningLaserRow.value = -1;
      }

      game.logLaserSpawned(
        row: isRow ? idx : -1,
        col: isRow ? -1 : idx,
        warningDuration: 1.2,
      );

      game.sound.playLaserWarning();

      final targetRow = isRow ? idx : -1;
      final targetCol = isRow ? -1 : idx;

      _laserActiveTimer?.cancel();
      _laserActiveTimer = Timer(const Duration(milliseconds: 1200), () {
        _laserActiveTimer = null;
        if (game.gameStatus.value != GameStatus.playing) {
          game.warningLaserRow.value = -1;
          game.warningLaserCol.value = -1;
          return;
        }
        game.activeLaserRow.value = targetRow;
        game.activeLaserCol.value = targetCol;
        game.warningLaserRow.value = -1;
        game.warningLaserCol.value = -1;
        game.sound.playLaserBeam();

        _laserClearTimer?.cancel();
        _laserClearTimer = Timer(const Duration(milliseconds: 900), () {
          _laserClearTimer = null;
          game.activeLaserRow.value = -1;
          game.activeLaserCol.value = -1;
        });
      });
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
      color: const Color(0xFFFF9100), // Laser Theme Orange
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
    cancelTimers();
  }

  @override
  void onDestroy() {
    cancelTimers();
    _game = null;
  }
}
