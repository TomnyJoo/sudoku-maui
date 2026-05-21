import 'dart:math';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/generation/index.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';

/// 武士数独专用生成器
class SamuraiGenerator implements IGameGenerator {

  SamuraiGenerator({
    Random? random,
    DiggingAlgorithm? diggingAlgorithm,
  })  : _random = random ?? Random(),
        _diggingAlgorithm = diggingAlgorithm ?? SmartSymmetricDiggingAlgorithm(random: random);
  final Random _random;
  final DiggingAlgorithm _diggingAlgorithm;

  @override
  GameType get supportedGameType => GameType.samurai;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 武士数独可以使用模板作为中心盘答案
    onStageUpdate?.call(GenerationStage.generatingSolution);
    final solution = await _generateSolution(isCancelled, templateData);

    onStageUpdate?.call(GenerationStage.diggingPuzzle);
    final puzzle = await _generatePuzzle(solution, difficulty, isCancelled);

    stopwatch.stop();

    // 【关键】全程 isFixed=false，只在返回前将有数字的格子标记为固定
    // 同时同步标记 solution（答案面板），确保两者一致
    final finalPuzzle = _markFixedCells(puzzle);
    final finalSolution = _markFixedCells(solution);

    stopwatch.stop();

    return GenerationResult(
      solution: finalSolution,
      puzzle: finalPuzzle,
      generationTime: stopwatch.elapsed,
    );
  }

  /// 生成武士数独终盘
  ///
  /// 生成策略：
  /// 1. 如果有模板数据，使用模板作为中心子盘答案
  /// 2. 否则生成中心子盘
  /// 3. 然后生成4个角子盘，考虑与中心子盘的重叠约束
  Future<SamuraiBoard> _generateSolution(bool Function()? isCancelled, Map<String, dynamic>? templateData) async {
    const maxAttempts = 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }

      try {
        // 1. 生成中心子盘（优先使用模板）
        StandardBoard? centerBoard;
        if (templateData != null && templateData['centerSolution'] != null) {
          centerBoard = _createBoardFromTemplate(templateData['centerSolution'] as List<List<int>>);
        } else {
          centerBoard = _generateStandardSolution();
        }
        if (centerBoard == null) continue;

        // 2. 创建武士数独棋盘并放置中心子盘
        final cells = List.generate(
          SamuraiBoard.boardSize,
          (r) => List.generate(
            SamuraiBoard.boardSize,
            (c) => Cell(row: r, col: c),
          ),
        );

        // 放置中心子盘 (offset: 6, 6)
        _placeSubBoard(cells, centerBoard, 6, 6);

        // 3. 生成4个角子盘，考虑重叠约束
        // 左上角 (offset: 0, 0)，与中心重叠 (6-8, 6-8)
        final topLeftBoard = _generateCornerBoard(cells, 0, 0, centerBoard, 0, 0);
        if (topLeftBoard == null) continue;
        _placeSubBoard(cells, topLeftBoard, 0, 0);

        // 右上角 (offset: 0, 12)，与中心重叠 (6-8, 12-14)
        final topRightBoard = _generateCornerBoard(cells, 0, 12, centerBoard, 0, 6);
        if (topRightBoard == null) continue;
        _placeSubBoard(cells, topRightBoard, 0, 12);

        // 左下角 (offset: 12, 0)，与中心重叠 (12-14, 6-8)
        final bottomLeftBoard = _generateCornerBoard(cells, 12, 0, centerBoard, 6, 0);
        if (bottomLeftBoard == null) continue;
        _placeSubBoard(cells, bottomLeftBoard, 12, 0);

        // 右下角 (offset: 12, 12)，与中心重叠 (12-14, 12-14)
        final bottomRightBoard = _generateCornerBoard(cells, 12, 12, centerBoard, 6, 6);
        if (bottomRightBoard == null) continue;
        _placeSubBoard(cells, bottomRightBoard, 12, 12);

        // 4. 验证整个棋盘
        final samuraiBoard = SamuraiBoard(cells: cells);
        if (_validateBoard(samuraiBoard)) {
          return samuraiBoard;
        }
      } catch (e) {
        // 继续尝试
      }
    }

    throw GameGenerationException('无法生成武士数独终盘');
  }

  /// 生成标准数独终盘
  StandardBoard? _generateStandardSolution() {
    final solver = StandardDLXSolver.create(random: _random);
    final board = solver.generateSolution();
    if (board == null) return null;
    return board as StandardBoard;
  }

  /// 从模板数据创建标准数独棋盘
  StandardBoard _createBoardFromTemplate(List<List<int>> templateData) {
    final cells = List.generate(9, (r) => List.generate(9, (c) => Cell(
      row: r,
      col: c,
      value: templateData[r][c] > 0 ? templateData[r][c] : null,
    )));
    return StandardBoard(size: 9, cells: cells);
  }

  /// 生成角子盘，考虑与中心子盘的重叠约束
  ///
  /// [cells] - 武士数独棋盘单元格
  /// [offsetR], [offsetC] - 角子盘在武士棋盘中的偏移
  /// [centerBoard] - 中心子盘
  /// [centerOffsetR], [centerOffsetC] - 重叠区域在中心子盘中的偏移
  StandardBoard? _generateCornerBoard(
    List<List<Cell>> cells,
    int offsetR,
    int offsetC,
    StandardBoard centerBoard,
    int centerOffsetR,
    int centerOffsetC,
  ) {
    // 创建一个带约束的子盘矩阵
    final matrix = List.generate(9, (r) => List.generate(9, (c) => 0));

    // 计算重叠区域在角子盘中的位置
    // 重叠区域在武士棋盘中的位置是 (6-8, 6-8), (6-8, 12-14), (12-14, 6-8), (12-14, 12-14)
    // 需要转换为角子盘内的位置
    // 角子盘偏移: 左上(0,0), 右上(0,12), 左下(12,0), 右下(12,12)
    // 重叠区域中心: (6,6), (6,12), (12,6), (12,12)
    // 重叠区域在角子盘中的位置 = 重叠区域中心 - 角子盘偏移
    final overlapCenterR = 6 + centerOffsetR;
    final overlapCenterC = 6 + centerOffsetC;
    final cornerOverlapR = overlapCenterR - offsetR;
    final cornerOverlapC = overlapCenterC - offsetC;

    // 填充重叠区域的约束
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final centerCell = centerBoard.getCell(centerOffsetR + r, centerOffsetC + c);
        if (centerCell.value != null) {
          matrix[cornerOverlapR + r][cornerOverlapC + c] = centerCell.value!;
        }
      }
    }

    // 使用回溯算法生成带约束的子盘
    return _generateConstrainedStandardBoard(matrix);
  }

  /// 生成带约束的标准数独终盘
  StandardBoard? _generateConstrainedStandardBoard(List<List<int>> constraints) {
    // 使用回溯算法生成
    final matrix = List.generate(9, (r) => List.generate(9, (c) => constraints[r][c]));
    final rowMask = List.filled(9, 0);
    final colMask = List.filled(9, 0);
    final boxMask = List.filled(9, 0);

    // 初始化约束掩码
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
      if (found) return;

      // 找候选数最少的空格
      int bestR = -1, bestC = -1, bestBits = 0, minCount = 10;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (matrix[r][c] != 0) continue;

          final bits = 0x1ff & ~(rowMask[r] | colMask[c] | boxMask[(r ~/ 3) * 3 + (c ~/ 3)]);
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

      final candidates = _bitsToValues(bestBits)..shuffle(_random);
      for (final val in candidates) {
        if (found) return;

        final r = bestR;
        final c = bestC;
        final bit = 1 << (val - 1);
        final boxIdx = (r ~/ 3) * 3 + (c ~/ 3);

        matrix[r][c] = val;
        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[boxIdx] |= bit;

        dfs();

        if (!found) {
          matrix[r][c] = 0;
          rowMask[r] &= ~bit;
          colMask[c] &= ~bit;
          boxMask[boxIdx] &= ~bit;
        }
      }
    }

    dfs();

    if (!found) return null;

    // 创建 StandardBoard（solution 中所有格子都不是固定的）
    final cells = List.generate(9, (r) => List.generate(9, (c) => Cell(
      row: r,
      col: c,
      value: matrix[r][c] > 0 ? matrix[r][c] : null,
    )));
    return StandardBoard(size: 9, cells: cells);
  }

  /// 将子盘放置到武士棋盘的指定位置
  void _placeSubBoard(List<List<Cell>> cells, StandardBoard subBoard, int offsetR, int offsetC) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final subCell = subBoard.getCell(r, c);
        cells[offsetR + r][offsetC + c] = Cell(
          row: offsetR + r,
          col: offsetC + c,
          value: subCell.value,
        );
      }
    }
  }

  /// 验证武士数独棋盘
  bool _validateBoard(SamuraiBoard board) {
    // 检查每个子盘是否有效
    final subGridOffsets = SamuraiBoard.subGridOffsets;

    for (int i = 0; i < 5; i++) {
      final (startRow, startCol) = subGridOffsets[i];
      if (!_validateSubGrid(board, startRow, startCol)) {
        return false;
      }
    }

    return true;
  }

  /// 验证单个子网格
  bool _validateSubGrid(SamuraiBoard board, int startRow, int startCol) {
    // 检查行
    for (int r = 0; r < 9; r++) {
      final seen = <int>{};
      for (int c = 0; c < 9; c++) {
        final val = board.getCell(startRow + r, startCol + c).value;
        if (val != null) {
          if (seen.contains(val)) return false;
          seen.add(val);
        }
      }
    }

    // 检查列
    for (int c = 0; c < 9; c++) {
      final seen = <int>{};
      for (int r = 0; r < 9; r++) {
        final val = board.getCell(startRow + r, startCol + c).value;
        if (val != null) {
          if (seen.contains(val)) return false;
          seen.add(val);
        }
      }
    }

    // 检查宫
    for (int blockR = 0; blockR < 3; blockR++) {
      for (int blockC = 0; blockC < 3; blockC++) {
        final seen = <int>{};
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            final val = board.getCell(
              startRow + blockR * 3 + r,
              startCol + blockC * 3 + c,
            ).value;
            if (val != null) {
              if (seen.contains(val)) return false;
              seen.add(val);
            }
          }
        }
      }
    }

    return true;
  }

  /// 挖空生成谜题
  ///
  /// 关键修复：
  /// 1. 使用对称挖空算法（SmartSymmetricDiggingAlgorithm）
  /// 2. 传入 gameType=samurai 获取正确的难度配置
  /// 3. 每个子盘保证最少保留 17 个数字（标准数独最少唯一解要求）
  /// 4. 先处理中心子盘（被4角共享），再处理4个角子盘
  Future<SamuraiBoard> _generatePuzzle(
    SamuraiBoard solution,
    Difficulty difficulty,
    bool Function()? isCancelled,
  ) async {
    final subGridOffsets = SamuraiBoard.subGridOffsets;
    var puzzle = solution;

    // 使用 samurai 游戏类型的难度配置
    final diggingConfig = DiggingConfig.fromDifficulty(difficulty, gameType: GameType.samurai);
    // 每个子盘的目标填充数，且不低于标准数独最少保留数字（17）
    const minSubGridFilled = 17;
    final targetFilled = diggingConfig.maxFilledCells < minSubGridFilled
        ? minSubGridFilled
        : diggingConfig.maxFilledCells;

    // 处理顺序：先中心（索引4），再4个角（索引0,1,2,3）
    // 中心子盘被4个角共享，先挖空可以避免角子盘挖空时
    // 与中心子盘的固定值产生冲突
    const processOrder = [4, 0, 1, 2, 3];

    for (final i in processOrder) {
      final (startRow, startCol) = subGridOffsets[i];

      // 提取子盘（强制 isFixed=false 确保可挖空）
      final subBoard = _extractSubBoard(puzzle, startRow, startCol);

      // 计算子盘实际非空格数
      int actualFilled = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (subBoard.getCell(r, c).value != null) actualFilled++;
        }
      }

      // 如果子盘非空格数已经 <= targetFilled，跳过挖空
      if (actualFilled <= targetFilled) continue;

      // 使用统一的 targetFilled 作为挖空目标
      final subDiggingConfig = DiggingConfig(
        minFilledCells: targetFilled,
        maxFilledCells: targetFilled,
        maxAttempts: diggingConfig.maxAttempts,
      );

      // 挖空
      final subPuzzle = await _diggingAlgorithm.generatePuzzle(
        subBoard,
        subDiggingConfig,
        isCancelled,
      ) as StandardBoard;

      // 【关键】digging algorithm 返回时会调用 setFixedCells 将有值格子设为 isFixed=true
      // 但武士数独需要全程 isFixed=false，在最终返回前统一设置
      // 所以这里强制重置所有格子的 isFixed 为 false
      final resetCells = List.generate(9, (r) => List.generate(9, (c) {
        final cell = subPuzzle.getCell(r, c);
        return Cell(row: r, col: c, value: cell.value);
      }));
      final resetPuzzle = StandardBoard(size: 9, cells: resetCells);

      // 放回武士棋盘
      puzzle = _mergeSubBoard(puzzle, resetPuzzle, startRow, startCol);
    }

    return puzzle;
  }

  /// 从武士棋盘提取子盘
  StandardBoard _extractSubBoard(SamuraiBoard board, int startRow, int startCol) {
    final cells = List.generate(9, (r) => List.generate(9, (c) {
      final cell = board.getCell(startRow + r, startCol + c);
      return Cell(
        row: r,
        col: c,
        value: cell.value,
      );
    }));
    return StandardBoard(size: 9, cells: cells);
  }

  /// 将子盘合并回武士棋盘（不设置 isFixed，保持 false）
  SamuraiBoard _mergeSubBoard(SamuraiBoard board, StandardBoard subBoard, int startRow, int startCol) {
    final newCells = board.cells.map((row) => row.map((cell) => cell).toList()).toList();

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final subCell = subBoard.getCell(r, c);
        newCells[startRow + r][startCol + c] = Cell(
          row: startRow + r,
          col: startCol + c,
          value: subCell.value,
          // 不设置 isFixed，保持默认 false
        );
      }
    }

    return SamuraiBoard(cells: newCells);
  }

  /// 标记棋盘中有值的格子为固定
  SamuraiBoard _markFixedCells(SamuraiBoard board) {
    final newCells = board.cells.map((row) =>
        row.map((cell) {
          if (cell.value != null && !cell.isFixed) {
            return Cell(
              row: cell.row,
              col: cell.col,
              value: cell.value,
              isFixed: true,
            );
          }
          return cell;
        }).toList()).toList();

    return SamuraiBoard(cells: newCells);
  }

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
}
