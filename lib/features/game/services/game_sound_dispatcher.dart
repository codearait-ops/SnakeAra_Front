import 'package:get/get.dart';
import 'package:snake_game/app/core/utils/enums.dart';
import 'package:snake_game/services/sound_service.dart';

/// Centralizes sound effects, background music, and haptic feedback triggers for SnakeGame.
/// Decouples the game engine and entities from direct service locators and audio SDK dependencies.
class GameSoundDispatcher {
  final SoundService Function()? _soundServiceResolver;
  SoundService? _soundService;

  GameSoundDispatcher({SoundService Function()? soundServiceResolver})
      : _soundServiceResolver = soundServiceResolver;

  /// Underlying SoundService instance.
  SoundService get sound =>
      _soundService ??= (_soundServiceResolver != null
          ? _soundServiceResolver()
          : Get.find<SoundService>());

  // --- Background Music ---

  /// Play default background music track.
  void playBgMusic() => sound.playBgMusic();

  /// Play dark background music for Infection mode.
  void playInfectionBgMusic() => sound.playInfectionBgMusic();

  /// Play ambient rain background music for Storm / Blind Memory mode.
  void playRainBgMusic() => sound.playRainBgMusic();

  /// Play frantic soundtrack for Meltdown mode.
  void playMeltdownBgMusic() => sound.playMeltdownBgMusic();

  /// Pause current background music (e.g. during pause menu or level complete dialog).
  void pauseBgMusic() => sound.pauseBgMusic();

  /// Stop current background music.
  void stopBgMusic() => sound.stopBgMusic();

  /// Plays appropriate background music matching the active [GameMode].
  void playBgmForMode(GameMode mode) {
    switch (mode) {
      case GameMode.infection:
        playInfectionBgMusic();
        break;
      case GameMode.blindMemory:
        playRainBgMusic();
        break;
      case GameMode.meltdown:
        playMeltdownBgMusic();
        break;
      default:
        playBgMusic();
        break;
    }
  }

  // --- Gameplay SFX & Haptics ---

  /// Trigger food/apple consumption audio.
  void playEatApple() => sound.playEatApple();

  /// Trigger heal audio (played when curing infected segments in Infection mode).
  void playHeal() => sound.playHeal();

  /// Trigger level complete celebratory sound.
  void playLevelComplete() => sound.playLevelComplete();

  /// Trigger game over sound.
  void playGameOver() => sound.playGameOver();

  /// Trigger pre-fire laser warning sound or explosion cue.
  void playLaserWarning() => sound.playLaserWarning();

  /// Trigger active laser firing beam sound.
  void playLaserBeam() => sound.playLaserBeam();

  /// Trigger laser death impact sound.
  void playLaserDeath() => sound.playLaserDeath();

  /// Trigger flamethrower pulse sound.
  void playFlamethrower() => sound.playFlamethrower();

  /// Trigger flash sound in Blind Memory mode.
  void playCameraFlash() => sound.playCameraFlash();

  /// Trigger infection hazard pulse sound and haptic vibration.
  void playInfectionPulse() => sound.playInfectionPulse();

  /// Trigger heartbeat audio pulse with volume modulated by infection ratio.
  void playHeartbeat({double volume = 0.8}) => sound.playHeartbeat(volume: volume);

  /// Trigger thunderstorm crack/rumble sound.
  void playThunderstorm() => sound.playThunderstorm();
}
