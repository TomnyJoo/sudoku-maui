import 'dart:math';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';
import 'package:sudoku/services/solving/strategy_engine.dart';

/// 谜题分析结果类
class PuzzleAnalysisResult {
  PuzzleAnalysisResult({
    required this.isSolvable,
    required this.usedStrategies,
    required this.requiredLevel,
    required this.strategyUsageCount,
    this.failureReason,
  });
  
  final bool isSolvable;
  final List<StrategyType> usedStrategies;
  final StrategyLevel requiredLevel;
  final Map<StrategyType, int> strategyUsageCount;
  final String? failureReason;
}

/// 挖空算法抽象基类
abstract class DiggingAlgorithm {

  DiggingAlgorithm({
    Random? random,
    DLXSudokuSolver? dlxSolver,
  })  : _random = random ?? Random(),
        _dlxSolver = dlxSolver ?? StandardDLXSolver.create();
  final Random _random;
  final DLXSudokuSolver _dlxSolver;

  /// 生成谜题
  Future<Board> generatePuzzle(
    Board solution,
    DiggingConfig config,
    bool Function()? isCancelled,
  );

  /// 快速检查当前棋盘是否违反基本规则
  bool quickCheck(Board board) {
    final size = board.size;
    for (int r = 0; r < size; r++) {
      final seen = <int>{};
      for (int c = 0; c < size; c++) {
        final val = board.getCell(r, c).value;
        if (val != null) {
          if (seen.contains(val)) return false;
          seen.add(val);
        }
      }
    }
    for (int c = 0; c < size; c++) {
      final seen = <int>{};
      for (int r = 0; r < size; r++) {
        final val = board.getCell(r, c).value;
        if (val != null) {
          if (seen.contains(val)) return false;
          seen.add(val);
        }
      }
    }
    for (final region in board.regions) {
      final seen = <int>{};
      for (final cell in region.cells) {
        final val = cell.value;
        if (val != null) {
          if (seen.contains(val)) return false;
          seen.add(val);
        }
      }
    }
    return true;
  }

  /// 验证唯一解（使用 DLX 求解器）
  bool hasUniqueSolution(Board puzzle, bool Function()? isCancelled) {
    final count = _dlxSolver.countSolutions(puzzle, isCancelled: isCancelled);
    return count == 1;
  }

