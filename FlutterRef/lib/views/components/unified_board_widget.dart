import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/constants/game_constants.dart';
import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';
import 'package:sudoku/models/killer_cage.dart';
import 'package:sudoku/renderers/board_render_context.dart';
import 'package:sudoku/services/app_settings.dart';
import 'package:sudoku/theme/app_colors.dart';
import 'package:sudoku/theme/app_text_styles.dart';

/// 统一棋盘组件
///
/// 通过 board.gameType 条件分支处理不同游戏类型的绘制差异
class UnifiedBoardWidget extends StatelessWidget {
  const UnifiedBoardWidget({
    required this.board,
    required this.onCellSelected,
    required this.cellSize,
    this.showDiagonalLines = true,
    this.showRegionNumbers = true,
    this.showCageSums = true,
    this.showCageBorders = true,
    super.key,
  });

  final Board board;
  final Function(Cell) onCellSelected;
  final double cellSize;
  final bool showDiagonalLines;
  final bool showRegionNumbers;
  final bool showCageSums;
  final bool showCageBorders;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final boardSize = cellSize * 9;
    final colors = BoardColors.fromContext(context);

    return RepaintBoundary(
      child: GestureDetector(
        onTapUp: (final TapUpDetails details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            final col = (localPosition.dx / cellSize).floor();
            final row = (localPosition.dy / cellSize).floor();

            if (row >= 0 && row < 9 && col >= 0 && col < 9) {
              onCellSelected(board.cells[row][col]);
            }
          }
        },
        child: SizedBox(
          width: boardSize,
          height: boardSize,
          child: CustomPaint(
            painter: _UnifiedBoardPainter(
              board: board,
              cellSize: cellSize,
              colors: colors,
              highlightMistakesEnabled: settings.highlightMistakesEnabled,
              showDiagonalLines: showDiagonalLines,
              showRegionNumbers: showRegionNumbers,
              showCageSums: showCageSums,
              showCageBorders: showCageBorders,
            ),
            size: Size(boardSize, boardSize),
          ),
        ),
      ),
    );
  }
}

/// 统一棋盘绘制器
class _UnifiedBoardPainter extends CustomPainter {
  _UnifiedBoardPainter({
    required this.board,
    required this.cellSize,
    required this.colors,
    required this.highlightMistakesEnabled,
    required this.showDiagonalLines,
    required this.showRegionNumbers,
    required this.showCageSums,
    required this.showCageBorders,
  });

  final Board board;
  final double cellSize;
  final BoardColors colors;
  final bool highlightMistakesEnabled;
  final bool showDiagonalLines;
  final bool showRegionNumbers;
  final bool showCageSums;
  final bool showCageBorders;

  String get _gameType => board.gameType;

  bool get _isDiagonal => _gameType == 'diagonal';
  bool get _isWindow => _gameType == 'window';
  bool get _isJigsaw => _gameType == 'jigsaw';
  bool get _isKiller => _gameType == 'killer';

