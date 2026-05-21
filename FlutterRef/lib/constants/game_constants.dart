/// 游戏常量集合
///
/// 合并了所有游戏模式相关的常量类：
/// - StandardConstants（标准数独）
/// - DiagonalConstants（对角线数独）+ DiagonalGeneratorType
/// - WindowConstants（窗口数独）+ WindowRegion
/// - KillerConstants（杀手数独）
/// - SamuraiConstants（武士数独）
library;

/// 标准数独常量
class StandardConstants {
  StandardConstants._();

  static const int boardSize = 9;
  static const int boxSize = 3;
  static const int minFilledCells = 17;
  static const int maxSolutionsToCheck = 2;
}

/// 对角线数独常量
class DiagonalConstants {
  DiagonalConstants._();

  static const int boardSize = 9;
  static const int boxSize = 3;
  static const int minFilledCells = 17;
  static const int maxSolutionsToCheck = 2;
}

/// 对角线生成器类型
class DiagonalGeneratorType {
  static const String efficient = 'efficient';
  static const String random = 'random';
  static const String mixed = 'mixed';
}

/// 窗口数独常量
class WindowConstants {
  WindowConstants._();

  static const int boardSize = 9;
  static const int boxSize = 3;
  static const int minFilledCells = 17;
  static const int maxSolutionsToCheck = 2;

  static const List<WindowRegion> windowRegions = [
    WindowRegion(
      id: 'window_top_left',
      name: 'Window Top Left',
      startRow: 1,
      startCol: 1,
      endRow: 3,
      endCol: 3,
    ),
    WindowRegion(
      id: 'window_top_right',
      name: 'Window Top Right',
      startRow: 1,
      startCol: 5,
      endRow: 3,
      endCol: 7,
    ),
    WindowRegion(
      id: 'window_bottom_left',
      name: 'Window Bottom Left',
      startRow: 5,
      startCol: 1,
      endRow: 7,
      endCol: 3,
    ),
    WindowRegion(
      id: 'window_bottom_right',
      name: 'Window Bottom Right',
      startRow: 5,
      startCol: 5,
      endRow: 7,
      endCol: 7,
    ),
  ];
}

/// 窗口区域定义类
class WindowRegion {
  const WindowRegion({
    required this.id,
    required this.name,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  final String id;
  final String name;
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  int get width => endCol - startCol + 1;
  int get height => endRow - startRow + 1;
}

/// 杀手数独常量
class KillerConstants {
  static const int boardSize = 9;
  static const int boxSize = 3;

  // Cage大小：1-9格都允许
  static const int minCageSize = 1;
  static const int maxCageSize = 9;

  // Sum范围：根据cage大小动态计算
  // 1格: 1-9
  // 2格: 3-17 (1+2=3, 8+9=17)
  // 9格: 45 (1+2+...+9)
  static const int minCageSum = 1;
  static const int maxCageSum = 45;

  // 关键规则：笼子内数字绝对不能重复
  // 这是杀手数独的硬性规则之一
}

/// 武士数独常量
class SamuraiConstants {
  static const int boardSize = 21;
  static const int subGridSize = 9;
  static const int subGridCount = 5;

  // 子数独的起始位置
  static const List<(int, int)> subGridOffsets = [
    (0, 0),      // 左上
    (0, 12),     // 右上
    (12, 0),     // 左下
    (12, 12),    // 右下
    (6, 6),      // 中心
  ];

  // 子数独名称（使用 key 标识符，实际显示通过国际化处理）
  static const List<String> subGridNames = [
    'topLeft',
    'topRight',
    'bottomLeft',
    'bottomRight',
    'center',
  ];

  // 重叠区域的位置
  static const List<(int, int, int, int)> overlapRegions = [
    (6, 6, 8, 8),    // 左上与中心重叠
    (6, 12, 8, 14),   // 右上与中心重叠
    (12, 6, 14, 8),   // 左下与中心重叠
    (12, 12, 14, 14), // 右下与中心重叠
  ];

  // 难度级别对应的提示数
  static const Map<String, int> difficultyClues = {
    'beginner': 45,
    'easy': 40,
    'medium': 35,
    'hard': 30,
    'expert': 25,
    'master': 17,
  };
}