  /// 计算填充的单元格数量
  int countFilledCells(Board board) {
    int cnt = 0;
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        if (board.getCell(r, c).value != null) cnt++;
      }
    }
    return cnt;
  }

  /// 重置固定单元格标记
  Board resetFixedCells(Board board) {
    final newCells = board.cells.map((row) =>
        row.map((cell) => Cell(
          row: cell.row,
          col: cell.col,
          value: cell.value,
        )).toList()).toList();
    return board.createInstance(newCells, regions: board.regions);
  }

  /// 设置固定单元格标记
  Board setFixedCells(Board puzzle) {
    final newCells = puzzle.cells.map((row) =>
        row.map((cell) => Cell(
          row: cell.row,
          col: cell.col,
          value: cell.value,
          isFixed: cell.value != null,
        )).toList()).toList();
    return puzzle.createInstance(newCells, regions: puzzle.regions);
  }

  /// 分析谜题的策略级别
  PuzzleAnalysisResult analyzePuzzle({
    required Board puzzle,
    required Board solution,
    required GameType gameType,
  }) {
    // 创建候选数计算器
    final calculator = CandidateCalculator(puzzle);
    final context = calculator.context;
    
    // 记录使用的策略和次数
    final usedStrategies = <StrategyType>[];
    final strategyUsageCount = <StrategyType, int>{};
    
    // 按策略级别依次尝试求解
    bool solved = false;
    StrategyLevel requiredLevel = StrategyLevel.basic;
    
    // 第一级：基础策略
    final basicStrategies = [
      StrategyType.nakedSingle,
      StrategyType.hiddenSingle,
    ];
    
    for (final type in basicStrategies) {
      final strategy = StrategyRegistry.get(type);
      if (strategy != null && strategy.applicableGames.contains(gameType)) {
        int count = 0;
        while (strategy.apply(context)) {
          count++;
          if (_isSolved(context)) {
            solved = true;
            break;
          }
        }
        if (count > 0) {
          usedStrategies.add(type);
          strategyUsageCount[type] = count;
        }
      }
      if (solved) break;
    }
    
    if (solved) {
      requiredLevel = StrategyLevel.basic;
      return PuzzleAnalysisResult(
        isSolvable: true,
        usedStrategies: usedStrategies,
        requiredLevel: requiredLevel,
        strategyUsageCount: strategyUsageCount,
      );
    }
    
    // 第二级：中级策略
    final intermediateStrategies = [
      StrategyType.nakedPair,
      StrategyType.hiddenPair,
      StrategyType.nakedTriple,
      StrategyType.hiddenTriple,
      StrategyType.lockedCandidate,
    ];
    
    for (final type in intermediateStrategies) {
      final strategy = StrategyRegistry.get(type);
      if (strategy != null && strategy.applicableGames.contains(gameType)) {
        int count = 0;
        while (strategy.apply(context)) {
          count++;
          if (_isSolved(context)) {
            solved = true;
            break;
          }
        }
        if (count > 0) {
          usedStrategies.add(type);
          strategyUsageCount[type] = count;
        }
      }
      if (solved) break;
    }
    
    if (solved) {
      requiredLevel = StrategyLevel.intermediate;
      return PuzzleAnalysisResult(
        isSolvable: true,
        usedStrategies: usedStrategies,
        requiredLevel: requiredLevel,
        strategyUsageCount: strategyUsageCount,
      );
    }
    
    // 第三级：高级策略
    final advancedStrategies = [
      StrategyType.xWing,
      StrategyType.swordfish,
    ];
    
    for (final type in advancedStrategies) {
      final strategy = StrategyRegistry.get(type);
      if (strategy != null && strategy.applicableGames.contains(gameType)) {
        int count = 0;
        while (strategy.apply(context)) {
          count++;
          if (_isSolved(context)) {
            solved = true;
            break;
          }
        }
        if (count > 0) {
          usedStrategies.add(type);
          strategyUsageCount[type] = count;
        }
      }
      if (solved) break;
    }
    
    if (solved) {
      requiredLevel = StrategyLevel.advanced;
      return PuzzleAnalysisResult(
        isSolvable: true,
        usedStrategies: usedStrategies,
        requiredLevel: requiredLevel,
        strategyUsageCount: strategyUsageCount,
      );
    }
    
    // 第四级：专家级策略
    final expertStrategies = [
      StrategyType.xyWing,
      StrategyType.xyzWing,
      StrategyType.uniqueRectangle,
    ];
    
    for (final type in expertStrategies) {
      final strategy = StrategyRegistry.get(type);
      if (strategy != null && strategy.applicableGames.contains(gameType)) {
        int count = 0;
        while (strategy.apply(context)) {
          count++;
          if (_isSolved(context)) {
            solved = true;
            break;
          }
        }
        if (count > 0) {
          usedStrategies.add(type);
          strategyUsageCount[type] = count;
        }
      }
      if (solved) break;
    }
    
    if (solved) {
      requiredLevel = StrategyLevel.expert;
      return PuzzleAnalysisResult(
        isSolvable: true,
        usedStrategies: usedStrategies,
        requiredLevel: requiredLevel,
        strategyUsageCount: strategyUsageCount,
      );
    }
    
    // 第五级：大师级策略
    final masterStrategies = [
      StrategyType.twoStringKite,
      StrategyType.skyscraper,
      StrategyType.emptyRectangle,
      StrategyType.finnedXWing,
      StrategyType.finnedSwordfish,
    ];
    
    for (final type in masterStrategies) {
      final strategy = StrategyRegistry.get(type);
      if (strategy != null && strategy.applicableGames.contains(gameType)) {
        int count = 0;
        while (strategy.apply(context)) {
          count++;
          if (_isSolved(context)) {
            solved = true;
            break;
          }
        }
        if (count > 0) {
          usedStrategies.add(type);
          strategyUsageCount[type] = count;
        }
      }
      if (solved) break;
    }
    
    if (solved) {
      requiredLevel = StrategyLevel.master;
      return PuzzleAnalysisResult(
        isSolvable: true,
        usedStrategies: usedStrategies,
        requiredLevel: requiredLevel,
        strategyUsageCount: strategyUsageCount,
      );
    }
    
    // 如果所有策略都无法求解，返回未求解状态
    return PuzzleAnalysisResult(
      isSolvable: false,
      usedStrategies: usedStrategies,
      requiredLevel: requiredLevel,
      strategyUsageCount: strategyUsageCount,
      failureReason: '无法使用标准策略求解谜题',
    );
  }
  
  /// 检查棋盘是否已解决
  bool _isSolved(BoardContext context) {
    for (int r = 0; r < context.size; r++) {
      for (int c = 0; c < context.size; c++) {
        final cell = context.board.getCell(r, c);
        if (cell.value == null) {
          return false;
        }
      }
    }
    return true;
  }

  /// 验证谜题是否符合目标难度
  bool validatePuzzleDifficulty({
    required Board puzzle,
    required Board solution,
    required GameType gameType,
    required DifficultyConfig config,
  }) {
    // 获取游戏类型配置
    final gameConfig = config.getGameConfig(gameType);
    
    // 1. 检查填充单元格数量是否在范围内
    final filledCount = countFilledCells(puzzle);
    if (filledCount < gameConfig.minFilledCells || filledCount > gameConfig.maxFilledCells) {
      return false;
    }
    
    // 2. 分析谜题的策略级别
    final analysis = analyzePuzzle(
      puzzle: puzzle,
      solution: solution,
      gameType: gameType,
    );
    
    // 3. 检查是否可解
    if (!analysis.isSolvable) {
      return false;
    }
    
    // 4. 检查所需策略级别是否在范围内
    final requiredLevel = analysis.requiredLevel;
    if (requiredLevel.index < gameConfig.minStrategyLevel.index ||
        requiredLevel.index > gameConfig.maxStrategyLevel.index) {
      return false;
    }
    
    // 5. 检查是否使用了必需的策略
    for (final requiredStrategy in gameConfig.requiredStrategies) {
      if (!analysis.usedStrategies.contains(requiredStrategy)) {
        // 如果没有使用必需策略，检查是否可以通过其他方式达到难度
        // 如果使用了更高级别的策略，也可以接受
        bool hasHigherLevelStrategy = false;
        for (final usedStrategy in analysis.usedStrategies) {
          final strategyInfo = strategyMetadata[usedStrategy];
          if (strategyInfo != null &&
              strategyInfo.level.index >= gameConfig.maxStrategyLevel.index) {
            hasHigherLevelStrategy = true;
            break;
          }
        }
        if (!hasHigherLevelStrategy) {
          return false;
        }
      }
    }
    
    // 6. 检查唯一解
    if (!hasUniqueSolution(puzzle, null)) {
      return false;
    }
    
    return true;
  }

  /// 调整谜题难度
  Board adjustPuzzleDifficulty({
    required Board puzzle,
    required Board solution,
    required int targetFilled,
    required int minFilled,
    required int maxFilled,
    bool Function()? isCancelled,
  }) {
    var adjusted = puzzle;
    int filled = countFilledCells(adjusted);
    const int maxTotalAttempts = AppConstants.maxDifficultyAdjustAttempts;
    int totalAttempts = 0;

    while (filled > maxFilled && totalAttempts < maxTotalAttempts) {
      if (isCancelled?.call() ?? false) break;
      final cells = findRemovable(adjusted);
      if (cells.isEmpty) break;
      
      // 打乱顺序，尝试多个单元格
      cells.shuffle(_random);
      bool success = false;
      
      for (final (r, c) in cells) {
        totalAttempts++;
        if (totalAttempts >= maxTotalAttempts) break;
        
        final test = adjusted.setCellValue(r, c, null);
        if (quickCheck(test) && hasUniqueSolution(test, isCancelled)) {
          adjusted = test;
          filled--;
          success = true;
          break;
        }
      }
      
      if (!success) break;
    }

    while (filled < minFilled) {
      if (isCancelled?.call() ?? false) break;
      final cells = findFillable(adjusted, solution);
      if (cells.isEmpty) break;
      final (r, c) = cells[_random.nextInt(cells.length)];
      final val = solution.getCell(r, c).value!;
      final test = adjusted.setCellValue(r, c, val);
      if (quickCheck(test) && hasUniqueSolution(test, isCancelled)) {
        adjusted = test;
        filled++;
      } else {
        break;
      }
    }

    return adjusted;
  }

  /// 查找可移除的单元格
  List<(int, int)> findRemovable(Board puzzle) {
    final list = <(int, int)>[];
    for (int r = 0; r < puzzle.size; r++) {
      for (int c = 0; c < puzzle.size; c++) {
        if (puzzle.getCell(r, c).value != null) list.add((r, c));
      }
    }
    return list;
  }

  /// 查找可填充的单元格
  List<(int, int)> findFillable(Board puzzle, Board solution) {
    final list = <(int, int)>[];
    for (int r = 0; r < puzzle.size; r++) {
      for (int c = 0; c < puzzle.size; c++) {
        if (puzzle.getCell(r, c).value == null) list.add((r, c));
      }
    }
    return list;
  }

  /// 计算单元格的候选数（用于智能挖空）
  /// 使用 board.regions 统一排除所有区域约束（行、列、宫格及特殊区域）
  int calculateCandidateCount(Board puzzle, int r, int c, int size) {
    if (puzzle.getCell(r, c).value != null) return 0;
    
    final candidates = <int>{};
    for (int d = 1; d <= size; d++) {
      candidates.add(d);
    }
    
    // 使用 board.regions 排除（已包含行、列、宫格及特殊区域）
    for (final region in puzzle.regions) {
      if (region.cells.any((cell) => cell.row == r && cell.col == c)) {
        for (final cell in region.cells) {
          final val = cell.value;
          if (val != null) candidates.remove(val);
        }
      }
    }
    
    return candidates.length;
  }

  /// 计算单元格的区域均衡分数
  /// 分别计算行/列区域和约束区域（宫格/对角线/窗口）的均衡因子，
  /// 使用加权乘积，避免单个低填充率区域过度抑制
  double calculateRegionBalanceScore(Board puzzle, int r, int c) {
    double lineBalance = 1.0; // 行/列均衡因子
    double blockBalance = 1.0; // 约束区域均衡因子

    for (final region in puzzle.regions) {
      if (region.cells.any((cell) => cell.row == r && cell.col == c)) {
        final filled = region.cells.where((cell) => cell.value != null).length;
        final ratio = filled / region.cells.length;
        if (region.type == RegionType.row || region.type == RegionType.column) {
          if (ratio < lineBalance) lineBalance = ratio;
        } else {
          if (ratio < blockBalance) blockBalance = ratio;
        }
      }
    }

    // 使用加权乘积：约束区域权重更高（0.6），行/列权重较低（0.4）
    // 这样即使某行填充率很低，只要约束区域填充率正常，仍有机会被挖空
    return (pow(lineBalance, 0.4) * pow(blockBalance, 0.6)).toDouble();
  }
}

