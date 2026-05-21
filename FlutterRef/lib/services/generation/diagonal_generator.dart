import 'dart:math';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/generation/index.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';

/// 对角线数独专用生成器
///
/// 使用 DLX 求解器生成满足对角线约束的终盘
class DiagonalGenerator implements IGameGenerator {

  DiagonalGenerator({
    Random? random,
    DiggingAlgorithm? diggingAlgorithm,
  })  : _random = random ?? Random(),
        _diggingAlgorithm = diggingAlgorithm ?? SmartSymmetricDiggingAlgorithm(
          random: random,
          dlxSolver: DiagonalDLXSolver.create(random: random),
        );
  final Random _random;
  final DiggingAlgorithm _diggingAlgorithm;

  @override
  GameType get supportedGameType => GameType.diagonal;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 对角线数独不能使用 rrn17 模板（不满足对角线约束）
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

      final solver = DiagonalDLXSolver.create(random: _random);
      final board = solver.generateSolution(isCancelled: isCancelled);
      if (board != null) {
        return _convertToDiagonalBoard(board);
      }
    }
    throw GameGenerationException('无法生成对角线数独终盘');
  }

  /// 挖空生成谜题（使用通用挖空算法）
  Future<Board> _generatePuzzle(
    Board solution,
    Difficulty difficulty,
    bool Function()? isCancelled,
  ) async {
    final config = DiggingConfig.fromDifficulty(difficulty, gameType: GameType.diagonal);
    return _diggingAlgorithm.generatePuzzle(
      solution,
      config,
      isCancelled,
    );
  }

  DiagonalBoard _convertToDiagonalBoard(Board board) {
    final cells = board.cells.map((row) =>
        row.map((cell) => Cell(
          row: cell.row,
          col: cell.col,
          value: cell.value,
          isFixed: cell.isFixed,
        )).toList()).toList();

    final diagonalBoard = DiagonalBoard(size: board.size, cells: cells);
    return DiagonalBoard(
      size: board.size,
      cells: cells,
      regions: diagonalBoard.createRegions(),
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
