import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku/models/difficulty.dart';

/// 应用颜色资源集合
class AppColors {
  // ==================== 基础颜色系统 ====================
  
  /// 主色调 - 现代蓝色系
  static const primary = Color(0xFF3B82F6);
  static const secondary = Color(0xFF60A5FA);
  static const accent = Color(0xFFF59E0B);
  
  /// 语义化颜色 - 鲜明的功能色
  static const error = Color(0xFFEF4444);
  static const errorDark = Color(0xFFDC2626);
  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF059669);
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFD97706);
  static const info = Color(0xFF3B82F6);
  static const infoDark = Color(0xFF2563EB);
  
  /// 扩展颜色 - 常用辅助色
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF97316);
  static const grey = Color(0xFF6B7280);
  
  // ==================== 主题颜色 ====================
  
  /// 背景色 - 舒适的基础色
  static const lightBackground = Color(0xFFF9FAFB);
  static const darkBackground = Color(0xFF111827);
  
  /// 暗色主题颜色 - 协调的深色系
  static const darkPrimary = Color(0xFF60A5FA);
  static const darkSecondary = Color(0xFF93C5FD);
  
  // ==================== 文本颜色 ====================
  
  /// 文本颜色 - 增强对比度
  static const lightText = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF1E293B);
  static const fixedText = Color(0xFF1E293B);
  static const userText = Color(0xFF2563EB);
  static const mutedText = Color(0xFF6B7280);
  static const lightMutedText = Color(0xFFF1F5F9);
  
  // ==================== 交互状态颜色 ====================
  
  /// 交互状态颜色 - 明显的反馈
  static const selected = Color(0xFFFFF3C4);
  static const selectedDark = Color(0xFF818CF8);
  static const highlighted = Color(0xFFDBEAFE);
  static const highlightedDark = Color(0xFF3B82F6);
  static const hover = Color(0xFFF3F4F6);
  static const hoverDark = Color(0xFF1E293B);
  static const pressed = Color(0xFFE5E7EB);
  static const pressedDark = Color(0xFF334155);
  
  // ==================== 边框和分割线 ====================
  
  /// 边框和分割线 - 细微的区分
  static const border = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF334155);
  static const gridLine = Color(0xFFD1D5DB);
  static const gridLineDark = Color(0xFF475569);
  static const divider = Color(0xFFF3F4F6);
  static const dividerDark = Color(0xFF1E293B);
  
  // ==================== 单元格背景 ====================
  
  /// 单元格背景 - 干净的底色
  static const lightCellBackground = Color(0xFFFFFFFF);
  static const darkCellBackground = Color(0xFF1E293B);

  // ==================== 渐变颜色 ====================
  
  /// 基础渐变 - 和谐的过渡
  static const List<Color> primaryGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
  static const List<Color> successGradient = [Color(0xFF10B981), Color(0xFF34D399)];
  static const List<Color> errorGradient = [Color(0xFFEF4444), Color(0xFFF87171)];
  static const List<Color> warningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];
  
  /// 背景渐变 - 明亮活力风格
  static const List<Color> lightBackgroundGradient = [Color(0xFFFFFFFF), Color(0xFFF0F9FF), Color(0xFFE0F2FE)];
  static const List<Color> darkBackgroundGradient = [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)];
  static const List<Color> gameBackgroundGradient = [Color(0xFF2563EB), Color(0xFF1D4ED8)];
  static const List<Color> finishScreenGradient = [Color(0xFF10B981), Color(0xFF059669)];
  
  /// 首页/设置/统计页背景渐变
  static const List<Color> homeBackgroundGradientLight = [Color(0xFFE0E7FF), Color(0xFFC7D2FE)];
  static const List<Color> homeBackgroundGradientDark = [Color(0xFF0F172A), Color(0xFF1E1B4B)];


  // ==================== 卡片和阴影 ====================
  
  /// 卡片颜色 - 增强与背景对比
  static const lightCard = Color(0xFFFFFFFF);
  static const darkCard = Color(0xFF1E293B);
  
  /// 卡片阴影 - 增强层次感
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  /// 阴影颜色 - 增强深度
  static const shadowLight = Color(0x10000000);
  static const shadowMedium = Color(0x20000000);
  static const shadowDark = Color(0x30000000);

  // ==================== 按钮颜色 ====================
  
  /// 按钮颜色 - 强烈对比度
  static const buttonPrimary = Color(0xFF2563EB);
  static const buttonSuccess = Color(0xFF059669);
  static const buttonWarning = Color(0xFFD97706);
  static const buttonError = Color(0xFFDC2626);
  static const buttonAccent = Color(0xFFF59E0B);
  static const buttonLoadGame = Color(0xFF7C3AED);
  
  /// 暗色主题按钮颜色 - 柔和协调
  static const darkButtonPrimary = Color(0xFF60A5FA);
  static const darkButtonSuccess = Color(0xFF34D399);
  static const darkButtonWarning = Color(0xFFFBBF24);
  static const darkButtonError = Color(0xFFF87171);
  static const darkButtonAccent = Color(0xFFFBBF24);
  static const darkButtonLoadGame = Color(0xFFA78BFA);
  
  /// 按钮渐变 - 柔和协调的色调
  static const List<Color> buttonPrimaryGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
  static const List<Color> buttonSuccessGradient = [Color(0xFF10B981), Color(0xFF34D399)];
  static const List<Color> buttonWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];
  static const List<Color> buttonErrorGradient = [Color(0xFFEF4444), Color(0xFFF87171)];
  static const List<Color> buttonLoadGameGradient = [Color(0xFF8B5CF6), Color(0xFFA78BFA)];
  
  /// 暗色主题按钮渐变 - 柔和协调的色调
  static const List<Color> darkButtonPrimaryGradient = [Color(0xFF60A5FA), Color(0xFF93C5FD)];
  static const List<Color> darkButtonSuccessGradient = [Color(0xFF34D399), Color(0xFF6EE7B7)];
  static const List<Color> darkButtonWarningGradient = [Color(0xFFFBBF24), Color(0xFFFDE68A)];
  static const List<Color> darkButtonErrorGradient = [Color(0xFFF87171), Color(0xFFFCA5A5)];
  static const List<Color> darkButtonLoadGameGradient = [Color(0xFFA78BFA), Color(0xFFC4B5FD)];

  // ==================== 棋盘专用配色系统 ====================
  
  // 浅色主题棋盘配色 - 增强对比度
  static const boardLightBackground = Color(0xFFFFFFFF);
  static const boardLightCellBackground = Color(0xFFFFFFFF);
  static const boardLightSelectedCell = Color(0xFFFFF3C4);
  static const boardLightHighlightedCell = Color(0xFFDBEAFE); // 优化：更柔和的蓝色，增强可见性
  static const boardLightFixedValue = Color(0xFF111827);
  static const boardLightUserValue = Color(0xFF2563EB); // 优化：更深的蓝色，提高对比度
  static const boardLightMarker = Color(0xFF6B7280);
  static const boardLightGridLine = Color(0xFFD1D5DB); // 优化：更明显的网格线
  static const boardLightGridLineBold = Color(0xFF6B7280); // 优化：更强的粗网格线
  static const boardLightRegionNumber = Color(0xFF7C3AED);
  
  // 浅色主题区域背景色（柔和协调的色调）
  static const List<Color> boardLightRegionColors = [
    Color(0xFFFFF3E0), // 浅橙色
    Color(0xFFE8F5E8), // 浅绿色
    Color(0xFFE3F2FD), // 浅蓝色
    Color(0xFFF9FAFB), // 优化：浅灰色替代浅粉色，减少视觉疲劳
    Color(0xFFF3E5F5), // 浅紫色
    Color(0xFFE0F2F1), // 浅青绿色
    Color(0xFFFFF8E1), // 浅黄色
    Color(0xFFE8EAF6), // 浅靛蓝色
    Color(0xFFFBE9E7), // 浅红色
  ];

  // 深色主题棋盘配色 - 增强对比度
  static const boardDarkBackground = Color(0xFF111827);
  static const boardDarkCellBackground = Color(0xFF1F2937);
  static const boardDarkSelectedCell = Color(0xFF818CF8);
  static const boardDarkHighlightedCell = Color(0xFF3B82F6);
  static const boardDarkFixedValue = Color(0xFFFFFFFF); // 纯白色，固定值（高对比度）
  static const boardDarkUserValue = Color(0xFF60A5FA);   // 更亮的蓝色，用户值（高对比度）
  static const boardDarkMarker = Color(0xFFE5E7EB);      // 优化：更亮的灰色，提高可见性
  static const boardDarkGridLine = Color(0xFF4B5563);    // 优化：更亮的灰色，增加对比度
  static const boardDarkGridLineBold = Color(0xFF6B7280);
  static const boardDarkRegionNumber = Color(0xFFA78BFA);
  
  // 深色主题区域背景色（优化：增加对比度和区分度）
  static const List<Color> boardDarkRegionColors = [
    Color(0xFF4A3535), // 优化：深棕色（更亮）
    Color(0xFF2D4A2D), // 优化：深绿色（更亮）
    Color(0xFF2D2D4A), // 优化：深蓝色（更亮）
    Color(0xFF4A3540), // 优化：深紫色（更亮）
    Color(0xFF40354A), // 优化：深紫红色（更亮）
    Color(0xFF2D4A4A), // 优化：深青绿色（更亮）
    Color(0xFF4A4035), // 优化：深黄色（更亮）
    Color(0xFF2D354A), // 优化：深靛蓝色（更亮）
    Color(0xFF4A3535), // 优化：深红色（更亮）
  ];

  // 杀手数独笼子配色 - 边框和和值(已弃用,改用背景色方案)
  static const boardLightCageBorderColor = Color(0xFFEF4444);
  static const boardDarkCageBorderColor = Color(0xFFF87171);
  static const boardLightCageSum = Color(0xFF5D4037);
  static const boardDarkCageSum = Color(0xFFFFCCBC);

  // 杀手数独笼子背景色配色方案 - 柔和马卡龙色系(浅色主题)
  static const List<Color> boardLightCageColors = [
    Color(0xFFFFF3E0), // 浅橙 - 温暖
    Color(0xFFE8F5E8), // 浅绿 - 清新
    Color(0xFFE3F2FD), // 浅蓝 - 冷静
    Color(0xFFF3E5F5), // 浅紫 - 优雅
    Color(0xFFE0F2F1), // 浅青 - 宁静
    Color(0xFFFFF8E1), // 浅黄 - 明亮
    Color(0xFFE8EAF6), // 浅靛 - 深邃
    Color(0xFFFBE9E7), // 浅红 - 活力
    Color(0xFFF9FAFB), // 浅灰 - 中性
  ];

  // 杀手数独笼子背景色配色方案 - 低饱和度色系(深色主题)
  static const List<Color> boardDarkCageColors = [
    Color(0xFF4A3535), // 深棕 - 稳重
    Color(0xFF2D4A2D), // 深绿 - 自然
    Color(0xFF2D2D4A), // 深蓝 - 专业
    Color(0xFF4A3540), // 深紫 - 神秘
    Color(0xFF40354A), // 深紫红 - 高雅
    Color(0xFF2D4A4A), // 深青 - 冷静
    Color(0xFF4A4035), // 深黄 - 温暖
    Color(0xFF2D354A), // 深靛 - 沉稳
    Color(0xFF4A3535), // 深红 - 活力
  ];

  // 杀手数独笼子和值配色 - 适配新背景色
  static const boardLightCageSumNew = Color(0xFF5D4037); // 深棕色,在浅色背景上清晰可见
  static const boardDarkCageSumNew = Color(0xFFFFCCBC); // 浅橙色,在深色背景上清晰可见

  // 窗口数独窗口区域配色 - 旧版边框颜色(已弃用,改用背景色方案)
  static const boardLightWindowColor = Color(0xFF8B5CF6);
  static const boardDarkWindowColor = Color(0xFFA78BFA);

  // 窗口数独窗口区域背景色 - 柔和紫罗兰色系(新方案)
  static const boardLightWindowBackground = Color(0xFFF5F3FF); // 浅紫罗兰色
  static const boardDarkWindowBackground = Color(0xFF312E81);  // 深紫罗兰色

  // ==================== 游戏类型主题色 ====================
  
  // 标准数独 - 强烈的蓝色
  static const standardSudoku = Color(0xFF2563EB);
  
  // 锯齿数独 - 鲜艳的粉红
  static const jigsawSudoku = Color(0xFFEC4899);
  
  // 对角线数独 - 鲜明的绿色
  static const diagonalSudoku = Color(0xFF10B981);
  
  // 杀手数独 - 强烈的橙色
  static const killerSudoku = Color(0xFFF97316);

  // 窗口数独 - 浓郁的紫色
  static const windowSudoku = Color(0xFF8B5CF6);

  // 武士数独 - 鲜艳的红色
  static const samuraiSudoku = Color(0xFFDC2626);

  // 自定义游戏 - 鲜明的青色
  static const customGame = Color(0xFF06B6D4);
  
  // 加载游戏 - 强烈的橙色
  static const loadGame = Color(0xFFD97706);

  // 成就颜色
  static const bronze = Color(0xFFCD7F32);
  static const silver = Color(0xFFC0C0C0);
  static const gold = Color(0xFFFFD700);

  // 统计图表颜色
  static const chartColors = [
    Color(0xFF3B82F6), // 蓝色
    Color(0xFF10B981), // 绿色
    Color(0xFFF59E0B), // 橙色
    Color(0xFFEF4444), // 红色
    Color(0xFF8B5CF6), // 紫色
  ];

  // ==================== 难度级别主题色 ====================
  
  /// 获取指定难度级别的主题色
  static Color getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return const Color(0xFF10B981); // 绿色 - 简单
      case Difficulty.easy:
        return const Color(0xFF34D399); // 浅绿色 - 容易
      case Difficulty.medium:
        return const Color(0xFF3B82F6); // 蓝色 - 中等
      case Difficulty.hard:
        return const Color(0xFF8B5CF6); // 紫色 - 困难
      case Difficulty.expert:
        return const Color(0xFFEC4899); // 粉红色 - 专家
      case Difficulty.master:
        return const Color(0xFFDC2626); // 红色 - 大师
      case Difficulty.custom:
        return const Color(0xFF6B7280); // 蓝灰色 - 自定义
    }
  }
  
  /// 获取难度级别的渐变颜色
  static List<Color> getDifficultyGradient(Difficulty difficulty) {
    final color = getDifficultyColor(difficulty);
    return [color, color.withAlpha(0xCC)];
  }

  // ==================== 设置页面配色 ====================
  
  // 暗色主题下的未选中/非激活状态背景色
  static const darkUnselectedBackground = Color(0xFF374151);
  
  // ==================== 色彩工具方法 ====================
  
  /// 根据主题获取棋盘背景色
  static Color getBoardBackground(bool isDarkMode) => 
      isDarkMode ? boardDarkBackground : boardLightBackground;
  
  /// 根据主题获取单元格背景色
  static Color getBoardCellBackground(bool isDarkMode) => 
      isDarkMode ? boardDarkCellBackground : boardLightCellBackground;
  
  /// 根据主题获取选中单元格颜色
  static Color getBoardSelectedCell(bool isDarkMode) => 
      isDarkMode ? boardDarkSelectedCell : boardLightSelectedCell;
  
  /// 根据主题获取高亮单元格颜色
  static Color getBoardHighlightedCell(bool isDarkMode) => 
      isDarkMode ? boardDarkHighlightedCell : boardLightHighlightedCell;
  
  /// 根据主题获取固定值颜色
  static Color getBoardFixedValue(bool isDarkMode) => 
      isDarkMode ? boardDarkFixedValue : boardLightFixedValue;
  
  /// 根据主题获取用户值颜色
  static Color getBoardUserValue(bool isDarkMode) => 
      isDarkMode ? boardDarkUserValue : boardLightUserValue;
  
  /// 根据主题获取标记颜色
  static Color getBoardMarker(bool isDarkMode) => 
      isDarkMode ? boardDarkMarker : boardLightMarker;
  
  /// 根据主题获取网格线颜色
  static Color getBoardGridLine(bool isDarkMode) => 
      isDarkMode ? boardDarkGridLine : boardLightGridLine;
  
  /// 根据主题获取粗网格线颜色
  static Color getBoardGridLineBold(bool isDarkMode) => 
      isDarkMode ? boardDarkGridLineBold : boardLightGridLineBold;
  
  /// 根据主题获取区域颜色列表
  static List<Color> getBoardRegionColors(bool isDarkMode) => 
      isDarkMode ? boardDarkRegionColors : boardLightRegionColors;
  
  /// 根据主题获取区域编号颜色
  static Color getBoardRegionNumber(bool isDarkMode) => 
      isDarkMode ? boardDarkRegionNumber : boardLightRegionNumber;
  
  /// 根据主题获取笼子边框颜色
  static Color getBoardCageBorderColor(bool isDarkMode) => 
      isDarkMode ? boardDarkCageBorderColor : boardLightCageBorderColor;
  
  /// 根据主题获取笼子和值颜色
  static Color getBoardCageSum(bool isDarkMode) => 
      isDarkMode ? boardDarkCageSum : boardLightCageSum;
  
  /// 根据主题和颜色索引获取笼子背景色
  static Color getBoardCageColor(bool isDarkMode, int colorIndex) {
    final colors = isDarkMode ? boardDarkCageColors : boardLightCageColors;
    return colors[colorIndex % colors.length];
  }
  
  /// 根据主题获取笼子和值颜色(新配色方案)
  static Color getBoardCageSumNew(bool isDarkMode) => 
      isDarkMode ? boardDarkCageSumNew : boardLightCageSumNew;
  
  /// 根据主题获取窗口区域背景色
  static Color getBoardWindowBackground(bool isDarkMode) => 
      isDarkMode ? boardDarkWindowBackground : boardLightWindowBackground;
  
  /// 计算两个颜色的对比度
  /// 返回值范围：1-21，值越大对比度越高
  /// WCAG AA 标准：正常文本至少 4.5:1，大文本至少 3:1
  /// WCAG AAA 标准：正常文本至少 7:1，大文本至少 4.5:1
  static double calculateContrast(Color foreground, Color background) {
    final double luminance1 = _calculateLuminance(foreground);
    final double luminance2 = _calculateLuminance(background);
    
    final double lighter = max(luminance1, luminance2);
    final double darker = min(luminance1, luminance2);
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// 计算颜色的相对亮度
  static double _calculateLuminance(Color color) {
    final double r = _linearizeColorComponent(color.r);
    final double g = _linearizeColorComponent(color.g);
    final double b = _linearizeColorComponent(color.b);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// 线性化颜色分量
  static double _linearizeColorComponent(double component) {
    final double c = component / 255.0;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) as double;
  }
  
  /// 检查对比度是否符合 WCAG AA 标准
  /// [isLargeText] 是否为大文本（18pt+ 或 14pt+ 粗体）
  static bool isContrastAA(Color foreground, Color background, {bool isLargeText = false}) {
    final double contrast = calculateContrast(foreground, background);
    return isLargeText ? contrast >= 3.0 : contrast >= 4.5;
  }
  
  /// 检查对比度是否符合 WCAG AAA 标准
  /// [isLargeText] 是否为大文本（18pt+ 或 14pt+ 粗体）
  static bool isContrastAAA(Color foreground, Color background, {bool isLargeText = false}) {
    final double contrast = calculateContrast(foreground, background);
    return isLargeText ? contrast >= 4.5 : contrast >= 7.0;
  }
  
  /// 获取推荐的文本颜色（根据背景色自动选择黑色或白色）
  static Color getRecommendedTextColor(Color background) {
    final double luminance = _calculateLuminance(background);
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// 验证棋盘配色对比度
  /// 返回对比度不达标的颜色组合列表
  static List<String> validateBoardContrast(bool isDarkMode) {
    final List<String> issues = [];
    final background = getBoardBackground(isDarkMode);
    final cellBackground = getBoardCellBackground(isDarkMode);
    final fixedValue = getBoardFixedValue(isDarkMode);
    final userValue = getBoardUserValue(isDarkMode);
    final marker = getBoardMarker(isDarkMode);
    final gridLine = getBoardGridLine(isDarkMode);
    
    // 检查固定值对比度
    if (!isContrastAA(fixedValue, cellBackground)) {
      issues.add('固定值与单元格背景对比度不足: ${calculateContrast(fixedValue, cellBackground).toStringAsFixed(2)}:1');
    }
    
    // 检查用户值对比度
    if (!isContrastAA(userValue, cellBackground)) {
      issues.add('用户值与单元格背景对比度不足: ${calculateContrast(userValue, cellBackground).toStringAsFixed(2)}:1');
    }
    
    // 检查标记对比度
    if (!isContrastAA(marker, cellBackground)) {
      issues.add('标记与单元格背景对比度不足: ${calculateContrast(marker, cellBackground).toStringAsFixed(2)}:1');
    }
    
    // 检查网格线对比度
    if (!isContrastAA(gridLine, background)) {
      issues.add('网格线与背景对比度不足: ${calculateContrast(gridLine, background).toStringAsFixed(2)}:1');
    }
    
    return issues;
  }
}
