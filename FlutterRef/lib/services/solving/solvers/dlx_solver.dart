import 'dart:math';
import 'package:sudoku/constants/game_constants.dart';
import 'package:sudoku/models/index.dart';

/// DLX 节点
class _DLXNode {
  _DLXNode? left, right, up, down;
  _DLXColumn? column;
  int rowId = -1;
}

/// DLX 列头
class _DLXColumn extends _DLXNode {
  _DLXColumn() {
    column = this;
    left = right = up = down = this;
  }
  int size = 0;
  int index = -1;
}

/// 高效的 DLX 数独求解器
///
/// 使用 Dancing Links 算法实现高效求解和计数
class DLXSudokuSolver {
  DLXSudokuSolver({required this.size, Random? random, this.extraRegions})
    : boxSize = size == 9 ? 3 : 2,
      random = random ?? Random();
  final int size;
  final int boxSize;
  final Random random;
  final List<List<int>>? extraRegions;

  late _DLXColumn _root;
  late List<_DLXColumn> _columns;
  List<int> solution = [];
  int solutionsFound = 0;
  int maxSolutionsToFind = 1;

  /// 计算解的数量
  int countSolutions(
    Board puzzle, {
    int maxCount = 2,
    bool Function()? isCancelled,
  }) {
    final puzzleMatrix = List.generate(
      size,
      (r) => List.generate(size, (c) => puzzle.getCell(r, c).value ?? 0),
    );
    return _countSolutionsFromMatrix(
      puzzleMatrix,
      maxCount: maxCount,
      isCancelled: isCancelled,
    );
  }

  /// 生成一个完整的数独终盘
  /// 
  /// 从空棋盘开始，使用 DLX 算法随机生成一个有效解
  Board? generateSolution({
    bool Function()? isCancelled,
  }) {
    // 创建空棋盘矩阵
    final emptyMatrix = List.generate(
      size,
      (_) => List.generate(size, (_) => 0),
    );
    
    _init(emptyMatrix);
    solution = List.filled(size * size, 0);
    solutionsFound = 0;
    maxSolutionsToFind = 1;
    
    final found = _search(0, isCancelled);
    if (!found || solution.isEmpty) return null;
    
    // 将解转换为 Board
    return _solutionToBoard();
  }

  /// 将解转换为 Board 对象
  Board _solutionToBoard() {
    final cells = List.generate(
      size,
      (r) => List.generate(
        size,
        (c) {
          final value = solution[r * size + c];
          return Cell(
            row: r,
            col: c,
            value: value > 0 ? value : null,
            isFixed: true,
          );
        },
      ),
    );
    
    return StandardBoard(size: size, cells: cells);
  }

  /// 从矩阵计算解的数量
  int _countSolutionsFromMatrix(
    List<List<int>> puzzleMatrix, {
    int maxCount = 2,
    bool Function()? isCancelled,
  }) {
    _init(puzzleMatrix);
    solution = List.filled(size * size, 0);
    solutionsFound = 0;
    maxSolutionsToFind = maxCount;
    _search(0, isCancelled);
    return solutionsFound;
  }

  /// 初始化 DLX 结构
  void _init(List<List<int>> puzzleMatrix) {
    // 标准数独有 4 个约束类型，每个类型有 size*size 个约束
    // 如果有额外区域（如对角线、窗口），需要添加更多约束
    int constraintCount = 4 * size * size;
    if (extraRegions != null) {
      constraintCount += extraRegions!.length * size;
    }

    _columns = List.generate(constraintCount, (i) => _DLXColumn()..index = i);
    _root = _DLXColumn();
    _root.right = _columns[0];
    _root.left = _columns.last;
    _columns[0].left = _root;
    _columns.last.right = _root;

    for (int i = 0; i < _columns.length - 1; i++) {
      _columns[i].right = _columns[i + 1];
      _columns[i + 1].left = _columns[i];
    }

    _addRows(puzzleMatrix);
  }

