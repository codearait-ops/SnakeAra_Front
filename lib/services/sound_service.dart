import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

/// GetX service for playing sound effects, haptic vibrations, and background music using FlameAudio.
class SoundService extends GetxService {
  bool _initialized = false;
  AudioPool? _eatApplePool;
  AudioPool? _buttonTapPool;
  AudioPool? _gameOverPool;
  AudioPool? _levelCompletePool;
  AudioPool? _infectionPulsePool;
  AudioPool? _healPool;
  AudioPool? _heartbeatPool;
  AudioPool? _cameraFlashPool;
  AudioPool? _warningBeepPool;
  AudioPool? _laserPool;
  AudioPool? _laserDeathPool;
  AudioPool? _flamethrowerPool;
  AudioPool? _thunderstormPool;
  AudioPool? _levelUpPool;
  
  StorageService? _storageService;

  DateTime? _lastWarningBeepTime;
  DateTime? _lastLaserTime;
  DateTime? _lastLaserDeathTime;
  DateTime? _lastEatAppleTime;
  DateTime? _lastButtonTapTime;
  DateTime? _lastGameOverTime;
  DateTime? _lastThunderstormTime;

  StorageService get _storage => _storageService ??= Get.find<StorageService>();

  bool get _isSfxEnabled => _storage.prefs.getBool('sfx_enabled') ?? true;
  bool get _isVibrationEnabled => _storage.prefs.getBool('vibration_enabled') ?? true;

