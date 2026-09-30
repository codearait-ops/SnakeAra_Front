import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/entities/parasite_worm.dart';
import '../components/snake_game.dart';
import '../models/game_particles.dart';
import 'base_game_mode_handler.dart';

/// Handler for Infection Mode.
class InfectionModeHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  double _infectionTimer = 0.0;
  double _heartbeatTimer = 0.0;
  double _infectionInterval = 3.5;
  double _parasiteIntroTimer = 0.0;
  bool _parasiteAttached = false;
  ParasiteWorm? _parasite;

  bool get parasiteAttached => _parasiteAttached;
  ParasiteWorm? get parasite => _parasite;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _infectionInterval = 3.0; // base seconds per tail segment infection
    _parasiteAttached = false;
    _parasite = null;
    _infectionTimer = 0.0;
    _heartbeatTimer = 0.0;
    _parasiteIntroTimer = 0.0;

    game.snake.resetInfection();
    game.infectionRatio.value = 0.0;
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null || game.gameStatus.value != GameStatus.playing) return;

    if (!_parasiteAttached) {
      _parasiteIntroTimer += dt;
      if (_parasiteIntroTimer >= 5.0 && _parasite == null) {
        _spawnParasiteWorm(game);
      }
      if (_parasite != null) {
        _parasite!.update(dt, game.getSnakeTailWorldPos());
        if (_parasite!.hasReachedTarget) {
          _onParasiteAttached(game);
        }
      }
    } else {
      _infectionTimer += dt;

      // Accelerate snake movement speed smoothly over 100s (190ms down to 110ms)
      game.speed = max(110, 190 - ((game.elapsedTimeInSeconds / 100.0) * 80).round());

      // Accelerate infection tick rate smoothly over 100s (3.0s down to 1.0s)
      final currentInterval = max(
        1.0,
        _infectionInterval -
            ((game.elapsedTimeInSeconds - 5.0).clamp(0, 100) / 100.0) * 2.0 -
            (game.applesEaten * 0.03),
      );

      if (_infectionTimer >= currentInterval) {
        _infectionTimer = 0;
        game.snake.infectTail();
        game.infectionRatio.value = game.snake.infectionRatio;

        game.logInfectionTick(
          infectionRatio: game.snake.infectionRatio,
          currentInterval: currentInterval,
          snakeLength: game.snake.segments.length,
        );

        game.sound.playInfectionPulse();

        if (game.snake.isHeadInfected) {
          game.triggerGameOver(GameOverReason.infectionReachedHead);
          return;
        }
      }

      if (game.snake.infectionRatio >= 0.60) {
        _heartbeatTimer += dt;
        final heartbeatInterval = game.snake.infectionRatio >= 0.80 ? 0.6 : 1.0;
        if (_heartbeatTimer >= heartbeatInterval) {
          _heartbeatTimer = 0;
          game.sound.playHeartbeat(volume: (game.snake.infectionRatio).clamp(0.5, 1.0));
        }
      }
    }
  }

  void _spawnParasiteWorm(SnakeGame game) {
    final startSide = Random().nextInt(4);
    double spawnX = 0;
    double spawnY = 0;
    final offsetX = game.offsetX;
    final offsetY = game.offsetY;
    final gridCols = game.gridCols;
    final gridRows = game.gridRows;
    final cellSize = game.cellSize;

    switch (startSide) {
      case 0: // Top
        spawnX = offsetX + Random().nextDouble() * (gridCols * cellSize);
        spawnY = offsetY - cellSize * 4;
        break;
      case 1: // Right
        spawnX = offsetX + gridCols * cellSize + cellSize * 4;
        spawnY = offsetY + Random().nextDouble() * (gridRows * cellSize);
        break;
      case 2: // Bottom
        spawnX = offsetX + Random().nextDouble() * (gridCols * cellSize);
        spawnY = offsetY + gridRows * cellSize + cellSize * 4;
        break;
      case 3: // Left
      default:
        spawnX = offsetX - cellSize * 4;
        spawnY = offsetY + Random().nextDouble() * (gridRows * cellSize);
        break;
    }
    _parasite = ParasiteWorm(headX: spawnX, headY: spawnY, cellSize: cellSize);
  }

  void _onParasiteAttached(SnakeGame game) {
    _parasiteAttached = true;
    game.snake.infectTail();
    game.infectionRatio.value = game.snake.infectionRatio;

    final tailPos = game.getSnakeTailWorldPos();
    final cellSize = game.cellSize;
    final offsetX = game.offsetX;
    final offsetY = game.offsetY;

    // Toxic splash particle burst
    for (int i = 0; i < 22; i++) {
      final angle = Random().nextDouble() * 2 * pi;
      final spd = 60.0 + Random().nextDouble() * 160.0;
      game.slicedParticles.add(
        SlicedParticle(
          x: tailPos.dx,
          y: tailPos.dy,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd,
          radius: cellSize * (0.1 + Random().nextDouble() * 0.15),
          color: Random().nextBool()
              ? const Color(0xFF00E676)
              : const Color(0xFFE040FB),
          life: 0.0,
          maxLife: 0.6,
        ),
      );
    }

    game.triggerShake();
    game.sound.playInfectionPulse();

    game.floatingTexts.add(
      FloatingTextParticle(
        text: 'parasite_attached_floating'.tr,
        x: (tailPos.dx - offsetX) / cellSize,
        y: (tailPos.dy - offsetY) / cellSize - 0.5,
        color: const Color(0xFF00E676),
        vy: -1.2,
        maxLife: 2.0,
      ),
    );

    game.logParasiteAttached(game.elapsedTimeInSeconds);
    _parasite = null;
  }

  @override
  void onFoodEaten(GridPos pos) {
    final game = _game;
    if (game == null) return;

    // Eating an apple strictly heals 1 single infected segment
    game.snake.healInfection(1);
    game.infectionRatio.value = game.snake.infectionRatio;
  }

  @override
  ({int points, Color color}) getScoreForFood() {
    return (
      points: 10,
      color: const Color(0xFFFF1744), // Infection Theme Red
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
    _parasite = null;
  }

  @override
  void onDestroy() {
    _parasite = null;
    _game = null;
  }
}
