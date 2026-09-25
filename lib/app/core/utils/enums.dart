// Enums used throughout the Snake game.

enum GameMode {
  classic,
  level,
  infection,
  blindMemory,
  laser,
  meltdown,
  crabChase,
  casual,
  custom,
}

extension GameModeExtension on GameMode {
  String get apiName {
    switch (this) {
      case GameMode.classic:
        return 'classic';
      case GameMode.infection:
        return 'infection';
      case GameMode.blindMemory:
        return 'blind_memory';
      case GameMode.laser:
        return 'laser_core';
      case GameMode.meltdown:
        return 'meltdown';
      case GameMode.crabChase:
        return 'crab';
      case GameMode.casual:
        return 'casual';

      default:
        return name;
    }
  }
}

enum Direction {
  up,
  down,
  left,
  right;

  /// Returns true if [other] is the opposite of this direction.
  bool isOpposite(Direction other) {
    switch (this) {
      case Direction.up:
        return other == Direction.down;
      case Direction.down:
        return other == Direction.up;
      case Direction.left:
        return other == Direction.right;
      case Direction.right:
        return other == Direction.left;
    }
  }
}

enum GameStatus { idle, playing, paused, gameOver, levelComplete }

/// Game over reason
enum GameOverReason {
  wallCollision('wall_collision'),
  selfCollision('self_collision'),
  infectionReachedHead('infection_reached_head'),
  laserHeadHit('laser_head_hit'),
  timerExpired('timer_expired'),
  obstacleCollision('wall_collision'),
  bulletCollision('unknown'),
  crabCollision('crab_collision'),
  unknown('unknown');

  final String value;
  const GameOverReason(this.value);

  String get apiReason {
    switch (this) {
      case GameOverReason.wallCollision:
        return 'wall_collision';
      case GameOverReason.selfCollision:
        return 'self_collision';
      case GameOverReason.infectionReachedHead:
        return 'infection_reached_head';
      case GameOverReason.laserHeadHit:
        return 'laser_head_hit';
      case GameOverReason.timerExpired:
        return 'timer_expired';
      case GameOverReason.obstacleCollision:
        return 'wall_collision';
      case GameOverReason.crabCollision:
        return 'crab_collision';
      case GameOverReason.bulletCollision:
      case GameOverReason.unknown:
        return 'unknown';
    }
  }
}
