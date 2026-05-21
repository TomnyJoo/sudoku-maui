import 'package:sudoku/models/cell.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 数独区域类型枚举
enum RegionType {
  block,     // 宫格/块（标准数独的3x3宫格）
  row,       // 行
  column,    // 列
  diagonal,  // 对角线
  window,    // 窗口（窗口数独的特殊区域）
  jigsaw,    // 锯齿（锯齿数独的不规则区域）
  cage,      // 笼子（杀手数独的笼子区域）
  custom,    // 自定义区域
}

/// RegionType枚举扩展方法
extension RegionTypeExtension on RegionType {
  /// 获取本地化的区域类型名称
  String getLocalizedName(final dynamic localizations) {
    try {
      if (localizations is Map) {
        switch (this) {
          case RegionType.block:
            return localizations['blockRegion'] ?? '宫格';
          case RegionType.row:
            return localizations['rowRegion'] ?? '行';
          case RegionType.column:
            return localizations['columnRegion'] ?? '列';
          case RegionType.diagonal:
            return localizations['diagonalRegion'] ?? '对角线';
          case RegionType.window:
            return localizations['windowRegion'] ?? '窗口';
          case RegionType.jigsaw:
            return localizations['jigsawRegion'] ?? '锯齿';
          case RegionType.cage:
            return localizations['cageRegion'] ?? '笼子';
          case RegionType.custom:
            return localizations['customRegion'] ?? '自定义';
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to get localized region type name', e);
    }
    return toString().split('.').last;
  }
}

/// 数独区域具体类，表示数独棋盘中的逻辑区域，如行、列、宫格、对角线等
class Region { 
  const Region({
    required this.id,
    required this.type,
    required this.name,
    required this.cells,
  });

  /// 从JSON创建区域
  factory Region.fromJson(final Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = RegionType.values.firstWhere(
      (final t) => t.toString() == typeStr,
      orElse: () => RegionType.custom,
    );
    
    final cellsJson = json['cells'] as List;
    final cells = cellsJson
        .map((final cellJson) => Cell.fromJson(cellJson as Map<String, dynamic>))
        .toList();
    
    return Region(
      id: json['id'] as String,
      type: type,
      name: json['name'] as String,
      cells: cells,
    );
  }
  
  final String id;  /// 区域标识符
  final RegionType type;  /// 区域类型
  final String name;  /// 区域名称（用于显示）
  final List<Cell> cells;

  /// 检查区域是否包含指定单元格
  bool contains(final Cell cell) => cells.contains(cell);

  /// 检查区域是否包含指定坐标的单元格
  bool containsCoordinate(final int row, final int col) {
    for (final cell in cells) {
      if (cell.row == row && cell.col == col) {
        return true;
      }
    }
    return false;
  }

  /// 获取区域中已填数字的集合
  Set<int> getFilledNumbers() {
    final numbers = <int>{};
    for (final cell in cells) {
      if (cell.value != null) {
        numbers.add(cell.value!);
      }
    }
    return numbers;
  }

  /// 获取区域中未填数字的集合
  Set<int> getMissingNumbers(final int maxNumber) {
    if (maxNumber < 1) {
      final errorMsg = '最大数字必须大于0: $maxNumber';
      throw ArgumentError(errorMsg);
    }
    final filledNumbers = getFilledNumbers();
    final allNumbers = Set<int>.from(List.generate(maxNumber, (final i) => i + 1));
    return allNumbers.difference(filledNumbers);
  }

  /// 检查区域是否完整（所有单元格已填且不重复）
  bool isComplete() {
    final filledNumbers = getFilledNumbers();
    return filledNumbers.length == cells.length;
  }

  /// 检查区域是否有效（无重复数字）
  bool isValid() {
    final seenValues = <int>{};
    for (final cell in cells) {
      final value = cell.value;
      if (value != null && !seenValues.add(value)) {
        return false;
      }
    }
    return true;
  }

  /// 获取区域中指定数字的单元格
  List<Cell> getCellsWithNumber(final int number) {
    if (number < 1 || number > 9) {
      final errorMsg = '数字必须在1-9范围内: $number';
      throw ArgumentError(errorMsg);
    }
    return cells.where((final cell) => cell.value == number).toList();
  }

  /// 获取区域中的空单元格
  List<Cell> getEmptyCells() => 
    cells.where((final cell) => cell.isEmpty).toList();

  /// 获取区域中的已填单元格
  List<Cell> getFilledCells() => 
    cells.where((final cell) => !cell.isEmpty).toList();

  /// 转换为JSON格式，用于持久化存储
  Map<String, dynamic> toJson() => {
      'id': id,
      'type': type.toString(),
      'name': name,
      'cells': cells.map((final cell) => cell.toJson()).toList(),
    };

  /// 创建区域实例
  Region createInstance({
    required String id,
    required RegionType type,
    required String name,
    required List<Cell> cells,
  }) => Region(
      id: id,
      type: type,
      name: name,
      cells: cells,
    );

  /// 获取用于调试的字符串表示（不依赖国际化）
  String toDebugString() => 
    'Region(id: $id, type: $type, name: $name, cells: ${cells.length})';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is Region &&
        other.id == id &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString() => toDebugString();
}

/// 区域集合工具类，提供区域集合的通用操作和验证方法
class RegionCollectionUtils {
  /// 获取包含指定单元格的区域
  static List<Region> getRegionsForCell(
    final List<Region> regions,
    final Cell cell,
  ) => regions.where((final region) => region.contains(cell)).toList();

  /// 获取包含指定坐标的区域
  static List<Region> getRegionsForCoordinate(
    final List<Region> regions,
    final int row,
    final int col,
  ) => regions.where((final region) => region.containsCoordinate(row, col)).toList();

  /// 获取指定类型的所有区域
  static List<Region> getRegionsByType(
    final List<Region> regions,
    final RegionType type,
  ) => regions.where((final region) => region.type == type).toList();

  /// 检查所有区域是否完整
  static bool areAllRegionsComplete(final List<Region> regions) =>
    regions.every((final region) => region.isComplete());

  /// 检查所有区域是否有效
  static bool areAllRegionsValid(final List<Region> regions) =>
    regions.every((final region) => region.isValid());

  /// 获取区域数量统计
  static Map<RegionType, int> getRegionCountByType(final List<Region> regions) {
    final counts = <RegionType, int>{};
    for (final region in regions) {
      counts[region.type] = (counts[region.type] ?? 0) + 1;
    }
    return counts;
  }

  /// 转换为JSON格式，用于持久化存储
  static Map<String, dynamic> toJson(
    final List<Region> regions,
    final int boardSize,
  ) => {
      'boardSize': boardSize,
      'regions': regions.map((final region) => region.toJson()).toList(),
    };

  /// 获取用于调试的字符串表示（不依赖国际化）
  static String toDebugString(
    final List<Region> regions,
    final int boardSize,
  ) => 'RegionCollection(regions: ${regions.length}, boardSize: $boardSize)';

}
