import 'dart:math';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/solvers/bit_solver.dart';

/// 锯齿数独专用BitSolver
class JigsawBitSolver extends BitSolver {
  JigsawBitSolver({required this.regionMatrix, super.random}) : super(size: 9) {
    _initRegionData();
  }

  factory JigsawBitSolver.create({
    required List<List<int>> regionMatrix,
    Random? random,
  }) => JigsawBitSolver(regionMatrix: regionMatrix, random: random);

  final List<List<int>> regionMatrix;
  late List<List<int>> regionCells; // 每个区域包含的单元格坐标
  late List<List<int>> cellToRegion; // 每个单元格所属的区域索引

  void _initRegionData() {
    final size = this.size;
    regionCells = List.generate(size, (_) => []);
    cellToRegion = List.generate(size, (_) => List.filled(size, -1));

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final regionId = regionMatrix[r][c];
        cellToRegion[r][c] = regionId;
        regionCells[regionId].add(r * size + c);
      }
    }
  }

  @override
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

  int _countSolutionsFromMatrix(
    List<List<int>> puzzleMatrix, {
    int maxCount = 2,
    bool Function()? isCancelled,
  }) {
    final cells = List.generate(
      size,
      (r) => List.generate(
        size,
        (c) => Cell(
          row: r,
          col: c,
          value: puzzleMatrix[r][c] == 0 ? null : puzzleMatrix[r][c],
        ),
      ),
    );

    rowMask = List.filled(size, 0);
    colMask = List.filled(size, 0);
    boxMask = List.filled(size, 0); // 这里boxMask实际上是regionMask

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = cells[r][c].value;
        if (val != null) {
          final bit = 1 << (val - 1);
          rowMask[r] |= bit;
          colMask[c] |= bit;
          final regionId = cellToRegion[r][c];
          boxMask[regionId] |= bit;
        }
      }
    }

    int solutionsFound = 0;
    final int maxSolutionsToFind = maxCount;

    void dfs() {
      if (isCancelled?.call() ?? false) return;
      if (solutionsFound >= maxSolutionsToFind) return;

      int minCount = size + 1;
      int bestR = -1, bestC = -1, bestBits = 0;
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (cells[r][c].value != null) continue;
          final bits = _candidates(r, c);
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
        if (minCount == 1) break;
      }

      if (bestR == -1) {
        solutionsFound++;
        return;
      }

      final values = _bitsToValues(bestBits)..shuffle(random);

      for (final val in values) {
        final bit = 1 << (val - 1);
        final savedRow = rowMask[bestR];
        final savedCol = colMask[bestC];
        final regionId = cellToRegion[bestR][bestC];
        final savedRegion = boxMask[regionId];

        cells[bestR][bestC] = Cell(row: bestR, col: bestC, value: val);
        rowMask[bestR] |= bit;
        colMask[bestC] |= bit;
        boxMask[regionId] |= bit;

        dfs();
        if (solutionsFound >= maxSolutionsToFind) return;

        cells[bestR][bestC] = Cell(row: bestR, col: bestC);
        rowMask[bestR] = savedRow;
        colMask[bestC] = savedCol;
        boxMask[regionId] = savedRegion;
      }
    }

    dfs();
    return solutionsFound;
  }

  int _candidates(int r, int c) {
    int bits = fullMask;
    bits &= ~rowMask[r];
    bits &= ~colMask[c];
    final regionId = cellToRegion[r][c];
    return bits & ~boxMask[regionId];
  }

  int _countBits(int bits) {
    int cnt = 0;
    while (bits != 0) {
      cnt += bits & 1;
      bits >>= 1;
    }
    return cnt;
  }

  List<int> _bitsToValues(int bits) {
    final values = <int>[];
    for (int i = 0; i < size; i++) {
      if ((bits & (1 << i)) != 0) values.add(i + 1);
    }
    return values;
  }

  /// 生成锯齿数独终盘
  ///
  /// 从空棋盘开始，使用回溯算法生成一个有效的锯齿数独终盘
  Board? generateSolution(
    List<List<int>> regionMatrix,
    bool Function()? isCancelled,
  ) {
    final cells = List.generate(
      size,
      (r) => List.generate(size, (c) => Cell(row: r, col: c)),
    );

    rowMask = List.filled(size, 0);
    colMask = List.filled(size, 0);
    boxMask = List.filled(size, 0);

    bool found = false;

    void dfs() {
      if (isCancelled?.call() ?? false) return;
      if (found) return;

      int minCount = size + 1;
      int bestR = -1, bestC = -1, bestBits = 0;
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (cells[r][c].value != null) continue;
          final bits = _candidates(r, c);
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
        if (minCount == 1) break;
      }

      if (bestR == -1) {
        found = true;
        return;
      }

      final values = _bitsToValues(bestBits)..shuffle(random);

      for (final val in values) {
        if (found) return;

        final bit = 1 << (val - 1);
        final regionId = cellToRegion[bestR][bestC];

        cells[bestR][bestC] = Cell(row: bestR, col: bestC, value: val);
        rowMask[bestR] |= bit;
        colMask[bestC] |= bit;
        boxMask[regionId] |= bit;

        dfs();

        if (!found) {
          cells[bestR][bestC] = Cell(row: bestR, col: bestC);
          rowMask[bestR] &= ~bit;
          colMask[bestC] &= ~bit;
          boxMask[regionId] &= ~bit;
        }
      }
    }

    dfs();

    if (!found) return null;

    // 创建 JigsawBoard
    final jigsawCells = cells.map((row) =>
        row.map((cell) => Cell(
          row: cell.row,
          col: cell.col,
          value: cell.value,
          isFixed: true,
        )).toList()).toList();

    final jigsawBoard = JigsawBoard(size: size, cells: jigsawCells, regionMatrix: regionMatrix);
    return JigsawBoard(
      size: size,
      cells: jigsawCells,
      regionMatrix: regionMatrix,
      regions: jigsawBoard.createRegions(),
    );
  }
}
