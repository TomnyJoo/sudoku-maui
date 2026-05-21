import 'dart:ui';
import 'package:sudoku/index.dart';
import 'board_render_context.dart';

/// 棋盘渲染器抽象基类
///
/// 提供通用的单元格绘制、网格线绘制等基础功能，
/// 子类只需实现 drawSpecialElements 来处理特殊元素。
abstract class BoardRendererBase {
  const BoardRendererBase();

  /// 绘制棋盘背景（网格线、宫粗线、高亮背景）
  void drawBackground(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    _drawGrid(canvas, size, ctx);
  }

  /// 绘制单元格内容（数字、候选数、错误标记）
  void drawCells(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final cell = board.cells[row][col];
        final cellRect = Rect.fromLTWH(col * ctx.cellSize, row * ctx.cellSize, ctx.cellSize, ctx.cellSize);
        drawCellBackground(canvas, board, cell, cellRect, row, col, ctx);
        drawCellValue(canvas, cell, cellRect, ctx);
      }
    }
  }

  /// 绘制特殊元素（子类覆写）
  void drawSpecialElements(Canvas canvas, Board board, Size size, BoardRenderContext ctx) {}

  /// 绘制单个单元格背景（子类可覆写以添加特殊背景）
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
    paint.color = ctx.colors.boardCellBackgroundColor;
    canvas.drawRect(cellRect, paint);
  }

  /// 绘制单元格值（数字或候选数）
  void drawCellValue(Canvas canvas, Cell cell, Rect cellRect, BoardRenderContext ctx) {
    if (cell.value != null) {
      final textStyle = cell.isFixed
          ? AppTextStyles.cellFixed.copyWith(color: ctx.colors.boardFixedValueColor, fontWeight: FontWeight.bold)
          : AppTextStyles.cellUser.copyWith(
              color: (ctx.highlightMistakesEnabled && cell.isError) ? ctx.colors.errorColor : ctx.colors.boardUserValueColor);
      ctx.drawTextInCenter(canvas, cell.value.toString(), cellRect, textStyle);
    } else if (cell.candidates.isNotEmpty) {
      _drawCandidates(canvas, cell, cellRect, ctx);
    }
  }

  void _drawCandidates(Canvas canvas, Cell cell, Rect cellRect, BoardRenderContext ctx) {
    final candidateColor = ctx.colors.boardMarkerColor;
    final candidateRect = Rect.fromLTWH(cellRect.left + 2, cellRect.top + 2, cellRect.width - 4, cellRect.height - 4);
    final smallCellSize = candidateRect.width / 3;
    for (var num = 1; num <= 9; num++) {
      if (cell.candidates.contains(num)) {
        final r = ((num - 1) ~/ 3).floor();
        final c = ((num - 1) % 3).floor();
        final textRect = Rect.fromLTWH(candidateRect.left + c * smallCellSize, candidateRect.top + r * smallCellSize, smallCellSize, smallCellSize);
        ctx.drawTextInCenter(canvas, num.toString(), textRect, AppTextStyles.candidate.copyWith(color: candidateColor));
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, BoardRenderContext ctx) {
    final thinPaint = Paint()..color = ctx.colors.boardGridLineColor..strokeWidth = 1.0;
    final thickPaint = Paint()..color = ctx.colors.boardGridLineBoldColor..strokeWidth = 3.0;
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
}
