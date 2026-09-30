import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:get/get.dart';
import 'package:snake_game/app/routes/app_routes.dart';
import 'package:snake_game/features/game/components/pear_component.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../services/game_sound_dispatcher.dart';
import '../../../services/storage_service.dart';
import '../../../services/api_service.dart';
import '../../../services/game_event_logger.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../daily_mission/controllers/daily_mission_controller.dart';
import '../../levels/data/levels_data.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../../cosmetics/controllers/cosmetics_controller.dart';
import '../../cosmetics/models/cosmetics_models.dart';
import 'snake_component.dart';
import 'food_component.dart';
import 'obstacle_component.dart';
import 'crab_component.dart';
import 'casual_power_up_component.dart';
import 'casual_mission_manager.dart';
import '../models/casual_mode_models.dart';
import '../models/board_skin.dart';
import '../models/snake_skin.dart';
import '../utils/game_mechanics_rng.dart';
import '../models/game_particles.dart';
import 'entities/parasite_worm.dart';
import '../rendering/board_background_renderer.dart';
import '../rendering/snake_canvas_renderer.dart';
import '../services/game_session_coordinator.dart';
import '../modes/base_game_mode_handler.dart';
import '../modes/level_mode_handler.dart';
import '../modes/classic_mode_handler.dart';
import '../modes/casual_mode_handler.dart';
import '../modes/laser_mode_handler.dart';
import '../modes/meltdown_mode_handler.dart';
import '../modes/crab_chase_handler.dart';
import '../modes/infection_mode_handler.dart';
import '../modes/blind_memory_handler.dart';

/// The core Flame game engine for Snake.
///
/// Supports both Level Mode and Classic (Endless) Mode.
class SnakeGame extends FlameGame {
  // --- Game components ---
  final SnakeComponent snake = SnakeComponent();
  final FoodComponent food = FoodComponent();
  final ObstacleComponent obstacles = ObstacleComponent();
  final PearComponent pear = PearComponent();
  final CrabComponent crab = CrabComponent();
  final CasualPowerUpComponent casualPowerUp = CasualPowerUpComponent();
  final CasualMissionManager casualMissionManager = CasualMissionManager();

  // --- Game Mode ---
  final Rx<GameMode> gameMode = GameMode.level.obs;

  // --- Casual Mode State ---
  final Rx<PowerUpType?> casualActivePowerUp = Rx<PowerUpType?>(null);
  final RxDouble casualPowerUpTimeRemaining = 0.0.obs;
  final RxInt casualLives = 3.obs;
  static const int maxCasualLives = 3;

  // --- Daily Mission & Challenge & League ---
  bool isDailyMission = false;
  bool isLeagueAttempt = false;
  final RxInt leagueAttemptsRemaining = (-1).obs;
  final RxBool canPlayLeagueAttempt = true.obs;
  int? dailyMissionId;
  int dailyMissionAttempt = 1;
  String dailyMissionType = 'eat_count';
  int dailyMissionTarget = 50;
  int dailyMissionReward = 50;
  final RxBool isDailyMissionCompleted = false.obs;
  bool get isDailyChallenge => isDailyMission;
  set isDailyChallenge(bool val) => isDailyMission = val;
  int? get dailyChallengeId => dailyMissionId;
  set dailyChallengeId(int? val) => dailyMissionId = val;
  bool? isAdRetry;
  int? gameSeed;
  Future<bool>? sessionStartFuture;
  bool _firstTickLogged = false;
  void Function(int level)? onBossIntroRequested;
  GameMechanicsRng? _mechanicsRng;
  GameMechanicsRng get mechanicsRng {
    _mechanicsRng ??= GameMechanicsRng(seed: isDailyMission ? gameSeed : null);
    return _mechanicsRng!;
  }

  // --- Strategy Pattern Mode Handler ---
  BaseGameModeHandler? _modeHandler;

  int get appleTarget => _appleTarget;
  void triggerLevelComplete() => _levelComplete();
  void triggerGameOver(GameOverReason reason) => _gameOver(reason);
  void triggerSnakeSliced(List<GridPos> cutSegments) => _onSnakeSliced(cutSegments);

  int get speed => _speed;
  set speed(int value) => _speed = value;

  void triggerEatEffect() => _playEatEffect();
  void triggerShake() => _triggerShake();
  void triggerConsumeFood() => _consumeFood();
  void spawnSliceParticles(List<GridPos> cutSegments) => _spawnSliceParticles(cutSegments);

