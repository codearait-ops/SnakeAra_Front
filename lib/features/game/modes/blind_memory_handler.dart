import 'dart:math';
import 'package:flutter/material.dart';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';
import '../models/game_particles.dart';
import 'base_game_mode_handler.dart';

/// Handler for Blind Memory Mode (Storm & Lightning mechanics).
class BlindMemoryHandler implements BaseGameModeHandler {
  SnakeGame? _game;

  double _flashTimer = 0.0;
  double _thunderPreTimer = 0.0;
  int _lastFlashIntervalIndex = 0;
  final List<RainDrop> _rainDrops = [];
  final List<List<Offset>> _lightningBranches = [];
  final Random _rainRand = Random();

  double get flashTimer => _flashTimer;
  List<RainDrop> get rainDrops => _rainDrops;
  List<List<Offset>> get lightningBranches => _lightningBranches;

  @override
  void onInit(SnakeGame game) {
    _game = game;
    _flashTimer = 0.0;
    _thunderPreTimer = 0.0;
    _lastFlashIntervalIndex = 0;
    _lightningBranches.clear();
    _initRainDrops();

    game.memoryBodyOpacity.value = 1.0;
    game.isFlashActive.value = false;
  }

  void _initRainDrops() {
    _rainDrops.clear();
    for (int i = 0; i < 50; i++) {
      _rainDrops.add(
        RainDrop(
          x: _rainRand.nextDouble(),
          y: _rainRand.nextDouble(),
          speed: 1.2 + _rainRand.nextDouble() * 0.9,
          length: 10.0 + _rainRand.nextDouble() * 12.0,
          alpha: 0.12 + _rainRand.nextDouble() * 0.38,
        ),
      );
    }
  }

  void _updateRain(double dt) {
    if (_rainDrops.isEmpty) _initRainDrops();

    for (final drop in _rainDrops) {
      drop.y += drop.speed * dt * 2.8;
      drop.x -= drop.speed * dt * 0.6;
      if (drop.y > 1.0) {
        drop.y = -0.05;
        drop.x = _rainRand.nextDouble() + 0.15;
      }
      if (drop.x < 0.0) {
        drop.x = 1.0;
      }
    }
  }

  void _generateLightningBolts(SnakeGame game) {
    _lightningBranches.clear();
    final boardW = game.gridCols * game.cellSize;
    final boardH = game.gridRows * game.cellSize;
    final rand = Random();

    // 1-2 main lightning strikes from sky/top of board down
    final strikeCount = 1 + rand.nextInt(2);
    for (int s = 0; s < strikeCount; s++) {
      final startX = game.offsetX + boardW * (0.2 + rand.nextDouble() * 0.6);
      final startY = game.offsetY;
      final targetX = startX + (rand.nextDouble() - 0.5) * boardW * 0.45;
      final targetY = game.offsetY + boardH * (0.65 + rand.nextDouble() * 0.35);

      _createLightningBranch(
        Offset(startX, startY),
        Offset(targetX, targetY),
        displace: boardW * 0.16,
        depth: 0,
      );
    }
  }

  void _createLightningBranch(
    Offset p1,
    Offset p2, {
    required double displace,
    required int depth,
  }) {
    if (depth >= 5 || displace < 3.0) {
      _lightningBranches.add([p1, p2]);
      return;
    }

    final rand = Random();
    final midX = (p1.dx + p2.dx) / 2 + (rand.nextDouble() - 0.5) * displace;
    final midY =
        (p1.dy + p2.dy) / 2 + (rand.nextDouble() - 0.2) * (displace * 0.4);
    final mid = Offset(midX, midY);

    _createLightningBranch(
      p1,
      mid,
      displace: displace * 0.55,
      depth: depth + 1,
    );
    _createLightningBranch(
      mid,
      p2,
      displace: displace * 0.55,
      depth: depth + 1,
    );

    // Random split branch (forking bolt)
    if (rand.nextDouble() < 0.35 && depth < 3) {
      final forkEndX = midX + (rand.nextDouble() - 0.5) * displace * 2.2;
      final forkEndY = midY + (rand.nextDouble() * 0.7 + 0.3) * (p2.dy - midY);
      _createLightningBranch(
        mid,
        Offset(forkEndX, forkEndY),
        displace: displace * 0.45,
        depth: depth + 2,
      );
    }
  }

  @override
  void update(double dt) {
    final game = _game;
    if (game == null || game.gameStatus.value != GameStatus.playing) return;

    _updateRain(dt);

    final elapsed = game.elapsedTimeInSeconds;

    // Check thunderstorm audio trigger (every 18s starting at 16s: 16s, 34s, 52s, 70s...)
    if (elapsed >= 16) {
      final intervalIndex = (elapsed - 16) ~/ 18;
      final secondsInInterval = (elapsed - 16) % 18;
      if (secondsInInterval == 0 && intervalIndex > _lastFlashIntervalIndex) {
        _lastFlashIntervalIndex = intervalIndex;
        _thunderPreTimer = 2.0; // Audio plays 2 seconds before visual strike!

        game.logThunderstormTriggered(4.8);
        game.sound.playThunderstorm(); // Sound starts with 2s build-up
      }
    }

    // Handle 2-second pre-timer:
    if (_thunderPreTimer > 0) {
      _thunderPreTimer -= dt;
      if (_thunderPreTimer <= 0) {
        // Exactly 2 seconds later -> Visual lightning strike!
        _flashTimer = 4.2;
        _generateLightningBolts(game);
        game.isFlashActive.value = true;
        game.memoryBodyOpacity.value = 1.0;
      }
    }

    if (_flashTimer > 0) {
      _flashTimer -= dt;
      game.isFlashActive.value =
          _flashTimer >
          3.2; // Screen flash & bolts visible for first 1.0s of visual strike
      game.memoryBodyOpacity.value =
          1.0; // 100% visible luminous body during lightning!
    } else if (_thunderPreTimer <= 0) {
      game.isFlashActive.value = false;
      // Initial intro fade out from 6s to 8s:
      if (elapsed < 6) {
        game.memoryBodyOpacity.value = 1.0;
      } else if (elapsed < 8) {
        final fadeT = (elapsed + dt - 6) / 2.0;
        game.memoryBodyOpacity.value = (1.0 - fadeT * 0.995).clamp(0.005, 1.0);
      } else {
        game.memoryBodyOpacity.value =
            0.005; // Stealth ghost echo in the dark rain
      }
    }
  }

  @override
  void onFoodEaten(GridPos pos) {}

  @override
  ({int points, Color color}) getScoreForFood() {
    return (
      points: 50,
      color: const Color(0xFFD500F9), // Blind Memory Theme Purple/Magenta
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
    _lightningBranches.clear();
  }

  @override
  void onDestroy() {
    _lightningBranches.clear();
    _rainDrops.clear();
    _game = null;
  }
}
