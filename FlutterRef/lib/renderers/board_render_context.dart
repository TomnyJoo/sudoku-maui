import 'package:flutter/material.dart';
import 'package:sudoku/theme/app_colors.dart';
import 'package:sudoku/theme/theme_extension.dart';

/// 棋盘渲染所需的配色数据
///
/// 从 BuildContext 中提取，避免在渲染层持有 BuildContext 引用
class BoardColors {
  const BoardColors({
    required this.isDarkMode,
    required this.boardSelectedCellColor,
    required this.boardHighlightedCellColor,
    required this.boardCellBackgroundColor,
    required this.boardFixedValueColor,
    required this.boardUserValueColor,
    required this.errorColor,
    required this.boardMarkerColor,
    required this.boardGridLineColor,
    required this.boardGridLineBoldColor,
    required this.boardRegionColors,
    required this.boardRegionNumberColor,
    required this.primaryColor,
    required this.boardWindowBackgroundColor,
  });

  /// 从 BuildContext 提取配色数据
  factory BoardColors.fromContext(BuildContext context) => BoardColors(
    isDarkMode: context.isDarkMode,
    boardSelectedCellColor: context.boardSelectedCellColor,
    boardHighlightedCellColor: context.boardHighlightedCellColor,
    boardCellBackgroundColor: context.boardCellBackgroundColor,
    boardFixedValueColor: context.boardFixedValueColor,
    boardUserValueColor: context.boardUserValueColor,
    errorColor: context.errorColor,
    boardMarkerColor: context.boardMarkerColor,
    boardGridLineColor: context.boardGridLineColor,
    boardGridLineBoldColor: context.boardGridLineBoldColor,
    boardRegionColors: context.boardRegionColors,
    boardRegionNumberColor: context.boardRegionNumberColor,
    primaryColor: context.primaryColor,
    boardWindowBackgroundColor: context.boardWindowBackgroundColor,
  );

  final bool isDarkMode;
  final Color boardSelectedCellColor;
  final Color boardHighlightedCellColor;
  final Color boardCellBackgroundColor;
  final Color boardFixedValueColor;
  final Color boardUserValueColor;
  final Color errorColor;
  final Color boardMarkerColor;
  final Color boardGridLineColor;
  final Color boardGridLineBoldColor;
  final List<Color> boardRegionColors;
  final Color boardRegionNumberColor;
  final Color primaryColor;
  final Color boardWindowBackgroundColor;

  /// 获取杀手数独笼子背景色
  Color getBoardCageColor(int colorIndex) => AppColors.getBoardCageColor(isDarkMode, colorIndex);
}

/// 棋盘渲染上下文
/// 封装渲染所需的共享状态，避免每个渲染器重复传递参数
class BoardRenderContext {
  const BoardRenderContext({
    required this.cellSize,
    required this.colors,
    required this.themeData,
    required this.highlightMistakesEnabled,
    required this.showDiagonalLines,
    required this.showRegionNumbers,
    required this.showCageSums,
    required this.showCageBorders,
  });

  final double cellSize;
  final BoardColors colors;
  final ThemeData themeData;
  final bool highlightMistakesEnabled;
  final bool showDiagonalLines;
  final bool showRegionNumbers;
  final bool showCageSums;
  final bool showCageBorders;

  /// 绘制居中文字
  void drawTextInCenter(Canvas canvas, String text, Rect rect, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final offset = Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  /// 绘制虚线
  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
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
}
