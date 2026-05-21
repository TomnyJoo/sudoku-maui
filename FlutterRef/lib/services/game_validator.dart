import 'package:sudoku/models/index.dart';

/// 统一游戏验证器，基于区域验证，支持所有数独类型
class GameValidator {
  /// 验证棋盘是否有效，只验证区域约束（行、列、宫格、对角线、窗口、不规则区域等）
  bool validateBoard(Board board) {
    for (final region in board.regions) {
      if (!_validateRegion(region)) {
        return false;
      }
    }
    return true;
  }

  /// 验证移动是否有效
  bool isValidMove(Board board, int row, int col, int value) {
    // 检查值范围
    if (value < 1 || value > board.size) {
      return false;
    }

    // 检查单元格是否固定
    final cell = board.getCell(row, col);
    if (cell.isFixed) {
      return false;
    }

    // 检查区域约束
    for (final region in board.regions) {
      if (region.containsCoordinate(row, col)) {
        for (final regionCell in region.cells) {
          if (regionCell.row == row && regionCell.col == col) continue;
          if (regionCell.value == value) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// 验证谜题与答案是否匹配
  bool validatePuzzleSolution(Board puzzle, Board solution) {
    if (puzzle.size != solution.size) {
      return false;
    }

    for (int row = 0; row < puzzle.size; row++) {
      for (int col = 0; col < puzzle.size; col++) {
        final puzzleCell = puzzle.getCell(row, col);
        final solutionCell = solution.getCell(row, col);

        if (puzzleCell.value != null && puzzleCell.value != solutionCell.value) {
          return false;
        }
      }
    }

    return true;
  }

  /// 检查游戏是否完成
  bool isGameCompleted(Board board) {
    // 检查所有单元格是否已填满
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        if (board.getCell(row, col).value == null) {
          return false;
        }
      }
    }

    // 检查是否有效
    return validateBoard(board);
  }

  /// 检查是否有重复数字
  bool hasDuplicates(Board board) {
    for (final region in board.regions) {
      if (!_validateRegion(region)) {
        return true;
      }
    }
    return false;
  }

  /// 验证区域（核心方法）
  bool _validateRegion(Region region) {
    final values = <int>{};
    for (final cell in region.cells) {
      final value = cell.value;
      if (value != null) {
        if (values.contains(value)) {
          return false;
        }
        values.add(value);
      }
    }
    return true;
  }

  /// 验证Killer数独所有cage的和值
  /// 只在生成答案面板时调用，验证cage.sum是否等于单元格值的和
  bool validateKillerCages(KillerBoard board) {
    for (final cage in board.cages) {
      final cells = cage.cellCoordinates
          .map((coord) => board.getCell(coord.$1, coord.$2))
          .toList();

      // 检查cage是否填满
      final filledCells = cells.where((c) => c.value != null).toList();
      if (filledCells.length != cells.length) {
        return false; // cage未填满
      }

      // 计算实际和值
      final actualSum = filledCells.fold(0, (s, c) => s + c.value!);

      // 验证和值是否匹配
      if (actualSum != cage.sum) {
        return false;
      }
    }
    return true;
  }

  /// 验证游戏状态是否有效（用于保存/加载前检查）
  /// [state] - 游戏状态
  /// 返回 true 表示状态有效，可以保存/恢复
  static bool isValidGameState<B extends Board>(GameState<B> state) {
    if (state.startTime == null) return false;
    if (state.isCompleted) return false;
    if (state.board.cells.isEmpty) return false;

    int fixedCount = 0;
    for (final row in state.initialBoard.cells) {
      for (final cell in row) {
        if (cell.isFixed && cell.value != null) {
          fixedCount++;
        }
      }
    }

    bool hasFixedCellsInSolution = false;
    for (final row in state.solution.cells) {
      for (final cell in row) {
        if (cell.isFixed && cell.value != null) {
          hasFixedCellsInSolution = true;
          break;
        }
      }
      if (hasFixedCellsInSolution) break;
    }

    if (hasFixedCellsInSolution && fixedCount == 0) return false;

    int solutionCount = 0;
    for (final row in state.solution.cells) {
      for (final cell in row) {
        if (cell.value != null) {
          solutionCount++;
        }
      }
    }

    final totalCells = state.solution.size * state.solution.size;
    if (solutionCount < totalCells) return false;

    return true;
  }
}
