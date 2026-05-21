import 'dart:math';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/generation/index.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';

/// 窗口数独专用生成器
///
/// 使用 DLX 求解器生成满足窗口约束的终盘
class WindowGenerator implements IGameGenerator {

  WindowGenerator({
    Random? random,
    DiggingAlgorithm? diggingAlgorithm,
  })  : _random = random ?? Random(),
        _diggingAlgorithm = diggingAlgorithm ?? SmartSymmetricDiggingAlgorithm(
          random: random,
          dlxSolver: WindowDLXSolver.create(random: random),
        );
  final Random _random;
  final DiggingAlgorithm _diggingAlgorithm;

  @override
  GameType get supportedGameType => GameType.window;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 窗口数独不能使用 rrn17 模板（不满足窗口约束）
    // 直接使用 DLX 求解器生成终盘
    onStageUpdate?.call(GenerationStage.generatingSolution);
    final solution = await _generateSolution(size, isCancelled);

    // 根据难度挖空生成谜题
    onStageUpdate?.call(GenerationStage.diggingPuzzle);
    final puzzle = await _generatePuzzle(
      solution,
      difficulty,
      isCancelled,
    );

    stopwatch.stop();

    final finalSolution = _setSolutionFixedCells(solution, puzzle);

    return GenerationResult(
      solution: finalSolution,
      puzzle: puzzle,
      generationTime: stopwatch.elapsed,
    );
  }

  /// 生成随机终盘（使用 DLX 求解器）
  Future<Board> _generateSolution(int size, bool Function()? isCancelled) async {
    const maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }

      final solver = WindowDLXSolver.create(random: _random);
      final board = solver.generateSolution(isCancelled: isCancelled);
      if (board != null) {
        return _convertToWindowBoard(board);
      }
    }
    throw GameGenerationException('无法生成窗口数独终盘');
  }

  /// 挖空生成谜题（使用通用挖空算法）
  Future<Board> _generatePuzzle(
    Board solution,
    Difficulty difficulty,
    bool Function()? isCancelled,
  ) async {
    final config = DiggingConfig.fromDifficulty(difficulty, gameType: GameType.window);
    return _diggingAlgorithm.generatePuzzle(
      solution,
      config,
      isCancelled,
    );
  }

  WindowBoard _convertToWindowBoard(Board board) {
    final cells = board.cells.map((row) =>
        row.map((cell) => Cell(
          row: cell.row,
          col: cell.col,
          value: cell.value,
        )).toList()).toList();

    final windowBoard = WindowBoard(size: board.size, cells: cells);
    return WindowBoard(
      size: board.size,
      cells: cells,
      regions: windowBoard.createRegions(),
    );
  }

  Board _setSolutionFixedCells(Board solution, Board puzzle) {
    final newCells = solution.cells.map((row) =>
        row.map((cell) {
          final pCell = puzzle.getCell(cell.row, cell.col);
          return Cell(
            row: cell.row,
            col: cell.col,
            value: cell.value,
            isFixed: pCell.isFixed,
          );
        }).toList()).toList();
    return solution.createInstance(newCells, regions: solution.regions);
  }
}
