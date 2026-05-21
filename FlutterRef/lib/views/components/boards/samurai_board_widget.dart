import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';

/// 武士数独棋盘组件
///
/// 特点：
/// 1. 只显示当前选中的9x9子数独
/// 2. 支持滚动
/// 3. 角宫格有明显的颜色区分
class SamuraiBoardWidget extends GameBoardWidget<Cell> {

  const SamuraiBoardWidget({
    required this.board,
    required this.solution,
    required this.isShowingSolution,
    required this.onCellSelected,
    required this.currentSubGridIndex,
    required super.cellSize,
    super.key,
  });
  final SamuraiBoard board;
  final SamuraiBoard solution;
  final bool isShowingSolution;
  final Function(Cell) onCellSelected;
  final int currentSubGridIndex;

  @override
  CustomPainter createBoardPainter(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    return SamuraiBoardPainter(
      board: board,
      solution: solution,
      isShowingSolution: isShowingSolution,
      currentSubGridIndex: currentSubGridIndex,
      cellSize: cellSize,
      context: context,
      highlightMistakesEnabled: settings.highlightMistakesEnabled,
      themeData: Theme.of(context),
    );
  }

  @override
  void onCellTap(int row, int col) {
    final subGridOffset = SamuraiBoard.subGridOffsets[currentSubGridIndex];
    final actualRow = subGridOffset.$1 + row;
    final actualCol = subGridOffset.$2 + col;
    final cell = board.getCell(actualRow, actualCol);
    onCellSelected(cell);
  }
}

class SamuraiBoardPainter extends BaseBoardPainter<Cell> {

  SamuraiBoardPainter({
    required this.board,
    required this.solution,
    required this.isShowingSolution,
    required this.currentSubGridIndex,
    required super.cellSize,
    required super.context,
    required this.highlightMistakesEnabled,
    required super.themeData,
  });
  final SamuraiBoard board;
  final SamuraiBoard solution;
  final bool isShowingSolution;
  final int currentSubGridIndex;
  final bool highlightMistakesEnabled;

  @override
  void paintBoard(Canvas canvas, Size size) {
    _drawCells(canvas);
    _drawGrid(canvas, size);
  }

  void _drawCells(Canvas canvas) {
    final subGridOffset = SamuraiBoard.subGridOffsets[currentSubGridIndex];
    final (subGridStartRow, subGridStartCol) = subGridOffset;

    for (var row = 0; row < SamuraiConstants.subGridSize; row++) {
      for (var col = 0; col < SamuraiConstants.subGridSize; col++) {
        final actualRow = subGridStartRow + row;
        final actualCol = subGridStartCol + col;
        final cell = board.getCell(actualRow, actualCol);

        final cellRect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        _drawCellBackground(canvas, cell, cellRect, themeData, row, col);
        _drawCellValue(canvas, cell, actualRow, actualCol, cellRect, themeData);
      }
    }
  }

  void _drawCellBackground(Canvas canvas, Cell cell, Rect cellRect, ThemeData theme, int row, int col) {
    final paint = Paint();

    if (cell.isSelected) {
      paint.color = context.boardSelectedCellColor;
    } else if (cell.isHighlighted) {
      paint.color = context.boardHighlightedCellColor.withAlpha(0x99);
    } else if (_isCornerBlock(row, col)) {
      paint.color = _getCornerBlockColor(row, col);
    } else {
      paint.color = context.boardCellBackgroundColor;
    }

    canvas.drawRect(cellRect, paint);
  }

  bool _isCornerBlock(int row, int col) {
    final blockRow = row ~/ 3;
    final blockCol = col ~/ 3;
    return blockRow == 0 || blockRow == 2 || blockCol == 0 || blockCol == 2;
  }

  Color _getCornerBlockColor(int row, int col) {
    final blockRow = row ~/ 3;
    final blockCol = col ~/ 3;

    if (blockRow == 0 && blockCol == 0) {
      return AppColors.error.withAlpha(0x33);
    } else if (blockRow == 0 && blockCol == 2) {
      return AppColors.info.withAlpha(0x33);
    } else if (blockRow == 2 && blockCol == 0) {
      return AppColors.success.withAlpha(0x33);
    } else if (blockRow == 2 && blockCol == 2) {
      return AppColors.warning.withAlpha(0x33);
    }

    return context.boardCellBackgroundColor;
  }

