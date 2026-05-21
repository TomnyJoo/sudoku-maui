import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

import 'board_render_context.dart';
import 'board_renderer_base.dart';

/// 锯齿数独渲染器
class JigsawBoardRenderer extends BoardRendererBase {
  const JigsawBoardRenderer();

  List<List<int>>? _getRegionMatrix(Board board) {
    if (board is JigsawBoard) return board.regionMatrix;
    return null;
  }

  @override
  void drawCellBackground(Canvas canvas, Board board, Cell cell, Rect cellRect, int row, int col, BoardRenderContext ctx) {
    final paint = Paint();
    if (cell.isSelected) {
      paint.color = ctx.colors.boardSelectedCellColor;
      canvas.drawRect(cellRect, paint);
      // 选中时高亮同区域
      _drawRegionHighlight(canvas, board, cell, ctx);
      return;
    }
    if (cell.isHighlighted) {
      paint.color = ctx.colors.boardHighlightedCellColor.withAlpha(0x99);
      canvas.drawRect(cellRect, paint);
      return;
    }
    paint.color = _getRegionBackgroundColor(board, row, col, ctx);
    canvas.drawRect(cellRect, paint);
  }

  @override
  void drawSpecialElements(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    _drawRegionBoundaries(canvas, board, size, ctx);
    if (ctx.showRegionNumbers) _drawRegionNumbers(canvas, board, ctx);
  }

  Color _getRegionBackgroundColor(Board board, int row, int col, BoardRenderContext ctx) {
    final matrix = _getRegionMatrix(board);
    if (matrix == null) return ctx.colors.boardCellBackgroundColor;
    final regionId = matrix[row][col];
    if (regionId < 0 || regionId >= 9) return ctx.colors.boardCellBackgroundColor;
    final colors = ctx.colors.boardRegionColors;
    return colors[regionId % colors.length];
  }

  void _drawRegionHighlight(Canvas canvas, Board board, Cell cell, BoardRenderContext ctx) {
    final matrix = _getRegionMatrix(board);
    if (matrix == null) return;
    final regionId = matrix[cell.row][cell.col];
    final highlightPaint = Paint()..color = ctx.colors.boardSelectedCellColor.withAlpha(0x30)..style = PaintingStyle.fill;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (matrix[i][j] == regionId && !(i == cell.row && j == cell.col)) {
          canvas.drawRect(Rect.fromLTWH(j * ctx.cellSize, i * ctx.cellSize, ctx.cellSize, ctx.cellSize), highlightPaint);
        }
      }
    }
  }

  void _drawRegionBoundaries(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    final matrix = _getRegionMatrix(board);
    if (matrix == null) return;
    final boundaryPaint = Paint()..strokeWidth = 1.5..style = PaintingStyle.stroke..color = ctx.colors.primaryColor;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final cellRect = Rect.fromLTWH(j * ctx.cellSize, i * ctx.cellSize, ctx.cellSize, ctx.cellSize);
        final regionId = matrix[i][j];
        final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];
        for (final dir in directions) {
          final ni = i + dir.$1, nj = j + dir.$2;
          final shouldDraw = ni < 0 || ni >= 9 || nj < 0 || nj >= 9 || matrix[ni][nj] != regionId;
          if (shouldDraw) {
            if (dir.$1 == -1) {
              canvas.drawLine(cellRect.topLeft, cellRect.topRight, boundaryPaint);
            } else if (dir.$1 == 1) {
              canvas.drawLine(cellRect.bottomLeft, cellRect.bottomRight, boundaryPaint);
            } else if (dir.$2 == -1) {
              canvas.drawLine(cellRect.topLeft, cellRect.bottomLeft, boundaryPaint);
            } else if (dir.$2 == 1) {
              canvas.drawLine(cellRect.topRight, cellRect.bottomRight, boundaryPaint);
            }
          }
        }
      }
    }
  }

  void _drawRegionNumbers(Canvas canvas, Board board, BoardRenderContext ctx) {
    final matrix = _getRegionMatrix(board);
    if (matrix == null) return;
    for (var regionId = 0; regionId < 9; regionId++) {
      int minRow = 9, minCol = 9;
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          if (matrix[i][j] == regionId && (i < minRow || (i == minRow && j < minCol))) {
            minRow = i; minCol = j;
          }
        }
      }
      final cellRect = Rect.fromLTWH(minCol * ctx.cellSize, minRow * ctx.cellSize, ctx.cellSize, ctx.cellSize);
      final circleRadius = ctx.cellSize * 0.18;
      final circleCenter = Offset(cellRect.left + ctx.cellSize * 0.2, cellRect.top + ctx.cellSize * 0.2);
      final circlePaint = Paint()..color = ctx.colors.boardRegionNumberColor.withAlpha(0x80)..style = PaintingStyle.fill;
      canvas.drawCircle(circleCenter, circleRadius, circlePaint);
      final textPainter = TextPainter(
        text: TextSpan(text: (regionId + 1).toString(), style: AppTextStyles.candidate.copyWith(color: ctx.colors.boardRegionNumberColor, fontSize: ctx.cellSize * 0.2, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(circleCenter.dx - textPainter.width / 2, circleCenter.dy - textPainter.height / 2));
    }
  }
}
