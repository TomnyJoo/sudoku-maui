import 'dart:math';
import 'package:sudoku/models/index.dart';

abstract class BitSolver {
  BitSolver({required this.size, this.extraRegions, Random? random})
    : boxSize = size == 9 ? 3 : 2,
      random = random ?? Random() {
    fullMask = (1 << size) - 1;
  }
  final int size;
  final int boxSize;
  final List<List<int>>? extraRegions;
  final Random random;

  late List<int> rowMask;
  late List<int> colMask;
  late List<int> boxMask;
  late List<int>? extraRegionMask;
  late int fullMask;

  int countSolutions(
    Board puzzle, {
    int maxCount = 2,
    bool Function()? isCancelled,
  });
}

class StandardBitSolver extends BitSolver {
  StandardBitSolver({super.random}) : super(size: 9);

  factory StandardBitSolver.create({Random? random}) =>
      StandardBitSolver(random: random);

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
    boxMask = List.filled(size, 0);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = cells[r][c].value;
        if (val != null) {
          final bit = 1 << (val - 1);
          rowMask[r] |= bit;
          colMask[c] |= bit;
          final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
          boxMask[boxIdx] |= bit;
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
        final boxIdx =
            (bestR ~/ boxSize) * (size ~/ boxSize) + (bestC ~/ boxSize);
        final savedBox = boxMask[boxIdx];

        cells[bestR][bestC] = Cell(row: bestR, col: bestC, value: val);
        rowMask[bestR] |= bit;
        colMask[bestC] |= bit;
        boxMask[boxIdx] |= bit;

        dfs();
        if (solutionsFound >= maxSolutionsToFind) return;

        cells[bestR][bestC] = Cell(row: bestR, col: bestC);
        rowMask[bestR] = savedRow;
        colMask[bestC] = savedCol;
        boxMask[boxIdx] = savedBox;
      }
    }

    dfs();
    return solutionsFound;
  }

  int _candidates(int r, int c) {
    int bits = fullMask;
    bits &= ~rowMask[r];
    bits &= ~colMask[c];
    final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
    return bits & ~boxMask[boxIdx];
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
}

class WindowBitSolver extends BitSolver {
  WindowBitSolver({super.random})
    : super(size: 9, extraRegions: _generateWindowRegions()) {
    extraRegionMask = List.filled(extraRegions!.length, 0);
  }

  factory WindowBitSolver.create({Random? random}) =>
      WindowBitSolver(random: random);

  static List<List<int>> _generateWindowRegions() {
    final regions = <List<int>>[];
    const size = 9;

    final topLeftWindow = List.generate(size * size, (idx) => 0);
    final topRightWindow = List.generate(size * size, (idx) => 0);
    final bottomLeftWindow = List.generate(size * size, (idx) => 0);
    final bottomRightWindow = List.generate(size * size, (idx) => 0);

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        topLeftWindow[r * size + c] = 1;
      }
    }

    for (int r = 0; r < 3; r++) {
      for (int c = 4; c < 7; c++) {
        topRightWindow[r * size + c] = 1;
      }
    }

    for (int r = 4; r < 7; r++) {
      for (int c = 0; c < 3; c++) {
        bottomLeftWindow[r * size + c] = 1;
      }
    }

    for (int r = 4; r < 7; r++) {
      for (int c = 4; c < 7; c++) {
        bottomRightWindow[r * size + c] = 1;
      }
    }

    regions
      ..add(topLeftWindow)
      ..add(topRightWindow)
      ..add(bottomLeftWindow)
      ..add(bottomRightWindow);

    return regions;
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
    boxMask = List.filled(size, 0);
    extraRegionMask = List.filled(extraRegions!.length, 0);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = cells[r][c].value;
        if (val != null) {
          final bit = 1 << (val - 1);
          rowMask[r] |= bit;
          colMask[c] |= bit;
          final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
          boxMask[boxIdx] |= bit;

          for (int i = 0; i < extraRegions!.length; i++) {
            if (extraRegions![i][r * size + c] == 1) {
              extraRegionMask![i] |= bit;
            }
          }
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
        final boxIdx =
            (bestR ~/ boxSize) * (size ~/ boxSize) + (bestC ~/ boxSize);
        final savedBox = boxMask[boxIdx];
        final savedExtraMasks = extraRegionMask!.map((m) => m).toList();

        cells[bestR][bestC] = Cell(row: bestR, col: bestC, value: val);
        rowMask[bestR] |= bit;
        colMask[bestC] |= bit;
        boxMask[boxIdx] |= bit;

        for (int i = 0; i < extraRegions!.length; i++) {
          if (extraRegions![i][bestR * size + bestC] == 1) {
            extraRegionMask![i] |= bit;
          }
        }

        dfs();
        if (solutionsFound >= maxSolutionsToFind) return;

        cells[bestR][bestC] = Cell(row: bestR, col: bestC);
        rowMask[bestR] = savedRow;
        colMask[bestC] = savedCol;
        boxMask[boxIdx] = savedBox;
        for (int i = 0; i < extraRegions!.length; i++) {
          extraRegionMask![i] = savedExtraMasks[i];
        }
      }
    }

    dfs();
    return solutionsFound;
  }

  int _candidates(int r, int c) {
    int bits = fullMask;
    bits &= ~rowMask[r];
    bits &= ~colMask[c];
    final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
    bits &= ~boxMask[boxIdx];

    if (extraRegions != null && extraRegionMask != null) {
      for (int i = 0; i < extraRegions!.length; i++) {
        if (extraRegions![i][r * size + c] == 1) {
          bits &= ~extraRegionMask![i];
        }
      }
    }

    return bits;
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
}