  void _drawCellValue(Canvas canvas, Cell cell, int actualRow, int actualCol, Rect cellRect, ThemeData theme) {

    // 如果正在显示答案且单元格为空，显示答案值
    if (isShowingSolution && cell.value == null) {
      final solutionCell = solution.getCell(actualRow, actualCol);
      if (solutionCell.value != null) {
        final textStyle = AppTextStyles.cellUser.copyWith(
          color: context.boardSolutionValueColor,
          fontWeight: FontWeight.bold,
        );
        drawTextInCenter(
          canvas,
          solutionCell.value.toString(),
          cellRect,
          textStyle,
        );
      }
    } else if (cell.value != null) {

      final textStyle = cell.isFixed
          ? AppTextStyles.cellFixed.copyWith(
              color: context.boardFixedValueColor,
              fontWeight: FontWeight.bold,
            )
          : AppTextStyles.cellUser.copyWith(
              color: (highlightMistakesEnabled && cell.isError)
                  ? context.errorColor
                  : context.boardUserValueColor,
            );

      drawTextInCenter(
        canvas,
        cell.value.toString(),
        cellRect,
        textStyle,
      );
    } else if (cell.candidates.isNotEmpty) {
      _drawCandidates(canvas, cell, cellRect, theme);
    }
  }

  void _drawCandidates(Canvas canvas, Cell cell, Rect cellRect, ThemeData theme) {
    final candidateColor = context.boardMarkerColor;

    final candidateRect = Rect.fromLTWH(
      cellRect.left + 2,
      cellRect.top + 2,
      cellRect.width - 4,
      cellRect.height - 4,
    );

    final smallCellSize = candidateRect.width / 3;

    for (var num = 1; num <= 9; num++) {
      if (cell.candidates.contains(num)) {
        final row = ((num - 1) ~/ 3).floor();
        final col = ((num - 1) % 3).floor();

        final textRect = Rect.fromLTWH(
          candidateRect.left + col * smallCellSize,
          candidateRect.top + row * smallCellSize,
          smallCellSize,
          smallCellSize,
        );

        drawTextInCenter(
          canvas,
          num.toString(),
          textRect,
          AppTextStyles.candidate.copyWith(
            color: candidateColor,
          ),
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var row = 0; row <= 9; row++) {
      paint.color = (row % 3 == 0) ? Colors.black : Colors.grey;
      canvas.drawLine(
        Offset(0, row * cellSize),
        Offset(size.width, row * cellSize),
        paint,
      );
    }

    for (var col = 0; col <= 9; col++) {
      paint.color = (col % 3 == 0) ? Colors.black : Colors.grey;
      canvas.drawLine(
        Offset(col * cellSize, 0),
        Offset(col * cellSize, size.height),
        paint,
      );
    }

    paint..strokeWidth = 2.0
    ..color = Colors.black;

    canvas..drawLine(
      Offset.zero,
      Offset(size.width, 0),
      paint,
    )
    ..drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    )
    ..drawLine(
      Offset.zero,
      Offset(0, size.height),
      paint,
    )
    ..drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SamuraiBoardPainter oldDelegate) {
    // 检查棋盘是否是同一个实例
    if (!identical(board, oldDelegate.board)) return true;
    if (!identical(solution, oldDelegate.solution)) return true;
    
    // 检查关键属性是否发生变化
    if (currentSubGridIndex != oldDelegate.currentSubGridIndex) return true;
    if (isShowingSolution != oldDelegate.isShowingSolution) return true;
    if (highlightMistakesEnabled != oldDelegate.highlightMistakesEnabled) return true;
    
    // 只检查当前子网格的单元格是否发生变化
    final subGridOffset = SamuraiBoard.subGridOffsets[currentSubGridIndex];
    final (subGridStartRow, subGridStartCol) = subGridOffset;
    
    for (int row = 0; row < SamuraiConstants.subGridSize; row++) {
      for (int col = 0; col < SamuraiConstants.subGridSize; col++) {
        final actualRow = subGridStartRow + row;
        final actualCol = subGridStartCol + col;
        final cell = board.getCell(actualRow, actualCol);
        final oldCell = oldDelegate.board.getCell(actualRow, actualCol);
        if (cell.value != oldCell.value ||
            cell.isSelected != oldCell.isSelected ||
            cell.isHighlighted != oldCell.isHighlighted ||
            cell.isError != oldCell.isError ||
            !areSetsEqual(cell.candidates, oldCell.candidates)) {
          return true;
        }
      }
    }
    
    return false;
  }
}
