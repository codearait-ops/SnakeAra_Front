import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import '../models/casual_mode_models.dart';
import '../models/game_particles.dart';
import 'base_game_mode_handler.dart';

/// Handler for Casual Mode mechanics (3 lives, power-ups, ice slide, streaks, missions).
class CasualModeHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  int _casualStreak = 0;
  int get casualStreak => _casualStreak;

  int _iceSlideRemaining = 0;
  Direction? _queuedIceDirection;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _casualStreak = 0;
    _iceSlideRemaining = 0;
    _queuedIceDirection = null;
    game.casualLives.value = SnakeGame.maxCasualLives;
    game.optimisticCasualCoins.value = 0;

    game.casualPowerUp.init();
    game.casualMissionManager.init(
      onRewardCoins: (coins) {
        // Optimistic UI preview (Do NOT modify WalletController.balance directly!)
        game.optimisticCasualCoins.value += coins;
        game.floatingTexts.add(
          FloatingTextParticle(
            text: 'coins_reward_floating'.trParams({'coins': '$coins'}),
            x: game.snake.head.x.toDouble() + 0.5,
            y: game.snake.head.y.toDouble() + 0.5,
            color: const Color(0xFFFFD700),
            vy: -2.0,
          ),
        );
      },
      onMissionCompleted: () {
        game.sound.playLevelComplete();
      },
      onLogMissionCompleted: (mission) {
        game.logCasualMissionCompleted(mission);
      },
    );
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null) return;

    final consumedByMagnet = game.casualPowerUp.update(
      dt: dt,
      gridWidth: game.gridCols,
      gridHeight: game.gridRows,
      snakeSegments: game.snake.segments,
      obstacles: game.obstacles.obstacles,
      food: game.food,
    );
    if (consumedByMagnet && game.gameStatus.value == GameStatus.playing) {
      game.triggerConsumeFood();
    }
    game.casualMissionManager.update(dt);
    if (game.casualActivePowerUp.value != game.casualPowerUp.activePowerUp) {
      game.casualActivePowerUp.value = game.casualPowerUp.activePowerUp;
    }
    final remainingDuration = game.casualPowerUp.activeDurationRemaining;
    if (remainingDuration <= 0) {
      if (game.casualPowerUpTimeRemaining.value != 0.0) {
        game.casualPowerUpTimeRemaining.value = 0.0;
      }
    } else {
      // Round to 1 decimal place to prevent 60-120fps UI rebuild thrashing
      final rounded = (remainingDuration * 10).round() / 10.0;
      if ((game.casualPowerUpTimeRemaining.value - rounded).abs() >= 0.05) {
        game.casualPowerUpTimeRemaining.value = rounded;
      }
    }
  }

  @override
  bool handleDirectionChange(Direction? queuedDir) {
    final game = _game;
    if (game == null) return false;

    if (game.casualPowerUp.activePowerUp == PowerUpType.ice) {
      if (queuedDir != null) {
        if (queuedDir != game.snake.currentDirection &&
            !queuedDir.isOpposite(game.snake.currentDirection)) {
          if (_iceSlideRemaining == 0) {
            _iceSlideRemaining = 1;
            _queuedIceDirection = queuedDir;
          } else {
            game.snake.changeDirection(queuedDir);
            _iceSlideRemaining = 0;
            _queuedIceDirection = null;
          }
        } else {
          game.snake.changeDirection(queuedDir);
        }
        return true;
      } else if (_iceSlideRemaining > 0 && _queuedIceDirection != null) {
        _iceSlideRemaining--;
        game.snake.changeDirection(_queuedIceDirection!);
        _queuedIceDirection = null;
        return true;
      }
    } else if (queuedDir != null) {
      game.snake.changeDirection(queuedDir);
      return true;
    }
    return false;
  }

  @override
  bool checkCustomCollision(GridPos nextHead) {
    final game = _game;
    if (game == null) return false;

    // In Casual Mode: Ghost allows passing through self safely. Otherwise deduct life and cut snake at collision point.
    if (!game.casualPowerUp.isGhostActive) {
      final h = game.snake.head;
      for (int i = 1; i < game.snake.segments.length; i++) {
        if (game.snake.segments[i] == h) {
          game.casualLives.value--;
          _casualStreak = 0; // Cut consequence: streak reset

          game.logLifeLost(game.casualLives.value);

          if (game.casualLives.value <= 0) {
            game.triggerShake();
            game.sound.playGameOver();
            game.triggerGameOver(GameOverReason.selfCollision);
            return true;
          }

          final cutIndex = max(CasualModeConfig.minSnakeLength, i);
          if (cutIndex < game.snake.segments.length) {
            final cutSegments = game.snake.sliceAt(cutIndex);
            if (cutSegments.isNotEmpty) {
              game.spawnSliceParticles(cutSegments);
              game.logSnakeCut(
                cutSegments.length,
                game.snake.segments.length,
              );
            }
          }

          game.triggerShake();
          game.sound.playLaserWarning();
          game.floatingTexts.add(
            FloatingTextParticle(
              text: '💔 -1',
              x: h.x.toDouble() + 0.5,
              y: h.y.toDouble() + 0.5,
              color: const Color(0xFFFF1744),
              vy: -2.2,
            ),
          );
          return true;
        }
      }
    } else {
      // Ghost power-up active: pass through self safely
      return true;
    }
    return false;
  }

  @override
  void onStep(GridPos head) {
    final game = _game;
    if (game == null) return;

    // Casual Mode Power-Up Collection
    final collected = game.casualPowerUp.checkCollection(head);
    if (collected != null) {
      game.floatingTexts.add(
        FloatingTextParticle(
          text: '${collected.emoji} ${collected.displayNameTr}!',
          x: head.x.toDouble() + 0.5,
          y: head.y.toDouble() + 0.5,
          color: collected.color,
          vy: -2.0,
        ),
      );
      game.sound.playHeal();
      game.logPowerUpCollected(
        collected.name,
        CasualModeConfig.powerUpDuration,
      );
    }

    // Casual Mode Rain Apple Collection (Apple Rain power-up)
    if (game.casualPowerUp.isAppleRainActive &&
        game.casualPowerUp.checkRainAppleCollection(head)) {
      game.snake.grow();
      game.applesEaten++;
      game.applesCount.value = game.applesEaten;
      _casualStreak++;
      final streakBonus = min(10, _casualStreak);
      final pts = 10 + streakBonus;
      game.score.value += pts;
      game.floatingTexts.add(
        FloatingTextParticle(
          text: '+$pts',
          x: head.x.toDouble() + 0.5,
          y: head.y.toDouble() + 0.5,
          color: const Color(0xFFFF5722),
        ),
      );
      game.sound.playEatApple();
      game.casualMissionManager.onAppleEaten(game.casualPowerUp.activePowerUp);
      game.logRainAppleEaten(pts);
    }
  }

  @override
  void onFoodEaten(GridPos pos) {
    _casualStreak++;
    _game?.casualMissionManager.onAppleEaten(
      _game?.casualPowerUp.activePowerUp,
    );
  }

  @override
  double modifySpeed(double baseSpeed) {
    final game = _game;
    if (game != null && game.casualPowerUp.isTurboActive) {
      return baseSpeed / CasualModeConfig.turboSpeedMultiplier;
    }
    return baseSpeed;
  }

  @override
  ({int points, Color color}) getScoreForFood() {
    final streakBonus = min(10, _casualStreak);
    return (
      points: 10 + streakBonus,
      color: const Color(0xFFA855F7), // Casual Theme Vibrant Fantasy Purple
    );
  }

  @override
  bool onTimeExpired() => false;

  @override
  void onGameOver() {
    _iceSlideRemaining = 0;
    _queuedIceDirection = null;
  }

  @override
  void onDestroy() {
    _iceSlideRemaining = 0;
    _queuedIceDirection = null;
    _game = null;
  }
}
