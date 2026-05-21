import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';
import 'board_render_context.dart';
import 'board_renderer_base.dart';

/// 杀手数独渲染器
class KillerBoardRenderer extends BoardRendererBase {
  const KillerBoardRenderer();

  @override
  void drawBackground(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    if (board is! KillerBoard) return;
    _drawCageBackgrounds(canvas, board, ctx);
    super.drawBackground(canvas, board, size, ctx);
  }

  @override
  void drawCellBackground(Canvas canvas, Board board, Cell cell, Rect cellRect, int row, int col, BoardRenderContext ctx) {
    // Killer 的背景由 drawBackground 中的笼子背景处理
    final paint = Paint();
    if (cell.isSelected) {
      paint.color = ctx.colors.boardSelectedCellColor;
      canvas.drawRect(cellRect, paint);
      return;
    }
    if (cell.isHighlighted) {
      paint.color = ctx.colors.boardHighlightedCellColor.withAlpha(0x99);
      canvas.drawRect(cellRect, paint);
      return;
    }
    // 不绘制默认背景，由笼子背景覆盖
  }

  @override
  void drawSpecialElements(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    if (!ctx.showCageSums || board is! KillerBoard) return;
    _drawCageSums(canvas, board, ctx);
  }

  void _drawCageBackgrounds(Canvas canvas, KillerBoard killerBoard, BoardRenderContext ctx) {
    final cageColorMap = _buildCageColorMap(killerBoard);
    final isDarkMode = ctx.colors.isDarkMode;
    for (final cage in killerBoard.cages) {
      final colorIndex = cageColorMap[cage.id] ?? 0;
      final cageColor = ctx.colors.getBoardCageColor(colorIndex).withValues(alpha: 0.55);
      final fillPaint = Paint()..color = cageColor..style = PaintingStyle.fill;
      for (final coord in cage.cellCoordinates) {
        final cellRect = Rect.fromLTWH(coord.$2 * ctx.cellSize, coord.$1 * ctx.cellSize, ctx.cellSize, ctx.cellSize);
        canvas.drawRect(cellRect, fillPaint);
      }
      // 笼子边线
      final borderPaint = Paint()
        ..color = isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      for (final coord in cage.cellCoordinates) {
        final x = coord.$2 * ctx.cellSize;
        final y = coord.$1 * ctx.cellSize;
        if (!cage.cellCoordinates.contains((coord.$1 - 1, coord.$2))) {
          ctx.drawDashedLine(canvas, Offset(x, y), Offset(x + ctx.cellSize, y), borderPaint);
        }
        if (!cage.cellCoordinates.contains((coord.$1 + 1, coord.$2))) {
          ctx.drawDashedLine(canvas, Offset(x, y + ctx.cellSize), Offset(x + ctx.cellSize, y + ctx.cellSize), borderPaint);
        }
        if (!cage.cellCoordinates.contains((coord.$1, coord.$2 - 1))) {
          ctx.drawDashedLine(canvas, Offset(x, y), Offset(x, y + ctx.cellSize), borderPaint);
        }
        if (!cage.cellCoordinates.contains((coord.$1, coord.$2 + 1))) {
          ctx.drawDashedLine(canvas, Offset(x + ctx.cellSize, y), Offset(x + ctx.cellSize, y + ctx.cellSize), borderPaint);
        }
      }
    }
  }

  Map<String, int> _buildCageColorMap(KillerBoard killerBoard) {
    final colorMap = <String, int>{};
    if (killerBoard.cages.isEmpty) return colorMap;
    final sortedCages = killerBoard.cages.toList()..sort((a, b) => b.cellCount.compareTo(a.cellCount));
    for (final cage in sortedCages) {
      final adjacent = _findAdjacentCages(cage, killerBoard.cages);
      final usedColors = adjacent.where((c) => colorMap.containsKey(c.id)).map((c) => colorMap[c.id]!).toSet();
      var colorIndex = 0;
      while (usedColors.contains(colorIndex) && colorIndex < 8) {
        colorIndex++;
      }
      colorMap[cage.id] = colorIndex;
    }
    return colorMap;
  }

  List<KillerCage> _findAdjacentCages(KillerCage cage, List<KillerCage> allCages) {
    final adjacent = <KillerCage>[];
    for (final other in allCages) {
      if (other.id == cage.id) continue;
      for (final coord in cage.cellCoordinates) {
        final neighbors = [(coord.$1 - 1, coord.$2), (coord.$1 + 1, coord.$2), (coord.$1, coord.$2 - 1), (coord.$1, coord.$2 + 1)];
        for (final neighbor in neighbors) {
          if (other.cellCoordinates.contains(neighbor)) { adjacent.add(other); break; }
        }
        if (adjacent.contains(other)) break;
      }
    }
    return adjacent;
  }

  void _drawCageSums(Canvas canvas, KillerBoard killerBoard, BoardRenderContext ctx) {
    for (final cage in killerBoard.cages) {
      final position = _findBestSumPosition(cage, killerBoard);
      final cellRect = Rect.fromLTWH(position.$2 * ctx.cellSize, position.$1 * ctx.cellSize, ctx.cellSize, ctx.cellSize);
      const sumFontSize = 11.0;
      final sumText = TextSpan(
        text: cage.sum.toString(),
        style: TextStyle(fontSize: sumFontSize, fontWeight: FontWeight.w700, color: ctx.colors.isDarkMode ? AppColors.boardDarkCageSumNew : AppColors.boardLightCageSumNew, height: 1.0),
      );
      final textPainter = TextPainter(text: sumText, textDirection: TextDirection.ltr)..layout();
      const padding = 2.0;
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cellRect.left + 2, cellRect.top + 2, textPainter.width + padding * 2, textPainter.height + padding),
        const Radius.circular(3),
      );
      final bgPaint = Paint()..color = ctx.colors.boardCellBackgroundColor.withValues(alpha: 0.95)..style = PaintingStyle.fill;
      canvas.drawRRect(bgRect, bgPaint);
      textPainter.paint(canvas, Offset(cellRect.left + 2 + padding, cellRect.top + 2 + padding / 2));
    }
  }

  (int, int) _findBestSumPosition(KillerCage cage, KillerBoard killerBoard) {
    for (final coord in cage.cellCoordinates) {
      if (killerBoard.getCell(coord.$1, coord.$2).value != null) return coord;
    }
    for (final coord in cage.cellCoordinates) {
      if (killerBoard.getCell(coord.$1, coord.$2).candidates.isEmpty) return coord;
    }
    var bestCoord = cage.cellCoordinates.first;
    var minCandidates = 10;
    for (final coord in cage.cellCoordinates) {
      final count = killerBoard.getCell(coord.$1, coord.$2).candidates.length;
      if (count < minCandidates) { minCandidates = count; bestCoord = coord; }
    }
    return bestCoord;
  }
}
