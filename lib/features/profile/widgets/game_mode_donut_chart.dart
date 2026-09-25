import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/models/game_mode_config.dart';

/// Data class representing a single segment in the Game Mode Donut Chart.
class ModeChartSegment {
  final String modeId;
  final String title;
  final int count;
  final double percentage;
  final Color color;
  final String patternAsset;

  const ModeChartSegment({
    required this.modeId,
    required this.title,
    required this.count,
    required this.percentage,
    required this.color,
    required this.patternAsset,
  });
}

/// Standalone, interactive Donut Chart rendering pattern textures directly on slices.
class GameModeDonutChart extends StatefulWidget {
  final Map<String, int> playCounts;
  final double size;
  final String? selectedModeId;
  final ValueChanged<String?>? onModeSelected;

  const GameModeDonutChart({
    super.key,
    required this.playCounts,
    this.size = 175.0,
    this.selectedModeId,
    this.onModeSelected,
  });

  @override
  State<GameModeDonutChart> createState() => _GameModeDonutChartState();
}

class _GameModeDonutChartState extends State<GameModeDonutChart>
    with SingleTickerProviderStateMixin {
  int? _internalSelectedIndex;
  late AnimationController _animController;
  late Animation<double> _animProgress;

  /// Global memory cache for decoded UI images of patterns
  static final Map<String, ui.Image> _patternImageCache = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _loadPatternImages();
  }

  Future<void> _loadPatternImages() async {
    final assets = [
      'assets/image/pattern/Classic_pattern.png',
      'assets/image/pattern/Laser_pattern.png',
      'assets/image/pattern/Infection_pattern.png',
      'assets/image/pattern/BlindMemory_pattern.png',
      'assets/image/pattern/Meltdown_pattern.png',
      'assets/image/pattern/crab_pattern.png',
      'assets/image/pattern/Level_pattern.png',
      'assets/image/pattern/Adventure_pattern.png',
    ];

    bool hasNewImages = false;
    for (final asset in assets) {
      if (!_patternImageCache.containsKey(asset)) {
        try {
          final ByteData data = await rootBundle.load(asset);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          _patternImageCache[asset] = frame.image;
          hasNewImages = true;
        } catch (e) {
          debugPrint('Error loading pattern image $asset: $e');
        }
      }
    }

    if (hasNewImages && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant GameModeDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.playCounts, widget.playCounts)) {
      final wasEmpty = oldWidget.playCounts.values.every((v) => v <= 0);
      final isNowNotEmpty = widget.playCounts.values.any((v) => v > 0);
      if (wasEmpty && isNowNotEmpty) {
        _animController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getModeTitle(String modeId) {
    switch (modeId.toLowerCase().replaceAll('_', '')) {
      case 'classic':
        return 'classic_mode'.tr;
      case 'level':
        return 'level_mode'.tr;
      case 'infection':
        return 'infection_mode'.tr;
      case 'blindmemory':
        return 'blind_memory_mode'.tr;
      case 'laser':
      case 'lasercore':
        return 'laser_mode'.tr;
      case 'meltdown':
        return 'meltdown_mode'.tr;
      case 'crab':
      case 'crabchase':
        return 'crab_chase_mode'.tr;
      case 'casual':
      case 'adventure':
        return 'casual_mode'.tr;
      default:
        return modeId.replaceAll('_', ' ').toUpperCase();
    }
  }

  List<ModeChartSegment> _buildSegments() {
    final total = widget.playCounts.values.fold<int>(
      0,
      (sum, val) => sum + val,
    );

    final segments = <ModeChartSegment>[];
    widget.playCounts.forEach((modeId, count) {
      if (count > 0) {
        final pct = total > 0 ? (count / total) : 0.0;
        segments.add(
          ModeChartSegment(
            modeId: modeId,
            title: _getModeTitle(modeId),
            count: count,
            percentage: pct,
            color: GameModeConfig.getColorForMode(modeId),
            patternAsset: GameModeConfig.getPatternForMode(modeId),
          ),
        );
      }
    });

    // Sort by count descending
    segments.sort((a, b) => b.count.compareTo(a.count));
    return segments;
  }

  int? _getEffectiveSelectedIndex(List<ModeChartSegment> segments) {
    if (widget.selectedModeId != null && widget.selectedModeId!.isNotEmpty) {
      final selectedConfig =
          GameModeConfig.findByModeString(widget.selectedModeId!);
      final index = segments.indexWhere((s) {
        if (selectedConfig != null) {
          final segConfig = GameModeConfig.findByModeString(s.modeId);
          if (segConfig != null &&
              (segConfig.id == selectedConfig.id ||
                  segConfig.mode == selectedConfig.mode)) {
            return true;
          }
        }
        return s.modeId.toLowerCase().replaceAll('_', '') ==
            widget.selectedModeId!.toLowerCase().replaceAll('_', '');
      });
      if (index != -1) return index;
    }
    return _internalSelectedIndex;
  }

  void _handleChartTap(
    Offset localPosition,
    double chartSize,
    List<ModeChartSegment> segments,
  ) {
    final center = Offset(chartSize / 2, chartSize / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final outerRadius = chartSize / 2;
    final innerRadius = outerRadius - 28.0;

    // Check if tap falls within the donut ring
    if (distance < innerRadius - 8 || distance > outerRadius + 8) {
      setState(() {
        _internalSelectedIndex = null;
      });
      widget.onModeSelected?.call(null);
      return;
    }

    if (segments.length == 1) {
      final newIndex = (_getEffectiveSelectedIndex(segments) == 0) ? null : 0;
      setState(() {
        _internalSelectedIndex = newIndex;
      });
      widget.onModeSelected?.call(newIndex != null ? segments[0].modeId : null);
      return;
    }

    // Angle from center in radians: starting at -pi/2 (top)
    double angle = math.atan2(dy, dx) + (math.pi / 2);
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    double currentAngle = 0;
    for (int i = 0; i < segments.length; i++) {
      final sweep = segments[i].percentage * 2 * math.pi;
      if (angle >= currentAngle && angle <= currentAngle + sweep) {
        final newIndex = (_getEffectiveSelectedIndex(segments) == i) ? null : i;
        setState(() {
          _internalSelectedIndex = newIndex;
        });
        widget.onModeSelected?.call(
          newIndex != null ? segments[newIndex].modeId : null,
        );
        return;
      }
      currentAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments();
    final totalPlays = widget.playCounts.values.fold<int>(
      0,
      (sum, val) => sum + val,
    );
    final chartSize = widget.size;
    final selectedIdx = _getEffectiveSelectedIndex(segments);

    if (totalPlays == 0) {
      return Center(
        child: SizedBox(
          width: chartSize,
          height: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(chartSize, chartSize),
                painter: _PatternDonutChartPainter(
                  segments: const [],
                  patternImages: _patternImageCache,
                  progress: 1.0,
                  selectedIndex: null,
                  strokeWidth: 26.0,
                ),
              ),
              Text(
                '0',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white24,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: GestureDetector(
        onTapDown: (details) =>
            _handleChartTap(details.localPosition, chartSize, segments),
        child: SizedBox(
          width: chartSize,
          height: chartSize,
          child: AnimatedBuilder(
            animation: _animProgress,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(chartSize, chartSize),
                    painter: _PatternDonutChartPainter(
                      segments: segments,
                      patternImages: _patternImageCache,
                      progress: _animProgress.value,
                      selectedIndex: selectedIdx,
                      strokeWidth: 28.0,
                    ),
                  ),
                  // Center Stats Content
                  _buildCenterContent(segments, totalPlays, selectedIdx),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent(
    List<ModeChartSegment> segments,
    int totalPlays,
    int? selectedIdx,
  ) {
    if (selectedIdx != null && selectedIdx < segments.length) {
      final selected = segments[selectedIdx];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Image.asset(
              GameModeConfig.getIconAssetForMode(selected.modeId),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected.color,
                  boxShadow: [
                    BoxShadow(
                      color: selected.color.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(selected.percentage * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.vazirmatn(
              color: selected.color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              selected.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                color: Colors.white70,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$totalPlays',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'plays_count_label'.tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.vazirmatn(color: Colors.white38, fontSize: 9.5),
        ),
      ],
    );
  }
}

/// Custom painter for Donut Chart where each arc is clipped and mapped with its
/// mode pattern texture, mode color wash, and glowing neon outline borders.
class _PatternDonutChartPainter extends CustomPainter {
  final List<ModeChartSegment> segments;
  final Map<String, ui.Image> patternImages;
  final double progress;
  final int? selectedIndex;
  final double strokeWidth;

  _PatternDonutChartPainter({
    required this.segments,
    required this.patternImages,
    required this.progress,
    this.selectedIndex,
    required this.strokeWidth,
  });

  /// Generate the annular sector (doughnut arc) Path between inner and outer radius
  Path _getAnnularSectorPath(
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
  ) {
    if (sweepAngle >= (2 * math.pi - 0.005)) {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
        ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
        ..fillType = PathFillType.evenOdd;
      return path;
    }

    final path = Path();
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    path.arcTo(outerRect, startAngle, sweepAngle, false);
    path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width / 2;
    final baseInnerRadius = baseOuterRadius - strokeWidth;

    if (segments.isEmpty) {
      // Empty placeholder ring
      final bgPaint = Paint()
        ..color = const Color(0xFF21262D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, baseOuterRadius - (strokeWidth / 2), bgPaint);
      return;
    }

    // Background track ring
    final trackPaint = Paint()
      ..color = const Color(0xFF21262D).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, baseOuterRadius - (strokeWidth / 2), trackPaint);

    double startAngle = -math.pi / 2;
    const gapAngle = 0.05; // Gap between slices in radians

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final rawSweep = (seg.percentage * 2 * math.pi * progress);
      final sweepAngle = (segments.length > 1)
          ? (rawSweep - gapAngle).clamp(0.0, 2 * math.pi)
          : rawSweep;

      if (sweepAngle <= 0) continue;

      final isSelected = selectedIndex == i;
      final outerRadius = isSelected ? baseOuterRadius + 4 : baseOuterRadius;
      final innerRadius = isSelected ? baseInnerRadius - 2 : baseInnerRadius;
      final isFullCircle = sweepAngle >= (2 * math.pi - 0.005);

      final sectorPath = _getAnnularSectorPath(
        center,
        innerRadius,
        outerRadius,
        startAngle,
        sweepAngle,
      );

      // 1. Draw glowing background blur if selected
      if (isSelected) {
        final glowPaint = Paint()
          ..color = seg.color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        if (isFullCircle) {
          canvas.drawCircle(center, outerRadius, glowPaint);
          canvas.drawCircle(center, innerRadius, glowPaint);
        } else {
          canvas.drawPath(sectorPath, glowPaint);
        }
      }

      canvas.save();
      canvas.clipPath(sectorPath);

      // 2. Base dark tinted background under the texture
      final baseFillPaint = Paint()..color = const Color(0xFF0D1117);
      canvas.drawPath(sectorPath, baseFillPaint);

      // 3. Draw pattern texture directly onto the slice
      final uiImage = patternImages[seg.patternAsset];
      if (uiImage != null) {
        final bounds = Rect.fromCircle(center: center, radius: outerRadius);
        paintImage(
          canvas: canvas,
          rect: bounds,
          image: uiImage,
          fit: BoxFit.cover,
          opacity: 0.85,
          colorFilter: ColorFilter.mode(
            seg.color.withValues(alpha: 0.75),
            BlendMode.srcATop,
          ),
        );
      } else {
        // Fallback solid color fill if texture is loading
        final fallbackPaint = Paint()..color = seg.color.withValues(alpha: 0.8);
        canvas.drawPath(sectorPath, fallbackPaint);
      }

      // 4. Vibrant color glow overlay for mode identity
      final colorOverlayPaint = Paint()
        ..color = seg.color.withValues(alpha: isSelected ? 0.35 : 0.25)
        ..blendMode = BlendMode.screen;
      canvas.drawPath(sectorPath, colorOverlayPaint);

      canvas.restore();

      // 5. Crisp neon outline border around the annular segment
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : seg.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.2;
      if (isFullCircle) {
        canvas.drawCircle(center, outerRadius, borderPaint);
        canvas.drawCircle(center, innerRadius, borderPaint);
      } else {
        canvas.drawPath(sectorPath, borderPaint);
      }

      startAngle += (seg.percentage * 2 * math.pi * progress);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternDonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments != segments ||
        oldDelegate.patternImages.length != patternImages.length;
  }
}
