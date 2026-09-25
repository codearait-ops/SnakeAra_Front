import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../auth/controllers/game_session_controller.dart';
import '../../daily_mission/controllers/daily_mission_controller.dart';
import '../../levels/controllers/level_controller.dart';
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
import '../widgets/level_up_dialog.dart';
import '../models/board_skin.dart';
import '../models/snake_skin.dart';
import '../utils/game_mechanics_rng.dart';
import '../models/game_particles.dart';
import 'entities/parasite_worm.dart';
import '../rendering/board_background_renderer.dart';
import '../rendering/snake_game_paints.dart';

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

  // Reusable static cached paints delegated to SnakeGamePaints
  static Paint get _obstacleFillPaint => SnakeGamePaints.obstacleFillPaint;
  static Paint get _obstacleBorderPaint => SnakeGamePaints.obstacleBorderPaint;
  static Paint get _obstacleGlowPaint => SnakeGamePaints.obstacleGlowPaint;

  static Paint get _foodOuterGlowPaint => SnakeGamePaints.foodOuterGlowPaint;
  static Paint get _foodSecondaryGlowPaint => SnakeGamePaints.foodSecondaryGlowPaint;
  static Paint get _foodHighlightPaint => SnakeGamePaints.foodHighlightPaint;

  static Paint get _pearOuterGlowPaint => SnakeGamePaints.pearOuterGlowPaint;
  static Paint get _pearSecondaryGlowPaint => SnakeGamePaints.pearSecondaryGlowPaint;
  static Paint get _pearStemPaint => SnakeGamePaints.pearStemPaint;
  static Paint get _pearLeafPaint => SnakeGamePaints.pearLeafPaint;
  static Paint get _pearTimerBgPaint => SnakeGamePaints.pearTimerBgPaint;
  static Paint get _pearTimerFgPaint => SnakeGamePaints.pearTimerFgPaint;
  static Paint get _pearBodyPaint => SnakeGamePaints.pearBodyPaint;

  static Paint get _snakeGlowPaint => SnakeGamePaints.snakeGlowPaint;
  static Paint get _snakeBodyPaint => SnakeGamePaints.snakeBodyPaint;
  static Paint get _snakeShinePaint => SnakeGamePaints.snakeShinePaint;
  static Paint get _eyeWhitePaint => SnakeGamePaints.eyeWhitePaint;
  static Paint get _eyePupilPaint => SnakeGamePaints.eyePupilPaint;
  static Paint get _snakeHeadGlowPaint => SnakeGamePaints.snakeHeadGlowPaint;
  static Paint get _snakeHeadPaint => SnakeGamePaints.snakeHeadPaint;

  static Paint get _infectedEyePupilPaint => SnakeGamePaints.infectedEyePupilPaint;

  // --- Fossil / Skeletal Infected Snake Static Cached Paints ---
  static Paint get _fossilShadowPaint => SnakeGamePaints.fossilShadowPaint;
  static Paint get _fossilBoneDarkPaint => SnakeGamePaints.fossilBoneDarkPaint;
  static Paint get _fossilBoneMainPaint => SnakeGamePaints.fossilBoneMainPaint;
  static Paint get _fossilBoneLightPaint => SnakeGamePaints.fossilBoneLightPaint;
  static Paint get _fossilBoneRimPaint => SnakeGamePaints.fossilBoneRimPaint;
  static Paint get _fossilSpinalHolePaint => SnakeGamePaints.fossilSpinalHolePaint;
  static Paint get _fossilMarrowPulsePaint => SnakeGamePaints.fossilMarrowPulsePaint;
  static Paint get _fossilRibPaint => SnakeGamePaints.fossilRibPaint;
  static Paint get _fossilCrackPaint => SnakeGamePaints.fossilCrackPaint;

  // --- Optimization: Reusable static particle & effect paints ---
  static Paint get _slicedParticleGlowPaint => SnakeGamePaints.slicedParticleGlowPaint;
  static Paint get _slicedParticleCorePaint => SnakeGamePaints.slicedParticleCorePaint;
  static Paint get _blindMemoryOuterGlowPaint => SnakeGamePaints.blindMemoryOuterGlowPaint;
  static Paint get _blindMemoryMidGlowPaint => SnakeGamePaints.blindMemoryMidGlowPaint;
  static Paint get _stormTintPaint => SnakeGamePaints.stormTintPaint;
  static Paint get _rainDropPaint => SnakeGamePaints.rainDropPaint;
  static Paint get _lightningFlashGlowPaint => SnakeGamePaints.lightningFlashGlowPaint;
  static Paint get _lightningFlashCorePaint => SnakeGamePaints.lightningFlashCorePaint;
  static Paint get _lightningOuterGlowPaint => SnakeGamePaints.lightningOuterGlowPaint;
  static Paint get _lightningMidGlowPaint => SnakeGamePaints.lightningMidGlowPaint;
  static Paint get _lightningCoreBoltPaint => SnakeGamePaints.lightningCoreBoltPaint;

  static Paint get _fogPaint => SnakeGamePaints.fogPaint;
  static Paint get _fogSoftGradientPaint => SnakeGamePaints.fogSoftGradientPaint;
  static Paint get _fogVignettePaint => SnakeGamePaints.fogVignettePaint;

  // --- Optimization: Shader cache trackers ---
  double _lastFoodCx = -1.0;
  double _lastFoodCy = -1.0;
  double _lastFoodRadius = -1.0;
  TextPainter? _appleTextPainter;
  double _appleTextPainterCellSize = 0.0;

  double _lastPearCx = -1.0;
  double _lastPearCy = -1.0;
  double _lastPearRadius = -1.0;

  // --- Continuous game time accumulator (replaces DateTime.now() in hot render paths) ---
  double _gameTime = 0.0;

  // --- Audio & Haptic Dispatcher ---
  final GameSoundDispatcher _soundDispatcher = GameSoundDispatcher();
  GameSoundDispatcher get sound => _soundDispatcher;
  GameSoundDispatcher get soundDispatcher => _soundDispatcher;

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

    _drawObstacles(canvas);
    _drawLasers(canvas);
    _drawShockwave(canvas);
    _drawBullets(canvas);
    _drawFood(canvas);
    _drawExplosions(canvas);
    _drawPear(canvas);
    _drawSnake(canvas);
    if (gameMode.value == GameMode.casual) {
      casualPowerUp.render(
        canvas: canvas,
        offsetX: _offsetX,
        offsetY: _offsetY,
        cellSize: _cellSize,
        snake: snake,
        food: food,
      );
    }
    if (_parasite != null) {
      _parasite!.render(canvas);
    }
    if (gameMode.value == GameMode.crabChase) {
      crab.render(canvas, _offsetX, _offsetY, _cellSize);
    }
    _drawSlicedParticles(canvas);
    _drawFloatingTexts(canvas);
    _drawInfectionFogOfWar(canvas);
    _drawStormAndRain(canvas);
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

  void _drawSlicedParticles(Canvas canvas) {
    if (slicedParticles.isEmpty) return;

    for (final p in slicedParticles) {
      final progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final cx = _offsetX + p.x * _cellSize;
      final cy = _offsetY + p.y * _cellSize;

      _slicedParticleGlowPaint.color = p.color.withValues(alpha: alpha * 0.8);
      _slicedParticleCorePaint.color = Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(cx, cy),
        p.radius * _cellSize * 0.22,
        _slicedParticleGlowPaint,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        p.radius * _cellSize * 0.10,
        _slicedParticleCorePaint,
      );
    }
  }

  void _drawFloatingTexts(Canvas canvas) {
    if (floatingTexts.isEmpty) return;

    for (final ft in floatingTexts) {
      final progress = (ft.life / ft.maxLife).clamp(0.0, 1.0);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final scale = 1.0 + sin(progress * pi * 0.5) * 0.25;

      final cx = _offsetX + ft.x * _cellSize;
      final cy = _offsetY + ft.y * _cellSize;

      ft.painter ??= TextPainter(
        text: TextSpan(
          text: ft.text,
          style: TextStyle(
            color: ft.color,
            fontSize: _cellSize * 0.75,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black87, offset: Offset(1.5, 1.5)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final tp = ft.painter!;
      final halfW = tp.width / 2;
      final halfH = tp.height / 2;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale);
      tp.paint(canvas, Offset(-halfW, -halfH));
      canvas.restore();
    }
  }

  void _drawLasers(Canvas canvas) {
    if (gameMode.value != GameMode.laser &&
        (gameMode.value != GameMode.level || currentLevel != 20)) {
      return;
    }

    // Warning Laser Line (Glowing Red semi-transparent)
    if (warningLaserRow.value >= 0) {
      final y = _offsetY + warningLaserRow.value * _cellSize + _cellSize / 2;
      final paint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.55)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(_offsetX, y),
        Offset(_offsetX + 20 * _cellSize, y),
        paint,
      );
    }
    if (warningLaserCol.value >= 0) {
      final x = _offsetX + warningLaserCol.value * _cellSize + _cellSize / 2;
      final paint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.55)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x, _offsetY),
        Offset(x, _offsetY + 20 * _cellSize),
        paint,
      );
    }

    // Active Deadly Laser Beam (Neon Red & White Core)
    if (activeLaserRow.value >= 0) {
      final y = _offsetY + activeLaserRow.value * _cellSize + _cellSize / 2;
      final outerGlow = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.85)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final coreLine = Paint()
        ..color = Colors.white
        ..strokeWidth = 6;
      canvas.drawLine(
        Offset(_offsetX, y),
        Offset(_offsetX + 20 * _cellSize, y),
        outerGlow,
      );
      canvas.drawLine(
        Offset(_offsetX, y),
        Offset(_offsetX + 20 * _cellSize, y),
        coreLine,
      );
    }
    if (activeLaserCol.value >= 0) {
      final x = _offsetX + activeLaserCol.value * _cellSize + _cellSize / 2;
      final outerGlow = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.85)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final coreLine = Paint()
        ..color = Colors.white
        ..strokeWidth = 6;
      canvas.drawLine(
        Offset(x, _offsetY),
        Offset(x, _offsetY + 20 * _cellSize),
        outerGlow,
      );
      canvas.drawLine(
        Offset(x, _offsetY),
        Offset(x, _offsetY + 20 * _cellSize),
        coreLine,
      );
    }
  }

  void _drawShockwave(Canvas canvas) {
    if (gameMode.value != GameMode.level || currentLevel != 40) return;
    final r = shockwaveRadius.value;
    if (r <= 0) return;

    final y = _offsetY + r * _cellSize;
    final alpha = (1.0 - r / _gridRows).clamp(0.1, 1.0);

    // Draw Fire Tail
    final tailHeight = 5.0 * _cellSize;
    final topY = (y - tailHeight).clamp(_offsetY, y);
    if (y > _offsetY) {
      final tailRect = Rect.fromLTRB(
        _offsetX,
        topY,
        _offsetX + _gridCols * _cellSize,
        y,
      );

      final tailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFF1744).withValues(alpha: alpha * 0.3), // Faded Red
            const Color(
              0xFFFF9100,
            ).withValues(alpha: alpha * 0.7), // Intense Orange
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(tailRect);

      canvas.drawRect(tailRect, tailPaint);
    }

    // Deep outer blast glow (Fire Red)
    final outerGlow = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: alpha * 0.5)
      ..strokeWidth = 30
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Mid intense blast energy (Fire Orange)
    final midGlow = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: alpha * 0.8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Blinding core (Yellow/White)
    final corePaint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: alpha)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final p1 = Offset(_offsetX, y);
    final p2 = Offset(_offsetX + _gridCols * _cellSize, y);

    canvas.drawLine(p1, p2, outerGlow);
    canvas.drawLine(p1, p2, midGlow);
    canvas.drawLine(p1, p2, corePaint);
  }

  void _drawBullets(Canvas canvas) {
    if (gameMode.value != GameMode.level || currentLevel != 50) return;

    final bulletGlow = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final bulletCore = Paint()..color = const Color(0xFFFFD700);

    for (final b in bullets) {
      final cx = _offsetX + b.x * _cellSize;
      final cy = _offsetY + b.y * _cellSize;
      canvas.drawCircle(Offset(cx, cy), _cellSize * 0.45, bulletGlow);
      canvas.drawCircle(Offset(cx, cy), _cellSize * 0.28, bulletCore);
    }
  }

  void _drawObstacles(Canvas canvas) {
    if (gameMode.value == GameMode.classic ||
        gameMode.value == GameMode.infection ||
        gameMode.value == GameMode.casual) {
      return; // No obstacles in Classic, Infection, or Casual Mode
    }

    for (final obs in obstacles.obstacles) {
      final x = _offsetX + obs.x * _cellSize;
      final y = _offsetY + obs.y * _cellSize;
      const padding = 1.5;

      final glowRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + padding - 1.0,
          y + padding - 1.0,
          _cellSize - padding * 2 + 2.0,
          _cellSize - padding * 2 + 2.0,
        ),
        Radius.circular(_cellSize * 0.22),
      );
      canvas.drawRRect(glowRRect, _obstacleGlowPaint);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + padding,
          y + padding,
          _cellSize - padding * 2,
          _cellSize - padding * 2,
        ),
        Radius.circular(_cellSize * 0.2),
      );
      if (gameMode.value == GameMode.meltdown) {
        // Draw Crater
        final craterPaint = Paint()..color = const Color(0xFF1B1B1B);
        final craterRim = Paint()
          ..color =
              const Color(0xFFFF5722) // Orange-red rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(
          Offset(x + _cellSize / 2, y + _cellSize / 2),
          _cellSize * 0.4,
          craterPaint,
        );
        canvas.drawCircle(
          Offset(x + _cellSize / 2, y + _cellSize / 2),
          _cellSize * 0.4,
          craterRim,
        );
        // Inner crack
        canvas.drawCircle(
          Offset(x + _cellSize / 2, y + _cellSize / 2),
          _cellSize * 0.15,
          Paint()..color = Colors.black,
        );
      } else {
        canvas.drawRRect(rrect, _obstacleFillPaint);
        canvas.drawRRect(rrect, _obstacleBorderPaint);
      }
    }
  }

  void _drawFood(Canvas canvas) {
    if (gameMode.value == GameMode.meltdown && _meltdownAppleTimer <= 1.0) {
      _drawBombState(canvas);
      return;
    }

    final cx = _offsetX + food.visualX * _cellSize + _cellSize / 2;
    final cy = _offsetY + food.visualY * _cellSize + _cellSize / 2;

    // Heartbeat pulse animation calculation (lub-dub pulse curve)
    final double t = (_gameTime * 1.6) % 1.0;
    double pulseScale = 1.0;
    if (t < 0.15) {
      // First heartbeat expansion
      pulseScale = 1.0 + 0.22 * sin(t / 0.15 * pi);
    } else if (t >= 0.2 && t < 0.35) {
      // Second heartbeat mini expansion
      pulseScale = 1.0 + 0.14 * sin((t - 0.2) / 0.15 * pi);
    }

    final baseRadius = _cellSize * 0.38 * pulseScale;

    canvas.drawCircle(Offset(cx, cy), baseRadius * 2.2, _foodOuterGlowPaint);
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius * 3.5,
      _foodSecondaryGlowPaint,
    );

    // Render Apple emoji matching Apple Rain
    canvas.save();
    canvas.translate(cx, cy);
    if (pulseScale != 1.0) {
      canvas.scale(pulseScale, pulseScale);
    }

    // Glowing aura directly around apple
    final appleGlow = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.35);
    canvas.drawCircle(Offset.zero, _cellSize * 0.48, appleGlow);

    if (_appleTextPainter == null || _appleTextPainterCellSize != _cellSize) {
      _appleTextPainterCellSize = _cellSize;
      _appleTextPainter = TextPainter(
        text: TextSpan(
          text: '🍎',
          style: TextStyle(fontSize: _cellSize * 0.68),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _appleTextPainter!.paint(
      canvas,
      Offset(-_appleTextPainter!.width / 2, -_appleTextPainter!.height / 2),
    );

    canvas.restore();

    if (gameMode.value == GameMode.meltdown) {
      // Draw Countdown Ring
      final progress = _meltdownAppleTimer / _meltdownMaxTimer;
      final ringColor = progress < 0.2
          ? Colors.redAccent
          : const Color(0xFFC6FF00);
      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius * 1.8),
        -pi / 2,
        2 * pi * progress,
        false,
        ringPaint,
      );
    }
  }

  void _drawBombState(Canvas canvas) {
    final cx = _offsetX + food.visualX * _cellSize + _cellSize / 2;
    final cy = _offsetY + food.visualY * _cellSize + _cellSize / 2;

    // Fast blinking in the last 1 second
    final blink = (sin(_meltdownAppleTimer * pi * 12) > 0);
    final pulse = (1.0 + sin(_meltdownAppleTimer * pi * 4)) / 2.0;
    final baseRadius = _cellSize * 0.45 + (pulse * 2.0);

    // Glow
    final glowPaint = Paint()
      ..color = (blink ? Colors.white : const Color(0xFFFF1744)).withValues(
        alpha: 0.6,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy), baseRadius * 1.5, glowPaint);

    // Bomb body
    final bombPaint = Paint()
      ..color = blink ? Colors.white : const Color(0xFF1E1E1E);
    canvas.drawCircle(Offset(cx, cy), baseRadius, bombPaint);

    // Draw the countdown ring around it
    final progress = _meltdownAppleTimer / _meltdownMaxTimer;
    final ringPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius * 1.8),
      -pi / 2,
      2 * pi * progress,
      false,
      ringPaint,
    );
  }

  void _drawExplosions(Canvas canvas) {
    if (gameMode.value != GameMode.meltdown) return;

    for (final exp in explosions) {
      final pos = exp.position;
      final cx = _offsetX + pos.x * _cellSize + _cellSize / 2;
      final cy = _offsetY + pos.y * _cellSize + _cellSize / 2;

      final progress = 1.0 - (exp.life / exp.maxLife); // 0 to 1
      final blastRadius = _cellSize * 0.5 + (progress * _cellSize * 2.5);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      // Expanding fiery blast
      final blastPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(cx, cy), blastRadius, blastPaint);

      // Bright inner core
      final corePaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy), blastRadius * 0.5, corePaint);

      // Shockwave ring
      final shockwavePaint = Paint()
        ..color = const Color(0xFFFF9100).withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(Offset(cx, cy), blastRadius * 1.2, shockwavePaint);
    }
  }

  void _drawPear(Canvas canvas) {
    if (!pear.isActive) return;
    final pos = pear.position!;
    final cx = _offsetX + pos.x * _cellSize + _cellSize / 2;
    final cy = _offsetY + pos.y * _cellSize + _cellSize / 2;
    final baseRadius = _cellSize * 0.36;

    // Outer glowing effects
    canvas.drawCircle(Offset(cx, cy), baseRadius * 2.2, _pearOuterGlowPaint);
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius * 3.2,
      _pearSecondaryGlowPaint,
    );

    // Pear body - bottom circle (larger) & top circle (smaller)
    final bottomCenter = Offset(cx, cy + baseRadius * 0.15);
    final bottomRadius = baseRadius * 0.85;
    final topCenter = Offset(cx, cy - baseRadius * 0.3);
    final topRadius = baseRadius * 0.6;

    if (_lastPearCx != cx ||
        _lastPearCy != cy ||
        _lastPearRadius != baseRadius) {
      _lastPearCx = cx;
      _lastPearCy = cy;
      _lastPearRadius = baseRadius;
      _pearBodyPaint.shader = ui.Gradient.radial(
        Offset(cx - baseRadius * 0.2, cy - baseRadius * 0.2),
        baseRadius * 1.5,
        const [
          Color(0xFFFFEE58), // Bright Yellow
          Color(0xFFFBC02D), // Gold/Amber
          Color(0xFFF57F17), // Deep Amber Pear
        ],
        const [0.0, 0.65, 1.0],
      );
    }

    // Draw pear body
    canvas.drawCircle(bottomCenter, bottomRadius, _pearBodyPaint);
    canvas.drawCircle(topCenter, topRadius, _pearBodyPaint);

    // Pear highlight
    canvas.drawCircle(
      Offset(cx - baseRadius * 0.25, cy - baseRadius * 0.2),
      baseRadius * 0.22,
      _foodHighlightPaint,
    );

    // Pear Stem
    final stemPath = Path()
      ..moveTo(cx, cy - baseRadius * 0.85)
      ..quadraticBezierTo(
        cx + 2,
        cy - baseRadius * 1.1,
        cx + 4,
        cy - baseRadius * 1.25,
      );
    canvas.drawPath(stemPath, _pearStemPaint);

    // Pear Leaf
    final leafPath = Path()
      ..moveTo(cx + 2, cy - baseRadius * 1.05)
      ..quadraticBezierTo(
        cx + 8,
        cy - baseRadius * 1.2,
        cx + 7,
        cy - baseRadius * 0.85,
      )
      ..quadraticBezierTo(
        cx + 3,
        cy - baseRadius * 0.85,
        cx + 2,
        cy - baseRadius * 1.05,
      );
    canvas.drawPath(leafPath, _pearLeafPaint);

    // Timer countdown ring around pear (shrinks over 5s)
    final ringRadius = baseRadius * 1.4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: ringRadius);
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, _pearTimerBgPaint);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * pear.timeProgress,
      false,
      _pearTimerFgPaint,
    );
  }

  void _drawSnake(Canvas canvas) {
    final segments = snake.segments;
    if (segments.isEmpty) return;

    final activeSkin = currentSkin;
    final segmentCount = segments.length;
    final bodyRadius = _cellSize * 0.38;
    final headRadius = _cellSize * 0.48;
    final isInfectedMode = gameMode.value == GameMode.infection;
    final isBlindMemoryMode = gameMode.value == GameMode.blindMemory;

    final moveInterval = _effectiveMoveInterval;
    final double interpolationT = moveInterval > 0
        ? (_moveAccumulator / moveInterval).clamp(0.0, 1.0)
        : 1.0;

    final bodyAlpha = isBlindMemoryMode
        ? memoryBodyOpacity.value
        : (gameMode.value == GameMode.casual && casualPowerUp.isGhostActive
              ? (0.42 + 0.18 * (sin(_gameTime * 8.0) * 0.5 + 0.5))
              : 1.0);

    for (int i = segmentCount - 1; i >= 1; i--) {
      final visualPos = snake.getInterpolatedPosition(
        i,
        interpolationT,
        _cellSize,
        _cellSize,
      );
      final cx = _offsetX + visualPos.dx;
      final cy = _offsetY + visualPos.dy;
      final t = segmentCount > 1 ? i / (segmentCount - 1) : 0.0;

      final isSegInfected = isInfectedMode && snake.isSegmentInfected(i);

      if (isSegInfected) {
        _drawInfectedSegment(canvas, cx, cy, bodyRadius, i);
      } else if (isBlindMemoryMode && bodyAlpha <= 0.05) {
        // Extremely faint 0.5% ghost echo stealth rendering
        final ghostFillPaint = Paint()
          ..color = const Color(0xFFD500F9).withValues(alpha: 0.005);
        canvas.drawCircle(Offset(cx, cy), bodyRadius, ghostFillPaint);

        final ghostRingPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.01)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), bodyRadius * 0.85, ghostRingPaint);
      } else {
        final color = activeSkin.getColorAt(t);
        _snakeGlowPaint.color = activeSkin.glowColor.withValues(
          alpha: 0.2 * bodyAlpha,
        );
        canvas.drawCircle(Offset(cx, cy), bodyRadius * 1.3, _snakeGlowPaint);

        _snakeBodyPaint.color = color.withValues(alpha: bodyAlpha);
        canvas.drawCircle(Offset(cx, cy), bodyRadius, _snakeBodyPaint);

        if (bodyAlpha > 0.3) {
          canvas.drawCircle(
            Offset(cx - bodyRadius * 0.2, cy - bodyRadius * 0.2),
            bodyRadius * 0.35,
            _snakeShinePaint,
          );
        }
      }
    }

    if (segmentCount > 0) {
      final headVisualPos = snake.getInterpolatedPosition(
        0,
        interpolationT,
        _cellSize,
        _cellSize,
      );

      // Add sick jitter vibration if infection > 40%
      double jitterX = 0;
      double jitterY = 0;
      if (isInfectedMode && snake.infectionRatio > 0.4) {
        final t = _gameTime * 20.0;
        final intensity = (snake.infectionRatio - 0.4) * 3.5;
        jitterX = sin(t * 1.7) * intensity;
        jitterY = cos(t * 2.3) * intensity;
      }

      final hx = _offsetX + headVisualPos.dx + jitterX;
      final hy = _offsetY + headVisualPos.dy + jitterY;

      final isHeadInfected = isInfectedMode && snake.isHeadInfected;

      if (isHeadInfected) {
        _drawInfectedSegment(canvas, hx, hy, headRadius, 0, isHead: true);
      } else if (isBlindMemoryMode) {
        // Head is a luminous guide with electric storm glow in the dark
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius * 2.2,
          _blindMemoryOuterGlowPaint,
        );
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius * 1.5,
          _blindMemoryMidGlowPaint,
        );

        _snakeHeadPaint.shader = ui.Gradient.radial(
          Offset(hx, hy),
          headRadius,
          const [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF0091EA)],
          const [0.0, 0.55, 1.0],
        );
        canvas.drawCircle(Offset(hx, hy), headRadius, _snakeHeadPaint);
      }

      if (gameMode.value == GameMode.casual && casualPowerUp.hasActivePowerUp) {
        final powerUpColor = casualPowerUp.activePowerUp!.color;
        final auraPaint = Paint()
          ..color = powerUpColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(hx, hy), headRadius * 1.6, auraPaint);
      } else {
        _snakeHeadGlowPaint.color = isInfectedMode && snake.infectionRatio > 0.5
            ? const Color(0xFFFF1744).withValues(alpha: 0.4)
            : activeSkin.glowColor.withValues(alpha: 0.3);
        canvas.drawCircle(
          Offset(hx, hy),
          headRadius * 1.5,
          _snakeHeadGlowPaint,
        );

        final headColor1 = isInfectedMode && snake.infectionRatio > 0.5
            ? const Color(0xFFD50000)
            : activeSkin.headColor;
        final headColor2 = activeSkin.getColorAt(0.2);

        _snakeHeadPaint.shader = ui.Gradient.radial(
          Offset(hx, hy),
          headRadius,
          [headColor1, headColor2],
          const [0.0, 0.85],
        );
        canvas.drawCircle(Offset(hx, hy), headRadius, _snakeHeadPaint);
      }

      _drawEyes(
        canvas,
        hx,
        hy,
        headRadius,
        isSick:
            isInfectedMode && (snake.infectionRatio > 0.25 || isHeadInfected),
      );
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

  void _drawStormAndRain(Canvas canvas) {
    if (gameMode.value != GameMode.blindMemory) return;

    final boardRect = Rect.fromLTWH(
      _offsetX,
      _offsetY,
      _gridCols * _cellSize,
      _gridRows * _cellSize,
    );

    canvas.save();
    canvas.clipRect(boardRect);

    // 1. Dark stormy ambient tint over the board (clears during lightning)
    final double tintAlpha = isFlashActive.value ? 0.0 : 0.40;
    _stormTintPaint.color = const Color(
      0xFF020617,
    ).withValues(alpha: tintAlpha);
    canvas.drawRect(boardRect, _stormTintPaint);

    // 2. Falling Raindrops
    final boardW = _gridCols * _cellSize;
    final boardH = _gridRows * _cellSize;

    for (final drop in _rainDrops) {
      final startX = _offsetX + drop.x * boardW;
      final startY = _offsetY + drop.y * boardH;
      final endX = startX - drop.length * 0.22;
      final endY = startY + drop.length;

      _rainDropPaint.color = Colors.white.withValues(alpha: drop.alpha);
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        _rainDropPaint,
      );
    }

    // 3. Lightning Electric Bolts & Flash Overlay
    if (isFlashActive.value) {
      final flashProg = (_flashTimer - 3.2).clamp(0.0, 1.0);
      final flicker = (sin(flashProg * pi * 8).abs() * 0.5 + 0.5) * flashProg;

      // Ambient screen flash glow (pure white)
      _lightningFlashGlowPaint.color = Colors.white.withValues(
        alpha: (flicker * 0.45).clamp(0.0, 0.45),
      );
      canvas.drawRect(boardRect, _lightningFlashGlowPaint);

      _lightningFlashCorePaint.color = Colors.white.withValues(
        alpha: (flicker * 0.25).clamp(0.0, 0.25),
      );
      canvas.drawRect(boardRect, _lightningFlashCorePaint);

      // Draw Jagged Lightning Bolts (pure white outer glow, mid glow and core)
      _lightningOuterGlowPaint.color = Colors.white.withValues(
        alpha: (flicker * 0.85).clamp(0.0, 0.85),
      );

      _lightningMidGlowPaint.color = Colors.white.withValues(
        alpha: (flicker * 0.95).clamp(0.0, 0.95),
      );

      _lightningCoreBoltPaint.color = Colors.white.withValues(
        alpha: (flicker * 1.0).clamp(0.0, 1.0),
      );

      for (final branch in _lightningBranches) {
        if (branch.length >= 2) {
          canvas.drawLine(branch[0], branch[1], _lightningOuterGlowPaint);
          canvas.drawLine(branch[0], branch[1], _lightningMidGlowPaint);
          canvas.drawLine(branch[0], branch[1], _lightningCoreBoltPaint);
        }
      }
    }

    canvas.restore();
  }

  void _drawEyes(
    Canvas canvas,
    double cx,
    double cy,
    double headRadius, {
    bool isSick = false,
  }) {
    final eyeRadius = headRadius * 0.23;
    final pupilRadius = eyeRadius * 0.55;
    final offset = headRadius * 0.38;

    final pupilPaint = isSick ? _infectedEyePupilPaint : _eyePupilPaint;

    canvas.drawCircle(
      Offset(cx - offset, cy - offset * 0.8),
      eyeRadius,
      _eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(cx - offset, cy - offset * 0.8),
      pupilRadius,
      pupilPaint,
    );

    canvas.drawCircle(
      Offset(cx + offset, cy - offset * 0.8),
      eyeRadius,
      _eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(cx + offset, cy - offset * 0.8),
      pupilRadius,
      pupilPaint,
    );
  }

  /// Ultra-performant Fossil / Skeletal Vertebra infected snake segment renderer.
  /// Uses pre-allocated static paints with zero runtime GC overhead for steady 60/120fps.
  void _drawInfectedSegment(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    int index, {
    bool isHead = false,
  }) {
    if (isHead) {
      // --- FOSSIL SKULL (HEAD) ---
      // 1. Dark background skull drop-shadow
      canvas.drawCircle(Offset(cx + 1.0, cy + 1.5), radius * 1.05, _fossilShadowPaint);

      // 2. Base weathered bone cranium
      canvas.drawCircle(Offset(cx, cy), radius * 1.02, _fossilBoneDarkPaint);
      canvas.drawCircle(Offset(cx, cy), radius * 0.94, _fossilBoneMainPaint);

      // 3. Cranial highlight crest
      canvas.drawCircle(
        Offset(cx - radius * 0.22, cy - radius * 0.25),
        radius * 0.38,
        _fossilBoneLightPaint,
      );

      // 4. Skull outer bone rim
      canvas.drawCircle(Offset(cx, cy), radius * 0.94, _fossilBoneRimPaint);

      // 5. Skull bone suture / cranial fracture line
      canvas.drawLine(
        Offset(cx - radius * 0.5, cy - radius * 0.1),
        Offset(cx + radius * 0.4, cy + radius * 0.3),
        _fossilCrackPaint,
      );

      // 6. Deep hollow eye sockets with eerie glowing core
      final eyeOffset = radius * 0.38;
      final socketRadius = radius * 0.28;
      final pupilRadius = radius * 0.11;

      // Left eye socket
      final leftSocket = Offset(cx - eyeOffset, cy - eyeOffset * 0.6);
      canvas.drawCircle(leftSocket, socketRadius, _fossilSpinalHolePaint);
      _fossilMarrowPulsePaint.color = const Color(0xFF76FF03).withValues(
        alpha: 0.85 + 0.15 * sin(_gameTime * 6.0),
      );
      canvas.drawCircle(leftSocket, pupilRadius, _fossilMarrowPulsePaint);

      // Right eye socket
      final rightSocket = Offset(cx + eyeOffset, cy - eyeOffset * 0.6);
      canvas.drawCircle(rightSocket, socketRadius, _fossilSpinalHolePaint);
      canvas.drawCircle(rightSocket, pupilRadius, _fossilMarrowPulsePaint);

      // 7. Nasal fossil hollow
      canvas.drawCircle(
        Offset(cx, cy + radius * 0.18),
        radius * 0.14,
        _fossilSpinalHolePaint,
      );
    } else {
      // --- FOSSIL VERTEBRA (BODY SEGMENT) ---
      // 1. Lateral Skeletal Ribs / Bone Spurs (4 Symmetrical spurs)
      final ribAngle = (index * 0.4);
      final rCos = cos(ribAngle);
      final rSin = sin(ribAngle);
      final spurExt = radius * 1.35;
      final spurIn = radius * 0.55;

      // Primary rib pair
      canvas.drawLine(
        Offset(cx - rCos * spurIn, cy - rSin * spurIn),
        Offset(cx - rCos * spurExt, cy - rSin * spurExt),
        _fossilRibPaint,
      );
      canvas.drawLine(
        Offset(cx + rCos * spurIn, cy + rSin * spurIn),
        Offset(cx + rCos * spurExt, cy + rSin * spurExt),
        _fossilRibPaint,
      );

      // Secondary transverse process pair (perpendicular)
      canvas.drawLine(
        Offset(cx + rSin * (spurIn * 0.8), cy - rCos * (spurIn * 0.8)),
        Offset(cx + rSin * (spurExt * 0.85), cy - rCos * (spurExt * 0.85)),
        _fossilRibPaint,
      );
      canvas.drawLine(
        Offset(cx - rSin * (spurIn * 0.8), cy + rCos * (spurIn * 0.8)),
        Offset(cx - rSin * (spurExt * 0.85), cy + rCos * (spurExt * 0.85)),
        _fossilRibPaint,
      );

      // 2. Drop shadow under vertebra
      canvas.drawCircle(Offset(cx + 0.8, cy + 1.2), radius * 0.95, _fossilShadowPaint);

      // 3. Ancient Fossilized Bone Disk (Centrum)
      canvas.drawCircle(Offset(cx, cy), radius * 0.96, _fossilBoneDarkPaint);
      canvas.drawCircle(Offset(cx, cy), radius * 0.86, _fossilBoneMainPaint);

      // 4. Bone light bevel & highlight
      canvas.drawCircle(
        Offset(cx - radius * 0.2, cy - radius * 0.22),
        radius * 0.32,
        _fossilBoneLightPaint,
      );

      // 5. Outer bone rim line
      canvas.drawCircle(Offset(cx, cy), radius * 0.86, _fossilBoneRimPaint);

      // 6. Central Neural Canal / Spinal Marrow Cavity (Dark hollow)
      final canalRadius = radius * 0.34;
      canvas.drawCircle(Offset(cx, cy), canalRadius, _fossilSpinalHolePaint);

      // 7. Eerie toxic marrow luminescence inside spinal cavity (minimal pulse)
      final pulse = sin(_gameTime * 4.0 + index * 0.7) * 0.5 + 0.5;
      _fossilMarrowPulsePaint.color = const Color(0xFF76FF03).withValues(
        alpha: 0.4 + 0.45 * pulse,
      );
      canvas.drawCircle(Offset(cx, cy), canalRadius * 0.55, _fossilMarrowPulsePaint);

      // 8. Natural bone fissure / seam crack
      final crackAngle = ribAngle + 0.6;
      canvas.drawLine(
        Offset(cx + cos(crackAngle) * (canalRadius * 0.9), cy + sin(crackAngle) * (canalRadius * 0.9)),
        Offset(cx + cos(crackAngle) * (radius * 0.78), cy + sin(crackAngle) * (radius * 0.78)),
        _fossilCrackPaint,
      );
    }
  }

  /// Dynamic Fog of War & Vision Decay overlay for Infection Mode (clipped to game board).
  void _drawInfectionFogOfWar(Canvas canvas) {
    if (gameMode.value != GameMode.infection) return;
    if (!_parasiteAttached && snake.infectedSegmentCount == 0) return;

    final boardRect = Rect.fromLTWH(
      _offsetX,
      _offsetY,
      _gridCols * _cellSize,
      _gridRows * _cellSize,
    );

    final ratio = snake.infectionRatio;
    final moveInterval = _effectiveMoveInterval;
    final double interpolationT = moveInterval > 0
        ? (_moveAccumulator / moveInterval).clamp(0.0, 1.0)
        : 1.0;
    final headVisualPos = snake.getInterpolatedPosition(
      0,
      interpolationT,
      _cellSize,
      _cellSize,
    );
    final hx = _offsetX + headVisualPos.dx;
    final hy = _offsetY + headVisualPos.dy;

    final boardSide = min(_gridCols * _cellSize, _gridRows * _cellSize);

    // Non-linear vision decay curve relative to game board size:
    // 0.0 - 0.30: 1.1 * boardSide (clear vision)
    // 0.30 - 0.60: 1.1 -> 0.55 * boardSide (gradually shrinking)
    // 0.60 - 0.80: 0.55 -> 0.30 * boardSide (rapidly shrinking)
    // 0.80 - 1.00: 0.30 -> 0.15 * boardSide (extreme narrow spotlight)
    double visionRadiusMultiplier;
    if (ratio <= 0.30) {
      visionRadiusMultiplier = 1.1;
    } else if (ratio <= 0.60) {
      final t = (ratio - 0.30) / 0.30;
      visionRadiusMultiplier = 1.1 - t * 0.55;
    } else if (ratio <= 0.80) {
      final t = (ratio - 0.60) / 0.20;
      visionRadiusMultiplier = 0.55 - t * 0.25;
    } else {
      final t = (ratio - 0.80) / 0.20;
      visionRadiusMultiplier = 0.30 - t * 0.15;
    }

    final radius = max(_cellSize * 1.5, boardSide * visionRadiusMultiplier);

    canvas.save();
    canvas.clipRect(boardRect);

    // Dark path with circular vision cut-out at snake head within boardRect
    final fogPath = Path()
      ..addRect(boardRect)
      ..addOval(Rect.fromCircle(center: Offset(hx, hy), radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(fogPath, _fogPaint);

    // Soft gradient transition edge
    _fogSoftGradientPaint.shader = ui.Gradient.radial(
      Offset(hx, hy),
      radius,
      const [Color(0x00000000), Color(0x9905070A), Color(0xFB05070A)],
      const [0.60, 0.88, 1.0],
    );
    canvas.drawCircle(Offset(hx, hy), radius, _fogSoftGradientPaint);

    // Red pulsating vignette border when infection is severe (>65%)
    if (ratio > 0.65) {
      final pulseTime = _gameTime * 2.5;
      final redAlpha = (0.2 + 0.25 * sin(pulseTime)).clamp(0.0, 0.5);
      _fogVignettePaint.shader = ui.Gradient.radial(
        Offset(_offsetX + boardSide / 2, _offsetY + boardSide / 2),
        boardSide * 0.75,
        [
          const Color(0x00000000),
          Color(0xFFFF1744).withValues(alpha: redAlpha * 0.4),
          Color(0xFFFF1744).withValues(alpha: redAlpha),
        ],
        const [0.4, 0.8, 1.0],
      );
      canvas.drawRect(boardRect, _fogVignettePaint);
    }

    canvas.restore();
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
    _lastFoodCx = -1.0;
    _lastFoodCy = -1.0;
    _lastFoodRadius = -1.0;
    _lastPearCx = -1.0;
    _lastPearCy = -1.0;
    _lastPearRadius = -1.0;
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

    final levelController = Get.find<LevelController>();
    final bool isReplay = levelController.isLevelCompleted(currentLevel);
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🏆 [SnakeGame] _levelComplete called!');
    debugPrint('   - currentLevel: $currentLevel');
    debugPrint('   - isReplay: $isReplay');
    debugPrint(
      '   - isLoggedIn: ${Get.find<AuthController>().isLoggedIn.value}',
    );
    debugPrint('   - sessionId: ${Get.find<GameEventLogger>().sessionId}');
    debugPrint('═══════════════════════════════════════════════════════════');
    levelController.markLevelCompleted(currentLevel);

    _saveHighscore(isReplay: isReplay);
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

    if (gameMode.value != GameMode.level) {
      Get.find<GameEventLogger>().logEvent('game_over', {
        'reason': reason.apiReason,
        'final_score': score.value,
        'apples_eaten': applesEaten,
        'time_survived_sec': _elapsedTime,
      });
    }

    if (reason == GameOverReason.laserHeadHit) {
      sound.playLaserDeath();
    } else {
      sound.playGameOver();
    }
    sound.stopBgMusic();
    _saveHighscore();
    _triggerShake();
  }

  Future<void> _saveHighscore({bool isReplay = false}) async {
    final storage = Get.find<StorageService>();

    // --- LEVEL MODE: No score, no records, XP only on win ---
    if (gameMode.value == GameMode.level) {
      isNewHighscore.value = false;
      debugPrint(
        '🏁 [SnakeGame] _saveHighscore: gameMode=level, showLevelComplete=${showLevelComplete.value}, isReplay=$isReplay, applesEaten=$applesEaten/$_appleTarget',
      );
      if (showLevelComplete.value) {
        earnedXp.value = 0;
        levelCoinAwarded.value = false;
        levelCoinsAwarded.value = 0;

        // Replay of an already cleared level
        if (isReplay) {
          debugPrint(
            '[SnakeGame] ⚠️ Level $currentLevel replayed: submitting replay to server...',
          );
          final auth = Get.find<AuthController>();
          if (auth.isLoggedIn.value && auth.currentUser.value != null) {
            final logger = Get.find<GameEventLogger>();
            final effectiveSessionId =
                logger.sessionId ??
                'replay_${DateTime.now().millisecondsSinceEpoch}';
            final api = Get.find<ApiService>();
            api
                .submitLevelComplete(
                  sessionId: effectiveSessionId,
                  levelId: currentLevel,
                  applesEaten: applesEaten,
                  token: auth.currentUser.value!.token,
                  userId: auth.currentUser.value!.id,
                  isReplay: true,
                )
                .then((response) {
                  debugPrint(
                    '[SnakeGame] 🏆 Replay response: coinsAwarded=${response.coinsAwarded}, newBalance=${response.newBalance}',
                  );
                  final coins = response.coinsAwarded ?? 0;
                  if (coins > 0) {
                    levelCoinAwarded.value = true;
                    levelCoinsAwarded.value = coins;
                    if (Get.isRegistered<WalletController>()) {
                      Get.find<WalletController>().receiveCoins(
                        coins,
                        animate: true,
                        newServerBalance: response.newBalance,
                      );
                    }
                  } else if (response.newBalance != null &&
                      Get.isRegistered<WalletController>()) {
                    Get.find<WalletController>().balance.value =
                        response.newBalance!;
                  }
                })
                .catchError((e, st) {
                  debugPrint(
                    '❌ [SnakeGame] submitLevelComplete (replay) error: $e\n$st',
                  );
                });
          }
          return;
        }

        // First-time Level completed (Win) -> Award XP & Coins
        final auth = Get.find<AuthController>();
        final api = Get.find<ApiService>();
        if (auth.isLoggedIn.value && auth.currentUser.value != null) {
          final logger = Get.find<GameEventLogger>();
          final effectiveSessionId =
              logger.sessionId ??
              'level_${DateTime.now().millisecondsSinceEpoch}';
          debugPrint(
            '[SnakeGame] 🚀 Submitting level complete: level=$currentLevel, sessionId=$effectiveSessionId',
          );
          api
              .submitLevelComplete(
                sessionId: effectiveSessionId,
                levelId: currentLevel,
                applesEaten: applesEaten,
                token: auth.currentUser.value!.token,
                userId: auth.currentUser.value!.id,
                isReplay: false,
              )
              .then((response) {
                debugPrint(
                  '[SnakeGame] 🏆 submitLevelComplete response: isSuccess=${response.isSuccess}, coinsAwarded=${response.coinsAwarded}, coinAwarded=${response.coinAwarded}, newBalance=${response.newBalance}',
                );
                if (response.isSuccess) {
                  if (response.xp != null) {
                    earnedXp.value = response.xp!.xpAwarded;
                    auth.updateXpAndLevel(response.xp!);
                    if (response.xp!.leveledUp) {
                      LevelUpDialog.show(response.xp!);
                    }
                  }

                  // Level Mode Coin Reward verification from server (robust against missing boolean)
                  final coins = response.coinsAwarded ?? 0;
                  final isCoinAwarded =
                      response.coinAwarded == true || coins > 0;
                  if (isCoinAwarded && coins > 0) {
                    levelCoinAwarded.value = true;
                    levelCoinsAwarded.value = coins;

                    // Authoritative wallet balance sync via centralized receiveCoins funnel
                    if (Get.isRegistered<WalletController>()) {
                      final wallet = Get.find<WalletController>();
                      wallet.receiveCoins(
                        coins,
                        animate: true,
                        newServerBalance: response.newBalance,
                      );
                    }
                  } else {
                    // Server did not award coins
                    levelCoinAwarded.value = false;
                    levelCoinsAwarded.value = 0;
                    if (response.newBalance != null &&
                        Get.isRegistered<WalletController>()) {
                      Get.find<WalletController>().balance.value =
                          response.newBalance!;
                    }
                  }
                } else if (response.isRejected) {
                  Get.snackbar('error'.tr, 'err_validation'.tr);
                } else if (response.isSessionExpired) {
                  Get.snackbar('error'.tr, 'session_expired_title'.tr);
                }
              })
              .catchError((e, st) {
                debugPrint(
                  '❌ [SnakeGame] submitLevelComplete (win) error: $e\n$st',
                );
              });
        } else {
          // Guest player (not logged in) completing a new level
          earnedXp.value = 0;
          if (!isReplay) {
            const guestCoins = 10;
            levelCoinAwarded.value = true;
            levelCoinsAwarded.value = guestCoins;
            if (Get.isRegistered<WalletController>()) {
              Get.find<WalletController>().receiveCoins(
                guestCoins,
                animate: true,
              );
            }
          }
        }
      } else {
        // Level failed (Loss) -> 0 XP
        earnedXp.value = 0;
      }
      return;
    }

    // --- OTHER MODES (Classic, Infection, BlindMemory) ---

    // Daily Challenge unified API now handles submission automatically via logger

    // --- Award XP to Registered Players via server response ---
    final auth = Get.find<AuthController>();
    earnedXp.value = 0;

    final supportedModes = [
      GameMode.classic,
      GameMode.infection,
      GameMode.blindMemory,
      GameMode.laser,
      GameMode.meltdown,
      GameMode.crabChase,
      GameMode.casual,
    ];

    if (supportedModes.contains(gameMode.value)) {
      int submitValue = (gameMode.value == GameMode.infection)
          ? elapsedTime.value
          : score.value;

      // Update in-memory (RAM only) session best score
      bool isNewSessionBest = false;
      if (Get.isRegistered<GameSessionController>()) {
        isNewSessionBest = Get.find<GameSessionController>().updateIfBetter(
          gameMode.value.name,
          submitValue,
        );
      } else {
        isNewSessionBest = storage.updateSessionBestScore(
          gameMode.value.name,
          submitValue,
        );
      }

      if (!auth.isLoggedIn.value && isNewSessionBest) {
        isNewHighscore.value = true;
      }

      // Daily Mission Submission
      if (isDailyMission && Get.isRegistered<DailyMissionController>()) {
        final missionController = Get.find<DailyMissionController>();
        final mType =
            missionController.currentMission.value?.type ?? dailyMissionType;
        final int rawStat = (mType == 'survive_time')
            ? elapsedTime.value
            : (mType == 'eat_count' ? applesEaten : submitValue);
        final effectiveId = (dailyMissionId != null && dailyMissionId! > 0)
            ? dailyMissionId
            : missionController.currentMission.value?.id;

        debugPrint(
          '[SnakeGame] 🎯 Daily Mission GameOver Submit -> effectiveId: $effectiveId | rawStat: $rawStat | type: $mType',
        );

        missionController.submitMission(rawStat, missionId: effectiveId).then((
          res,
        ) {
          if (res != null && res.isCompleted) {
            Get.snackbar(
              'mission_completed_reward_title'.tr,
              'mission_completed_reward_desc'.trParams({
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

      // Path A: Submit score to online backend (or dedicated league endpoint if isLeagueAttempt)
      // Note: Daily Mission uses dedicated /daily-mission/submit endpoint above.
      final logger = Get.find<GameEventLogger>();
      if (!isDailyMission &&
          auth.isLoggedIn.value &&
          auth.currentUser.value != null) {
        () async {
          // If session is still being initiated, await it to prevent skipping submission
          if (logger.sessionId == null && sessionStartFuture != null) {
            debugPrint(
              '[SnakeGame] ⏳ Waiting for session initialization before score submission...',
            );
            await sessionStartFuture;
          }

          if (logger.sessionId != null) {
            debugPrint(
              '🏆 [SnakeGame] Submitting score: value=$submitValue, isLeagueAttempt=$isLeagueAttempt, session=${logger.sessionId}',
            );
            final response = await logger.submitFinalScore(
              submitValue,
              isLeague: isLeagueAttempt,
            );
            if (response.isSuccess) {
              if (response.xp != null) {
                earnedXp.value = response.xp!.xpAwarded;
                auth.updateXpAndLevel(response.xp!);
                if (response.xp!.leveledUp) {
                  LevelUpDialog.show(response.xp!);
                }
              }
              if (response.league != null) {
                leagueResult.value = response.league;
              }
              if (response.attemptsRemaining != null) {
                leagueAttemptsRemaining.value = response.attemptsRemaining!;
                canPlayLeagueAttempt.value =
                    response.canRetry ?? (response.attemptsRemaining! > 0);
              }
              if (response.isNewHighscore) {
                Get.snackbar(
                  'new_record'.tr,
                  response.message ?? 'msg_score_updated'.tr,
                  backgroundColor: const Color(
                    0xFF4CAF50,
                  ).withValues(alpha: 0.9),
                  colorText: const Color(0xFFFFFFFF),
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                  ),
                );
              }
              if (response.leagueRankImproved) {
                Get.snackbar(
                  'league_title'.tr,
                  'rank_improved'.tr,
                  backgroundColor: Colors.amber.withValues(alpha: 0.9),
                  colorText: Colors.black,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.black,
                  ),
                );
              }

              // Authoritative wallet balance sync from backend response via receiveCoins funnel
              if (Get.isRegistered<WalletController>()) {
                final wallet = Get.find<WalletController>();
                final coinsWon = response.coinsAwarded ?? 0;
                if (coinsWon > 0) {
                  wallet.receiveCoins(
                    coinsWon,
                    animate: true,
                    newServerBalance: response.newBalance,
                  );
                } else if (response.newBalance != null) {
                  wallet.balance.value = response.newBalance!;
                } else {
                  wallet.fetchWalletBalance();
                }
              }

              // Casual Mode: check server-confirmed coins against optimistic preview
              if (gameMode.value == GameMode.casual) {
                final confirmedCoins = response.coinsAwarded;
                if (confirmedCoins != null) {
                  if (confirmedCoins != optimisticCasualCoins.value) {
                    // Discrepancy between optimistic preview and server verification
                    optimisticCasualCoins.value = confirmedCoins;
                    Get.snackbar(
                      'notice'.tr,
                      'wallet_balance_updated'.tr,
                      backgroundColor: const Color(
                        0xFF00E5FF,
                      ).withValues(alpha: 0.9),
                      colorText: Colors.black,
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(16),
                      icon: const Icon(Icons.sync_rounded, color: Colors.black),
                    );
                  }
                }
              }
            } else if (response.isRejected) {
              if (response.message != null &&
                  response.message!.isNotEmpty &&
                  response.message != 'Invalid score payload') {
                Get.snackbar(
                  'league_ended_title'.tr,
                  response.message!,
                  backgroundColor: const Color(
                    0xFFFF9100,
                  ).withValues(alpha: 0.95),
                  colorText: Colors.black,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(Icons.info_outline, color: Colors.black),
                );
              }
            } else if (response.isNetworkError || response.isSessionExpired) {
              Get.snackbar(
                'error'.tr,
                response.message ?? 'err_score_update_failed'.tr,
                backgroundColor: const Color(0xFFFF1744).withValues(alpha: 0.9),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: const EdgeInsets.all(16),
              );
            }
          }
        }();
      }
    }
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
