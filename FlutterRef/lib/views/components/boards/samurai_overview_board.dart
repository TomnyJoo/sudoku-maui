import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// 武士数独概览棋盘组件
/// 
/// 显示完整的21x21棋盘，允许用户：
/// 1. 查看全局布局
/// 2. 点击子网格切换到该子网格的聚焦模式
/// 3. 缩放和平移查看细节
class SamuraiOverviewBoard extends StatefulWidget {

  const SamuraiOverviewBoard({
    required this.board,
    required this.solution,
    required this.isShowingSolution,
    required this.onCellSelected,
    required this.currentSubGridIndex,
    required this.cellSize,
    required this.onSubGridSelected,
    super.key,
  });
  final SamuraiBoard board;
  final SamuraiBoard solution;
  final bool isShowingSolution;
  final Function(Cell) onCellSelected;
  final int currentSubGridIndex;
  final double cellSize;
  final Function(int subGridIndex) onSubGridSelected;

  @override
  State<SamuraiOverviewBoard> createState() => _SamuraiOverviewBoardState();
}

class _SamuraiOverviewBoardState extends State<SamuraiOverviewBoard> {
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    // 初始缩放比例，使完整棋盘适应视图
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBoardToView();
    });
  }

  void _fitBoardToView() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final viewSize = renderBox.size;
      final boardSize = widget.cellSize * 21;
      // 减小缩放比例，确保棋盘完全可见（使用0.85而不是0.9）
      final scale = (viewSize.width < viewSize.height ? viewSize.width : viewSize.height) / boardSize * 0.85;
      
      // 计算平移量，使棋盘居中
      final offsetX = (viewSize.width - boardSize * scale) / 2;
      final offsetY = (viewSize.height - boardSize * scale) / 2;
      
      // 创建变换矩阵：使用向量进行平移和缩放
      final matrix = Matrix4.identity()
        ..translateByVector3(vm.Vector3(offsetX, offsetY, 0.0))
        ..scaleByVector3(vm.Vector3(scale, scale, 1.0));
      
      _transformationController.value = matrix;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = widget.cellSize * 21;
    
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.3,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(200),
      constrained: false,
      child: SizedBox(
        width: boardSize,
        height: boardSize,
        child: Stack(
          children: [
            // 底层：绘制棋盘
            CustomPaint(
              painter: SamuraiOverviewPainter(
                board: widget.board,
                solution: widget.solution,
                isShowingSolution: widget.isShowingSolution,
                currentSubGridIndex: widget.currentSubGridIndex,
                cellSize: widget.cellSize,
                context: context,
                themeData: Theme.of(context),
              ),
              size: Size(boardSize, boardSize),
            ),
            // 上层：可点击的子网格区域
            ..._buildSubGridClickAreas(),
          ],
        ),
      ),
    );
  }

  /// 构建子网格点击区域
  List<Widget> _buildSubGridClickAreas() {
    final subGridNames = LocalizationUtils.app(context).subGridNames;
    
    return List.generate(5, (index) {
      final (startRow, startCol) = SamuraiBoard.subGridOffsets[index];
      final left = startCol * widget.cellSize;
      final top = startRow * widget.cellSize;
      final size = 9 * widget.cellSize;
      
      return Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: GestureDetector(
          onTap: () => widget.onSubGridSelected(index),
          behavior: HitTestBehavior.translucent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: index == widget.currentSubGridIndex
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: index == widget.currentSubGridIndex
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subGridNames[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.cellSize * 0.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      );
    });
  }
}

/// 武士数独概览绘制器
class SamuraiOverviewPainter extends CustomPainter {

