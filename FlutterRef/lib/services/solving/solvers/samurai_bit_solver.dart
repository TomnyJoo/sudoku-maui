import 'dart:math';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/solvers/bit_solver.dart';

/// 武士数独专用BitSolver
class SamuraiBitSolver extends BitSolver {
  SamuraiBitSolver({required this.board, super.random}) : super(size: 9) {
    _initOverlapData();
  }

  final SamuraiBoard board;
  late List<List<int>> overlapCells; // 重叠区域的单元格索引
  late List<List<int>> subgridMasks; // 每个子网格的掩码

  /// 初始化重叠数据
  void _initOverlapData() {
    overlapCells = List.generate(5, (_) => <int>[]);
    subgridMasks = List.generate(5, (_) => List.filled(9, 0));

    // 定义五个子网格的区域
    final subgrids = [
      // 左上角子网格 (0,0)
      [
        for (int r = 0; r < 9; r++)
          for (int c = 0; c < 9; c++) r * 15 + c,
      ],
      // 右上角子网格 (0,6)
      [
        for (int r = 0; r < 9; r++)
          for (int c = 6; c < 15; c++) r * 15 + c,
      ],
      // 中心子网格 (6,3)
      [
        for (int r = 6; r < 15; r++)
          for (int c = 3; c < 12; c++) r * 15 + c,
      ],
      // 左下角子网格 (12,0)
      [
        for (int r = 12; r < 21; r++)
          for (int c = 0; c < 9; c++) r * 15 + c,
      ],
      // 右下角子网格 (12,6)
      [
        for (int r = 12; r < 21; r++)
          for (int c = 6; c < 15; c++) r * 15 + c,
      ],
    ];

    for (int sg = 0; sg < 5; sg++) {
      overlapCells[sg] = subgrids[sg];
    }
  }

  /// 计算指定子网格中单元格的候选数
  int getCandidates(int sg, int r, int c) {
    final globalR = _getGlobalRow(sg, r);
    final globalC = _getGlobalCol(sg, c);

    // 计算行、列掩码
    int rowMask = 0;
    int colMask = 0;

    // 计算行掩码
    for (int i = 0; i < 15; i++) {
      final cell = board.getCell(globalR, i);
      if (cell.value != null) {
        rowMask |= 1 << (cell.value! - 1);
      }
    }

    // 计算列掩码
    for (int i = 0; i < 21; i++) {
      final cell = board.getCell(i, globalC);
      if (cell.value != null) {
        colMask |= 1 << (cell.value! - 1);
      }
    }

    // 计算子网格掩码
    int gridMask = 0;
    for (final cellIdx in overlapCells[sg]) {
      final cr = cellIdx ~/ 15;
      final cc = cellIdx % 15;
      final cell = board.getCell(cr, cc);
      if (cell.value != null) {
        gridMask |= 1 << (cell.value! - 1);
      }
    }

    return fullMask & ~(rowMask | colMask | gridMask);
  }

  /// 转换子网格坐标到全局坐标
  int _getGlobalRow(int sg, int r) {
    switch (sg) {
      case 0:
        return r; // 左上角
      case 1:
        return r; // 右上角
      case 2:
        return r + 6; // 中心
      case 3:
        return r + 12; // 左下角
      case 4:
        return r + 12; // 右下角
      default:
        return r;
    }
  }

  int _getGlobalCol(int sg, int c) {
    switch (sg) {
      case 0:
        return c; // 左上角
      case 1:
        return c + 6; // 右上角
      case 2:
        return c + 3; // 中心
      case 3:
        return c; // 左下角
      case 4:
        return c + 6; // 右下角
      default:
        return c;
    }
  }

  /// 计数解的数量
  @override
  int countSolutions(
    Board puzzle, {
    int maxCount = 2,
    bool Function()? isCancelled,
  }) {
    if (puzzle is SamuraiBoard) {
      return _countSolutionsFast(
        puzzle,
        maxCount: maxCount,
        isCancelled: isCancelled,
      );
    }
    return 0;
  }

