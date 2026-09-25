import 'dart:ui' as ui;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' show Color, Colors, Offset, Paint, PaintingStyle, Rect;
import 'package:snake_game/features/game/models/board_skin.dart';
import 'package:snake_game/features/game/rendering/snake_game_paints.dart';

/// Handles pre-rendering, caching, and drawing of the game board background grid and border.
/// Uses [ui.PictureRecorder] to cache static board graphics, preventing expensive redraws per frame.
class BoardBackgroundRenderer {
  ui.Picture? _cachedBackgroundPicture;

  /// Whether a cached background picture is currently available.
  bool get hasCache => _cachedBackgroundPicture != null;

  /// Discards the cached picture so that the next render cycle rebuilds it.
  void invalidate() {
    _cachedBackgroundPicture?.dispose();
    _cachedBackgroundPicture = null;
  }

  /// Disposes of any resources held by the renderer.
  void dispose() {
    invalidate();
  }

  /// Rebuilds the cached background picture with the given board metrics and theme skin.
  void updateCache({
    required Vector2 size,
    required BoardSkin boardSkin,
    required int gridCols,
    required int gridRows,
    required double cellSize,
    required double offsetX,
    required double offsetY,
  }) {
    _cachedBackgroundPicture?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final boardRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      gridCols * cellSize,
      gridRows * cellSize,
    );

