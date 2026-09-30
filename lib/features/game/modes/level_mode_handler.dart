import 'dart:async';
import 'dart:math';
import 'dart:ui';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import '../models/game_particles.dart';
import 'base_game_mode_handler.dart';

/// Handler for Level Mode and Boss mechanics across levels 10–50.
class LevelModeHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  // Boss 2 (Laser Core - Level 20) state
  double _laserTimer = 0.0;
  Timer? _laserActiveTimer;
  Timer? _laserClearTimer;

  // Boss 3 (The Architect - Level 30) state
  double _architectTimer = 0.0;

  // Boss 4 (Void Sentinel - Level 40) state
  double _shockwaveTimer = 0.0;
  Timer? _shockwavePeriodicTimer;

  // Boss 5 (The Overlord - Level 50) state
  double _bulletTimer = 0.0;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _laserTimer = 0.0;
    _architectTimer = 0.0;
    _shockwaveTimer = 0.0;
    _bulletTimer = 0.0;
    cancelTransientTimers();
  }

  /// Cancels any active boss effect timers (lasers, shockwaves) and clears transient visual state.
  void cancelTransientTimers() {
    _laserActiveTimer?.cancel();
    _laserActiveTimer = null;
    _laserClearTimer?.cancel();
    _laserClearTimer = null;
    _shockwavePeriodicTimer?.cancel();
    _shockwavePeriodicTimer = null;

    final game = _game;
    if (game != null) {
      game.warningLaserRow.value = -1;
      game.warningLaserCol.value = -1;
      game.activeLaserRow.value = -1;
      game.activeLaserCol.value = -1;
      game.shockwaveRadius.value = -1.0;
      game.bullets.clear();
    }
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null || game.gameStatus.value != GameStatus.playing) return;

    final currentLevel = game.currentLevel;

    // --- Boss 2 (Laser Core - Level 20) Mechanics ---
    if (currentLevel == 20) {
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

    // --- Boss 3 (The Architect - Level 30) ---
    if (currentLevel == 30) {
      _architectTimer += dt;
      if (_architectTimer >= 7.5) {
        _architectTimer = 0.0;
        final rand = game.mechanicsRng.boss ?? Random();
        for (int attempt = 0; attempt < 30; attempt++) {
          final rx = rand.nextInt(18) + 1;
          final ry = rand.nextInt(18) + 1;
          final pos = GridPos(rx, ry);
          if (!game.snake.segments.contains(pos) &&
              game.food.position != pos &&
              !game.obstacles.occupiesPosition(pos)) {
            game.obstacles.addObstacle(pos);
            game.sound.playEatApple();
            break;
          }
        }
      }
    }

    // --- Boss 4 (Void Sentinel - Level 40) ---
    if (currentLevel == 40) {
      _shockwaveTimer += dt;
      if (_shockwaveTimer >= 8.0) {
        _shockwaveTimer = 0.0;
        game.sound.playFlamethrower();
        double r = 0.0;
        _shockwavePeriodicTimer?.cancel();
        _shockwavePeriodicTimer = Timer.periodic(
          const Duration(milliseconds: 35),
          (timer) {
            if (game.gameStatus.value != GameStatus.playing) {
              timer.cancel();
              _shockwavePeriodicTimer = null;
              game.shockwaveRadius.value = -1.0;
              return;
            }
            r += 0.2; // Slower speed for the wave
            game.shockwaveRadius.value = r;

            final isHit = game.snake.segments.any((s) {
              final dist = s.y.toDouble();
              return (dist - r).abs() < 0.65;
            });

            if (isHit) {
              timer.cancel();
              _shockwavePeriodicTimer = null;
              game.shockwaveRadius.value = -1.0;
              game.triggerGameOver(GameOverReason.obstacleCollision);
            }

            if (r >= game.gridRows.toDouble()) {
              timer.cancel();
              _shockwavePeriodicTimer = null;
              game.shockwaveRadius.value = -1.0;
            }
          },
        );
      }
    }

    // --- Boss 5 (The Overlord - Level 50) ---
    if (currentLevel == 50) {
      _bulletTimer += dt;
      if (_bulletTimer >= 3.2) {
        _bulletTimer = 0.0;
        final rand = Random();
        final isHorizontal = rand.nextBool();
        if (isHorizontal) {
          final y = (rand.nextInt(18) + 1).toDouble();
          final fromLeft = rand.nextBool();
          game.bullets.add(
            BossBullet(
              x: fromLeft ? 0.0 : 19.0,
              y: y,
              vx: fromLeft ? 8.5 : -8.5,
              vy: 0.0,
            ),
          );
        } else {
          final x = (rand.nextInt(18) + 1).toDouble();
          final fromTop = rand.nextBool();
          game.bullets.add(
            BossBullet(
              x: x,
              y: fromTop ? 0.0 : 19.0,
              vx: 0.0,
              vy: fromTop ? 8.5 : -8.5,
            ),
          );
        }
        game.sound.playCameraFlash();
      }

      for (int i = game.bullets.length - 1; i >= 0; i--) {
        final b = game.bullets[i];
        b.x += b.vx * dt;
        b.y += b.vy * dt;

        const double hitRadiusSq = 0.85 * 0.85;
        final isHit = game.snake.segments.any((s) {
          final dx = s.x - b.x;
          final dy = s.y - b.y;
          return (dx * dx + dy * dy) < hitRadiusSq;
        });

        if (isHit) {
          game.bullets.clear();
          game.triggerGameOver(GameOverReason.bulletCollision);
          return;
        }

        if (b.x < -1 || b.x > 21 || b.y < -1 || b.y > 21) {
          game.bullets.removeAt(i);
        }
      }
    }
  }

  @override
  void onFoodEaten(GridPos pos) {
    final game = _game;
    if (game == null) return;

    // Check level completion in Level Mode (if appleTarget > 0)
    if (game.appleTarget > 0 && game.applesEaten >= game.appleTarget) {
      game.triggerLevelComplete();
    }
  }

  @override
  bool checkCustomCollision(GridPos nextHead) {
    // Level mode does not intercept nextHead collision before standard checks
    return false;
  }

  @override
  bool onTimeExpired() {
    final game = _game;
    if (game == null) return false;

    // Survival boss survived the time limit!
    if (game.appleTarget == 0) {
      game.triggerLevelComplete();
      return true;
    }
    return false;
  }

  @override
  bool handleDirectionChange(Direction? queuedDir) => false;

  @override
  void onStep(GridPos head) {}

  @override
  double modifySpeed(double baseSpeed) => baseSpeed;

  @override
  ({int points, Color color})? getScoreForFood() => null;

  @override
  void onGameOver() {
    cancelTransientTimers();
  }

  @override
  void onDestroy() {
    cancelTransientTimers();
    _game = null;
  }
}
