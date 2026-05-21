import 'package:flutter/material.dart';
import 'package:sudoku/theme/app_colors.dart';

/// 主题扩展
extension AppThemeExtension on BuildContext {
  /// 是否为暗黑模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 获取主颜色
  Color get primaryColor => isDarkMode ? AppColors.darkPrimary : AppColors.primary;
  Color get secondaryColor => isDarkMode ? AppColors.darkSecondary : AppColors.secondary;
  Color get accentColor => AppColors.accent;
  Color get buttonPrimaryColor => isDarkMode ? AppColors.darkButtonPrimary : AppColors.buttonPrimary;
  Color get buttonSuccessColor => isDarkMode ? AppColors.darkButtonSuccess : AppColors.buttonSuccess;
  Color get buttonWarningColor => isDarkMode ? AppColors.darkButtonWarning : AppColors.buttonWarning;
  Color get buttonErrorColor => isDarkMode ? AppColors.darkButtonError : AppColors.buttonError;
  Color get buttonAccentColor => isDarkMode ? AppColors.darkButtonAccent : AppColors.buttonAccent;
  Color get buttonLoadGameColor => isDarkMode ? AppColors.darkButtonLoadGame : AppColors.buttonLoadGame;

  /// 获取按钮主颜色渐变
  List<Color> get buttonPrimaryGradient => isDarkMode
      ? AppColors.darkButtonPrimaryGradient
      : AppColors.buttonPrimaryGradient;
  List<Color> get buttonSuccessGradient => isDarkMode
      ? AppColors.darkButtonSuccessGradient
      : AppColors.buttonSuccessGradient;
  List<Color> get buttonWarningGradient => isDarkMode
      ? AppColors.darkButtonWarningGradient
      : AppColors.buttonWarningGradient;
  List<Color> get buttonErrorGradient => isDarkMode
      ? AppColors.darkButtonErrorGradient
      : AppColors.buttonErrorGradient;
  List<Color> get buttonAccentGradient => isDarkMode
      ? AppColors.darkButtonWarningGradient
      : AppColors.buttonWarningGradient;
  List<Color> get buttonLoadGameGradient => isDarkMode
      ? AppColors.darkButtonLoadGameGradient
      : AppColors.buttonLoadGameGradient;

  /// 获取信息颜色
  Color get infoColor => isDarkMode ? AppColors.infoDark : AppColors.info;
  Color get successColor => isDarkMode ? AppColors.successDark : AppColors.success;
  Color get warningColor => isDarkMode ? AppColors.warningDark : AppColors.warning;
  Color get errorColor => isDarkMode ? AppColors.errorDark : AppColors.error;

  Color get selectedColor => isDarkMode ? AppColors.selectedDark : AppColors.selected;
  Color get highlightedColor => isDarkMode ? AppColors.highlightedDark : AppColors.highlighted;
  Color get hoverColor => isDarkMode ? AppColors.hoverDark : AppColors.hover;
  Color get pressedColor => isDarkMode ? AppColors.pressedDark : AppColors.pressed;

  Color get borderColor => isDarkMode ? AppColors.borderDark : AppColors.border;
  Color get dividerColor => isDarkMode ? AppColors.dividerDark : AppColors.divider;

  Color get cardColor => isDarkMode ? AppColors.darkCard : AppColors.lightCard;

  List<Color> get homeBackgroundGradient => isDarkMode ? AppColors.homeBackgroundGradientDark : AppColors.homeBackgroundGradientLight;
  List<Color> get gameBackgroundGradient => AppColors.gameBackgroundGradient;
  List<Color> get lightBackgroundGradient => AppColors.lightBackgroundGradient;
  List<Color> get darkBackgroundGradient => AppColors.darkBackgroundGradient;
  List<Color> get finishScreenGradient => AppColors.finishScreenGradient;

  // 首页背景渐变（亮色/暗色）
  List<Color> get homeBackgroundGradientLight => AppColors.homeBackgroundGradientLight;
  List<Color> get homeBackgroundGradientDark => AppColors.homeBackgroundGradientDark;

  // ==================== 棋盘专用配色扩展 ====================

  // 棋盘背景色
  Color get boardBackgroundColor => isDarkMode ? AppColors.boardDarkBackground : AppColors.boardLightBackground;

  // 单元格背景色
  Color get boardCellBackgroundColor => isDarkMode ? AppColors.boardDarkCellBackground : AppColors.boardLightCellBackground;

  // 选中单元格颜色
  Color get boardSelectedCellColor => isDarkMode ? AppColors.boardDarkSelectedCell : AppColors.boardLightSelectedCell;

  // 高亮单元格颜色
  Color get boardHighlightedCellColor => isDarkMode ? AppColors.boardDarkHighlightedCell : AppColors.boardLightHighlightedCell;

  // 固定值颜色
  Color get boardFixedValueColor => isDarkMode ? AppColors.boardDarkFixedValue : AppColors.boardLightFixedValue;

  // 用户值颜色
  Color get boardUserValueColor => isDarkMode ? AppColors.boardDarkUserValue : AppColors.boardLightUserValue;

  // 答案值颜色（查看答案模式）
  Color get boardSolutionValueColor => isDarkMode ? Colors.green.shade300 : Colors.green;

  // 标记（候选数字）颜色
  Color get boardMarkerColor => isDarkMode ? AppColors.boardDarkMarker : AppColors.boardLightMarker;

  // 网格线颜色
  Color get boardGridLineColor => isDarkMode ? AppColors.boardDarkGridLine : AppColors.boardLightGridLine;

  // 粗网格线颜色
  Color get boardGridLineBoldColor => isDarkMode ? AppColors.boardDarkGridLineBold : AppColors.boardLightGridLineBold;

  // 区域编号颜色
  Color get boardRegionNumberColor => isDarkMode ? AppColors.boardDarkRegionNumber : AppColors.boardLightRegionNumber;

  // 区域背景色列表
  List<Color> get boardRegionColors => isDarkMode ? AppColors.boardDarkRegionColors : AppColors.boardLightRegionColors;

  // 杀手数独笼子配色
  Color get boardCageBorderColor => isDarkMode ? AppColors.boardDarkCageBorderColor : AppColors.boardLightCageBorderColor;
  Color get boardCageSumColor => isDarkMode ? AppColors.boardDarkCageSum : AppColors.boardLightCageSum;

  // 杀手数独笼子背景色(新配色方案)
  Color getBoardCageColor(int colorIndex) => AppColors.getBoardCageColor(isDarkMode, colorIndex);

  // 杀手数独笼子和值颜色(新配色方案)
  Color get boardCageSumNewColor => AppColors.getBoardCageSumNew(isDarkMode);

  // 窗口数独窗口区域配色
  Color get boardWindowColor => isDarkMode ? AppColors.boardDarkWindowColor : AppColors.boardLightWindowColor;

  // 窗口数独窗口区域背景色(新配色方案)
  Color get boardWindowBackgroundColor => AppColors.getBoardWindowBackground(isDarkMode);
}