    // 1. Draw canvas background fill around game board
    if (boardSkin.style != BoardStyle.textured &&
        boardSkin.fillColor != Colors.transparent &&
        boardSkin.fillColor.a > 0) {
      SnakeGamePaints.bgFillPaint.color = boardSkin.fillColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), SnakeGamePaints.bgFillPaint);
    }

    // 2. Render board tiles according to skin style
    switch (boardSkin.style) {
      case BoardStyle.checkerboard:
      case BoardStyle.textured:
        // Render delicate translucent micro-checkered tiles
        if (boardSkin.showCheckerOverlay) {
          SnakeGamePaints.bgLightTilePaint.color = boardSkin.lightTileColor;
          SnakeGamePaints.bgDarkTilePaint.color = boardSkin.darkTileColor;
          for (int col = 0; col < gridCols; col++) {
            for (int row = 0; row < gridRows; row++) {
              final isEven = (col + row) % 2 == 0;
              canvas.drawRect(
                Rect.fromLTWH(
                  offsetX + col * cellSize,
                  offsetY + row * cellSize,
                  cellSize,
                  cellSize,
                ),
                isEven ? SnakeGamePaints.bgLightTilePaint : SnakeGamePaints.bgDarkTilePaint,
              );
            }
          }
        }

        // Crisp faint white transparent grid lines
        final gridLinePaint = Paint()
          ..color = (boardSkin.gridLineColor ?? const Color(0x16FFFFFF))
          ..strokeWidth = 1.0;
        for (int col = 0; col <= gridCols; col++) {
          final x = offsetX + col * cellSize;
          canvas.drawLine(
            Offset(x, offsetY),
            Offset(x, offsetY + boardRect.height),
            gridLinePaint,
          );
        }
        for (int row = 0; row <= gridRows; row++) {
          final y = offsetY + row * cellSize;
          canvas.drawLine(
            Offset(offsetX, y),
            Offset(offsetX + boardRect.width, y),
            gridLinePaint,
          );
        }

        // Delicate micro-intersection crosshairs for cyber tactical precision
        final dotPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill;
        for (int col = 1; col < gridCols; col++) {
          for (int row = 1; row < gridRows; row++) {
            final x = offsetX + col * cellSize;
            final y = offsetY + row * cellSize;
            canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
          }
        }
        break;

      case BoardStyle.gradient:
        final gradPaint = Paint();
        final colors = boardSkin.gradientColors!;
        final colorStops = List<double>.generate(
          colors.length,
          (i) => colors.length > 1 ? i / (colors.length - 1) : 0.0,
        );

        if (boardSkin.isRadialGradient) {
          gradPaint.shader = ui.Gradient.radial(
            boardRect.center,
            boardRect.width * 0.7,
            colors,
            colorStops,
          );
        } else {
          gradPaint.shader = ui.Gradient.linear(
            boardRect.topCenter,
            boardRect.bottomCenter,
            colors,
            colorStops,
          );
        }
        canvas.drawRect(boardRect, gradPaint);

        // Subtle grid line overlay for gradient backgrounds
        final linePaint = Paint()
          ..color =
              (boardSkin.gridLineColor ??
              const Color(0xFFFFFFFF).withValues(alpha: 0.12))
          ..strokeWidth = 1.0;
        for (int col = 0; col <= gridCols; col++) {
          final x = offsetX + col * cellSize;
          canvas.drawLine(
            Offset(x, offsetY),
            Offset(x, offsetY + boardRect.height),
            linePaint,
          );
        }
        for (int row = 0; row <= gridRows; row++) {
          final y = offsetY + row * cellSize;
          canvas.drawLine(
            Offset(offsetX, y),
            Offset(offsetX + boardRect.width, y),
            linePaint,
          );
        }
        break;

      case BoardStyle.dotMatrix:
        final bgPaint = Paint()..color = boardSkin.darkTileColor;
        canvas.drawRect(boardRect, bgPaint);

        final dotGlowPaint = Paint()
          ..color = (boardSkin.gridLineColor ?? boardSkin.accentColor)
              .withValues(alpha: 0.25);
        final dotCorePaint = Paint()
          ..color = (boardSkin.gridLineColor ?? boardSkin.accentColor)
              .withValues(alpha: 0.7);

        for (int col = 0; col < gridCols; col++) {
          for (int row = 0; row < gridRows; row++) {
            final cx = offsetX + col * cellSize + cellSize / 2;
            final cy = offsetY + row * cellSize + cellSize / 2;
            canvas.drawCircle(Offset(cx, cy), 3.0, dotGlowPaint);
            canvas.drawCircle(Offset(cx, cy), 1.5, dotCorePaint);
          }
        }
        break;

      case BoardStyle.neonGrid:
        final bgPaint = Paint()..color = boardSkin.darkTileColor;
        canvas.drawRect(boardRect, bgPaint);

        final gridGlowPaint = Paint()
          ..color = (boardSkin.gridLineColor ?? boardSkin.accentColor)
              .withValues(alpha: 0.25)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        final gridLinePaint = Paint()
          ..color = (boardSkin.gridLineColor ?? boardSkin.accentColor)
              .withValues(alpha: 0.6)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        for (int col = 0; col <= gridCols; col++) {
          final x = offsetX + col * cellSize;
          canvas.drawLine(
            Offset(x, offsetY),
            Offset(x, offsetY + boardRect.height),
            gridGlowPaint,
          );
          canvas.drawLine(
            Offset(x, offsetY),
            Offset(x, offsetY + boardRect.height),
            gridLinePaint,
          );
        }
        for (int row = 0; row <= gridRows; row++) {
          final y = offsetY + row * cellSize;
          canvas.drawLine(
            Offset(offsetX, y),
            Offset(offsetX + boardRect.width, y),
            gridGlowPaint,
          );
          canvas.drawLine(
            Offset(offsetX, y),
            Offset(offsetX + boardRect.width, y),
            gridLinePaint,
          );
        }
        break;
    }

    // 3. Draw outer border frame (if defined)
    if (boardSkin.borderColor != Colors.transparent &&
        boardSkin.borderColor.a > 0) {
      SnakeGamePaints.bgBorderPaint.color = boardSkin.borderColor;
      canvas.drawRect(boardRect, SnakeGamePaints.bgBorderPaint);
    }

    _cachedBackgroundPicture = recorder.endRecording();
  }

  /// Draws the cached background picture onto the provided [canvas].
  void render(ui.Canvas canvas) {
    if (_cachedBackgroundPicture != null) {
      canvas.drawPicture(_cachedBackgroundPicture!);
    }
  }
}