  void logPearEaten(int bonusScore) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('pear_eaten', {
        'bonus_awarded': bonusScore,
        'current_score': score.value,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });
    }
  }

  void logLifeLost(int remainingLives) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('life_lost', {
        'remaining_lives': remainingLives,
      });
    }
  }

  void logSnakeCut(int cutSegmentsCount, int remainingLength) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('snake_cut', {
        'cut_segments_count': cutSegmentsCount,
        'remaining_length': remainingLength,
      });
    }
  }

  void logPowerUpCollected(String name, double duration) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('power_up_collected', {
        'type': name,
        'duration': duration,
      });
    }
  }

  void logRainAppleEaten(int pts) {
    if (Get.isRegistered<GameEventLogger>()) {
      final streak = (_modeHandler is CasualModeHandler)
          ? (_modeHandler as CasualModeHandler).casualStreak
          : 0;
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': pts,
        'current_score': score.value,
        'is_rain_apple': true,
        'speed_ms': (casualPowerUp.isTurboActive
            ? (_speed / CasualModeConfig.turboSpeedMultiplier).round()
            : _speed),
        'snake_length': snake.segments.length,
        'streak': streak,
        'active_powerup': 'appleRain',
      });
    }
  }

  void logCasualMissionCompleted(CasualMission mission) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('casual_mission_completed', {
        'mission_id': mission.id,
        'mission_type': mission.type.name,
        'target': mission.target,
        'reward_coins': mission.rewardCoins,
      });
    }
  }

  void logLaserSpawned({
    required int row,
    required int col,
    required double warningDuration,
  }) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('laser_spawned', {
        'row': row,
        'col': col,
        'warning_duration': warningDuration,
        'score_at_time': score.value,
      });
    }
  }

  void logCraterSpawned({required int row, required int col}) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('crater_spawned', {
        'row': row,
        'col': col,
        'score_at_time': score.value,
      });
    }
  }

  void logInfectionTick({
    required double infectionRatio,
    required double currentInterval,
    required int snakeLength,
  }) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('infection_tick', {
        'infection_ratio': infectionRatio,
        'tick_interval_sec': currentInterval,
        'snake_length': snakeLength,
      });
    }
  }

  void logParasiteAttached(int elapsedSec) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('parasite_attached', {
        'elapsed_sec': elapsedSec,
        'snake_length': snake.segments.length,
      });
    }
  }

  void logThunderstormTriggered(double durationSec) {
    if (Get.isRegistered<GameEventLogger>()) {
      Get.find<GameEventLogger>().logEvent('thunderstorm_triggered', {
        'duration_sec': durationSec,
        'score_at_time': score.value,
      });
    }
  }

  // --- Dynamic Grid Dimensions (Square 20x20) ---
  int _gridCols = kGridSize;
  int _gridRows = kGridSize;
  double _cellSize = 20;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _dimensionsInitialized = false;

  // --- Performance optimization: Cached Background Picture & Paints ---
  final BoardBackgroundRenderer _backgroundRenderer = BoardBackgroundRenderer();

  // --- Rendering Pipeline Delegation ---
  late final SnakeCanvasRenderer _canvasRenderer = SnakeCanvasRenderer(this);

  // --- Read-only accessors for SnakeCanvasRenderer and Mode Handlers ---
  int get gridCols => _gridCols;
  int get gridRows => _gridRows;
  double get cellSize => _cellSize;
  double get offsetX => _offsetX;
  double get offsetY => _offsetY;
  double get gameTime => _gameTime;
  double get effectiveMoveInterval => _effectiveMoveInterval;
  double get moveAccumulator => _moveAccumulator;
  int get elapsedTimeInSeconds => _elapsedTime;
  Offset getSnakeTailWorldPos() => _getSnakeTailWorldPos();

  ParasiteWorm? get parasite =>
      (_modeHandler is InfectionModeHandler)
          ? (_modeHandler as InfectionModeHandler).parasite
          : null;
  bool get parasiteAttached =>
      (_modeHandler is InfectionModeHandler)
          ? (_modeHandler as InfectionModeHandler).parasiteAttached
          : false;

  double get meltdownAppleTimer =>
      (_modeHandler is MeltdownModeHandler)
          ? (_modeHandler as MeltdownModeHandler).appleTimer
          : 5.0;
  double get meltdownMaxTimer => MeltdownModeHandler.maxTimer;
  List<ExplosionEffect> get explosions =>
      (_modeHandler is MeltdownModeHandler)
          ? (_modeHandler as MeltdownModeHandler).explosions
          : const [];

  List<RainDrop> get rainDrops =>
      (_modeHandler is BlindMemoryHandler)
          ? (_modeHandler as BlindMemoryHandler).rainDrops
          : const [];
  List<List<Offset>> get lightningBranches =>
      (_modeHandler is BlindMemoryHandler)
          ? (_modeHandler as BlindMemoryHandler).lightningBranches
          : const [];
  double get flashTimer =>
      (_modeHandler is BlindMemoryHandler)
          ? (_modeHandler as BlindMemoryHandler).flashTimer
          : 0.0;

  // --- Continuous game time accumulator (replaces DateTime.now() in hot render paths) ---
  double _gameTime = 0.0;

  // --- Audio & Haptic Dispatcher ---
  final GameSoundDispatcher _soundDispatcher = GameSoundDispatcher();
  GameSoundDispatcher get sound => _soundDispatcher;
  GameSoundDispatcher get soundDispatcher => _soundDispatcher;

  // --- Session & Score Submission Coordinator ---
  final GameSessionCoordinator _sessionCoordinator = GameSessionCoordinator();

  SnakeSkin? _cachedSkin;
  SnakeSkin get currentSkin {
    if (_cachedSkin == null) {
      _resolveSkin();
    }
    return _cachedSkin!;
  }

  void _resolveSkin() {
    CosmeticSnakeSkin? activeCosmetic;
    if (Get.isRegistered<CosmeticsController>()) {
      activeCosmetic = Get.find<CosmeticsController>().activeSkin.value;
    }
    if (activeCosmetic != null) {
      _cachedSkin = SnakeSkin.fromCosmetic(activeCosmetic);
    } else {
      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;
      final savedSkinId = storage?.getSelectedSkinId() ?? 'neon_green';
      _cachedSkin = SnakeSkin(
        id: savedSkinId,
        name: 'Emerald Neon',
        headColor: const Color(0xFF69F0AE),
        tailColor: const Color(0xFF004D40),
        glowColor: const Color(0xFF00E676),
      );
    }
  }

  BoardSkin? _cachedBoardSkin;
  BoardSkin get currentBoardSkin {
    if (_cachedBoardSkin == null) {
      _resolveBoardSkin();
    }
    return _cachedBoardSkin!;
  }

  void _resolveBoardSkin() {
    final cosmetics = Get.isRegistered<CosmeticsController>()
        ? Get.find<CosmeticsController>()
        : null;
    final activeTheme = cosmetics?.activeTheme.value;
    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    final themeKey =
        activeTheme?.themeKey ?? storage?.getSelectedBoardSkinId() ?? 'default';
    final modeKey = BoardSkins.getModeKey(gameMode.value);
    final cachedPath = cosmetics?.getCachedThemeAssetPath(themeKey, modeKey);

    _cachedBoardSkin = BoardSkins.getSkinForThemeAndMode(
      themeKey: themeKey,
      mode: gameMode.value,
      cosmeticTheme: activeTheme,
      cachedImagePath: cachedPath,
    );
  }

  void refreshSkin() {
    _resolveSkin();
    refreshBoardSkin();
  }

  void refreshBoardSkin() {
    _resolveBoardSkin();
    _backgroundRenderer.invalidate();
  }

  // --- Level & Game state ---
  bool isIntroWaiting = false;
  int currentLevel = 1;
  int _speed = 400; // ms between moves
  int _timeLimit = 120; // seconds
  int _appleTarget = kAppleTarget;
  int applesEaten = 0;
  int _elapsedTime = 0;

  /// Effective movement interval in seconds, taking active speed modifiers into account.
  double get _effectiveMoveInterval {
    double spd = _speed.toDouble();
    if (_modeHandler != null) {
      spd = _modeHandler!.modifySpeed(spd);
    }
    return spd / 1000.0;
  }

  // --- Infection Mode state ---
  final RxDouble infectionRatio = 0.0.obs;

  // --- Blind Memory / Storm Mode state ---
  final RxDouble memoryBodyOpacity = 1.0.obs;
  final RxBool isFlashActive = false.obs;

  // --- Boss Battles & Laser Mode state ---
  final RxBool isBossLevelRx = false.obs;
  final RxString bossNameKey = ''.obs;
  final RxInt warningLaserRow = (-1).obs;
  final RxInt warningLaserCol = (-1).obs;
  final RxInt activeLaserRow = (-1).obs;
  final RxInt activeLaserCol = (-1).obs;
  final RxDouble shockwaveRadius = (-1.0).obs;
  final List<BossBullet> bullets = [];

  final List<SlicedParticle> slicedParticles = [];
  final List<FloatingTextParticle> floatingTexts = [];

  // --- Accumulator-based movement ---
  double _moveAccumulator = 0;

  // --- Timer state ---
  int _timeRemaining = 120;
  Timer? _gameTimer;
  Timer? _shakeTimer;

  // --- Reactive state (GetX) ---
  final Rx<GameStatus> gameStatus = GameStatus.idle.obs;
  final RxInt score = 0.obs;
  final RxBool isNewHighscore = false.obs;
  final RxInt earnedXp = 0.obs;
  final RxInt applesCount = 0.obs;
  final RxInt appleTargetRx = 10.obs;
  final RxInt pearsCount = 0.obs;
  final RxInt pearScore = 0.obs;
  final RxInt timeRemaining = 120.obs;
  final RxInt elapsedTime = 0.obs;
  final RxInt currentLevelRx = 1.obs;

  // --- Visual effects ---
  final RxDouble shakeOffsetX = 0.0.obs;
  final RxDouble shakeOffsetY = 0.0.obs;
  final RxBool showEatEffect = false.obs;
  final RxBool showLevelComplete = false.obs;
  final Rx<GameOverReason?> gameOverReason = Rx<GameOverReason?>(null);
  final Rx<LeagueScoreResult?> leagueResult = Rx<LeagueScoreResult?>(null);

  // --- Coin Rewards & Missions ---
  final RxInt optimisticCasualCoins = 0.obs;
  final RxBool levelCoinAwarded = false.obs;
  final RxInt levelCoinsAwarded = 0.obs;

  // --- Direction input buffer ---
  final List<Direction> _inputQueue = [];

  // ---------------------------------------------------------------------------
  // Rendering – draw square grid, obstacles, snake, food directly on Flame canvas.
  // ---------------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await crab.loadAssets(this);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    final double boardSide = min(size.x, size.y);
    final double newCellSize = boardSide / kGridSize;
    final int newGridCols = kGridSize;
    final int newGridRows = kGridSize;

    if (newGridCols != _gridCols ||
        newGridRows != _gridRows ||
        (newCellSize - _cellSize).abs() > 0.01 ||
        !_dimensionsInitialized) {
      _gridCols = newGridCols;
      _gridRows = newGridRows;
      _cellSize = newCellSize;
      _offsetX = (size.x - boardSide) / 2;
      _offsetY = (size.y - boardSide) / 2;

      _dimensionsInitialized = true;

      _updateCachedBackground(size);
    } else if (!_backgroundRenderer.hasCache) {
      _updateCachedBackground(size);
    }
  }

  void _updateCachedBackground(Vector2 size) {
    _backgroundRenderer.updateCache(
      size: size,
      boardSkin: currentBoardSkin,
      gridCols: _gridCols,
      gridRows: _gridRows,
      cellSize: _cellSize,
      offsetX: _offsetX,
      offsetY: _offsetY,
    );
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    if (!_backgroundRenderer.hasCache) {
      _updateCachedBackground(size);
    }
    _backgroundRenderer.render(canvas);

    _canvasRenderer.render(canvas);
  }

  void _onSnakeSliced(List<GridPos> cutSegments) {
    if (cutSegments.isEmpty) return;

    // 1. Spawn particle explosion animation
    _spawnSliceParticles(cutSegments);

    // 2. Reduce eaten apples count (each cut segment decreases apple progress)
    applesEaten = max(0, applesEaten - cutSegments.length);
    applesCount.value = applesEaten;

    // 3. Deduct score (25 points per segment sliced in Laser & Crab Chase modes)
    int penalty = 0;
    if (gameMode.value == GameMode.laser ||
        gameMode.value == GameMode.crabChase) {
      penalty = cutSegments.length * 25;
    } else {
      penalty = cutSegments.length * 20;
    }

    score.value = max(0, score.value - penalty);

    // 4. Log event for backend anti-cheat validation
    if (gameMode.value == GameMode.laser) {
      Get.find<GameEventLogger>().logEvent('laser_hit', {
        'penalty': penalty,
        'cut_segments_count': cutSegments.length,
        'current_score': score.value,
      });
    } else if (gameMode.value == GameMode.crabChase) {
      Get.find<GameEventLogger>().logEvent('crab_hit', {
        'penalty': penalty,
        'cut_segments_count': cutSegments.length,
        'current_score': score.value,
      });
    }

    // 5. Spawn floating red penalty text animation
    final slicePos = cutSegments.first;
    floatingTexts.add(
      FloatingTextParticle(
        text: '-$penalty',
        x: slicePos.x.toDouble() + 0.5,
        y: slicePos.y.toDouble() + 0.5,
        color: const Color(0xFFFF1744),
        vy: -1.5,
      ),
    );

    // 6. Trigger screen shake and laser beam SFX
    _triggerShake();
    sound.playLaserBeam();
  }

  void _spawnSliceParticles(List<GridPos> cutSegments) {
    final rand = Random();
    final colors = [
      const Color(0xFFFF1744),
      const Color(0xFFFF9100),
      const Color(0xFFFFD700),
      Colors.white,
    ];

    for (final seg in cutSegments) {
      final cx = seg.x.toDouble();
      final cy = seg.y.toDouble();
      for (int i = 0; i < 9; i++) {
        final angle = rand.nextDouble() * 2 * pi;
        final speed = rand.nextDouble() * 7.0 + 3.0;
        slicedParticles.add(
          SlicedParticle(
            x: cx + 0.5,
            y: cy + 0.5,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            radius: rand.nextDouble() * 2.5 + 2.0,
            color: colors[rand.nextInt(colors.length)],
            maxLife: 0.45 + rand.nextDouble() * 0.2,
          ),
        );
      }
    }
  }

  Future<bool> _startSessionEventLogger(String mode) async {
    final auth = Get.find<AuthController>();

    // For Guests: Start immediately without backend session
    if (!auth.isLoggedIn.value || auth.currentUser.value == null) {
      debugPrint(
        '[SnakeGame] Guest mode active: Playing locally in practice mode.',
      );
      return true;
    }

    debugPrint(
      '[SnakeGame] 🎮 _startSessionEventLogger: mode=$mode, isDailyChallenge=$isDailyChallenge, dailyChallengeId=$dailyChallengeId',
    );

    // Start logger session asynchronously in background for ALL modes (including Daily Challenge)
    // so gameplay starts instantly without freezing or blocking on network latency/timeouts.
    sessionStartFuture = Future<bool>(() async {
      try {
        final logger = Get.find<GameEventLogger>();
        final started = await logger
            .startSession(
              mode,
              dailyChallengeId: dailyChallengeId,
              isAdRetry: isAdRetry,
            )
            .timeout(const Duration(seconds: 4));
        debugPrint(
          '[SnakeGame] 📡 Network session started: $started (mode: $mode, isDailyChallenge: $isDailyChallenge, isLeague: $isLeagueAttempt)',
        );
        return started;
      } catch (e) {
        debugPrint(
          '[SnakeGame] ⚠️ Network session start timed out or failed: $e',
        );
        return false;
      }
    });

    return true;
  }

  /// Initialize Classic (Endless) Mode.
  Future<void> initClassic() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.classic;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 220; // initial speed in ms
    obstacles.loadFromLevelData([]); // No obstacles
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    snake.init(_gridCols, _gridRows);

    final classicHandler = ClassicModeHandler();
    _modeHandler = classicHandler;
    classicHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playBgMusic());
  }

  /// Initialize Casual Mode.
  Future<void> initCasual() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.casual;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 210; // Comfortable base speed in ms
    obstacles.loadFromLevelData([]); // No obstacles
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();

    final casualHandler = CasualModeHandler();
    _modeHandler = casualHandler;
    casualHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playBgMusic());
  }

  void _startGameOrWaitIntro({VoidCallback? onPlayBgm}) {
    final bool isWaiting = isIntroWaiting;
    debugPrint(
      '[SnakeGame] 🎮 _startGameOrWaitIntro: isWaiting=$isWaiting, isIntroWaiting=$isIntroWaiting, currentStatus=${gameStatus.value}',
    );

    if (isWaiting) {
      gameStatus.value = GameStatus.paused;
      _moveAccumulator = 0;
      pauseEngine();
      debugPrint(
        '[SnakeGame] ⏸️ Game paused waiting for intro dialog dismissal',
      );
      return;
    }

    gameStatus.value = GameStatus.playing;
    _moveAccumulator = 0;
    _startTimer();
    resumeEngine();
    debugPrint(
      '[SnakeGame] ▶️ Game started! gameStatus is now playing, engine resumed',
    );
    if (onPlayBgm != null) {
      onPlayBgm();
    } else {
      playModeBgm();
    }
  }

  /// Initialize Infection Mode.
  Future<void> initInfection() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.infection;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 190; // initial speed in ms
    obstacles.loadFromLevelData([]); // No obstacles
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    snake.init(_gridCols, _gridRows);

    final infectionHandler = InfectionModeHandler();
    _modeHandler = infectionHandler;
    infectionHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playInfectionBgMusic());
  }

  /// Initialize Blind Memory Mode.
  Future<void> initBlindMemory() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.blindMemory;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 190; // ms between moves
    obstacles.loadFromLevelData([]);
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();

    final blindHandler = BlindMemoryHandler();
    _modeHandler = blindHandler;
    blindHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playRainBgMusic());
  }

  /// Initialize Meltdown Mode.
  Future<void> initMeltdown() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.meltdown;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 220; // Initial speed
    obstacles.loadFromLevelData([]); // Clear obstacles
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    snake.init(_gridCols, _gridRows);

    final meltdownHandler = MeltdownModeHandler();
    _modeHandler = meltdownHandler;
    meltdownHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playMeltdownBgMusic());
  }

  /// Initialize Crab Chase Mode.
  Future<void> initCrabChase() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.crabChase;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 200; // Normal starting speed

    obstacles.loadFromLevelData([]); // No initial obstacles unless desired
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    // Start with a standard snake length (3)
    snake.init(_gridCols, _gridRows);

    final crabHandler = CrabChaseHandler();
    _modeHandler = crabHandler;
    crabHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
      pearPos: pear.position,
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playBgMusic());
  }

  /// Initialize Laser Mode.
  Future<void> initLaser() async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.laser;
    refreshSkin();
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    _elapsedTime = 0;
    elapsedTime.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    _inputQueue.clear();

    _speed = 190; // initial speed in ms
    obstacles.loadFromLevelData([]); // Clear obstacles
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    bullets.clear();
    slicedParticles.clear();
    floatingTexts.clear();

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();

    final laserHandler = LaserModeHandler();
    _modeHandler = laserHandler;
    laserHandler.onInit(this);

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playBgMusic());
  }

  void _cancelLaserTimers() {
    if (_modeHandler is LaserModeHandler) {
      (_modeHandler as LaserModeHandler).cancelTimers();
    }
    warningLaserRow.value = -1;
    warningLaserCol.value = -1;
    activeLaserRow.value = -1;
    activeLaserCol.value = -1;
  }

  void _cancelShockwaveTimer() {
    shockwaveRadius.value = -1.0;
  }

  void _cancelShakeTimer() {
    _shakeTimer?.cancel();
    _shakeTimer = null;
    shakeOffsetX.value = 0;
    shakeOffsetY.value = 0;
  }

  void _resetAccumulatorTimers() {
    _modeHandler?.onDestroy();
    _modeHandler = null;
    _gameTime = 0.0;
    _canvasRenderer.resetCache();
    _firstTickLogged = false;
  }

  void _cancelAllTimers() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _cancelLaserTimers();
    _cancelShockwaveTimer();
    _cancelShakeTimer();
    if (_modeHandler is LevelModeHandler) {
      (_modeHandler as LevelModeHandler).cancelTransientTimers();
    }
  }

  /// Initialize Level Mode for the given level.
  Future<void> initLevel(int level) async {
    _cancelAllTimers();
    _resetAccumulatorTimers();
    gameMode.value = GameMode.level;
    refreshSkin();
    currentLevel = level;
    currentLevelRx.value = level;
    applesEaten = 0;
    applesCount.value = 0;
    score.value = 0;
    isNewHighscore.value = false;
    gameOverReason.value = null;
    showLevelComplete.value = false;
    levelCoinAwarded.value = false;
    levelCoinsAwarded.value = 0;
    _inputQueue.clear();

    final levelData = gameLevels.firstWhere(
      (l) => l['level'] == level,
      orElse: () => gameLevels[0],
    );
    _speed = ((levelData['speed'] as int) * 0.5).round();
    _timeLimit = levelData['timeLimit'] as int;
    _appleTarget = levelData['appleTarget'] as int;
    appleTargetRx.value = _appleTarget;
    _timeRemaining = _timeLimit;
    timeRemaining.value = _timeLimit;
    pear.despawn();

    // Reset boss reactive state
    isBossLevelRx.value = levelData['isBoss'] == true;
    bossNameKey.value = levelData['bossNameKey'] ?? '';
    bullets.clear();

    if (isBossLevelRx.value) {
      onBossIntroRequested?.call(level);
    }

    obstacles.loadFromLevelData(levelData['obstacles'] as List<dynamic>);
    snake.init(_gridCols, _gridRows);

    final levelHandler = LevelModeHandler();
    _modeHandler = levelHandler;
    levelHandler.onInit(this);
    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
    );

    final started = await _startSessionEventLogger(gameMode.value.apiName);
    if (!started) return;

    _startGameOrWaitIntro(onPlayBgm: () => sound.playBgMusic());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameStatus.value != GameStatus.playing) return;

    // Cap excessive dt from lag spikes to avoid fast-forward teleport bursts
    final safeDt = dt.clamp(0.0, 0.1);
    _gameTime += safeDt;

    // Update Sliced Particles
    for (int i = slicedParticles.length - 1; i >= 0; i--) {
      final p = slicedParticles[i];
      p.life += safeDt;
      if (p.life >= p.maxLife) {
        slicedParticles.removeAt(i);
      } else {
        p.x += p.vx * safeDt;
        p.y += p.vy * safeDt;
      }
    }

    // Update Floating Text Particles
    for (int i = floatingTexts.length - 1; i >= 0; i--) {
      final ft = floatingTexts[i];
      ft.life += safeDt;
      if (ft.life >= ft.maxLife) {
        floatingTexts.removeAt(i);
      } else {
        ft.y += ft.vy * safeDt;
      }
    }

    // --- Mode Handler Update (e.g. LevelModeHandler, LaserModeHandler, etc.) ---
    _modeHandler?.update(safeDt);

    final moveInterval = _effectiveMoveInterval;
    _moveAccumulator += safeDt;

    while (_moveAccumulator >= moveInterval) {
      _moveAccumulator -= moveInterval;
      _gameTick();
      if (gameStatus.value != GameStatus.playing) break;
    }
  }

  void queueDirection(Direction dir) {
    if (_inputQueue.length >= 3) return;
    if (_inputQueue.isNotEmpty && _inputQueue.last == dir) return;
    _inputQueue.add(dir);
  }

  void _gameTick() {
    if (!_firstTickLogged) {
      _firstTickLogged = true;
      debugPrint(
        '[SnakeGame] 🐍 First _gameTick executed! Head: ${snake.head}, direction: ${snake.currentDirection}, status: ${gameStatus.value}',
      );
    }
    final Direction? queuedDir =
        _inputQueue.isNotEmpty ? _inputQueue.removeAt(0) : null;
    if (_modeHandler?.handleDirectionChange(queuedDir) != true) {
      if (queuedDir != null) {
        snake.changeDirection(queuedDir);
      }
    }

    snake.move(_gridCols, _gridRows);
    final head = snake.head;

    // Obstacle collision
    if (obstacles.occupiesPosition(head)) {
      _gameOver(GameOverReason.obstacleCollision);
      return;
    }

    // Self collision (delegated to mode handler if custom)
    if (_modeHandler?.checkCustomCollision(head) != true) {
      if (snake.checkSelfCollision()) {
        _gameOver(GameOverReason.selfCollision);
        return;
      }
    }

    // Mode-specific step processing (power-ups, rain apples, pears, etc.)
    _modeHandler?.onStep(head);

    // Food collision
    if (head == food.position) {
      _consumeFood();
    }
  }

  /// Handles all effects, scoring, mission progress, growth, and spawning when food is consumed.
  void _consumeFood() {
    snake.grow();
    applesEaten++;
    applesCount.value = applesEaten;

    int scoreBefore = score.value;
    _addScore();
    int scoreAwarded = score.value - scoreBefore;

    if (gameMode.value == GameMode.classic) {
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });
    } else if (gameMode.value == GameMode.blindMemory) {
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'is_flash_active': isFlashActive.value,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });
    } else if (gameMode.value == GameMode.laser) {
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'active_lasers':
            (activeLaserRow.value >= 0 || activeLaserCol.value >= 0) ? 1 : 0,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });
    } else if (gameMode.value == GameMode.crabChase) {
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });
    } else if (gameMode.value == GameMode.casual) {
      final streak = (_modeHandler is CasualModeHandler)
          ? (_modeHandler as CasualModeHandler).casualStreak
          : 0;
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'speed_ms': (casualPowerUp.isTurboActive
            ? (_speed / CasualModeConfig.turboSpeedMultiplier).round()
            : _speed),
        'snake_length': snake.segments.length,
        'streak': streak,
        'active_powerup': casualPowerUp.activePowerUp?.name,
      });
    }

    _playEatEffect();

    if (gameMode.value == GameMode.infection) {
      // Eating an apple strictly heals 1 single infected segment
      snake.healInfection(1);
      infectionRatio.value = snake.infectionRatio;

      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'infection_ratio': snake.infectionRatio,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });

      sound.playHeal();
    } else {
      sound.playEatApple();
    }

    if (gameMode.value == GameMode.meltdown) {
      final bonusAwarded = (_modeHandler is MeltdownModeHandler)
          ? (_modeHandler as MeltdownModeHandler).bonusAwarded
          : false;
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'seconds_remaining_on_timer': double.parse(
          meltdownAppleTimer.toStringAsFixed(2),
        ),
        'bonus_awarded': bonusAwarded,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });
    }

    if (isDailyMission) {
      if (dailyMissionType == 'eat_count' &&
          applesEaten >= dailyMissionTarget) {
        _dailyMissionComplete();
        return;
      } else if (dailyMissionType == 'score_threshold' &&
          score.value >= dailyMissionTarget) {
        _dailyMissionComplete();
        return;
      }
    }

    _modeHandler?.onFoodEaten(food.position);
    if (gameStatus.value == GameStatus.levelComplete) {
      return;
    }

    food.spawn(
      _gridCols,
      _gridRows,
      snake.segments,
      obstacles.obstacles,
      mechanicsRng.food ?? Random(),
      pearPos: pear.position,
    );
  }

  void _addScore() {
    // In Level Mode, apples do not award score points (only eaten count matters)
    if (gameMode.value == GameMode.level) {
      return;
    }

    final int addedPoints;
    final Color popupColor;

    final customScore = _modeHandler?.getScoreForFood();
    if (customScore != null) {
      addedPoints = customScore.points;
      popupColor = customScore.color;
    } else {
      // Fallback / Custom Mode
      addedPoints = 10;
      popupColor = const Color(0xFFFFD700); // Custom Theme Gold
    }

    score.value += addedPoints;

    floatingTexts.add(
      FloatingTextParticle(
        text: '+$addedPoints',
        x: food.position.x.toDouble() + 0.5,
        y: food.position.y.toDouble() + 0.5,
        color: popupColor,
      ),
    );

    if (isDailyMission &&
        dailyMissionType == 'score_threshold' &&
        score.value >= dailyMissionTarget) {
      _dailyMissionComplete();
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameStatus.value != GameStatus.playing) return;

      if (isDailyMission) {
        _elapsedTime++;
        elapsedTime.value = _elapsedTime;
        if (dailyMissionType == 'survive_time') {
          if (_elapsedTime >= dailyMissionTarget) {
            _dailyMissionComplete();
            return;
          }
        }
      } else if (gameMode.value == GameMode.classic ||
          gameMode.value == GameMode.infection ||
          gameMode.value == GameMode.blindMemory ||
          gameMode.value == GameMode.laser ||
          gameMode.value == GameMode.meltdown ||
          gameMode.value == GameMode.crabChase ||
          gameMode.value == GameMode.casual) {
        _elapsedTime++;
        elapsedTime.value = _elapsedTime;
        if (gameMode.value == GameMode.blindMemory) {
          // Add survival time bonus
          score.value += 1;
        }
      } else {
        _timeRemaining--;
        timeRemaining.value = _timeRemaining;
        if (_timeRemaining <= 0) {
          if (_modeHandler?.onTimeExpired() == true) {
            // Handled by active mode handler (e.g. survival boss complete)
          } else {
            _gameOver(GameOverReason.timerExpired);
          }
        }
      }
    });
  }

  void _dailyMissionComplete() {
    if (gameStatus.value == GameStatus.gameOver ||
        gameStatus.value == GameStatus.levelComplete ||
        isDailyMissionCompleted.value) {
      return;
    }
    _cancelAllTimers();
    isDailyMissionCompleted.value = true;
    gameStatus.value = GameStatus.levelComplete;
    showLevelComplete.value = true;
    sound.playLevelComplete();
    sound.stopBgMusic();

    if (Get.isRegistered<DailyMissionController>()) {
      final missionController = Get.find<DailyMissionController>();
      final int rawStat = (dailyMissionType == 'survive_time')
          ? elapsedTime.value
          : (dailyMissionType == 'eat_count' ? applesEaten : score.value);
      final effectiveId = (dailyMissionId != null && dailyMissionId! > 0)
          ? dailyMissionId
          : missionController.currentMission.value?.id;

      debugPrint(
        '[SnakeGame] 🎯 _dailyMissionComplete Submit -> effectiveId: $effectiveId | rawStat: $rawStat | type: $dailyMissionType',
      );

      missionController.submitMission(rawStat, missionId: effectiveId).then((
        res,
      ) {
        if (res != null && res.isCompleted) {
          Get.snackbar(
            '🎉 ${'daily_mission_completed'.tr}!',
            'daily_mission_coins_reward'.trParams({
              'count': '${res.rewardCoins}',
            }),
            backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.95),
            colorText: Colors.black,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            icon: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.black,
            ),
          );
        }
      });
    }
  }

  void _levelComplete() {
    _cancelAllTimers();
    gameStatus.value = GameStatus.levelComplete;
    showLevelComplete.value = true;
    sound.playLevelComplete();
    sound.stopBgMusic();

    _sessionCoordinator.handleLevelComplete(
      currentLevel: currentLevel,
      applesEaten: applesEaten,
      earnedXp: earnedXp,
      levelCoinAwarded: levelCoinAwarded,
      levelCoinsAwarded: levelCoinsAwarded,
    );
  }

  void _gameOver(GameOverReason reason) {
    debugPrint(
      '💀 [SnakeGame] _gameOver called! reason=${reason.apiReason}, gameMode=${gameMode.value}',
    );
    if (gameStatus.value == GameStatus.gameOver ||
        gameStatus.value == GameStatus.levelComplete) {
      return;
    }
    _cancelAllTimers();
    _modeHandler?.onGameOver();
    gameStatus.value = GameStatus.gameOver;
    gameOverReason.value = reason;

    if (reason == GameOverReason.laserHeadHit) {
      sound.playLaserDeath();
    } else {
      sound.playGameOver();
    }
    sound.stopBgMusic();
    _triggerShake();

    _sessionCoordinator.handleGameOver(
      reason: reason,
      gameMode: gameMode.value,
      score: score.value,
      applesEaten: applesEaten,
      elapsedTimeSec: _elapsedTime,
      isDailyMission: isDailyMission,
      dailyMissionId: dailyMissionId,
      dailyMissionType: dailyMissionType,
      isLeagueAttempt: isLeagueAttempt,
      sessionStartFuture: sessionStartFuture,
      isNewHighscore: isNewHighscore,
      earnedXp: earnedXp,
      leagueResult: leagueResult,
      leagueAttemptsRemaining: leagueAttemptsRemaining,
      canPlayLeagueAttempt: canPlayLeagueAttempt,
      optimisticCasualCoins: optimisticCasualCoins,
    );
  }

  void pauseGame() {
    if (gameStatus.value != GameStatus.playing) return;
    gameStatus.value = GameStatus.paused;
    _cancelAllTimers();
    pauseEngine();
    _soundDispatcher.pauseBgMusic();
  }

  void resumeGame() {
    debugPrint(
      '[SnakeGame] ▶️ resumeGame called (currentStatus: ${gameStatus.value})',
    );
    if (gameStatus.value != GameStatus.paused &&
        gameStatus.value != GameStatus.idle) {
      return;
    }
    gameStatus.value = GameStatus.playing;
    _startTimer();
    resumeEngine();
    playModeBgm();
    debugPrint(
      '[SnakeGame] ▶️ resumeGame finished: gameStatus is now playing, engine resumed',
    );
  }

  void togglePause() {
    if (gameStatus.value == GameStatus.playing) {
      pauseGame();
    } else if (gameStatus.value == GameStatus.paused) {
      resumeGame();
    }
  }

  /// Play or resume the appropriate BGM for the active game mode.
  void playModeBgm() {
    if (gameStatus.value != GameStatus.playing &&
        gameStatus.value != GameStatus.paused)
      return;
    _soundDispatcher.playBgmForMode(gameMode.value);
  }

  void restartLevel() {
    _cancelAllTimers();
    if (gameMode.value == GameMode.casual) {
      initCasual();
    } else if (gameMode.value == GameMode.classic) {
      initClassic();
    } else if (gameMode.value == GameMode.infection) {
      initInfection();
    } else if (gameMode.value == GameMode.blindMemory) {
      initBlindMemory();
    } else if (gameMode.value == GameMode.laser) {
      initLaser();
    } else if (gameMode.value == GameMode.meltdown) {
      initMeltdown();
    } else if (gameMode.value == GameMode.crabChase) {
      initCrabChase();
    } else {
      initLevel(currentLevel);
    }
    resumeEngine();
  }

  void nextLevel() {
    if (gameMode.value == GameMode.level && currentLevel < 50) {
      _cancelAllTimers();
      initLevel(currentLevel + 1);
      final bool isWaitingForIntro = isIntroWaiting;
      if (!isWaitingForIntro) {
        resumeEngine();
      }
    }
  }

  void goToMenu() {
    _cancelAllTimers();
    pauseEngine();
    _soundDispatcher.stopBgMusic();
    if (Get.isRegistered<WalletController>()) {
      final wallet = Get.find<WalletController>();
      final pending = wallet.pendingCoinAnimation.value;
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🏠 [SnakeGame] goToMenu: pendingCoinAnimation=$pending');
      debugPrint('═══════════════════════════════════════════════════════════');
      if (pending > 0) {
        Future.delayed(const Duration(milliseconds: 450), () {
          debugPrint(
            '🚀 [SnakeGame] goToMenu timer fired -> triggering coin animation for $pending coins!',
          );
          wallet.triggerImmediateFlyAnimation();
        });
      }
    }
    if (isLeagueAttempt) {
      if (Get.context != null && Navigator.of(Get.context!).canPop()) {
        Get.back();
      } else {
        Get.offAllNamed(AppRoutes.leagueAttemptSelector);
      }
      return;
    }
    Get.offAllNamed('/menu');
  }

  void _playEatEffect() {
    showEatEffect.value = true;
    Future.delayed(const Duration(milliseconds: 200), () {
      showEatEffect.value = false;
    });
  }

  void _triggerShake() {
    _cancelShakeTimer();
    const amplitude = 6.0;
    const duration = Duration(milliseconds: 400);
    const tickDuration = Duration(milliseconds: 30);
    final int ticks = duration.inMilliseconds ~/ tickDuration.inMilliseconds;
    int count = 0;
    _shakeTimer = Timer.periodic(tickDuration, (timer) {
      if (count >= ticks ||
          (gameStatus.value != GameStatus.playing &&
              gameStatus.value != GameStatus.gameOver)) {
        shakeOffsetX.value = 0;
        shakeOffsetY.value = 0;
        timer.cancel();
        _shakeTimer = null;
        return;
      }
      final decay = 1.0 - (count / ticks);
      shakeOffsetX.value = (count.isEven ? amplitude : -amplitude) * decay;
      shakeOffsetY.value =
          (count.isEven ? amplitude : -amplitude) * decay * 0.5;
      count++;
    });
  }

  Offset _getSnakeTailWorldPos() {
    if (snake.segments.isEmpty) {
      return Offset(_offsetX, _offsetY);
    }
    final moveInterval = _effectiveMoveInterval;
    final double interpolationT = moveInterval > 0
        ? (_moveAccumulator / moveInterval).clamp(0.0, 1.0)
        : 1.0;
    final tailIndex = snake.segments.length - 1;
    final visualPos = snake.getInterpolatedPosition(
      tailIndex,
      interpolationT,
      _cellSize,
      _cellSize,
    );
    return Offset(_offsetX + visualPos.dx, _offsetY + visualPos.dy);
  }

  @override
  void onRemove() {
    _modeHandler?.onDestroy();
    _modeHandler = null;
    _cancelAllTimers();
    _backgroundRenderer.dispose();
    super.onRemove();
  }
}