/// 智能对称挖空算法
/// 
/// 实现中心对称的智能挖空策略，优先挖空候选数较多的单元格
class SmartSymmetricDiggingAlgorithm extends DiggingAlgorithm {
  SmartSymmetricDiggingAlgorithm({
    super.random,
    super.dlxSolver,
  });

  @override
  Future<Board> generatePuzzle(
    Board solution,
    DiggingConfig config,
    bool Function()? isCancelled,
  ) async {
    final size = solution.size;
    final int targetFilled = config.maxFilledCells;
    var puzzle = resetFixedCells(solution);
    int filled = size * size;

    // 生成所有对称位置对
    final pairs = generateSymmetricPairs(size);

    // 第一阶段：随机挖空到中等难度
    puzzle = await _randomDigPhase(
      puzzle: puzzle,
      solution: solution,
      pairs: pairs,
      targetFilled: (size * size + config.maxFilledCells) ~/ 2,
      isCancelled: isCancelled,
    );
    filled = countFilledCells(puzzle);

    // 第二阶段：智能挖空到目标难度
    puzzle = await _smartDigPhase(
      puzzle: puzzle,
      solution: solution,
      pairs: pairs.where((p) => 
        p.any((pos) => puzzle.getCell(pos.$1, pos.$2).value != null)
      ).toList(),
      targetFilled: targetFilled,
      config: config,
      isCancelled: isCancelled,
    );
    filled = countFilledCells(puzzle);

    // 微调
    if (filled < config.minFilledCells || filled > config.maxFilledCells) {
      puzzle = adjustPuzzleDifficulty(
        puzzle: puzzle,
        solution: solution,
        targetFilled: targetFilled,
        minFilled: config.minFilledCells,
        maxFilled: config.maxFilledCells,
        isCancelled: isCancelled,
      );
    }

    return setFixedCells(puzzle);
  }

