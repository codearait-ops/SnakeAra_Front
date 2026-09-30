import 'dart:ui';

import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../components/snake_game.dart';

/// Base strategy interface for isolated game mode logic handlers.
abstract class BaseGameModeHandler {
  /// Called when the game mode is initialized.
  void onInit(SnakeGame game);

  /// Called every frame from SnakeGame.update(dt).
  void update(double dt);

  /// Called when an apple / food item is eaten.
  void onFoodEaten(GridPos pos);

  /// Called during snake movement step to evaluate mode-specific collisions.
  /// Returns true if a collision occurred and was handled, false otherwise.
  bool checkCustomCollision(GridPos nextHead);

  /// Called when the game transitions to game over.
  void onGameOver();

  /// Called when cleaning up or switching away from the mode.
  void onDestroy();

  /// Optional hook called when the mode countdown timer reaches zero.
  /// Returns true if the mode handled completion (e.g., survival boss win),
  /// or false if standard GameOverReason.timerExpired should trigger.
  bool onTimeExpired() => false;

  /// Optional hook to intercept or override snake direction before moving.
  /// Returns true if the handler processed/delayed the direction change,
  /// or false to let SnakeGame handle it standardly.
  bool handleDirectionChange(Direction? queuedDir) => false;

  /// Optional hook called after the snake head moves to a new cell.
  /// Used for custom item pickups (e.g., power-ups, rain apples, pears).
  void onStep(GridPos head) {}

  /// Optional speed modifier applied to base speed in milliseconds.
  double modifySpeed(double baseSpeed) => baseSpeed;

  /// Returns custom score points and popup color when food is eaten, or null if unhandled.
  ({int points, Color color})? getScoreForFood() => null;
}