  SamuraiOverviewPainter({
    required this.board,
    required this.solution,
    required this.isShowingSolution,
    required this.currentSubGridIndex,
    required this.cellSize,
    required this.context,
    required this.themeData,
  });
  final SamuraiBoard board;
  final SamuraiBoard solution;
  final bool isShowingSolution;
  final int currentSubGridIndex;
  final double cellSize;
  final BuildContext context;
  final ThemeData themeData;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawCells(canvas);
    _drawGrid(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeData.colorScheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawCells(Canvas canvas) {
    final textStyle = TextStyle(
      color: themeData.colorScheme.onSurface,
      fontSize: cellSize * 0.6,
      fontWeight: FontWeight.bold,
    );

    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        // 跳过非子网格区域
        if (!_isInAnySubGrid(row, col)) continue;

        final cell = board.getCell(row, col);
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        // 绘制单元格背景
        _drawCellBackground(canvas, rect, cell, row, col);

        // 绘制数字
        if (cell.value != null || isShowingSolution) {
          final value = isShowingSolution 
              ? solution.getCell(row, col).value 
              : cell.value;
          if (value != null) {
            _drawCellValue(canvas, value.toString(), rect, textStyle, cell.isFixed);
          }
        }
      }
    }
  }

  void _drawCellBackground(Canvas canvas, Rect rect, Cell cell, int row, int col) {
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    // 固定数字背景
    if (cell.isFixed) {
      final paint = Paint()
        ..color = isDarkMode 
            ? Colors.grey.shade800 
            : Colors.grey.shade200;
      canvas.drawRect(rect, paint);
    }

    // 选中高亮
    if (cell.isSelected) {
      final paint = Paint()
        ..color = themeData.colorScheme.primary.withAlpha(100);
      canvas.drawRect(rect, paint);
    }
  }

  void _drawCellValue(Canvas canvas, String text, Rect rect, TextStyle style, bool isFixed) {
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    final textSpan = TextSpan(
      text: text,
      style: style.copyWith(
        color: isFixed 
            ? (isDarkMode ? AppColors.boardDarkFixedValue : AppColors.boardLightFixedValue)
            : (isDarkMode ? AppColors.boardDarkUserValue : AppColors.boardLightUserValue),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )
    ..layout();

    final offsetX = rect.center.dx - textPainter.width / 2;
    final offsetY = rect.center.dy - textPainter.height / 2;
    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  void _drawGrid(Canvas canvas) {
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    // 细线
    final thinPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400
      ..strokeWidth = 0.5;

    // 粗线（3x3宫格边界）
    final thickPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600
      ..strokeWidth = 1.5;

    // 绘制每个子网格的网格线
    for (int subGridIdx = 0; subGridIdx < SamuraiBoard.subGridOffsets.length; subGridIdx++) {
      final (startRow, startCol) = SamuraiBoard.subGridOffsets[subGridIdx];
      
      // 绘制子网格内部的细线
      for (int i = 1; i < 9; i++) {
        // 水平线
        final y = (startRow + i) * cellSize;
        final isThick = i % 3 == 0;
        canvas.drawLine(
          Offset(startCol * cellSize, y),
          Offset((startCol + 9) * cellSize, y),
          isThick ? thickPaint : thinPaint,
        );

        // 垂直线
        final x = (startCol + i) * cellSize;
        canvas.drawLine(
          Offset(x, startRow * cellSize),
          Offset(x, (startRow + 9) * cellSize),
          isThick ? thickPaint : thinPaint,
        );
      }

      // 绘制子网格外边框
      final borderPaint = Paint()
        ..color = themeData.colorScheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      final borderRect = Rect.fromLTWH(
        startCol * cellSize,
        startRow * cellSize,
        9 * cellSize,
        9 * cellSize,
      );
      canvas.drawRect(borderRect, borderPaint);
    }
  }

  bool _isInAnySubGrid(int row, int col) {
    for (final (startRow, startCol) in SamuraiBoard.subGridOffsets) {
      if (row >= startRow && row < startRow + 9 &&
          col >= startCol && col < startCol + 9) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant SamuraiOverviewPainter oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.solution != solution ||
      oldDelegate.currentSubGridIndex != currentSubGridIndex ||
      oldDelegate.isShowingSolution != isShowingSolution ||
      oldDelegate.themeData != themeData;
}
