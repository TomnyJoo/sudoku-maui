import 'dart:math';

/// 坐标工具类，提供坐标相关的工具方法
class CoordinateUtils {
  /// 获取相邻坐标（上下左右）
  static List<(int, int)> getNeighbors(int row, int col, int size) {
    final neighbors = <(int, int)>[];
    final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final (dr, dc) in directions) {
      final newRow = row + dr;
      final newCol = col + dc;

      if (isInBounds(newRow, newCol, size)) {
        neighbors.add((newRow, newCol));
      }
    }

    return neighbors;
  }

  /// 获取所有相邻坐标（包括对角线）
  static List<(int, int)> getAllNeighbors(int row, int col, int size) {
    final neighbors = <(int, int)>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final newRow = row + dr;
        final newCol = col + dc;
        if (isInBounds(newRow, newCol, size)) {
          neighbors.add((newRow, newCol));
        }
      }
    }
    return neighbors;
  }

  /// 检查坐标是否在边界内
  static bool isInBounds(int row, int col, int size) =>
      row >= 0 && row < size && col >= 0 && col < size;

  /// 计算两个坐标之间的曼哈顿距离
  static int manhattanDistance(int row1, int col1, int row2, int col2) =>
      (row1 - row2).abs() + (col1 - col2).abs();

  /// 计算两个坐标之间的欧几里得距离
  static double euclideanDistance(int row1, int col1, int row2, int col2) {
    final dx = row1 - row2;
    final dy = col1 - col2;
    return sqrt(dx * dx + dy * dy);
  }

  /// 检查两个坐标是否相邻
  static bool areAdjacent(int row1, int col1, int row2, int col2) =>
      manhattanDistance(row1, col1, row2, col2) == 1;

  /// 检查两个坐标是否对角线相邻
  static bool areDiagonallyAdjacent(int row1, int col1, int row2, int col2) {
    final dx = (row1 - row2).abs();
    final dy = (col1 - col2).abs();
    return dx == 1 && dy == 1;
  }

  /// 获取坐标的字符串表示
  static String coordinateToString(int row, int col) => '($row, $col)';

  /// 从字符串解析坐标
  static (int, int)? parseCoordinate(String str) {
    final match = RegExp(r'\((\d+),\s*(\d+)\)').firstMatch(str);
    if (match != null) {
      final row = int.tryParse(match.group(1)!)!;
      final col = int.tryParse(match.group(2)!)!;
      return (row, col);
    }
    return null;
  }

  /// 获取同一行的所有坐标
  static List<(int, int)> getRowCoordinates(int row, int size) {
    final coordinates = <(int, int)>[];
    for (int col = 0; col < size; col++) {
      coordinates.add((row, col));
    }
    return coordinates;
  }

  /// 获取同一列的所有坐标
  static List<(int, int)> getColumnCoordinates(int col, int size) {
    final coordinates = <(int, int)>[];
    for (int row = 0; row < size; row++) {
      coordinates.add((row, col));
    }
    return coordinates;
  }

  /// 获取指定区域的所有坐标（适用于标准数独的3x3区域）
  static List<(int, int)> getRegionCoordinates(int row, int col, int size, int regionSize) {
    final coordinates = <(int, int)>[];
    final regionRow = (row ~/ regionSize) * regionSize;
    final regionCol = (col ~/ regionSize) * regionSize;
    
    for (int r = 0; r < regionSize; r++) {
      for (int c = 0; c < regionSize; c++) {
        final newRow = regionRow + r;
        final newCol = regionCol + c;
        if (isInBounds(newRow, newCol, size)) {
          coordinates.add((newRow, newCol));
        }
      }
    }
    return coordinates;
  }
}
