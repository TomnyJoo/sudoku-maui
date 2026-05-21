import 'dart:math';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/generation/index.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';

/// 标准数独专用生成器
class StandardGenerator implements IGameGenerator {

  StandardGenerator({
    Random? random,
    TemplateManager? templateManager,
    DiggingAlgorithm? diggingAlgorithm,
  })  : _random = random ?? Random(),
        _templateManager = templateManager,
        _diggingAlgorithm = diggingAlgorithm ?? SmartSymmetricDiggingAlgorithm(random: random);
  final Random _random;
  final TemplateManager? _templateManager;
  final DiggingAlgorithm _diggingAlgorithm;

  @override
  GameType get supportedGameType => GameType.standard;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    final stopwatch = Stopwatch()..start();

    Board solution;
    Board puzzle;
    bool usedTemplate = false;

    // 1. 优先使用传入的模板数据
    List<List<int?>>? solutionData;
    
    if (templateData != null && templateData.containsKey('solutionData')) {
      solutionData = (templateData['solutionData'] as List)
          .map((row) => (row as List).map((v) => v as int?).toList())
          .toList();
    } else if (_templateManager != null) {
      // 2. 备用：从 TemplateManager 加载
      onStageUpdate?.call(GenerationStage.loadingTemplate);
      final template = await _templateManager.loadRrn17Solutions();
      if (template != null) {
        solutionData = template.solutionData;
      }
    }

    if (solutionData != null) {
      // 使用模板生成
      onStageUpdate?.call(GenerationStage.applyingSubstitution);
      solution = _createBoardFromTemplate(solutionData);

      // 根据难度挖空生成谜题
      onStageUpdate?.call(GenerationStage.diggingPuzzle);
      puzzle = await _generatePuzzle(solution, difficulty, isCancelled);

      usedTemplate = true;
    } else {
      // 备用：实时生成终盘（使用 DLX 求解器）
      onStageUpdate?.call(GenerationStage.generatingSolution);
      solution = await _generateSolution(size, isCancelled);

      // 根据难度挖空生成谜题
      onStageUpdate?.call(GenerationStage.diggingPuzzle);
      puzzle = await _generatePuzzle(solution, difficulty, isCancelled);
    }

    stopwatch.stop();

    final finalSolution = _setSolutionFixedCells(solution, puzzle);

    return GenerationResult(
      solution: finalSolution,
      puzzle: puzzle,
      generationTime: stopwatch.elapsed,
      usedTemplate: usedTemplate,
    );
  }

  /// 生成随机终盘（使用 DLX 求解器）
  Future<Board> _generateSolution(int size, bool Function()? isCancelled) async {
    const maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }

      final solver = StandardDLXSolver.create(random: _random);
      final board = solver.generateSolution(isCancelled: isCancelled);
      if (board != null) {
        return board;
      }
    }
    throw GameGenerationException('无法生成标准数独终盘');
  }

  /// 挖空生成谜题（使用通用挖空算法）
  Future<Board> _generatePuzzle(
    Board solution,
    Difficulty difficulty,
    bool Function()? isCancelled,
  ) async {
    final config = DiggingConfig.fromDifficulty(difficulty);
    return _diggingAlgorithm.generatePuzzle(solution, config, isCancelled);
  }

  Board _createBoardFromTemplate(List<List<int?>> data) {
    final size = data.length;
    final cells = List.generate(size, (row) =>
        List.generate(size, (col) {
          final val = data[row][col];
          return Cell(
            row: row,
            col: col,
            value: val == 0 ? null : val,
            isFixed: val != null && val != 0,
          );
        }));
    final tempBoard = StandardBoard(size: size, cells: cells);
    return StandardBoard(size: size, cells: cells, regions: tempBoard.createRegions());
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