  /// 随机挖空阶段
  Future<Board> _randomDigPhase({
    required Board puzzle,
    required Board solution,
    required List<List<(int, int)>> pairs,
    required int targetFilled,
    bool Function()? isCancelled,
  }) async {
    var result = puzzle;
    int filled = countFilledCells(result);
    
    pairs.shuffle(_random);
    
    for (final pair in pairs) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }
      if (filled <= targetFilled) break;
      
      // 检查这对是否还可以挖空
      if (!pair.any((pos) => result.getCell(pos.$1, pos.$2).value != null)) continue;
      
      var testPuzzle = result;
      for (final (r, c) in pair) {
        if (result.getCell(r, c).value != null) {
          testPuzzle = testPuzzle.setCellValue(r, c, null);
        }
      }
      
      if (quickCheck(testPuzzle) && hasUniqueSolution(testPuzzle, isCancelled)) {
        result = testPuzzle;
        filled = countFilledCells(result);
      }
    }
    
    return result;
  }

  /// 智能挖空阶段
  Future<Board> _smartDigPhase({
    required Board puzzle,
    required Board solution,
    required List<List<(int, int)>> pairs,
    required int targetFilled,
    required DiggingConfig config,
    bool Function()? isCancelled,
  }) async {
    var result = puzzle;
    int filled = countFilledCells(result);
    int consecutiveFailures = 0;
    final maxConsecutiveFailures = config.maxAttempts * 3;

    while (filled > targetFilled && consecutiveFailures < maxConsecutiveFailures) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }

      // 计算每个可挖空对的优先级（候选数越多优先级越高）
      final scoredPairs = <(List<(int, int)>, int)>[];
      for (final pair in pairs) {
        if (!pair.any((pos) => result.getCell(pos.$1, pos.$2).value != null)) continue;
        
        int score = 0;
        for (final (r, c) in pair) {
          if (result.getCell(r, c).value != null) {
            // 挖空后计算候选数
            final temp = result.setCellValue(r, c, null);
            final candidateCount = calculateCandidateCount(temp, r, c, result.size);
            // 乘以区域均衡因子
            final balanceFactor = calculateRegionBalanceScore(result, r, c);
            score += (candidateCount * balanceFactor).round();
          }
        }
        scoredPairs.add((pair, score));
      }

      if (scoredPairs.isEmpty) break;

      // 按分数排序，优先挖空候选数多的
      scoredPairs.sort((a, b) => b.$2.compareTo(a.$2));

      bool success = false;
      // 尝试前 50% 的高优先级对
      final topCount = (scoredPairs.length * AppConstants.smartDigTopScoreRatio).ceil().clamp(1, scoredPairs.length);
      
      for (int i = 0; i < topCount && !success; i++) {
        final pair = scoredPairs[i].$1;
        
        var testPuzzle = result;
        for (final (r, c) in pair) {
          if (result.getCell(r, c).value != null) {
            testPuzzle = testPuzzle.setCellValue(r, c, null);
          }
        }
        
        if (quickCheck(testPuzzle) && hasUniqueSolution(testPuzzle, isCancelled)) {
          result = testPuzzle;
          filled = countFilledCells(result);
          success = true;
          consecutiveFailures = 0;
        }
      }

      // 如果高优先级对都失败，尝试随机选择
      if (!success && scoredPairs.length > topCount) {
        final remainingPairs = scoredPairs.sublist(topCount)
        ..shuffle(_random);
        
        for (int i = 0; i < remainingPairs.length && i < AppConstants.smartDigRandomFallbackCount && !success; i++) {
          final pair = remainingPairs[i].$1;
          
          var testPuzzle = result;
          for (final (r, c) in pair) {
            if (result.getCell(r, c).value != null) {
              testPuzzle = testPuzzle.setCellValue(r, c, null);
            }
          }
          
          if (quickCheck(testPuzzle) && hasUniqueSolution(testPuzzle, isCancelled)) {
            result = testPuzzle;
            filled = countFilledCells(result);
            success = true;
            consecutiveFailures = 0;
          }
        }
      }

      if (!success) {
        consecutiveFailures++;
      }
    }

    return result;
  }

  /// 生成对称位置对（中心对称）
  List<List<(int, int)>> generateSymmetricPairs(int size) {
    final pairs = <List<(int, int)>>[];
    final processed = <String>{};

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        final key = '$i,$j';
        if (processed.contains(key)) continue;

        final si = size - 1 - i;
        final sj = size - 1 - j;
        final symKey = '$si,$sj';

        if (i == si && j == sj) {
          pairs.add([(i, j)]);
        } else {
          pairs.add([(i, j), (si, sj)]);
          processed.add(symKey);
        }
        processed.add(key);
      }
    }
    return pairs;
  }
}