class DiagonalBitSolver extends BitSolver {
  DiagonalBitSolver({super.random})
    : super(size: 9, extraRegions: _generateDiagonalRegions()) {
    extraRegionMask = List.filled(extraRegions!.length, 0);
  }

  factory DiagonalBitSolver.create({Random? random}) =>
      DiagonalBitSolver(random: random);

  static List<List<int>> _generateDiagonalRegions() {
    final regions = <List<int>>[];
    const size = 9;

    final mainDiagonal = List.generate(size * size, (idx) => 0);
    final antiDiagonal = List.generate(size * size, (idx) => 0);

    for (int i = 0; i < size; i++) {
      mainDiagonal[i * size + i] = 1;
      antiDiagonal[i * size + (size - 1 - i)] = 1;
    }

    regions..add(mainDiagonal)
    ..add(antiDiagonal);

    return regions;
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
    boxMask = List.filled(size, 0);
    extraRegionMask = List.filled(extraRegions!.length, 0);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = cells[r][c].value;
        if (val != null) {
          final bit = 1 << (val - 1);
          rowMask[r] |= bit;
          colMask[c] |= bit;
          final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
          boxMask[boxIdx] |= bit;

          for (int i = 0; i < extraRegions!.length; i++) {
            if (extraRegions![i][r * size + c] == 1) {
              extraRegionMask![i] |= bit;
            }
          }
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
        final boxIdx =
            (bestR ~/ boxSize) * (size ~/ boxSize) + (bestC ~/ boxSize);
        final savedBox = boxMask[boxIdx];
        final savedExtraMasks = extraRegionMask!.map((m) => m).toList();

        cells[bestR][bestC] = Cell(row: bestR, col: bestC, value: val);
        rowMask[bestR] |= bit;
        colMask[bestC] |= bit;
        boxMask[boxIdx] |= bit;

        for (int i = 0; i < extraRegions!.length; i++) {
          if (extraRegions![i][bestR * size + bestC] == 1) {
            extraRegionMask![i] |= bit;
          }
        }

        dfs();
        if (solutionsFound >= maxSolutionsToFind) return;

        cells[bestR][bestC] = Cell(row: bestR, col: bestC);
        rowMask[bestR] = savedRow;
        colMask[bestC] = savedCol;
        boxMask[boxIdx] = savedBox;
        for (int i = 0; i < extraRegions!.length; i++) {
          extraRegionMask![i] = savedExtraMasks[i];
        }
      }
    }

    dfs();
    return solutionsFound;
  }

  int _candidates(int r, int c) {
    int bits = fullMask;
    bits &= ~rowMask[r];
    bits &= ~colMask[c];
    final boxIdx = (r ~/ boxSize) * (size ~/ boxSize) + (c ~/ boxSize);
    bits &= ~boxMask[boxIdx];

    if (extraRegions != null && extraRegionMask != null) {
      for (int i = 0; i < extraRegions!.length; i++) {
        if (extraRegions![i][r * size + c] == 1) {
          bits &= ~extraRegionMask![i];
        }
      }
    }

    return bits;
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
}
