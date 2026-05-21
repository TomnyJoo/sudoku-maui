import 'dart:ui';

import 'package:sudoku/index.dart';

import 'board_render_context.dart';
import 'board_renderer_base.dart';

/// 对角线数独渲染器
class DiagonalBoardRenderer extends BoardRendererBase {
  const DiagonalBoardRenderer();

  @override
  void drawCellBackground(Canvas canvas, Board board, Cell cell, Rect cellRect, int row, int col, BoardRenderContext ctx) {
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
    final isOnMainDiagonal = row == col;
    final isOnAntiDiagonal = row + col == DiagonalConstants.boardSize - 1;
    final isOnDiagonal = isOnMainDiagonal || isOnAntiDiagonal;
    paint.color = isOnDiagonal ? ctx.colors.boardCellBackgroundColor.withAlpha(0x99) : ctx.colors.boardCellBackgroundColor;
    canvas.drawRect(cellRect, paint);
  }

  @override
  void drawSpecialElements(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    if (!ctx.showDiagonalLines) return;
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..color = ctx.colors.boardGridLineBoldColor.withAlpha(0x80);
    ctx
      ..drawDashedLine(canvas, Offset.zero, Offset(size.width, size.height), paint)
      ..drawDashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), paint);
  }
}
