import 'dart:ui';

import 'package:sudoku/index.dart';

import 'board_render_context.dart';
import 'board_renderer_base.dart';

/// 窗口数独渲染器
class WindowBoardRenderer extends BoardRendererBase {
  const WindowBoardRenderer();

  @override
  void drawBackground(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    // 先绘制窗口背景
    for (final windowRegion in WindowConstants.windowRegions) {
      final windowRect = Rect.fromLTWH(
        windowRegion.startCol * ctx.cellSize,
        windowRegion.startRow * ctx.cellSize,
        windowRegion.width * ctx.cellSize,
        windowRegion.height * ctx.cellSize,
      );
      final paint = Paint()..color = ctx.colors.boardWindowBackgroundColor..style = PaintingStyle.fill;
      canvas.drawRect(windowRect, paint);
    }
    // 网格线（窗口用稍细的粗线）
    final thinPaint = Paint()..color = ctx.colors.boardGridLineColor..strokeWidth = 1.0;
    final thickPaint = Paint()..color = ctx.colors.boardGridLineBoldColor..strokeWidth = 2.5;
    for (var i = 0; i <= 9; i++) {
      final x = i * ctx.cellSize;
      final paint = (i % 3 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 0; i <= 9; i++) {
      final y = i * ctx.cellSize;
      final paint = (i % 3 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

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
    paint.color = _isCellInWindowRegion(row, col) ? ctx.colors.boardWindowBackgroundColor : ctx.colors.boardCellBackgroundColor;
    canvas.drawRect(cellRect, paint);
  }

  bool _isCellInWindowRegion(int row, int col) {
    for (final windowRegion in WindowConstants.windowRegions) {
      if (row >= windowRegion.startRow && row <= windowRegion.endRow && col >= windowRegion.startCol && col <= windowRegion.endCol) {
        return true;
      }
    }
    return false;
  }
}
