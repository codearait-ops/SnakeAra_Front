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
  int _iceSlideRemaining = 0;
  int _casualStreak = 0;
  Direction? _queuedIceDirection;

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

  // --- Read-only accessors for SnakeCanvasRenderer ---
  int get gridCols => _gridCols;
  int get gridRows => _gridRows;
  double get cellSize => _cellSize;
  double get offsetX => _offsetX;
  double get offsetY => _offsetY;
  double get gameTime => _gameTime;
  double get effectiveMoveInterval => _effectiveMoveInterval;
  double get moveAccumulator => _moveAccumulator;
  ParasiteWorm? get parasite => _parasite;
  bool get parasiteAttached => _parasiteAttached;
  double get meltdownAppleTimer => _meltdownAppleTimer;
  double get meltdownMaxTimer => _meltdownMaxTimer;
  List<RainDrop> get rainDrops => _rainDrops;
  List<List<Offset>> get lightningBranches => _lightningBranches;
  double get flashTimer => _flashTimer;

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
    double speed = _speed.toDouble();
    if (gameMode.value == GameMode.casual) {
      if (casualPowerUp.isTurboActive) {
        speed = _speed / CasualModeConfig.turboSpeedMultiplier;
      }
    }
    return speed / 1000.0;
  }

  // --- Infection Mode state ---
  final RxDouble infectionRatio = 0.0.obs;
  double _infectionTimer = 0.0;
  double _heartbeatTimer = 0.0;
  double _infectionInterval = 3.5;
  double _parasiteIntroTimer = 0.0;
  bool _parasiteAttached = false;
  ParasiteWorm? _parasite;

  // --- Blind Memory / Storm Mode state ---
  final RxDouble memoryBodyOpacity = 1.0.obs;
  final RxBool isFlashActive = false.obs;
  double _flashTimer = 0.0;
  double _thunderPreTimer = 0.0;
  int _lastFlashIntervalIndex = 0;
  final List<RainDrop> _rainDrops = [];
  final List<List<Offset>> _lightningBranches = [];
  final Random _rainRand = Random();

  // --- Boss Battles state ---
  final RxBool isBossLevelRx = false.obs;
  final RxString bossNameKey = ''.obs;

  final RxInt warningLaserRow = (-1).obs;
  final RxInt warningLaserCol = (-1).obs;
  final RxInt activeLaserRow = (-1).obs;
  final RxInt activeLaserCol = (-1).obs;
  double _laserTimer = 0.0;

  double _architectTimer = 0.0;

  final RxDouble shockwaveRadius = (-1.0).obs;
  double _shockwaveTimer = 0.0;

  final List<BossBullet> bullets = [];
  double _bulletTimer = 0.0;

  // --- Meltdown Mode ---
  double _meltdownAppleTimer = 5.0;
  int _meltdownExplosions = 0;
  final double _meltdownMaxTimer = 5.0;
  bool _meltdownBonusAwarded = false;
  final List<ExplosionEffect> explosions = [];

  final List<SlicedParticle> slicedParticles = [];
  final List<FloatingTextParticle> floatingTexts = [];

  // --- Crab Chase Mode ---
  double _crabChaseTimer = 0.0;
  int _lastDifficultyStage = 0;

  // --- Accumulator-based movement ---
  double _moveAccumulator = 0;

  // --- Timer state ---
  int _timeRemaining = 120;
  Timer? _gameTimer;
  Timer? _laserActiveTimer;
  Timer? _laserClearTimer;
  Timer? _shockwavePeriodicTimer;
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
    if (gameMode.value != GameMode.blindMemory) return;
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

  void _generateLightningBolts() {
    _lightningBranches.clear();
    final boardW = _gridCols * _cellSize;
    final boardH = _gridRows * _cellSize;
    final rand = Random();

    // 1-2 main lightning strikes from sky/top of board down
    final strikeCount = 1 + rand.nextInt(2);
    for (int s = 0; s < strikeCount; s++) {
      final startX = _offsetX + boardW * (0.2 + rand.nextDouble() * 0.6);
      final startY = _offsetY;
      final targetX = startX + (rand.nextDouble() - 0.5) * boardW * 0.45;
      final targetY = _offsetY + boardH * (0.65 + rand.nextDouble() * 0.35);

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

    // Load stored classic highscore (Removed)

    snake.init(_gridCols, _gridRows);
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
    _iceSlideRemaining = 0;
    _casualStreak = 0;
    _queuedIceDirection = null;
    casualLives.value = maxCasualLives;

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();

    optimisticCasualCoins.value = 0;
    casualPowerUp.init();
    casualMissionManager.init(
      onRewardCoins: (coins) {
        // Optimistic UI preview (Do NOT modify WalletController.balance directly!)
        optimisticCasualCoins.value += coins;
        floatingTexts.add(
          FloatingTextParticle(
            text: 'coins_reward_floating'.trParams({'coins': '$coins'}),
            x: snake.head.x.toDouble() + 0.5,
            y: snake.head.y.toDouble() + 0.5,
            color: const Color(0xFFFFD700),
            vy: -2.0,
          ),
        );
      },
      onMissionCompleted: () {
        sound.playLevelComplete();
      },
      onLogMissionCompleted: (mission) {
        if (Get.isRegistered<GameEventLogger>()) {
          Get.find<GameEventLogger>().logEvent('casual_mission_completed', {
            'mission_id': mission.id,
            'mission_type': mission.type.name,
            'target': mission.target,
            'reward_coins': mission.rewardCoins,
          });
        }
      },
    );

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

    _infectionInterval = 3.0; // base seconds per tail segment infection
    _parasiteAttached = false;
    _parasite = null;

    // Load stored infection highscore (Removed)

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();
    // Snake starts healthy for the first 5 seconds; worm will attach after 5s
    infectionRatio.value = 0.0;

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

    memoryBodyOpacity.value = 1.0;
    isFlashActive.value = false;
    _lastFlashIntervalIndex = 0;
    _lightningBranches.clear();
    _initRainDrops();

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();

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

    _meltdownExplosions = 0;
    _meltdownBonusAwarded = false;
    explosions.clear();

    // Load stored meltdown highscore (Removed)

    snake.init(_gridCols, _gridRows);
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
    _lastDifficultyStage = 0;

    obstacles.loadFromLevelData([]); // No initial obstacles unless desired
    pear.despawn();
    pearsCount.value = 0;
    pearScore.value = 0;

    // Start with a standard snake length (3)
    snake.init(_gridCols, _gridRows);

    crab.spawn(_gridCols, _gridRows, snake);

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

    // Load stored laser highscore (Removed)

    snake.init(_gridCols, _gridRows);
    snake.resetInfection();

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
    _laserActiveTimer?.cancel();
    _laserActiveTimer = null;
    _laserClearTimer?.cancel();
    _laserClearTimer = null;
    warningLaserRow.value = -1;
    warningLaserCol.value = -1;
    activeLaserRow.value = -1;
    activeLaserCol.value = -1;
  }

  void _cancelShockwaveTimer() {
    _shockwavePeriodicTimer?.cancel();
    _shockwavePeriodicTimer = null;
    shockwaveRadius.value = -1.0;
  }

  void _cancelShakeTimer() {
    _shakeTimer?.cancel();
    _shakeTimer = null;
    shakeOffsetX.value = 0;
    shakeOffsetY.value = 0;
  }

  void _resetAccumulatorTimers() {
    _gameTime = 0.0;
    _canvasRenderer.resetCache();
    _infectionTimer = 0.0;
    _heartbeatTimer = 0.0;
    _parasiteIntroTimer = 0.0;
    _flashTimer = 0.0;
    _thunderPreTimer = 0.0;
    _laserTimer = 0.0;
    _architectTimer = 0.0;
    _shockwaveTimer = 0.0;
    _bulletTimer = 0.0;
    _meltdownAppleTimer = _meltdownMaxTimer;
    _crabChaseTimer = 0.0;
    _iceSlideRemaining = 0;
    _queuedIceDirection = null;
    _firstTickLogged = false;
  }

  void _cancelAllTimers() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _cancelLaserTimers();
    _cancelShockwaveTimer();
    _cancelShakeTimer();
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

    // --- Crab Chase Mode Update ---
    if (gameMode.value == GameMode.crabChase) {
      _crabChaseTimer += safeDt;
      final int difficultyStage = (_crabChaseTimer / 90.0).floor();
      if (difficultyStage > _lastDifficultyStage) {
        _lastDifficultyStage = difficultyStage;
        crab.speedMultiplier = min(1.6, 1.0 + 0.15 * difficultyStage);
        sound.playLaserWarning(); // Using laser warning sound for level up
      }

      crab.update(safeDt, snake, _gridCols, _gridRows);

      // Check for cut timing
      if (crab.shouldApplyCutThisFrame()) {
        final hitIndex = crab.lastHitSegmentIndex;
        if (hitIndex > 0) {
          // Safety check
          final cutSegments = snake.sliceAt(hitIndex);
          if (cutSegments.isNotEmpty) {
            _onSnakeSliced(cutSegments);

            // Floating text is already added in _onSnakeSliced, but we can override or keep it.
            // Check minimum snake length
            if (snake.segments.length < 3) {
              _gameOver(GameOverReason.crabCollision);
              return;
            }
          }
        }
      }

      // Check collision
      if (!crab.isAttacking) {
        final hitIndex = crab.checkCollision(snake, _cellSize);
        if (hitIndex == 0) {
          // Head collision
          _gameOver(GameOverReason.crabCollision); // Head hit by crab
          return;
        } else if (hitIndex > 0) {
          // Body collision
          crab.triggerAttack(hitIndex);
        }
      }
    }

    // --- Laser Mode & Boss 2 Laser Core Mechanics Update ---
    if (gameMode.value == GameMode.laser ||
        (gameMode.value == GameMode.level && currentLevel == 20)) {
      // Continuous Laser Collision & Slicing Detection (every frame)
      if (activeLaserRow.value >= 0) {
        final targetY = activeLaserRow.value;
        if (snake.head.y == targetY) {
          _gameOver(GameOverReason.laserHeadHit);
          return;
        } else {
          for (int i = 1; i < snake.segments.length; i++) {
            if (snake.segments[i].y == targetY) {
              final cutSegments = snake.sliceAt(i);
              if (cutSegments.isNotEmpty) {
                _onSnakeSliced(cutSegments);
              }
              break;
            }
          }
        }
      }
      if (activeLaserCol.value >= 0) {
        final targetX = activeLaserCol.value;
        if (snake.head.x == targetX) {
          _gameOver(GameOverReason.laserHeadHit);
          return;
        } else {
          for (int i = 1; i < snake.segments.length; i++) {
            if (snake.segments[i].x == targetX) {
              final cutSegments = snake.sliceAt(i);
              if (cutSegments.isNotEmpty) {
                _onSnakeSliced(cutSegments);
              }
              break;
            }
          }
        }
      }

      _laserTimer += safeDt;
      const laserSpawnInterval = 5.0; // Spawns every 5 seconds as requested

      if (_laserTimer >= laserSpawnInterval) {
        _laserTimer = 0.0;
        final rand = mechanicsRng.boss ?? Random();
        final isRow = rand.nextBool();
        final idx = rand.nextInt(18) + 1;

        if (isRow) {
          warningLaserRow.value = idx;
          warningLaserCol.value = -1;
        } else {
          warningLaserCol.value = idx;
          warningLaserRow.value = -1;
        }

        if (gameMode.value == GameMode.laser) {
          Get.find<GameEventLogger>().logEvent('laser_spawned', {
            'row': isRow ? idx : -1,
            'col': isRow ? -1 : idx,
            'warning_duration': 1.2,
            'score_at_time': score.value,
          });
        }

        sound.playLaserWarning();

        final targetRow = isRow ? idx : -1;
        final targetCol = isRow ? -1 : idx;

        _laserActiveTimer?.cancel();
        _laserActiveTimer = Timer(const Duration(milliseconds: 1200), () {
          _laserActiveTimer = null;
          if (gameStatus.value != GameStatus.playing) {
            warningLaserRow.value = -1;
            warningLaserCol.value = -1;
            return;
          }
          activeLaserRow.value = targetRow;
          activeLaserCol.value = targetCol;
          warningLaserRow.value = -1;
          warningLaserCol.value = -1;
          sound.playLaserBeam();

          _laserClearTimer?.cancel();
          _laserClearTimer = Timer(const Duration(milliseconds: 900), () {
            _laserClearTimer = null;
            activeLaserRow.value = -1;
            activeLaserCol.value = -1;
          });
        });
      }
    }

    // --- Meltdown Mode Update ---
    if (gameMode.value == GameMode.meltdown) {
      _meltdownAppleTimer -= safeDt;
      if (_meltdownAppleTimer <= 0) {
        _meltdownAppleTimer = _meltdownMaxTimer;
        _meltdownExplosions++;

        // 1. Instant visual explosion
        explosions.add(ExplosionEffect(food.position, 0.6, 0.6));

        // 2. Explode! Bypass safety zone so crater is definitely created
        obstacles.addObstacle(
          food.position,
          gridWidth: _gridCols,
          gridHeight: _gridRows,
          ignoreSafetyZone: true,
        );

        Get.find<GameEventLogger>().logEvent('crater_spawned', {
          'row': food.position.y,
          'col': food.position.x,
          'score_at_time': score.value,
        });

        _triggerShake();
        sound.playLaserWarning(); // Explosion sound
        _speed = max(157, 220 - (_meltdownExplosions * 4));

        // 3. Respawn food
        food.spawn(
          _gridCols,
          _gridRows,
          snake.segments,
          obstacles.obstacles,
          mechanicsRng.food ?? Random(),
        );
      }

      // Update explosions
      for (int i = explosions.length - 1; i >= 0; i--) {
        explosions[i].life -= safeDt;
        if (explosions[i].life <= 0) {
          explosions.removeAt(i);
        }
      }
    }

    // --- Level Mode Boss Mechanics Update ---
    if (gameMode.value == GameMode.level) {
      // Boss 3 (The Architect - Level 30)
      if (currentLevel == 30) {
        _architectTimer += safeDt;
        if (_architectTimer >= 7.5) {
          _architectTimer = 0.0;
          final rand = mechanicsRng.boss ?? Random();
          for (int attempt = 0; attempt < 30; attempt++) {
            final rx = rand.nextInt(18) + 1;
            final ry = rand.nextInt(18) + 1;
            final pos = GridPos(rx, ry);
            if (!snake.segments.contains(pos) &&
                food.position != pos &&
                !obstacles.occupiesPosition(pos)) {
              obstacles.addObstacle(pos);
              sound.playEatApple();
              break;
            }
          }
        }
      }

      // Boss 4 (Void Sentinel - Level 40)
      if (currentLevel == 40) {
        _shockwaveTimer += safeDt;
        if (_shockwaveTimer >= 8.0) {
          _shockwaveTimer = 0.0;
          sound.playFlamethrower();
          double r = 0.0;
          _shockwavePeriodicTimer?.cancel();
          _shockwavePeriodicTimer = Timer.periodic(
            const Duration(milliseconds: 35),
            (timer) {
              if (gameStatus.value != GameStatus.playing) {
                timer.cancel();
                _shockwavePeriodicTimer = null;
                shockwaveRadius.value = -1.0;
                return;
              }
              r += 0.2; // Slower speed for the wave
              shockwaveRadius.value = r;

              final isHit = snake.segments.any((s) {
                final dist = s.y.toDouble();
                return (dist - r).abs() < 0.65;
              });

              if (isHit) {
                timer.cancel();
                _shockwavePeriodicTimer = null;
                shockwaveRadius.value = -1.0;
                _gameOver(GameOverReason.obstacleCollision);
              }

              if (r >= _gridRows.toDouble()) {
                timer.cancel();
                _shockwavePeriodicTimer = null;
                shockwaveRadius.value = -1.0;
              }
            },
          );
        }
      }

      // Boss 5 (The Overlord - Level 50)
      if (currentLevel == 50) {
        _bulletTimer += safeDt;
        if (_bulletTimer >= 3.2) {
          _bulletTimer = 0.0;
          final rand = Random();
          final isHorizontal = rand.nextBool();
          if (isHorizontal) {
            final y = (rand.nextInt(18) + 1).toDouble();
            final fromLeft = rand.nextBool();
            bullets.add(
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
            bullets.add(
              BossBullet(
                x: x,
                y: fromTop ? 0.0 : 19.0,
                vx: 0.0,
                vy: fromTop ? 8.5 : -8.5,
              ),
            );
          }
          sound.playCameraFlash();
        }

        for (int i = bullets.length - 1; i >= 0; i--) {
          final b = bullets[i];
          b.x += b.vx * safeDt;
          b.y += b.vy * safeDt;

          const double hitRadiusSq = 0.85 * 0.85;
          final isHit = snake.segments.any((s) {
            final dx = s.x - b.x;
            final dy = s.y - b.y;
            return (dx * dx + dy * dy) < hitRadiusSq;
          });

          if (isHit) {
            bullets.clear();
            _gameOver(GameOverReason.bulletCollision);
            return;
          }

          if (b.x < -1 || b.x > 21 || b.y < -1 || b.y > 21) {
            bullets.removeAt(i);
          }
        }
      }
    }

    if (gameMode.value == GameMode.classic) {
      pear.update(safeDt);
    } else if (gameMode.value == GameMode.infection) {
      if (!_parasiteAttached) {
        _parasiteIntroTimer += safeDt;
        if (_parasiteIntroTimer >= 5.0 && _parasite == null) {
          _spawnParasiteWorm();
        }
        if (_parasite != null) {
          _parasite!.update(safeDt, _getSnakeTailWorldPos());
          if (_parasite!.hasReachedTarget) {
            _onParasiteAttached();
          }
        }
      } else {
        _infectionTimer += safeDt;

        // Accelerate snake movement speed smoothly over 100s (190ms down to 110ms)
        _speed = max(110, 190 - ((_elapsedTime / 100.0) * 80).round());

        // Accelerate infection tick rate smoothly over 100s (3.0s down to 1.0s)
        final currentInterval = max(
          1.0,
          _infectionInterval -
              ((_elapsedTime - 5.0).clamp(0, 100) / 100.0) * 2.0 -
              (applesEaten * 0.03),
        );

        if (_infectionTimer >= currentInterval) {
          _infectionTimer = 0;
          snake.infectTail();
          infectionRatio.value = snake.infectionRatio;

          Get.find<GameEventLogger>().logEvent('infection_tick', {
            'infection_ratio': snake.infectionRatio,
            'tick_interval_sec': currentInterval,
            'snake_length': snake.segments.length,
          });

          sound.playInfectionPulse();

          if (snake.isHeadInfected) {
            _gameOver(GameOverReason.infectionReachedHead);
            return;
          }
        }

        if (snake.infectionRatio >= 0.60) {
          _heartbeatTimer += safeDt;
          final heartbeatInterval = snake.infectionRatio >= 0.80 ? 0.6 : 1.0;
          if (_heartbeatTimer >= heartbeatInterval) {
            _heartbeatTimer = 0;
            sound.playHeartbeat(volume: (snake.infectionRatio).clamp(0.5, 1.0));
          }
        }
      }
    } else if (gameMode.value == GameMode.blindMemory) {
      _updateRain(safeDt);

      // Check thunderstorm audio trigger (every 18s starting at 16s: 16s, 34s, 52s, 70s...)
      if (_elapsedTime >= 16) {
        final intervalIndex = (_elapsedTime - 16) ~/ 18;
        final secondsInInterval = (_elapsedTime - 16) % 18;
        if (secondsInInterval == 0 && intervalIndex > _lastFlashIntervalIndex) {
          _lastFlashIntervalIndex = intervalIndex;
          _thunderPreTimer = 2.0; // Audio plays 2 seconds before visual strike!

          Get.find<GameEventLogger>().logEvent('thunderstorm_triggered', {
            'duration_sec': 4.8,
            'score_at_time': score.value,
          });

          sound.playThunderstorm(); // Sound starts with 2s build-up
        }
      }

      // Handle 2-second pre-timer:
      if (_thunderPreTimer > 0) {
        _thunderPreTimer -= safeDt;
        if (_thunderPreTimer <= 0) {
          // Exactly 2 seconds later -> Visual lightning strike!
          _flashTimer = 4.2;
          _generateLightningBolts();
          isFlashActive.value = true;
          memoryBodyOpacity.value = 1.0;
        }
      }

      if (_flashTimer > 0) {
        _flashTimer -= safeDt;
        isFlashActive.value =
            _flashTimer >
            3.2; // Screen flash & bolts visible for first 1.0s of visual strike
        memoryBodyOpacity.value =
            1.0; // 100% visible luminous body during lightning!
      } else if (_thunderPreTimer <= 0) {
        isFlashActive.value = false;
        // Initial intro fade out from 6s to 8s:
        if (_elapsedTime < 6) {
          memoryBodyOpacity.value = 1.0;
        } else if (_elapsedTime < 8) {
          final fadeT = (_elapsedTime + safeDt - 6) / 2.0;
          memoryBodyOpacity.value = (1.0 - fadeT * 0.995).clamp(0.005, 1.0);
        } else {
          memoryBodyOpacity.value =
              0.005; // Stealth ghost echo in the dark rain
        }
      }
    }

    // --- Casual Mode Update ---
    if (gameMode.value == GameMode.casual) {
      final consumedByMagnet = casualPowerUp.update(
        dt: safeDt,
        gridWidth: _gridCols,
        gridHeight: _gridRows,
        snakeSegments: snake.segments,
        obstacles: obstacles.obstacles,
        food: food,
      );
      if (consumedByMagnet && gameStatus.value == GameStatus.playing) {
        _consumeFood();
      }
      casualMissionManager.update(safeDt);
      if (casualActivePowerUp.value != casualPowerUp.activePowerUp) {
        casualActivePowerUp.value = casualPowerUp.activePowerUp;
      }
      final remainingDuration = casualPowerUp.activeDurationRemaining;
      if (remainingDuration <= 0) {
        if (casualPowerUpTimeRemaining.value != 0.0) {
          casualPowerUpTimeRemaining.value = 0.0;
        }
      } else {
        // Round to 1 decimal place to prevent 60-120fps UI rebuild thrashing
        final rounded = (remainingDuration * 10).round() / 10.0;
        if ((casualPowerUpTimeRemaining.value - rounded).abs() >= 0.05) {
          casualPowerUpTimeRemaining.value = rounded;
        }
      }
    }

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
    if (_inputQueue.isNotEmpty) {
      final nextDir = _inputQueue.removeAt(0);
      if (gameMode.value == GameMode.casual &&
          casualPowerUp.activePowerUp == PowerUpType.ice) {
        if (nextDir != snake.currentDirection &&
            !nextDir.isOpposite(snake.currentDirection)) {
          if (_iceSlideRemaining == 0) {
            _iceSlideRemaining = 1;
            _queuedIceDirection = nextDir;
          } else {
            snake.changeDirection(nextDir);
            _iceSlideRemaining = 0;
            _queuedIceDirection = null;
          }
        } else {
          snake.changeDirection(nextDir);
        }
      } else {
        snake.changeDirection(nextDir);
      }
    } else if (_iceSlideRemaining > 0 && _queuedIceDirection != null) {
      _iceSlideRemaining--;
      snake.changeDirection(_queuedIceDirection!);
      _queuedIceDirection = null;
    }

    snake.move(_gridCols, _gridRows);
    final head = snake.head;

    // Obstacle collision
    if (obstacles.occupiesPosition(head)) {
      _gameOver(GameOverReason.obstacleCollision);
      return;
    }

    // Self collision
    if (gameMode.value == GameMode.casual) {
      // In Casual Mode: Ghost allows passing through self safely. Otherwise deduct life and cut snake at collision point.
      if (!casualPowerUp.isGhostActive) {
        final h = snake.head;
        for (int i = 1; i < snake.segments.length; i++) {
          if (snake.segments[i] == h) {
            casualLives.value--;
            _casualStreak = 0; // Cut consequence: streak reset

            Get.find<GameEventLogger>().logEvent('life_lost', {
              'remaining_lives': casualLives.value,
            });

            if (casualLives.value <= 0) {
              _triggerShake();
              sound.playGameOver();
              _gameOver(GameOverReason.selfCollision);
              return;
            }

            final cutIndex = max(CasualModeConfig.minSnakeLength, i);
            if (cutIndex < snake.segments.length) {
              final cutSegments = snake.sliceAt(cutIndex);
              if (cutSegments.isNotEmpty) {
                _spawnSliceParticles(cutSegments);
                Get.find<GameEventLogger>().logEvent('snake_cut', {
                  'cut_segments_count': cutSegments.length,
                  'remaining_length': snake.segments.length,
                });
              }
            }

            _triggerShake();
            sound.playLaserWarning();
            floatingTexts.add(
              FloatingTextParticle(
                text: '💔 -1',
                x: h.x.toDouble() + 0.5,
                y: h.y.toDouble() + 0.5,
                color: const Color(0xFFFF1744),
                vy: -2.2,
              ),
            );
            break;
          }
        }
      }
    } else {
      if (snake.checkSelfCollision()) {
        _gameOver(GameOverReason.selfCollision);
        return;
      }
    }

    // Casual Mode Power-Up Collection
    if (gameMode.value == GameMode.casual) {
      final collected = casualPowerUp.checkCollection(head);
      if (collected != null) {
        floatingTexts.add(
          FloatingTextParticle(
            text: '${collected.emoji} ${collected.displayNameTr}!',
            x: head.x.toDouble() + 0.5,
            y: head.y.toDouble() + 0.5,
            color: collected.color,
            vy: -2.0,
          ),
        );
        sound.playHeal();
        Get.find<GameEventLogger>().logEvent('power_up_collected', {
          'type': collected.name,
          'duration': CasualModeConfig.powerUpDuration,
        });
      }

      // Casual Mode Rain Apple Collection (Apple Rain power-up)
      if (casualPowerUp.isAppleRainActive &&
          casualPowerUp.checkRainAppleCollection(head)) {
        snake.grow();
        applesEaten++;
        applesCount.value = applesEaten;
        _casualStreak++;
        final streakBonus = min(10, _casualStreak);
        final pts = 10 + streakBonus;
        score.value += pts;
        floatingTexts.add(
          FloatingTextParticle(
            text: '+$pts',
            x: head.x.toDouble() + 0.5,
            y: head.y.toDouble() + 0.5,
            color: const Color(0xFFFF5722),
          ),
        );
        sound.playEatApple();
        casualMissionManager.onAppleEaten(casualPowerUp.activePowerUp);
        Get.find<GameEventLogger>().logEvent('food_eaten', {
          'score_awarded': pts,
          'current_score': score.value,
          'is_rain_apple': true,
          'speed_ms': (casualPowerUp.isTurboActive
              ? (_speed / CasualModeConfig.turboSpeedMultiplier).round()
              : _speed),
          'snake_length': snake.segments.length,
          'streak': _casualStreak,
          'active_powerup': 'appleRain',
        });
      }
    }

    // Pear collision (Classic Mode)
    if (gameMode.value == GameMode.classic &&
        pear.isActive &&
        head == pear.position) {
      snake.grow();
      final bonusScore = (50 + pear.timeProgress * 50).round();
      score.value += bonusScore;
      pearsCount.value++;
      pearScore.value += bonusScore;
      floatingTexts.add(
        FloatingTextParticle(
          text: '+$bonusScore',
          x: pear.position!.x.toDouble() + 0.5,
          y: pear.position!.y.toDouble() + 0.5,
          color: const Color(0xFFFFD700),
        ),
      );

      Get.find<GameEventLogger>().logEvent('pear_eaten', {
        'bonus_awarded': bonusScore,
        'current_score': score.value,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });

      _playEatEffect();
      sound.playEatApple();
      pear.despawn();
    }

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
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'speed_ms': (casualPowerUp.isTurboActive
            ? (_speed / CasualModeConfig.turboSpeedMultiplier).round()
            : _speed),
        'snake_length': snake.segments.length,
        'streak': _casualStreak,
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

    if (gameMode.value == GameMode.casual) {
      _casualStreak++;
      casualMissionManager.onAppleEaten(casualPowerUp.activePowerUp);
    }

    if (gameMode.value == GameMode.meltdown) {
      Get.find<GameEventLogger>().logEvent('food_eaten', {
        'score_awarded': scoreAwarded,
        'current_score': score.value,
        'seconds_remaining_on_timer': double.parse(
          _meltdownAppleTimer.toStringAsFixed(2),
        ),
        'bonus_awarded': _meltdownBonusAwarded,
        'speed_ms': _speed,
        'snake_length': snake.segments.length,
      });

      // Reset apple timer
      _meltdownAppleTimer = _meltdownMaxTimer;
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

    if (gameMode.value == GameMode.classic) {
      // Accelerate speed dynamically in Classic Mode (down to min limit 70ms)
      if (applesEaten % 5 == 0 && _speed > 70) {
        _speed = max(70, _speed - 10);
      }
      // Every 5 apples eaten, spawn a Pear alongside the 6th apple!
      if (applesEaten % 5 == 0) {
        pear.spawn(
          _gridCols,
          _gridRows,
          snake.segments,
          obstacles.obstacles,
          food.position,
          mechanicsRng.bonus ?? Random(),
        );
      }
    } else if (gameMode.value == GameMode.level) {
      // Check level completion in Level Mode (if appleTarget > 0)
      if (_appleTarget > 0 && applesEaten >= _appleTarget) {
        _levelComplete();
        return;
      }
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

    if (gameMode.value == GameMode.meltdown) {
      // Meltdown Mode: Progressive score
      addedPoints = 10 + (applesEaten - 1) * 5;
      popupColor = const Color(0xFFC6FF00); // Neon Yellow-Green

      // Last Second Bonus
      _meltdownBonusAwarded = _meltdownAppleTimer <= 1.0;
      if (_meltdownBonusAwarded) {
        final bonus = 50;
        score.value += bonus;
        floatingTexts.add(
          FloatingTextParticle(
            text: 'perfect_timing_floating'.trParams({'bonus': '$bonus'}),
            x: food.position.x.toDouble() + 0.5,
            y: food.position.y.toDouble() - 0.5, // slightly above
            color: const Color(0xFFC6FF00),
            vy: -1.0,
            maxLife: 2.0,
          ),
        );
      }
    } else if (gameMode.value == GameMode.laser) {
      // Laser Mode: Escalating progressive score per apple (10, 15, 20, 25...)
      addedPoints = 10 + (applesEaten - 1) * 5;
      popupColor = const Color(0xFFFF9100); // Laser Theme Orange
    } else if (gameMode.value == GameMode.crabChase) {
      // Crab Chase Mode: Escalating progressive score per apple (same as Laser Mode: 10, 15, 20, 25...)
      addedPoints = 10 + (applesEaten - 1) * 5;
      popupColor = const Color(0xFFFF5722); // Crab Chase Deep Orange
    } else if (gameMode.value == GameMode.classic) {
      // Classic Mode: Exactly 10 points per apple forever
      addedPoints = 10;
      popupColor = kPrimaryColor; // Classic Theme Green (0xFF00E676)
    } else if (gameMode.value == GameMode.blindMemory) {
      // Blind Memory Mode: 50 points per apple
      addedPoints = 50;
      popupColor = const Color(0xFFD500F9); // Blind Memory Theme Purple/Magenta
    } else if (gameMode.value == GameMode.infection) {
      // Infection Mode: 10 points per apple
      addedPoints = 10;
      popupColor = const Color(0xFFFF1744); // Infection Theme Red
    } else if (gameMode.value == GameMode.casual) {
      // Casual Mode: 10 base points + streak bonus (up to +10)
      final streakBonus = min(10, _casualStreak);
      addedPoints = 10 + streakBonus;
      popupColor = const Color(
        0xFFA855F7,
      ); // Casual Theme Vibrant Fantasy Purple
    } else {
      // Custom Mode
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
          if (gameMode.value == GameMode.level && _appleTarget == 0) {
            // Survival boss survived the time limit!
            _levelComplete();
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

  void _spawnParasiteWorm() {
    final startSide = Random().nextInt(4);
    double spawnX = 0;
    double spawnY = 0;
    switch (startSide) {
      case 0: // Top
        spawnX = _offsetX + Random().nextDouble() * (_gridCols * _cellSize);
        spawnY = _offsetY - _cellSize * 4;
        break;
      case 1: // Right
        spawnX = _offsetX + _gridCols * _cellSize + _cellSize * 4;
        spawnY = _offsetY + Random().nextDouble() * (_gridRows * _cellSize);
        break;
      case 2: // Bottom
        spawnX = _offsetX + Random().nextDouble() * (_gridCols * _cellSize);
        spawnY = _offsetY + _gridRows * _cellSize + _cellSize * 4;
        break;
      case 3: // Left
      default:
        spawnX = _offsetX - _cellSize * 4;
        spawnY = _offsetY + Random().nextDouble() * (_gridRows * _cellSize);
        break;
    }
    _parasite = ParasiteWorm(headX: spawnX, headY: spawnY, cellSize: _cellSize);
  }

  void _onParasiteAttached() {
    _parasiteAttached = true;
    snake.infectTail();
    infectionRatio.value = snake.infectionRatio;

    final tailPos = _getSnakeTailWorldPos();

    // Toxic splash particle burst
    for (int i = 0; i < 22; i++) {
      final angle = Random().nextDouble() * 2 * pi;
      final spd = 60.0 + Random().nextDouble() * 160.0;
      slicedParticles.add(
        SlicedParticle(
          x: tailPos.dx,
          y: tailPos.dy,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd,
          radius: _cellSize * (0.1 + Random().nextDouble() * 0.15),
          color: Random().nextBool()
              ? const Color(0xFF00E676)
              : const Color(0xFFE040FB),
          life: 0.0,
          maxLife: 0.6,
        ),
      );
    }

    _triggerShake();
    sound.playInfectionPulse();

    floatingTexts.add(
      FloatingTextParticle(
        text: 'parasite_attached_floating'.tr,
        x: (tailPos.dx - _offsetX) / _cellSize,
        y: (tailPos.dy - _offsetY) / _cellSize - 0.5,
        color: const Color(0xFF00E676),
        vy: -1.2,
        maxLife: 2.0,
      ),
    );

    Get.find<GameEventLogger>().logEvent('parasite_attached', {
      'elapsed_sec': _elapsedTime,
      'snake_length': snake.segments.length,
    });

    _parasite = null;
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
    _cancelAllTimers();
    _backgroundRenderer.dispose();
    super.onRemove();
  }
}