  /// 添加所有可能的行
  void _addRows(List<List<int>> puzzleMatrix) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = puzzleMatrix[r][c];
        if (val != 0) {
          // 固定值，只添加一行
          _addRowForValue(r, c, val);
        } else {
          // 空格，添加所有可能的值
          for (int d = 1; d <= size; d++) {
            _addRowForValue(r, c, d);
          }
        }
      }
    }
  }

  /// 为特定位置和值添加一行
  void _addRowForValue(int r, int c, int d) {
    final constraints = <int>[
      // 约束1：每个格子只能有一个值
      r * size + c,
      // 约束2：每行的每个数字只能出现一次
      size * size + r * size + (d - 1),
      // 约束3：每列的每个数字只能出现一次
      2 * size * size + c * size + (d - 1),
    ];

    // 约束4：每个宫的每个数字只能出现一次
    final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
    constraints.add(3 * size * size + boxIdx * size + (d - 1));

    // 约束5：额外区域（对角线、窗口等）
    if (extraRegions != null) {
      for (int i = 0; i < extraRegions!.length; i++) {
        if (extraRegions![i][r * size + c] == 1) {
          constraints.add(4 * size * size + i * size + (d - 1));
        }
      }
    }

    _addRow(r, c, d, constraints);
  }

  /// 添加一行到 DLX 结构
  void _addRow(int r, int c, int d, List<int> constraints) {
    final rowNodes = <_DLXNode>[];
    for (final colIdx in constraints) {
      if (colIdx >= _columns.length) continue;

      final node = _DLXNode()..rowId = r * size * size + c * size + (d - 1);
      final col = _columns[colIdx];
      node
        ..up = col.up
        ..down = col;
      col.up!.down = node;
      col.up = node;
      node.column = col;
      col.size++;
      rowNodes.add(node);
    }

    // 链接行内节点
    for (int i = 0; i < rowNodes.length; i++) {
      rowNodes[i].left = rowNodes[(i - 1 + rowNodes.length) % rowNodes.length];
      rowNodes[i].right = rowNodes[(i + 1) % rowNodes.length];
    }
  }

  /// 搜索解
  bool _search(int k, bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) return false;

    if (_root.right == _root) {
      solutionsFound++;
      return solutionsFound >= maxSolutionsToFind;
    }

    final col = _chooseColumn();
    if (col == null) return false;

    _cover(col);
    final rows = _getRows(col).toList()..shuffle(random);

    for (final row in rows) {
      final rowId = row.rowId;
      final r = rowId ~/ (size * size);
      final c = (rowId ~/ size) % size;
      final d = (rowId % size) + 1;
      solution[r * size + c] = d;

      var rNode = row.right;
      while (rNode != null && rNode != row) {
        if (rNode.column != null) _cover(rNode.column!);
        rNode = rNode.right;
      }

      if (_search(k + 1, isCancelled)) return true;

      rNode = row.left;
      while (rNode != null && rNode != row) {
        if (rNode.column != null) _uncover(rNode.column!);
        rNode = rNode.left;
      }
    }

    _uncover(col);
    return false;
  }

  /// 选择列（MRV启发式）
  _DLXColumn? _chooseColumn() {
    _DLXColumn? best;
    int minSize = size + 1;
    var col = _root.right as _DLXColumn?;

    while (col != null && col != _root) {
      if (col.size < minSize) {
        minSize = col.size;
        best = col;
        if (minSize == 0) return null;
      }
      col = col.right as _DLXColumn?;
    }
    return best;
  }

  /// 获取列中的所有行
  List<_DLXNode> _getRows(_DLXColumn col) {
    final rows = <_DLXNode>[];
    var node = col.down;
    while (node != null && node != col) {
      rows.add(node);
      node = node.down;
    }
    return rows;
  }

  /// 覆盖列
  void _cover(_DLXColumn col) {
    col.right!.left = col.left;
    col.left!.right = col.right;

    var row = col.down;
    while (row != null && row != col) {
      var node = row.right;
      while (node != null && node != row) {
        node.down!.up = node.up;
        node.up!.down = node.down;
        if (node.column != null) node.column!.size--;
        node = node.right;
      }
      row = row.down;
    }
  }

  /// 取消覆盖列
  void _uncover(_DLXColumn col) {
    var row = col.up;
    while (row != null && row != col) {
      var node = row.left;
      while (node != null && node != row) {
        if (node.column != null) node.column!.size++;
        node.down!.up = node;
        node.up!.down = node;
        node = node.left;
      }
      row = row.up;
    }
    col.right!.left = col;
    col.left!.right = col;
  }
}

/// 标准数独 DLX 求解器工厂
class StandardDLXSolver {
  static DLXSudokuSolver create({Random? random}) =>
      DLXSudokuSolver(size: 9, random: random);
}

/// 对角线数独 DLX 求解器工厂
class DiagonalDLXSolver {
  static DLXSudokuSolver create({Random? random}) {
    // 对角线约束：主对角线和副对角线
    final extraRegions = <List<int>>[];

    // 主对角线
    final mainDiagonal = List.generate(81, (i) {
      final r = i ~/ 9;
      final c = i % 9;
      return r == c ? 1 : 0;
    });
    extraRegions.add(mainDiagonal);

    // 副对角线
    final antiDiagonal = List.generate(81, (i) {
      final r = i ~/ 9;
      final c = i % 9;
      return r + c == 8 ? 1 : 0;
    });
    extraRegions.add(antiDiagonal);

    return DLXSudokuSolver(size: 9, random: random, extraRegions: extraRegions);
  }
}

/// 窗口数独 DLX 求解器工厂
class WindowDLXSolver {
  static DLXSudokuSolver create({Random? random}) {
    final extraRegions = <List<int>>[];

    // 直接使用 WindowConstants 中的窗口区域定义（0-based 索引）
    for (final windowRegion in WindowConstants.windowRegions) {
      final startR = windowRegion.startRow;
      final startC = windowRegion.startCol;
      final endR = windowRegion.endRow;
      final endC = windowRegion.endCol;

      final window = List.generate(81, (i) {
        final r = i ~/ 9;
        final c = i % 9;
        return (r >= startR && r <= endR && c >= startC && c <= endC) ? 1 : 0;
      });
      extraRegions.add(window);
    }

    return DLXSudokuSolver(size: 9, random: random, extraRegions: extraRegions);
  }
}