  List<List<int>>? get _regionMatrix {
    if (board is JigsawBoard) {
      return (board as JigsawBoard).regionMatrix;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Window: 先绘制窗口背景
    if (_isWindow) {
      _drawWindowBackgrounds(canvas);
    }

    // Killer: 先绘制笼子背景
    if (_isKiller) {
      _drawKillerCageBackgrounds(canvas);
    }

    // 绘制所有单元格
    _drawCells(canvas);

    // 绘制网格线
    _drawGrid(canvas, size);

    // Jigsaw: 绘制区域边界和区域编号
    if (_isJigsaw) {
      _drawRegionBoundaries(canvas, size);
      _drawRegionNumbers(canvas);
    }

    // Diagonal: 绘制对角线
    if (_isDiagonal && showDiagonalLines) {
      _drawDiagonalLines(canvas, size);
    }

    // Killer: 绘制笼子和值
    if (_isKiller && showCageSums) {
      _drawKillerCageSums(canvas);
    }
  }

  // ========== 单元格绘制 ==========

  void _drawCells(Canvas canvas) {
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final cell = board.cells[row][col];
        final cellRect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        _drawCellBackground(canvas, cell, cellRect, row, col);
        _drawCellValue(canvas, cell, cellRect);
      }
    }
  }

  void _drawCellBackground(Canvas canvas, Cell cell, Rect cellRect, int row, int col) {
    final paint = Paint();

    if (cell.isSelected) {
      paint.color = colors.boardSelectedCellColor;
      canvas.drawRect(cellRect, paint);

      // Jigsaw: 选中时高亮同区域
      if (_isJigsaw) {
        _drawRegionHighlight(canvas, cell);
      }
      return;
    }

    if (cell.isHighlighted) {
      paint.color = colors.boardHighlightedCellColor.withAlpha(0x99);
      canvas.drawRect(cellRect, paint);
      return;
    }

    // 根据游戏类型绘制不同背景
    if (_isDiagonal) {
      final isOnMainDiagonal = row == col;
      final isOnAntiDiagonal = row + col == DiagonalConstants.boardSize - 1;
      final isOnDiagonal = isOnMainDiagonal || isOnAntiDiagonal;
      paint.color = isOnDiagonal
          ? colors.boardCellBackgroundColor.withAlpha(0x99)
          : colors.boardCellBackgroundColor;
    } else if (_isWindow) {
      if (!_isCellInWindowRegion(row, col)) {
        paint.color = colors.boardCellBackgroundColor;
      } else {
        paint.color = colors.boardWindowBackgroundColor;
      }
    } else if (_isJigsaw) {
      paint.color = _getRegionBackgroundColor(row, col);
    } else if (_isKiller) {
      // Killer 的背景由 _drawKillerCageBackgrounds 处理
      return;
    } else {
      paint.color = colors.boardCellBackgroundColor;
    }

    canvas.drawRect(cellRect, paint);
  }

  void _drawCellValue(Canvas canvas, Cell cell, Rect cellRect) {
    if (cell.value != null) {
      final textStyle = cell.isFixed
          ? AppTextStyles.cellFixed.copyWith(
              color: colors.boardFixedValueColor,
              fontWeight: FontWeight.bold,
            )
          : AppTextStyles.cellUser.copyWith(
              color: (highlightMistakesEnabled && cell.isError)
                  ? colors.errorColor
                  : colors.boardUserValueColor,
            );

      _drawTextInCenter(canvas, cell.value.toString(), cellRect, textStyle);
    } else if (cell.candidates.isNotEmpty) {
      _drawCandidates(canvas, cell, cellRect);
    }
  }

  void _drawCandidates(Canvas canvas, Cell cell, Rect cellRect) {
    final candidateColor = colors.boardMarkerColor;

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

        _drawTextInCenter(
          canvas,
          num.toString(),
          textRect,
          AppTextStyles.candidate.copyWith(color: candidateColor),
        );
      }
    }
  }

  // ========== 网格线绘制 ==========

  void _drawGrid(Canvas canvas, Size size) {
    final thinPaint = Paint()
      ..color = colors.boardGridLineColor
      ..strokeWidth = 1.0;

    final thickPaint = Paint()
      ..color = colors.boardGridLineBoldColor
      ..strokeWidth = _isWindow ? 2.5 : 3.0;

    // 锯齿数独不绘制宫格粗线（使用统一的细线）
    final useBlockThickLines = !_isJigsaw;

    for (var i = 0; i <= 9; i++) {
      final x = i * cellSize;
      final paint = (useBlockThickLines && i % 3 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var i = 0; i <= 9; i++) {
      final y = i * cellSize;
      final paint = (useBlockThickLines && i % 3 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  // ========== Diagonal 特有绘制 ==========

  void _drawDiagonalLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..color = colors.boardGridLineBoldColor.withAlpha(0x80);

    _drawDashedLine(canvas, Offset.zero, Offset(size.width, size.height), paint);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 6.0;
    const gapLength = 4.0;

    final totalLength = (end - start).distance;
    final dashCount = (totalLength / (dashLength + gapLength)).floor();

    final dx = (end.dx - start.dx) / totalLength;
    final dy = (end.dy - start.dy) / totalLength;

    for (var i = 0; i < dashCount; i++) {
      final dashStart = i * (dashLength + gapLength);
      final dashEnd = dashStart + dashLength;

      canvas.drawLine(
        Offset(start.dx + dx * dashStart, start.dy + dy * dashStart),
        Offset(start.dx + dx * dashEnd, start.dy + dy * dashEnd),
        paint,
      );
    }
  }

  // ========== Window 特有绘制 ==========

  void _drawWindowBackgrounds(Canvas canvas) {
    for (final windowRegion in WindowConstants.windowRegions) {
      final windowRect = Rect.fromLTWH(
        windowRegion.startCol * cellSize,
        windowRegion.startRow * cellSize,
        windowRegion.width * cellSize,
        windowRegion.height * cellSize,
      );

      final paint = Paint()
        ..color = colors.boardWindowBackgroundColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(windowRect, paint);
    }
  }

  bool _isCellInWindowRegion(int row, int col) {
    for (final windowRegion in WindowConstants.windowRegions) {
      if (row >= windowRegion.startRow &&
          row <= windowRegion.endRow &&
          col >= windowRegion.startCol &&
          col <= windowRegion.endCol) {
        return true;
      }
    }
    return false;
  }

  // ========== Jigsaw 特有绘制 ==========

  Color _getRegionBackgroundColor(int row, int col) {
    final matrix = _regionMatrix;
    if (matrix == null) return colors.boardCellBackgroundColor;

    final regionId = matrix[row][col];
    if (regionId < 0 || regionId >= 9) {
      return colors.boardCellBackgroundColor;
    }

    final regionColors = colors.boardRegionColors;
    return regionColors[regionId % regionColors.length];
  }

  void _drawRegionHighlight(Canvas canvas, Cell cell) {
    final matrix = _regionMatrix;
    if (matrix == null) return;

    final regionId = matrix[cell.row][cell.col];
    final regionCells = _getRegionCellsCache(matrix)[regionId] ?? [];

    final highlightPaint = Paint()
      ..color = colors.boardSelectedCellColor.withAlpha(0x30)
      ..style = PaintingStyle.fill;

    for (final regionCell in regionCells) {
      if (regionCell.$1 == cell.row && regionCell.$2 == cell.col) continue;

      final cellRect = Rect.fromLTWH(
        regionCell.$2 * cellSize,
        regionCell.$1 * cellSize,
        cellSize,
        cellSize,
      );

      canvas.drawRect(cellRect, highlightPaint);
    }
  }

  Map<int, List<(int, int)>> _getRegionCellsCache(List<List<int>> matrix) {
    final cache = <int, List<(int, int)>>{};
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final regionId = matrix[i][j];
        cache.putIfAbsent(regionId, () => []);
        cache[regionId]!.add((i, j));
      }
    }
    return cache;
  }

  Map<int, (int, int)> _getRegionMinCellCache(List<List<int>> matrix) {
    final regionCellsCache = _getRegionCellsCache(matrix);
    final cache = <int, (int, int)>{};
    for (int regionId = 0; regionId < 9; regionId++) {
      final regionCells = regionCellsCache[regionId] ?? [];
      if (regionCells.isEmpty) continue;

      int minRow = 9, minCol = 9;
      for (final cell in regionCells) {
        if (cell.$1 < minRow || (cell.$1 == minRow && cell.$2 < minCol)) {
          minRow = cell.$1;
          minCol = cell.$2;
        }
      }
      cache[regionId] = (minRow, minCol);
    }
    return cache;
  }

  void _drawRegionBoundaries(Canvas canvas, Size size) {
    final matrix = _regionMatrix;
    if (matrix == null) return;

    final boundaryPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..color = colors.primaryColor;

    final regionCellsCache = _getRegionCellsCache(matrix);

    for (var regionId = 0; regionId < 9; regionId++) {
      final regionCells = regionCellsCache[regionId] ?? [];
      if (regionCells.isEmpty) continue;

      for (final cell in regionCells) {
        final cellRect = Rect.fromLTWH(
          cell.$2 * cellSize,
          cell.$1 * cellSize,
          cellSize,
          cellSize,
        );

        final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];
        for (final neighbor in directions) {
          final newRow = cell.$1 + neighbor.$1;
          final newCol = cell.$2 + neighbor.$2;

          if (newRow >= 0 && newRow < 9 && newCol >= 0 && newCol < 9) {
            final neighborRegionId = matrix[newRow][newCol];
            if (neighborRegionId != regionId) {
              _drawBoundaryBetweenCells(canvas, cellRect, neighbor, boundaryPaint);
            }
          } else {
            _drawBoundaryBetweenCells(canvas, cellRect, neighbor, boundaryPaint);
          }
        }
      }
    }
  }

  void _drawBoundaryBetweenCells(
    Canvas canvas,
    Rect cellRect,
    (int, int) direction,
    Paint paint,
  ) {
    if (direction.$1 == -1) {
      canvas.drawLine(cellRect.topLeft, cellRect.topRight, paint);
    } else if (direction.$1 == 1) {
      canvas.drawLine(cellRect.bottomLeft, cellRect.bottomRight, paint);
    } else if (direction.$2 == -1) {
      canvas.drawLine(cellRect.topLeft, cellRect.bottomLeft, paint);
    } else if (direction.$2 == 1) {
      canvas.drawLine(cellRect.topRight, cellRect.bottomRight, paint);
    }
  }

  void _drawRegionNumbers(Canvas canvas) {
    if (!showRegionNumbers) return;
    final matrix = _regionMatrix;
    if (matrix == null) return;

    final regionMinCellCache = _getRegionMinCellCache(matrix);

    for (var regionId = 0; regionId < 9; regionId++) {
      final minCell = regionMinCellCache[regionId];
      if (minCell == null) continue;

      final cellRect = Rect.fromLTWH(
        minCell.$2 * cellSize,
        minCell.$1 * cellSize,
        cellSize,
        cellSize,
      );

      final circleRadius = cellSize * 0.18;
      final circleCenter = Offset(
        cellRect.left + cellSize * 0.2,
        cellRect.top + cellSize * 0.2,
      );

      final circlePaint = Paint()
        ..color = colors.boardRegionNumberColor.withAlpha(0x80)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(circleCenter, circleRadius, circlePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: (regionId + 1).toString(),
          style: AppTextStyles.candidate.copyWith(
            color: colors.boardRegionNumberColor,
            fontSize: cellSize * 0.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        circleCenter.dx - textPainter.width / 2,
        circleCenter.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  // ========== Killer 特有绘制 ==========

  void _drawKillerCageBackgrounds(Canvas canvas) {
    if (board is! KillerBoard) return;
    final killerBoard = board as KillerBoard;

    final cageColorMap = _buildKillerCageColorMap(killerBoard);

    for (final cage in killerBoard.cages) {
      final colorIndex = cageColorMap[cage.id] ?? 0;
      final cageColor = colors.getBoardCageColor(colorIndex).withValues(alpha: 0.55);

      // 绘制笼子背景色
      final fillPaint = Paint()
        ..color = cageColor
        ..style = PaintingStyle.fill;

      for (final coord in cage.cellCoordinates) {
        final cellRect = Rect.fromLTWH(
          coord.$2 * cellSize,
          coord.$1 * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(cellRect, fillPaint);
      }

      // 绘制笼子边线（红色虚线）
      final borderPaint = Paint()
        ..color = colors.isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      for (final coord in cage.cellCoordinates) {
        final x = coord.$2 * cellSize;
        final y = coord.$1 * cellSize;

        // 上边：如果上方格子不属于同一笼子，画虚线
        if (!cage.cellCoordinates.contains((coord.$1 - 1, coord.$2))) {
          _drawDashedLine(canvas, Offset(x, y), Offset(x + cellSize, y), borderPaint);
        }
        // 下边
        if (!cage.cellCoordinates.contains((coord.$1 + 1, coord.$2))) {
          _drawDashedLine(canvas, Offset(x, y + cellSize), Offset(x + cellSize, y + cellSize), borderPaint);
        }
        // 左边
        if (!cage.cellCoordinates.contains((coord.$1, coord.$2 - 1))) {
          _drawDashedLine(canvas, Offset(x, y), Offset(x, y + cellSize), borderPaint);
        }
        // 右边
        if (!cage.cellCoordinates.contains((coord.$1, coord.$2 + 1))) {
          _drawDashedLine(canvas, Offset(x + cellSize, y), Offset(x + cellSize, y + cellSize), borderPaint);
        }
      }
    }
  }

  Map<String, int> _buildKillerCageColorMap(KillerBoard killerBoard) {
    final colorMap = <String, int>{};
    if (killerBoard.cages.isEmpty) return colorMap;

    final sortedCages = killerBoard.cages.toList()
      ..sort((a, b) => b.cellCount.compareTo(a.cellCount));

    for (final cage in sortedCages) {
      final adjacentCages = _findAdjacentKillerCages(cage, killerBoard.cages);
      final usedColors = adjacentCages
          .where((c) => colorMap.containsKey(c.id))
          .map((c) => colorMap[c.id]!)
          .toSet();

      var colorIndex = 0;
      while (usedColors.contains(colorIndex) && colorIndex < 8) {
        colorIndex++;
      }
      colorMap[cage.id] = colorIndex;
    }

    return colorMap;
  }

  List<KillerCage> _findAdjacentKillerCages(KillerCage cage, List<KillerCage> allCages) {
    final adjacent = <KillerCage>[];
    for (final other in allCages) {
      if (other.id == cage.id) continue;
      for (final coord in cage.cellCoordinates) {
        final neighbors = [
          (coord.$1 - 1, coord.$2),
          (coord.$1 + 1, coord.$2),
          (coord.$1, coord.$2 - 1),
          (coord.$1, coord.$2 + 1),
        ];
        for (final neighbor in neighbors) {
          if (other.cellCoordinates.contains(neighbor)) {
            adjacent.add(other);
            break;
          }
        }
        if (adjacent.contains(other)) break;
      }
    }
    return adjacent;
  }

  void _drawKillerCageSums(Canvas canvas) {
    if (board is! KillerBoard) return;
    final killerBoard = board as KillerBoard;

    for (final cage in killerBoard.cages) {
      final position = _findBestKillerSumPosition(cage, killerBoard);

      final cellRect = Rect.fromLTWH(
        position.$2 * cellSize,
        position.$1 * cellSize,
        cellSize,
        cellSize,
      );

      const sumFontSize = 11.0;
      final sumText = TextSpan(
        text: cage.sum.toString(),
        style: TextStyle(
          fontSize: sumFontSize,
          fontWeight: FontWeight.w700,
          color: colors.isDarkMode ? AppColors.boardDarkCageSumNew : AppColors.boardLightCageSumNew,
          height: 1.0,
        ),
      );

      final textPainter = TextPainter(
        text: sumText,
        textDirection: TextDirection.ltr,
      )..layout();

      const padding = 2.0;
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cellRect.left + 2,
          cellRect.top + 2,
          textPainter.width + padding * 2,
          textPainter.height + padding,
        ),
        const Radius.circular(3),
      );

      final bgPaint = Paint()
        ..color = colors.boardCellBackgroundColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(bgRect, bgPaint);

      final x = cellRect.left + 2 + padding;
      final y = cellRect.top + 2 + padding / 2;
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  (int, int) _findBestKillerSumPosition(KillerCage cage, KillerBoard killerBoard) {
    for (final coord in cage.cellCoordinates) {
      final cell = killerBoard.getCell(coord.$1, coord.$2);
      if (cell.value != null) return coord;
    }
    for (final coord in cage.cellCoordinates) {
      final cell = killerBoard.getCell(coord.$1, coord.$2);
      if (cell.candidates.isEmpty) return coord;
    }
    var bestCoord = cage.cellCoordinates.first;
    var minCandidates = 10;
    for (final coord in cage.cellCoordinates) {
      final cell = killerBoard.getCell(coord.$1, coord.$2);
      if (cell.candidates.length < minCandidates) {
        minCandidates = cell.candidates.length;
        bestCoord = coord;
      }
    }
    return bestCoord;
  }

  // ========== 通用工具方法 ==========

  void _drawTextInCenter(Canvas canvas, String text, Rect rect, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final offset = Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _UnifiedBoardPainter oldDelegate) {
    if (oldDelegate.cellSize != cellSize) return true;
    if (oldDelegate.colors != colors) return true;
    if (oldDelegate.highlightMistakesEnabled != highlightMistakesEnabled) return true;
    if (oldDelegate.showDiagonalLines != showDiagonalLines) return true;
    if (oldDelegate.showRegionNumbers != showRegionNumbers) return true;
    if (oldDelegate.showCageSums != showCageSums) return true;
    if (oldDelegate.showCageBorders != showCageBorders) return true;

    // 检查 board 是否变化
    if (oldDelegate.board.cells.length != board.cells.length) return true;
    for (var i = 0; i < board.cells.length; i++) {
      if (oldDelegate.board.cells[i].length != board.cells[i].length) return true;
      for (var j = 0; j < board.cells[i].length; j++) {
        if (!_areCellsEqual(oldDelegate.board.cells[i][j], board.cells[i][j])) {
          return true;
        }
      }
    }

    // Killer: 检查 cages 是否变化
    if (_isKiller && board is KillerBoard && oldDelegate.board is KillerBoard) {
      final oldKiller = oldDelegate.board as KillerBoard;
      final newKiller = board as KillerBoard;
      if (oldKiller.cages.length != newKiller.cages.length) return true;
      if (oldKiller.stateHash != newKiller.stateHash) return true;
    }

    return false;
  }

  bool _areCellsEqual(Cell a, Cell b) =>
      a.value == b.value &&
      a.isFixed == b.isFixed &&
      a.isSelected == b.isSelected &&
      a.isHighlighted == b.isHighlighted &&
      a.isError == b.isError &&
      a.candidates.length == b.candidates.length &&
      _areSetsEqual(a.candidates, b.candidates);

  bool _areSetsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}