  /// Preload sound assets and initialize audio pools and BGM engine.
  Future<SoundService> init() async {
    try {
      _storageService = Get.find<StorageService>();

      // Initialize Flame BGM engine
      await FlameAudio.bgm.initialize();

      // Preload audio assets into Flame audioCache
      await FlameAudio.audioCache.loadAll([
        'eat_apple.mp3',
        'game_over.mp3',
        'level_complete.mp3',
        'level_up.mp3',
        'button_tap.mp3',
        'bg_music.mp3',
        'Dark_Background.mp3',
        'Heal.mp3',
        'Heartbeat.mp3',
        'infection_pulse.mp3',
        'Memory-Ambient.mp3',
        'camera-flash.mp3',
        'laser.mp3',
        'warning-beep.mp3',
        'LaserDeath.mp3',
        'Flamethrower.mp3',
        'rain.mp3',
        'thunderstorm.mp3',
        'dark_synth.mp3',
      ]);

      // Create Flame AudioPool instances with strictly limited maxPlayers
      // to avoid exceeding Android SoundPool limit (max 32 streams).
      _eatApplePool = await FlameAudio.createPool('eat_apple.mp3', minPlayers: 1, maxPlayers: 2);
      _buttonTapPool = await FlameAudio.createPool('button_tap.mp3', minPlayers: 1, maxPlayers: 1);
      _gameOverPool = await FlameAudio.createPool('game_over.mp3', minPlayers: 1, maxPlayers: 1);
      _levelCompletePool = await FlameAudio.createPool('level_complete.mp3', minPlayers: 1, maxPlayers: 1);
      _levelUpPool = await FlameAudio.createPool('level_up.mp3', minPlayers: 1, maxPlayers: 1);
      _infectionPulsePool = await FlameAudio.createPool('infection_pulse.mp3', minPlayers: 1, maxPlayers: 1);
      _healPool = await FlameAudio.createPool('Heal.mp3', minPlayers: 1, maxPlayers: 1);
      _heartbeatPool = await FlameAudio.createPool('Heartbeat.mp3', minPlayers: 1, maxPlayers: 1);
      _cameraFlashPool = await FlameAudio.createPool('camera-flash.mp3', minPlayers: 1, maxPlayers: 1);
      _warningBeepPool = await FlameAudio.createPool('warning-beep.mp3', minPlayers: 1, maxPlayers: 1);
      _laserPool = await FlameAudio.createPool('laser.mp3', minPlayers: 1, maxPlayers: 2);
      _laserDeathPool = await FlameAudio.createPool('LaserDeath.mp3', minPlayers: 1, maxPlayers: 1);
      _flamethrowerPool = await FlameAudio.createPool('Flamethrower.mp3', minPlayers: 1, maxPlayers: 1);
      _thunderstormPool = await FlameAudio.createPool('thunderstorm.mp3', minPlayers: 1, maxPlayers: 1);

      _initialized = true;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SoundService.init error: $e\n$stack');
      }
    }
    return this;
  }

  /// Play the thunderstorm sound effect and trigger heavy haptic vibration during lightning.
  void playThunderstorm() {
    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.heavyImpact();
      });
      // Double rumble for thunder aftershock
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_isVibrationEnabled) {
          HapticFeedback.mediumImpact();
        }
      });
    }
    if (!_initialized || !_isSfxEnabled) return;
    final now = DateTime.now();
    if (_lastThunderstormTime != null && now.difference(_lastThunderstormTime!).inMilliseconds < 1000) {
      return;
    }
    _lastThunderstormTime = now;
    try {
      if (_thunderstormPool != null) {
        _thunderstormPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('thunderstorm.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the camera flash sound effect when the body reveals in Blind Memory mode.
  void playCameraFlash() {
    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.mediumImpact();
      });
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_cameraFlashPool != null) {
        _cameraFlashPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('camera-flash.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the laser warning beep SFX (with 300ms debounce).
  void playLaserWarning() {
    if (!_initialized || !_isSfxEnabled) return;
    final now = DateTime.now();
    if (_lastWarningBeepTime != null && now.difference(_lastWarningBeepTime!).inMilliseconds < 300) {
      return;
    }
    _lastWarningBeepTime = now;
    if (_isVibrationEnabled) {
      scheduleMicrotask(() => HapticFeedback.mediumImpact());
    }
    try {
      if (_warningBeepPool != null) {
        _warningBeepPool!.start(volume: 0.9);
      } else {
        FlameAudio.play('warning-beep.mp3', volume: 0.9);
      }
    } catch (_) {}
  }

  /// Play the laser beam firing / slicing SFX (with 300ms debounce).
  void playLaserBeam() {
    if (!_initialized || !_isSfxEnabled) return;
    final now = DateTime.now();
    if (_lastLaserTime != null && now.difference(_lastLaserTime!).inMilliseconds < 300) {
      return;
    }
    _lastLaserTime = now;
    if (_isVibrationEnabled) {
      scheduleMicrotask(() => HapticFeedback.heavyImpact());
    }
    try {
      if (_laserPool != null) {
        _laserPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('laser.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the laser death SFX when snake head is vaporized (2.0s debounce).
  void playLaserDeath() {
    if (!_initialized || !_isSfxEnabled) return;
    final now = DateTime.now();
    if (_lastLaserDeathTime != null && now.difference(_lastLaserDeathTime!).inMilliseconds < 2000) {
      return;
    }
    _lastLaserDeathTime = now;
    if (_isVibrationEnabled) {
      scheduleMicrotask(() => HapticFeedback.heavyImpact());
    }
    try {
      if (_laserDeathPool != null) {
        _laserDeathPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('LaserDeath.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Start playing continuous ambient rain sound for Storm / Blind Memory mode.
  Future<void> playMemoryBgMusic() => playRainBgMusic();

  /// Start playing continuous ambient rain sound.
  Future<void> playRainBgMusic() async {
    if (!_initialized) return;
    try {
      final storage = Get.find<StorageService>();
      final bgMusicEnabled = storage.prefs.getBool('bg_music_enabled') ?? true;
      if (!bgMusicEnabled) return;
      await FlameAudio.bgm.play('rain.mp3', volume: 0.7);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SoundService.playRainBgMusic error: $e\n$stack');
      }
    }
  }

  /// Play the infection pulse sound effect.
  void playInfectionPulse() {
    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.heavyImpact();
      });
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_infectionPulsePool != null) {
        _infectionPulsePool!.start(volume: 0.9);
      } else {
        FlameAudio.play('infection_pulse.mp3', volume: 0.9);
      }
    } catch (_) {}
  }

  /// Play the flamethrower pulse sound effect for level 40.
  void playFlamethrower() {
    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.heavyImpact();
      });
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_flamethrowerPool != null) {
        _flamethrowerPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('Flamethrower.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the heal sound effect when eating an apple in Infection mode.
  void playHeal() {
    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.lightImpact();
      });
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_healPool != null) {
        _healPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('Heal.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play heartbeat audio pulse effect.
  void playHeartbeat({double volume = 0.8}) {
    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.selectionClick();
      });
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_heartbeatPool != null) {
        _heartbeatPool!.start(volume: volume);
      } else {
        FlameAudio.play('Heartbeat.mp3', volume: volume);
      }
    } catch (_) {}
  }

  /// Start playing dark background music for Infection mode.
  Future<void> playInfectionBgMusic() async {
    if (!_initialized) return;
    try {
      final storage = Get.find<StorageService>();
      final bgMusicEnabled = storage.prefs.getBool('bg_music_enabled') ?? true;
      if (!bgMusicEnabled) return;
      await FlameAudio.bgm.play('Dark_Background.mp3', volume: 0.5);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SoundService.playInfectionBgMusic error: $e\n$stack');
      }
    }
  }

  /// Start playing dark synth background music for Meltdown mode.
  Future<void> playMeltdownBgMusic() async {
    if (!_initialized) return;
    try {
      final storage = Get.find<StorageService>();
      final bgMusicEnabled = storage.prefs.getBool('bg_music_enabled') ?? true;
      if (!bgMusicEnabled) return;
      await FlameAudio.bgm.play('dark_synth.mp3', volume: 0.5);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SoundService.playMeltdownBgMusic error: $e\n$stack');
      }
    }
  }

  /// Play the eat-apple sound effect & trigger light haptic vibration.
  void playEatApple() {
    if (!_initialized || !_isSfxEnabled) return;
    final now = DateTime.now();
    // 50ms debounce
    if (_lastEatAppleTime != null && now.difference(_lastEatAppleTime!).inMilliseconds < 50) {
      return;
    }
    _lastEatAppleTime = now;

    if (_isVibrationEnabled) {
      scheduleMicrotask(() {
        HapticFeedback.lightImpact();
      });
    }
    try {
      if (_eatApplePool != null) {
        _eatApplePool!.start(volume: 0.8);
      } else {
        FlameAudio.play('eat_apple.mp3', volume: 0.8);
      }
    } catch (_) {}
  }

  /// Play the game-over sound effect & trigger heavy haptic collision vibration (2.0s debounce).
  void playGameOver() {
    if (!_initialized || !_isSfxEnabled) return;
    final now = DateTime.now();
    if (_lastGameOverTime != null && now.difference(_lastGameOverTime!).inMilliseconds < 2000) {
      return;
    }
    _lastGameOverTime = now;

    if (_isVibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    try {
      if (_gameOverPool != null) {
        _gameOverPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('game_over.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the level-complete celebration sound & trigger medium haptic vibration.
  void playLevelComplete() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_levelCompletePool != null) {
        _levelCompletePool!.start(volume: 1.0);
      } else {
        FlameAudio.play('level_complete.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the level-up celebration sound & trigger heavy haptic vibration.
  void playLevelUp() {
    if (_isVibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (!_initialized || !_isSfxEnabled) return;
    try {
      if (_levelUpPool != null) {
        _levelUpPool!.start(volume: 1.0);
      } else {
        FlameAudio.play('level_up.mp3', volume: 1.0);
      }
    } catch (_) {}
  }

  /// Play the UI-button-tap sound effect (with 150ms debounce).
  void playButtonTap() {
    if (!_initialized || !_isSfxEnabled) return;

    final now = DateTime.now();
    if (_lastButtonTapTime != null && now.difference(_lastButtonTapTime!).inMilliseconds < 150) {
      return;
    }
    _lastButtonTapTime = now;

    try {
      if (_buttonTapPool != null) {
        _buttonTapPool!.start(volume: 0.5);
      } else {
        FlameAudio.play('button_tap.mp3', volume: 0.5);
      }
    } catch (_) {}
  }

  /// Alias for playButtonTap
  void playButtonClick() => playButtonTap();

  // --- Background music ---

  /// Start looping background music (if enabled in settings).
  Future<void> playBgMusic() async {
    if (!_initialized) return;
    try {
      final storage = Get.find<StorageService>();
      final bgMusicEnabled = storage.prefs.getBool('bg_music_enabled') ?? true;
      if (!bgMusicEnabled) return;
      await FlameAudio.bgm.play('bg_music.mp3', volume: 0.4);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SoundService.playBgMusic error: $e\n$stack');
      }
    }
  }

  /// Stop background music.
  Future<void> stopBgMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  /// Pause background music.
  Future<void> pauseBgMusic() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  /// Resume background music (if enabled in settings).
  Future<void> resumeBgMusic() async {
    try {
      final storage = Get.find<StorageService>();
      final bgMusicEnabled = storage.prefs.getBool('bg_music_enabled') ?? true;
      if (!bgMusicEnabled) return;
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  @override
  void onClose() {
    try {
      _eatApplePool?.dispose();
      _buttonTapPool?.dispose();
      _gameOverPool?.dispose();
      _levelCompletePool?.dispose();
      _levelUpPool?.dispose();
      _infectionPulsePool?.dispose();
      _healPool?.dispose();
      _heartbeatPool?.dispose();
      _cameraFlashPool?.dispose();
      _warningBeepPool?.dispose();
      _laserPool?.dispose();
      _laserDeathPool?.dispose();
      _flamethrowerPool?.dispose();
      _thunderstormPool?.dispose();
      FlameAudio.bgm.dispose();
    } catch (_) {}
    super.onClose();
  }
}