  /// 快速计数解 - 使用位掩码和MRV启发式
  ///
  /// 关键修复：每个单元格记录所有所属子网格的约束，
  /// 重叠区域的单元格需要同时满足所有相关子网格的约束。
  int _countSolutionsFast(
    SamuraiBoard puzzle, {
    required int maxCount,
    bool Function()? isCancelled,
  }) {
    const boardSize = 21;
    const subGridSize = 9;

    // 构建每个单元格所属的子网格列表
    // cellSubGrids[r][c] = 该单元格所属的所有子网格索引列表
    final cellSubGrids = List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => <int>[]),
    );

    for (int sg = 0; sg < 5; sg++) {
      final (startRow, startCol) = SamuraiBoard.subGridOffsets[sg];
      for (int r = 0; r < subGridSize; r++) {
        for (int c = 0; c < subGridSize; c++) {
          final gr = startRow + r;
          final gc = startCol + c;
          cellSubGrids[gr][gc].add(sg);
        }
      }
    }

    // 收集所有活跃单元格（属于至少一个子网格的单元格）
    final activeCells = <(int, int)>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (cellSubGrids[r][c].isNotEmpty) {
          activeCells.add((r, c));
        }
      }
    }

    // 初始化位掩码 - 每个子网格有独立的行/列/宫掩码
    // subRowMask[sg][r], subColMask[sg][c], subBoxMask[sg][boxIdx]
    final subRowMask = List.generate(5, (_) => List.filled(9, 0));
    final subColMask = List.generate(5, (_) => List.filled(9, 0));
    final subBoxMask = List.generate(5, (_) => List.filled(9, 0));

    // 从棋盘初始化掩码
    for (final (r, c) in activeCells) {
      final val = puzzle.getCell(r, c).value;
      if (val != null) {
        final bit = 1 << (val - 1);
        for (final sg in cellSubGrids[r][c]) {
          final (startRow, startCol) = SamuraiBoard.subGridOffsets[sg];
          final localR = r - startRow;
          final localC = c - startCol;
          final boxIdx = (localR ~/ 3) * 3 + (localC ~/ 3);
          subRowMask[sg][localR] |= bit;
          subColMask[sg][localC] |= bit;
          subBoxMask[sg][boxIdx] |= bit;
        }
      }
    }

    // 构建单元格值矩阵（用于回溯）
    final matrix = List.generate(
      boardSize,
      (r) => List.generate(boardSize, (c) => puzzle.getCell(r, c).value ?? 0),
    );

    int solutionsFound = 0;

    // 计算指定单元格的候选数（考虑所有所属子网格的约束）
    int candidates(int r, int c) {
      int bits = fullMask;
      for (final sg in cellSubGrids[r][c]) {
        final (startRow, startCol) = SamuraiBoard.subGridOffsets[sg];
        final localR = r - startRow;
        final localC = c - startCol;
        final boxIdx = (localR ~/ 3) * 3 + (localC ~/ 3);
        bits &= ~subRowMask[sg][localR];
        bits &= ~subColMask[sg][localC];
        bits &= ~subBoxMask[sg][boxIdx];
      }
      return bits;
    }

    void dfs() {
      if (isCancelled?.call() ?? false) return;
      if (solutionsFound >= maxCount) return;

      // MRV: 找候选数最少的空单元格
      int minCount = 10;
      int bestR = -1, bestC = -1, bestBits = 0;
      for (final (r, c) in activeCells) {
        if (matrix[r][c] != 0) continue;
        final bits = candidates(r, c);
        if (bits == 0) return; // 死胡同
        final cnt = _countBits(bits);
        if (cnt < minCount) {
          minCount = cnt;
          bestR = r;
          bestC = c;
          bestBits = bits;
          if (cnt == 1) break;
        }
      }

      if (bestR == -1) {
        // 所有单元格都已填满，找到一个解
        solutionsFound++;
        return;
      }

      final values = _bitsToValues(bestBits)..shuffle(random);

      for (final val in values) {
        if (solutionsFound >= maxCount) return;

        final bit = 1 << (val - 1);

        // 保存所有受影响子网格的掩码
        final savedMasks = <(int, int, int, int)>[];
        for (final sg in cellSubGrids[bestR][bestC]) {
          final (startRow, startCol) = SamuraiBoard.subGridOffsets[sg];
          final localR = bestR - startRow;
          final localC = bestC - startCol;
          final boxIdx = (localR ~/ 3) * 3 + (localC ~/ 3);
          savedMasks.add((
            subRowMask[sg][localR],
            subColMask[sg][localC],
            subBoxMask[sg][boxIdx],
            sg,
          ));
          subRowMask[sg][localR] |= bit;
          subColMask[sg][localC] |= bit;
          subBoxMask[sg][boxIdx] |= bit;
        }

        matrix[bestR][bestC] = val;
        dfs();

        // 恢复掩码
        matrix[bestR][bestC] = 0;
        for (final (savedRow, savedCol, savedBox, sg) in savedMasks) {
          final (startRow, startCol) = SamuraiBoard.subGridOffsets[sg];
          final localR = bestR - startRow;
          final localC = bestC - startCol;
          final boxIdx = (localR ~/ 3) * 3 + (localC ~/ 3);
          subRowMask[sg][localR] = savedRow;
          subColMask[sg][localC] = savedCol;
          subBoxMask[sg][boxIdx] = savedBox;
        }
      }
    }

    dfs();
    return solutionsFound;
  }

  /// 生成解决方案
  SamuraiBoard? generateSolution(bool Function()? isCancelled) {
    // 创建空的武士数独棋盘
    final cells = List.generate(21, (r) =>
      List.generate(15, (c) => Cell(row: r, col: c))
    );
    final board = SamuraiBoard(cells: cells);
    
    // 逐个生成子网格，按中心 -> 左上 -> 右上 -> 左下 -> 右下的顺序
    final subgrids = [2, 0, 1, 3, 4]; // 生成顺序：中心、左上、右上、左下、右下
    
    for (final sg in subgrids) {
      if (isCancelled?.call() ?? false) return null;
      
      if (!_generateSubgrid(board, sg, isCancelled)) {
        return null; // 生成失败
      }
    }
    
    return board;
  }

  /// 生成指定子网格
  bool _generateSubgrid(
    SamuraiBoard board,
    int sg,
    bool Function()? isCancelled,
  ) {
    // 为子网格创建一个临时的矩阵
    final subgridMatrix = List.generate(9, (r) =>
      List.generate(9, (c) {
        final globalR = _getGlobalRow(sg, r);
        final globalC = _getGlobalCol(sg, c);
        final cell = board.getCell(globalR, globalC);
        return cell.value ?? 0;
      })
    );
    
    // 使用标准数独生成器生成子网格
    
    // 生成完整的子网格解
    if (!_generateSubgridSolution(subgridMatrix, isCancelled)) {
      return false;
    }
    
    // 将生成的解复制回武士数独棋盘
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final globalR = _getGlobalRow(sg, r);
        final globalC = _getGlobalCol(sg, c);
        final value = subgridMatrix[r][c];
        if (value != 0) {
          board.setCellValue(globalR, globalC, value);
        }
      }
    }
    
    return true;
  }

  /// 生成子网格的解决方案
  bool _generateSubgridSolution(
    List<List<int>> matrix,
    bool Function()? isCancelled,
  ) {
    // 首先填充固定值的掩码
    final rowMask = List.filled(9, 0);
    final colMask = List.filled(9, 0);
    final boxMask = List.filled(9, 0);

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = matrix[r][c];
        if (val != 0) {
          final bit = 1 << (val - 1);
          rowMask[r] |= bit;
          colMask[c] |= bit;
          final boxIdx = (r ~/ 3) * 3 + (c ~/ 3);
          boxMask[boxIdx] |= bit;
        }
      }
    }

    bool found = false;

    void dfs() {
      if (isCancelled?.call() ?? false) return;
      if (found) return;

      // 找到第一个空单元格
      int bestR = -1, bestC = -1, bestBits = 0, minCount = 10;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (matrix[r][c] != 0) continue;
          
          // 计算候选数
          final row = rowMask[r];
          final col = colMask[c];
          final box = boxMask[(r ~/ 3) * 3 + (c ~/ 3)];
          final bits = 0x1ff & ~(row | col | box);
          
          if (bits == 0) return;
          
          final cnt = _countBits(bits);
          if (cnt < minCount) {
            minCount = cnt;
            bestR = r;
            bestC = c;
            bestBits = bits;
            if (cnt == 1) break;
          }
        }
        if (bestR != -1 && minCount == 1) break;
      }

      if (bestR == -1) {
        // 找到解决方案
        found = true;
        return;
      }

      // 尝试所有候选数
      final candidates = _bitsToValues(bestBits)..shuffle(random);
      for (final val in candidates) {
        if (isCancelled?.call() ?? false) return;
        
        final r = bestR;
        final c = bestC;
        final bit = 1 << (val - 1);
        final boxIdx = (r ~/ 3) * 3 + (c ~/ 3);
        
        // 保存状态
        final oldVal = matrix[r][c];
        final oldRowMask = rowMask[r];
        final oldColMask = colMask[c];
        final oldBoxMask = boxMask[boxIdx];
        
        // 设置值
        matrix[r][c] = val;
        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[boxIdx] |= bit;
        
        // 继续搜索
        dfs();
        
        if (found) return;
        
        // 回溯
        matrix[r][c] = oldVal;
        rowMask[r] = oldRowMask;
        colMask[c] = oldColMask;
        boxMask[boxIdx] = oldBoxMask;
      }
    }

    dfs();
    return found;
  }

  // 位操作辅助方法
  int _countBits(int bits) {
    int count = 0;
    while (bits > 0) {
      count += bits & 1;
      bits >>= 1;
    }
    return count;
  }

  List<int> _bitsToValues(int bits) {
    final values = <int>[];
    for (int i = 0; i < 9; i++) {
      if ((bits & (1 << i)) != 0) {
        values.add(i + 1);
      }
    }
    return values;
  }

  // 测试辅助方法
  int testCountBits(int bits) => _countBits(bits);
  List<int> testBitsToValues(int bits) => _bitsToValues(bits);

  /// 创建实例
  static SamuraiBitSolver create({
    required SamuraiBoard board,
    Random? random,
  }) => SamuraiBitSolver(board: board, random: random ?? Random());
}
