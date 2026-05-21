import 'package:sudoku/models/index.dart';

/// 杀手数独笼子模型
/// 杀手数独将棋盘划分为多个笼子，每个笼子包含一组单元格和一个和值
///
/// 优化说明：
/// 1. 存储坐标而非Cell引用，避免引用问题
/// 2. 添加缓存机制，提升性能
/// 3. 提供灵活的验证方法
class KillerCage {

  /// 主要构造函数
  KillerCage({
    required this.id,
    required this.cellCoordinates,
    required this.sum,
    this.operator,
  });

  factory KillerCage.fromJson(Map<String, dynamic> json) {
    final coordsJson = json['cellCoordinates'] as List;
    final cellCoordinates = coordsJson.map((coordJson) {
      final map = coordJson as Map<String, dynamic>;
      return (map['row'] as int, map['col'] as int);
    }).toList();

    return KillerCage(
      id: json['id'] as String,
      cellCoordinates: cellCoordinates,
      sum: json['sum'] as int,
      operator: json['operator'] as String?,
    );
  }

  /// 简化构造函数，使用cells参数
  KillerCage.fromCells({
    required List<(int row, int col)> cells,
    required this.sum,
    this.operator,
  }) : id = 'cage_${DateTime.now().millisecondsSinceEpoch}',
       cellCoordinates = cells;
  final String id;
  final List<(int, int)> cellCoordinates; // 存储坐标而非引用
  final int sum;
  final String? operator;

  /// 获取单元格坐标
  List<(int, int)> get cells => cellCoordinates;

  // 缓存机制
  int? _cachedSum;
  int? _cachedBoardStateHash;

  /// 检查坐标是否在笼子内
  bool containsCoordinate(int row, int col) {
    for (final coord in cellCoordinates) {
      if (coord.$1 == row && coord.$2 == col) {
        return true;
      }
    }
    return false;
  }

  /// 获取笼子包含的单元格数量
  int get cellCount => cellCoordinates.length;

  /// 计算当前和值 - 带缓存优化
  ///
  /// 参数：
  /// - board: 当前棋盘状态
  ///
  /// 返回：笼子内所有已填单元格的和
  int getCurrentSum(Board board) {
    // 使用棋盘状态哈希判断是否需要重新计算（仅KillerBoard支持stateHash）
    final currentHash = board is KillerBoard ? board.stateHash : null;
    if (currentHash != null && _cachedSum != null && _cachedBoardStateHash == currentHash) {
      return _cachedSum!;
    }

    _cachedSum = cellCoordinates.fold<int>(0, (total, coord) {
      final cell = board.getCell(coord.$1, coord.$2);
      return total + (cell.value ?? 0);
    });
    if (currentHash != null) {
      _cachedBoardStateHash = currentHash;
    }

    return _cachedSum!;
  }

  /// 检查笼子是否已完成（所有单元格已填）
  bool isComplete(Board board) {
    for (final coord in cellCoordinates) {
      final cell = board.getCell(coord.$1, coord.$2);
      if (cell.value == null) return false;
    }
    return true;
  }

  /// 验证笼子约束是否满足
  ///
  /// 规则：
  /// 1. 已填数字之和不能超过目标和
  /// 2. 完成后和必须等于目标和
  /// 3. 笼子内数字绝对不能重复（杀手数独硬性规则）
  bool isValid(Board board) {
    final currentSum = getCurrentSum(board);

    // 如果当前和已经超过目标和，无效
    if (currentSum > sum) return false;

    // 检查笼子内数字是否重复（硬性规则）
    if (_hasDuplicateValues(board)) {
      return false;
    }

    // 如果笼子已完成，和必须等于目标和
    if (isComplete(board)) {
      return currentSum == sum;
    }

    return true;
  }

  /// 检查笼子内是否有重复数字
  ///
  /// 杀手数独硬性规则：笼子内数字绝对不能重复
  bool _hasDuplicateValues(Board board) {
    final values = <int>{};

    for (final coord in cellCoordinates) {
      final cell = board.getCell(coord.$1, coord.$2);
      final value = cell.value;

      if (value != null) {
        // 如果值已存在，说明有重复
        if (values.contains(value)) {
          return true;
        }
        values.add(value);
      }
    }

    return false;
  }

  /// 检查笼子内数字是否有重复（公开方法）
  ///
  /// 用于验证和调试
  bool hasDuplicateValues(Board board) => _hasDuplicateValues(board);

  /// 获取笼子在棋盘上的单元格
  List<Cell> getCells(Board board) => cellCoordinates
        .map((coord) => board.getCell(coord.$1, coord.$2))
        .toList();

  /// 获取笼子的第一个单元格（用于显示和值）
  Cell getFirstCell(Board board) {
    final firstCoord = cellCoordinates.first;
    return board.getCell(firstCoord.$1, firstCoord.$2);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cellCoordinates': cellCoordinates
        .map((coord) => {'row': coord.$1, 'col': coord.$2})
        .toList(),
    'sum': sum,
    'operator': operator,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KillerCage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'KillerCage(id: $id, sum: $sum, cells: ${cellCoordinates.length})';
}
