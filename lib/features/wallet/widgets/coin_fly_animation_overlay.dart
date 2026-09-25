import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';

/// Centralized overlay widget that renders golden coin particles flying from an origin
/// (bursting outward first) along smooth, curved Bezier trajectories toward the currency pill.
class CoinFlyAnimationOverlay extends StatefulWidget {
  const CoinFlyAnimationOverlay({super.key});

  @override
  State<CoinFlyAnimationOverlay> createState() => _CoinFlyAnimationOverlayState();
}

class _CoinFlyAnimationOverlayState extends State<CoinFlyAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final WalletController _wallet;
  late final AnimationController _animController;
  Worker? _triggerWorker;
  Worker? _pendingWorker;

  final int _particleCount = 10;
  final List<_CoinParticle> _particles = [];
  final List<_TargetSparkle> _sparkles = [];
  bool _isAnimating = false;
  int _lastArrivedCount = 0;
  int _totalRewardAmount = 0;

  @override
  void initState() {
    super.initState();
    _wallet = Get.find<WalletController>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animController.addListener(_onAnimationTick);

    _animController.addStatusListener((status) {
      debugPrint('🎬 [CoinFlyAnimationOverlay] status: $status');
      if (status == AnimationStatus.completed) {
        _wallet.onCoinFlyAnimationCompleted();
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _particles.clear();
            _sparkles.clear();
          });
        }
      }
    });

    // Listen to immediate fly animation triggers from WalletController
    _triggerWorker = ever<int>(_wallet.flyAnimationTrigger, (count) {
      debugPrint('🎬 [CoinFlyAnimationOverlay] _triggerWorker fired! count=$count, mounted=$mounted');
      if (count > 0 && mounted) {
        _startFlyAnimation();
      }
    });

    // Check for pending coins on route changes or when returning to Home
    _pendingWorker = ever<int>(_wallet.pendingCoinAnimation, (pending) {
      if (pending > 0 && mounted && _isHomeActive()) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _wallet.pendingCoinAnimation.value > 0 && _isHomeActive()) {
            _wallet.triggerImmediateFlyAnimation();
          }
        });
      }
    });

    // Initial check when overlay mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _wallet.pendingCoinAnimation.value > 0 && _isHomeActive()) {
          _wallet.triggerImmediateFlyAnimation();
        }
      });
    });
  }

  bool _isHomeActive() {
    final route = Get.currentRoute;
    return route == '/' ||
        route == '/home' ||
        route == '/menu' ||
        route.isEmpty;
  }

  @override
  void dispose() {
    _triggerWorker?.dispose();
    _pendingWorker?.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!_isAnimating) return;

    final progress = _animController.value;

    // Check particle arrivals
    int arrivedSoFar = 0;
    for (final particle in _particles) {
      if (progress >= particle.flyEndInterval) {
        arrivedSoFar++;
        if (!particle.hasArrived) {
          particle.hasArrived = true;
          // Spawn impact sparkle at target
          _spawnSparkle(particle.target);
        }
      }
    }

    if (arrivedSoFar > _lastArrivedCount) {
      final newlyArrived = arrivedSoFar - _lastArrivedCount;
      _lastArrivedCount = arrivedSoFar;

      // Calculate coins to increment for this batch
      final coinsPerBatch = (_totalRewardAmount / _particleCount).ceil();
      _wallet.onCoinParticleArrived(coinsPerBatch * newlyArrived);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnSparkle(Offset target) {
    final random = math.Random();
    for (int i = 0; i < 2; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final dist = 8.0 + random.nextDouble() * 16.0;
      _sparkles.add(
        _TargetSparkle(
          position: Offset(
            target.dx + math.cos(angle) * dist,
            target.dy + math.sin(angle) * dist,
          ),
          createdAt: _animController.value,
          scale: 0.6 + random.nextDouble() * 0.5,
        ),
      );
    }
  }

  void _startFlyAnimation() {
    debugPrint('🎬 [CoinFlyAnimationOverlay] _startFlyAnimation CALLED!');
    final size = MediaQuery.sizeOf(context);
    final isRtl = Get.locale?.languageCode == 'fa';
    final topPadding = MediaQuery.paddingOf(context).top;

    // 1. Determine origin
    final customOrigin = _wallet.customFlyOrigin.value;
    final origin = customOrigin ?? Offset(size.width / 2, size.height / 2);

    // 2. Determine target coordinates
    // Direction-aware fallback: Left in RTL (Persian), Right in LTR (English)
    Offset target = Offset(
      isRtl ? 62.0 : size.width - 62.0,
      topPadding + 28.0,
    );

    final targetContext = _wallet.coinTargetKey.currentContext;
    if (targetContext != null) {
      final renderBox = targetContext.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.attached) {
        final globalPos = renderBox.localToGlobal(Offset.zero);
        target = Offset(
          globalPos.dx + renderBox.size.width / 2,
          globalPos.dy + renderBox.size.height / 2,
        );
      }
    }

    _totalRewardAmount = _wallet.lastRewardedAmount.value;
    if (_totalRewardAmount <= 0) {
      _totalRewardAmount = _wallet.pendingCoinAnimation.value > 0
          ? _wallet.pendingCoinAnimation.value
          : 10;
    }

    debugPrint(
      '🎬 [CoinFlyAnimationOverlay] Config: origin=$origin, target=$target, totalReward=$_totalRewardAmount, hasTargetKey=${targetContext != null}',
    );

    _particles.clear();
    _sparkles.clear();
    _lastArrivedCount = 0;
    final random = math.Random();

    for (int i = 0; i < _particleCount; i++) {
      // Phase 1 (Burst): radial scatter around origin
      final burstAngle = (i / _particleCount) * math.pi * 2 + (random.nextDouble() - 0.5) * 0.4;
      final burstDist = 32.0 + random.nextDouble() * 45.0;
      final burstOffset = Offset(
        math.cos(burstAngle) * burstDist,
        math.sin(burstAngle) * burstDist,
      );

      final burstEnd = 0.16 + random.nextDouble() * 0.06;
      final flyStart = burstEnd + (i * 0.035).clamp(0.0, 0.28);
      final flyEnd = (flyStart + 0.42 + random.nextDouble() * 0.10).clamp(0.65, 0.96);

      // Curved control point for graceful arching trajectory
      final startPos = origin + burstOffset;
      final midX = (startPos.dx + target.dx) / 2;
      final midY = (startPos.dy + target.dy) / 2;

      // Determine bow direction (arch outwards depending on screen position)
      final bowDirection = (startPos.dx > target.dx) ? 1.0 : -1.0;
      final arcDevX = bowDirection * (40.0 + random.nextDouble() * 50.0);
      final arcDevY = -50.0 - (random.nextDouble() * 60.0);

      final controlPoint = Offset(
        midX + arcDevX,
        (midY + arcDevY).clamp(topPadding + 10.0, size.height),
      );

      _particles.add(
        _CoinParticle(
          origin: origin,
          burstOffset: burstOffset,
          controlPoint: controlPoint,
          target: target,
          burstEndInterval: burstEnd,
          flyStartInterval: flyStart,
          flyEndInterval: flyEnd,
          initialRotation: random.nextDouble() * math.pi * 2,
          spinSpeed: (random.nextBool() ? 1 : -1) * (2.0 + random.nextDouble() * 2.5),
        ),
      );
    }

    setState(() {
      _isAnimating = true;
    });

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAnimating) {
      return const SizedBox.shrink();
    }

    final progress = _animController.value;

    return SizedBox.expand(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Flying Coin Particles
            ..._particles.map((particle) {
              if (progress < 0.0 || particle.hasArrived) {
                return const SizedBox.shrink();
              }

              final Offset currentPos;
              final double scale;
              final double rotation;

              if (progress < particle.burstEndInterval) {
                // --- PHASE 1: Radial Burst Out ---
                final burstT = (progress / particle.burstEndInterval).clamp(0.0, 1.0);
                final curvedBurst = Curves.easeOutBack.transform(burstT);

                currentPos = particle.origin + particle.burstOffset * curvedBurst;
                scale = (0.2 + curvedBurst * 0.9).clamp(0.2, 1.15);
                rotation = particle.initialRotation + burstT * particle.spinSpeed * 0.5;
              } else if (progress < particle.flyStartInterval) {
                // --- PAUSE / HOVER ---
                currentPos = particle.origin + particle.burstOffset;
                scale = 1.0;
                rotation = particle.initialRotation;
              } else {
                // --- PHASE 2: Bezier Flight to Target ---
                final flightT = ((progress - particle.flyStartInterval) /
                        (particle.flyEndInterval - particle.flyStartInterval))
                    .clamp(0.0, 1.0);
                final curvedFlight = Curves.easeInOutCubic.transform(flightT);

                final p0 = particle.origin + particle.burstOffset;
                final p1 = particle.controlPoint;
                final p2 = particle.target;

                final oneMinusT = 1.0 - curvedFlight;
                final x = oneMinusT * oneMinusT * p0.dx +
                    2 * oneMinusT * curvedFlight * p1.dx +
                    curvedFlight * curvedFlight * p2.dx;
                final y = oneMinusT * oneMinusT * p0.dy +
                    2 * oneMinusT * curvedFlight * p1.dy +
                    curvedFlight * curvedFlight * p2.dy;

                currentPos = Offset(x, y);

                // Slight shrink as it enters target pocket
                if (curvedFlight > 0.85) {
                  scale = 1.0 - ((curvedFlight - 0.85) / 0.15) * 0.45;
                } else {
                  scale = 1.0 + math.sin(curvedFlight * math.pi) * 0.15;
                }

                rotation = particle.initialRotation + curvedFlight * particle.spinSpeed * math.pi * 2;
              }

              return Positioned(
                left: currentPos.dx - 15,
                top: currentPos.dy - 15,
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: scale,
                    child: const _GoldenCoinWidget(),
                  ),
                ),
              );
            }),

            // 2. Impact Sparkles at Target
            ..._sparkles.map((sparkle) {
              final age = progress - sparkle.createdAt;
              if (age < 0 || age > 0.18) {
                return const SizedBox.shrink();
              }
              final opacity = (1.0 - (age / 0.18)).clamp(0.0, 1.0);

              return Positioned(
                left: sparkle.position.dx - 6,
                top: sparkle.position.dy - 6,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: sparkle.scale * (1.0 + age * 2.0),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD700),
                      size: 14,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CoinParticle {
  final Offset origin;
  final Offset burstOffset;
  final Offset controlPoint;
  final Offset target;
  final double burstEndInterval;
  final double flyStartInterval;
  final double flyEndInterval;
  final double initialRotation;
  final double spinSpeed;
  bool hasArrived = false;

  _CoinParticle({
    required this.origin,
    required this.burstOffset,
    required this.controlPoint,
    required this.target,
    required this.burstEndInterval,
    required this.flyStartInterval,
    required this.flyEndInterval,
    required this.initialRotation,
    required this.spinSpeed,
  });
}

class _TargetSparkle {
  final Offset position;
  final double createdAt;
  final double scale;

  _TargetSparkle({
    required this.position,
    required this.createdAt,
    required this.scale,
  });
}

/// A shining, premium golden coin badge particle
class _GoldenCoinWidget extends StatelessWidget {
  const _GoldenCoinWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            Color(0xFFFFFDE7), // Bright specular highlight
            Color(0xFFFFD700), // Pure lustrous gold
            Color(0xFFFFA000), // Amber edge
            Color(0xFFD84315), // Deep rim shadow
          ],
          stops: [0.0, 0.40, 0.78, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
            blurRadius: 10,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 5,
            offset: const Offset(0, 2.5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFF9C4),
          width: 1.6,
        ),
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFE082).withValues(alpha: 0.75),
              width: 1.2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.monetization_on_rounded,
              size: 14,
              color: Color(0xFFFFF9C4),
            ),
          ),
        ),
      ),
    );
  }
}