/// 智能随机挖空算法
/// 
/// 实现完全随机的智能挖空策略
class SmartRandomDiggingAlgorithm extends DiggingAlgorithm {
  SmartRandomDiggingAlgorithm({
    super.random,
    super.dlxSolver,
  });

  @override
  Future<Board> generatePuzzle(
    Board solution,
    DiggingConfig config,
    bool Function()? isCancelled,
  ) async {
    final size = solution.size;
    final targetFilled = config.maxFilledCells;
    var puzzle = resetFixedCells(solution);
    int filled = size * size;

    // 生成所有单元格位置
    final cells = <(int, int)>[];
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        cells.add((i, j));
      }
    }

    // 第一阶段：随机挖空
    puzzle = await _randomDigPhase(
      puzzle: puzzle,
      cells: cells,
      targetFilled: (size * size + config.maxFilledCells) ~/ 2,
      isCancelled: isCancelled,
    );
    filled = countFilledCells(puzzle);

    // 第二阶段：智能挖空
    puzzle = await _smartDigPhase(
      puzzle: puzzle,
      cells: cells.where((pos) => puzzle.getCell(pos.$1, pos.$2).value != null).toList(),
      targetFilled: targetFilled,
      config: config,
      isCancelled: isCancelled,
    );
    filled = countFilledCells(puzzle);

    // 微调
    if (filled < config.minFilledCells || filled > config.maxFilledCells) {
      puzzle = adjustPuzzleDifficulty(
        puzzle: puzzle,
        solution: solution,
        targetFilled: targetFilled,
        minFilled: config.minFilledCells,
        maxFilled: config.maxFilledCells,
        isCancelled: isCancelled,
      );
    }

    return setFixedCells(puzzle);
  }

  Future<Board> _randomDigPhase({
    required Board puzzle,
    required List<(int, int)> cells,
    required int targetFilled,
    bool Function()? isCancelled,
  }) async {
    var result = puzzle;
    int filled = countFilledCells(result);
    
    cells.shuffle(_random);
    
    for (final (r, c) in cells) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }
      if (filled <= targetFilled) break;
      
      final testPuzzle = result.setCellValue(r, c, null);
      
      if (quickCheck(testPuzzle) && hasUniqueSolution(testPuzzle, isCancelled)) {
        result = testPuzzle;
        filled--;
      }
    }
    
    return result;
  }

  Future<Board> _smartDigPhase({
    required Board puzzle,
    required List<(int, int)> cells,
    required int targetFilled,
    required DiggingConfig config,
    bool Function()? isCancelled,
  }) async {
    var result = puzzle;
    int filled = countFilledCells(result);
    int consecutiveFailures = 0;
    final maxConsecutiveFailures = config.maxAttempts * 3;

    while (filled > targetFilled && consecutiveFailures < maxConsecutiveFailures) {
      if (isCancelled?.call() ?? false) {
        throw GameGenerationCancelledException();
      }

      // 计算每个可挖空单元格的优先级
      final scoredCells = <((int, int), int)>[];
      for (final (r, c) in cells) {
        if (result.getCell(r, c).value == null) continue;
        
        final temp = result.setCellValue(r, c, null);
        final candidateCount = calculateCandidateCount(temp, r, c, result.size);
        final balanceFactor = calculateRegionBalanceScore(result, r, c);
        final score = (candidateCount * balanceFactor).round();
        scoredCells.add(((r, c), score));
      }

      if (scoredCells.isEmpty) break;

      scoredCells.sort((a, b) => b.$2.compareTo(a.$2));

      bool success = false;
      final topCount = (scoredCells.length * AppConstants.smartDigTopScoreRatio).ceil().clamp(1, scoredCells.length);
      
      for (int i = 0; i < topCount && !success; i++) {
        final (r, c) = scoredCells[i].$1;
        final testPuzzle = result.setCellValue(r, c, null);
        
        if (quickCheck(testPuzzle) && hasUniqueSolution(testPuzzle, isCancelled)) {
          result = testPuzzle;
          filled--;
          success = true;
          consecutiveFailures = 0;
        }
      }

      // 如果高优先级单元格都失败，尝试随机选择
      if (!success && scoredCells.length > topCount) {
        final remainingCells = scoredCells.sublist(topCount)
        ..shuffle(_random);
        
        for (int i = 0; i < remainingCells.length && i < AppConstants.smartDigRandomFallbackCount && !success; i++) {
          final (r, c) = remainingCells[i].$1;
          final testPuzzle = result.setCellValue(r, c, null);
          
          if (quickCheck(testPuzzle) && hasUniqueSolution(testPuzzle, isCancelled)) {
            result = testPuzzle;
            filled--;
            success = true;
            consecutiveFailures = 0;
          }
        }
      }

      if (!success) {
        consecutiveFailures++;
      }
    }

    return result;
  }
}

/// 向后兼容的别名
typedef SymmetricDiggingAlgorithm = SmartSymmetricDiggingAlgorithm;
typedef RandomDiggingAlgorithm = SmartRandomDiggingAlgorithm;
