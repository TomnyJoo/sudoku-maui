import 'dart:async';
import 'dart:math';
import 'package:sudoku/index.dart';

/// 锯齿数独专用生成器（重构版）
class JigsawGenerator implements IGameGenerator {
  JigsawGenerator({Random? random, GameValidator? validator})
    : _random = random ?? Random(),
      _validator = validator ?? GameValidator();
  final Random _random;
  final GameValidator _validator;

  /// 使用统一的智能随机挖空算法（无对称约束，适合不规则区域）
  final _diggingAlgorithm = SmartRandomDiggingAlgorithm(
    dlxSolver: JigsawDlxSolverAdapter(),
  );

  /// 获取JigsawBitSolver实例
  JigsawBitSolver _getSolver(List<List<int>> regionMatrix) =>
      JigsawBitSolver.create(regionMatrix: regionMatrix, random: _random);

  @override
  GameType get supportedGameType => GameType.jigsaw;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    final stopwatch = Stopwatch()..start();
    final diffConfig = DifficultyConfig.getConfig(difficulty);
    final gameConfig = diffConfig.getGameConfig(GameType.jigsaw);

    // 1. 加载区域模板
    onStageUpdate?.call(GenerationStage.loadingTemplate);
    final regionMatrix = await _loadRegionMatrix(
      isCancelled,
      templateData,
    );

    // 2. 生成终盘
    onStageUpdate?.call(GenerationStage.generatingSolution);
    final solution = await _generateSolution(
      regionMatrix: regionMatrix,
      config: gameConfig,
      isCancelled: isCancelled,
    );

    // 3. 挖空生成谜题
    onStageUpdate?.call(GenerationStage.diggingPuzzle);
    final puzzle = await _generatePuzzle(
      solution: solution,
      config: gameConfig,
      isCancelled: isCancelled,
    );

    // 4. 验证谜题与答案匹配
    onStageUpdate?.call(GenerationStage.validating);
    if (!_validator.validatePuzzleSolution(puzzle, solution)) {
      throw GameGenerationNoSolutionException('谜题验证失败');
    }

    stopwatch.stop();

    return GenerationResult(
      solution: solution,
      puzzle: puzzle,
      generationTime: stopwatch.elapsed,
    );
  }

  /// 加载区域模板
  Future<List<List<int>>> _loadRegionMatrix(
    bool Function()? isCancelled,
    Map<String, dynamic>? templateData,
  ) async {
    // 首先尝试使用传递的模板数据
    if (templateData != null && templateData.containsKey('regionMatrix')) {
      final regionMatrix = templateData['regionMatrix'] as List<List<int>>;
      // 验证模板有效性（9个连续区域ID 0-8）
      final ids = regionMatrix.expand((row) => row).toSet();
      if (ids.length == 9) {
        for (int i = 0; i < 9; i++) {
          if (!ids.contains(i)) {
            throw GameGenerationException('区域模板无效：缺少区域ID $i');
          }
        }
        return regionMatrix;
      }
    }

    // 当 templateData 为 null 时，抛出明确的错误
    throw GameGenerationException('无法加载区域模板：模板数据未传递');
  }

  /// 生成终盘
  Future<JigsawBoard> _generateSolution({
    required List<List<int>> regionMatrix,
    required GameTypeDifficultyConfig config,
    bool Function()? isCancelled,
  }) async {
    for (int attempt = 0; attempt < config.maxDiggingAttempts; attempt++) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }
      try {
        final solver = _getSolver(regionMatrix);
        final solution = solver.generateSolution(regionMatrix, isCancelled);
        if (solution != null) return solution as JigsawBoard;
      } on TimeoutException {
        // 重试
      }
    }
    throw GameGenerationException('无法生成终盘');
  }

  /// 使用统一的 DiggingAlgorithm 进行挖空
  Future<JigsawBoard> _generatePuzzle({
    required JigsawBoard solution,
    required GameTypeDifficultyConfig config,
    bool Function()? isCancelled,
  }) async {
    final diggingConfig = DiggingConfig(
      minFilledCells: config.minFilledCells,
      maxFilledCells: config.maxFilledCells,
      maxAttempts: config.maxDiggingAttempts,
    );
    
    final puzzle = await _diggingAlgorithm.generatePuzzle(
      solution,
      diggingConfig,
      isCancelled,
    );
    
    return puzzle as JigsawBoard;
  }
}
