import 'package:sudoku/models/index.dart';

/// Cage和值验证结果
class CageSumValidationResult {
  const CageSumValidationResult({
    required this.isValid,
    this.errorMessage,
    this.invalidCages,
  });

  factory CageSumValidationResult.invalid(
    String message,
    List<KillerCage> cages,
  ) => CageSumValidationResult(
    isValid: false,
    errorMessage: message,
    invalidCages: cages,
  );

  factory CageSumValidationResult.valid() =>
      const CageSumValidationResult(isValid: true);
  final bool isValid;
  final String? errorMessage;
  final List<KillerCage>? invalidCages;
}

/// Cage和值验证工具
///
/// 验证cage的和值是否合理，确保游戏可解且难度适中
class KillerCageSumValidator {
  /// 最小cage和值（2格cage，最小和为1+2=3）
  static const int minSumPerCell = 1;
  static const int maxSumPerCell = 9;

  /// 验证cage和的合理性
  ///
  /// 检查项：
  /// 1. 每个cage的和是否在合理范围内
  /// 2. 单格cage是否合理（和为1-9）
  /// 3. 超大cage是否合理（如7格以上cage和为45，几乎不可能）
  static CageSumValidationResult validateCageSums(KillerBoard board) =>
      validateCageList(board.cages);

  /// 验证cage列表的和值合理性
  ///
  /// 检查项：
  /// 1. 每个cage的和是否在合理范围内
  /// 2. 单格cage是否合理（和为1-9）
  /// 3. 超大cage是否合理（如7格以上cage和为45，几乎不可能）
  static CageSumValidationResult validateCageList(List<KillerCage> cages) {
    final invalidCages = <KillerCage>[];

    for (final cage in cages) {
      final validation = _validateSingleCage(cage);
      if (!validation.isValid) {
        invalidCages.add(cage);
      }
    }

    if (invalidCages.isNotEmpty) {
      return CageSumValidationResult.invalid(
        '发现 ${invalidCages.length} 个不合理的cage',
        invalidCages,
      );
    }

    return CageSumValidationResult.valid();
  }

  /// 验证单个cage
  static CageSumValidationResult _validateSingleCage(KillerCage cage) {
    final cellCount = cage.cellCount;
    final sum = cage.sum;

    // 1. 检查cage大小
    if (cellCount < 1 || cellCount > 9) {
      return CageSumValidationResult.invalid(
        'Cage ${cage.id} 大小不合理: $cellCount 格',
        [cage],
      );
    }

    // 2. 计算理论最小和最大和
    final minPossibleSum = _calculateMinSum(cellCount);
    final maxPossibleSum = _calculateMaxSum(cellCount);

    // 3. 检查是否在合理范围内
    if (sum < minPossibleSum || sum > maxPossibleSum) {
      return CageSumValidationResult.invalid(
        'Cage ${cage.id} 和值不合理: $sum (应为 $minPossibleSum-$maxPossibleSum)',
        [cage],
      );
    }

    // 4. 检查单格cage
    if (cellCount == 1) {
      if (sum < 1 || sum > 9) {
        return CageSumValidationResult.invalid(
          '单格cage ${cage.id} 和值必须在1-9之间: $sum',
          [cage],
        );
      }
    }

    // 5. 检查超大cage
    if (cellCount >= 7) {
      // 7格以上cage，和应该接近中间值
      final midSum = (minPossibleSum + maxPossibleSum) ~/ 2;
      final tolerance = (maxPossibleSum - minPossibleSum) ~/ 3;

      if (sum < midSum - tolerance || sum > midSum + tolerance) {
        return CageSumValidationResult.invalid(
          '超大cage ${cage.id} 和值偏离中间值: $sum (建议范围: ${midSum - tolerance}-${midSum + tolerance})',
          [cage],
        );
      }
    }

    // 6. 检查难度分布（放宽限制）
    final difficultyScore = calculateDifficultyScore(cellCount, sum);
    if (difficultyScore > 9) {
      return CageSumValidationResult.invalid(
        'Cage ${cage.id} 难度过高: 得分 $difficultyScore/10',
        [cage],
      );
    }

    return CageSumValidationResult.valid();
  }

  /// 计算cage的理论最小和
  ///
  /// 使用最小的n个不同数字：1+2+3+...+n
  static int _calculateMinSum(int cellCount) =>
      cellCount * (cellCount + 1) ~/ 2;

  /// 计算cage的理论最大和
  ///
  /// 使用最大的n个不同数字：9+8+7+...+(9-n+1)
  static int _calculateMaxSum(int cellCount) =>
      cellCount * (19 - cellCount) ~/ 2;

  /// 计算cage难度得分（0-10）
  ///
  /// 考虑因素：
  /// - cage大小
  /// - 和值偏离中间值的程度
  /// - 可能的组合数
  static double calculateDifficultyScore(int cellCount, int sum) {
    final minSum = _calculateMinSum(cellCount);
    final maxSum = _calculateMaxSum(cellCount);
    final midSum = (minSum + maxSum) / 2;

    // 1. 大小难度（小cage更难）
    final sizeScore = (10 - cellCount) * 0.3;

    // 2. 和值偏离难度
    final deviation = (sum - midSum).abs();
    final maxDeviation = (maxSum - minSum) / 2;
    final deviationScore = (deviation / maxDeviation) * 3;

    // 3. 组合数难度（组合数越少越难）
    final combinationCount = _countCombinations(cellCount, sum);
    final combinationScore = combinationCount < 5
        ? 3
        : (combinationCount < 20 ? 1.5 : 0);

    return sizeScore + deviationScore + combinationScore;
  }

  /// 计算满足条件的数字组合数
  ///
  /// 使用回溯算法计算有多少种不同的数字组合可以得到指定和
  static int _countCombinations(
    int cellCount,
    int targetSum, {
    int maxNum = 9,
  }) {
    final cache = <String, int>{};
    return _countCombinationsRecursive(cellCount, targetSum, 1, maxNum, <int>{}, cache);
  }

  static int _countCombinationsRecursive(
    int remainingCells,
    int remainingSum,
    int minNum,
    int maxNum,
    Set<int> used,
    Map<String, int> cache,
  ) {
    // 构建缓存键：使用已使用的数字排序后的字符串作为键的一部分
    final cacheKey = '$remainingCells,$remainingSum,$minNum,$maxNum,${used.join(',')}';
    final cached = cache[cacheKey];
    if (cached != null) return cached;

    if (remainingCells == 0) {
      final result = remainingSum == 0 ? 1 : 0;
      cache[cacheKey] = result;
      return result;
    }

    if (remainingSum <= 0) {
      cache[cacheKey] = 0;
      return 0;
    }

    int count = 0;
    for (int num = minNum; num <= maxNum && num <= remainingSum; num++) {
      if (!used.contains(num)) {
        final newUsed = Set<int>.from(used)..add(num);
        count += _countCombinationsRecursive(
          remainingCells - 1,
          remainingSum - num,
          num + 1,
          maxNum,
          newUsed,
          cache,
        );
      }
    }

    cache[cacheKey] = count;
    return count;
  }

  /// 获取cage难度等级
  static String getDifficultyLevel(KillerCage cage) {
    final score = calculateDifficultyScore(cage.cellCount, cage.sum);

    if (score <= 2) return 'easy';
    if (score <= 4) return 'medium';
    if (score <= 6) return 'hard';
    if (score <= 8) return 'expert';
    return 'master';
  }

  /// 获取cage统计信息
  static Map<String, dynamic> getCageStatistics(KillerBoard board) {
    final cages = board.cages;

    if (cages.isEmpty) {
      return {};
    }

    final cellCounts = cages.map((c) => c.cellCount).toList();
    final sums = cages.map((c) => c.sum).toList();
    final difficultyScores = cages
        .map((c) => calculateDifficultyScore(c.cellCount, c.sum))
        .toList();

    return {
      'totalCages': cages.length,
      'averageCageSize': cellCounts.reduce((a, b) => a + b) / cages.length,
      'minCageSize': cellCounts.reduce((a, b) => a < b ? a : b),
      'maxCageSize': cellCounts.reduce((a, b) => a > b ? a : b),
      'averageSum': sums.reduce((a, b) => a + b) / cages.length,
      'minSum': sums.reduce((a, b) => a < b ? a : b),
      'maxSum': sums.reduce((a, b) => a > b ? a : b),
      'averageDifficulty':
          difficultyScores.reduce((a, b) => a + b) / cages.length,
      'difficultyDistribution': {
        'easy': cages.where((c) => getDifficultyLevel(c) == 'easy').length,
        'medium': cages.where((c) => getDifficultyLevel(c) == 'medium').length,
        'hard': cages.where((c) => getDifficultyLevel(c) == 'hard').length,
        'expert': cages.where((c) => getDifficultyLevel(c) == 'expert').length,
        'master': cages.where((c) => getDifficultyLevel(c) == 'master').length,
      },
    };
  }
}

/// Killer Sudoku 工具类
///
/// 提供cage相关的公共方法，减少代码重复
class KillerUtils {
  /// 获取cage中的所有格子
  static List<Cell> getCageCells(KillerBoard board, KillerCage cage) => cage
      .cellCoordinates
      .map((coord) => board.getCell(coord.$1, coord.$2))
      .toList();

  /// 获取cage中已填充的格子
  static List<Cell> getFilledCells(KillerBoard board, KillerCage cage) =>
      getCageCells(board, cage).where((cell) => cell.value != null).toList();

  /// 获取cage中未填充的格子
  static List<Cell> getEmptyCells(KillerBoard board, KillerCage cage) =>
      getCageCells(board, cage).where((cell) => cell.value == null).toList();

  /// 计算n个格子的最小可能和
  /// 使用最小的n个不同数字：1+2+...+n
  static int minSum(int n) => n * (n + 1) ~/ 2;

  /// 计算n个格子的最大可能和
  /// 使用最大的n个不同数字：9+8+...+(9-n+1)
  static int maxSum(int n) => n * (19 - n) ~/ 2;

  /// 计算n个格子的最大可能和（考虑已使用的数字）
  static int maxPossibleSum(int n, List<int> usedNumbers) {
    final available =
        List.generate(
            9,
            (i) => i + 1,
          ).where((number) => !usedNumbers.contains(number)).toList()
          ..sort((a, b) => b.compareTo(a));

    return available.take(n).fold(0, (s, number) => s + number);
  }

  /// 检查cage的和值约束是否可满足
  static bool isCageSumSatisfiable(KillerBoard board, KillerCage cage) {
    final filledCells = getFilledCells(board, cage);
    final emptyCells = getEmptyCells(board, cage);

    if (filledCells.isEmpty) return true;

    final currentSum = filledCells.fold<int>(0, (s, c) => s + (c.value ?? 0));
    final remainingSum = cage.sum - currentSum;

    final emptyCount = emptyCells.length;
    final minPossible = minSum(emptyCount);

    final usedNumbers = filledCells.map((c) => c.value!).toList();
    final maxPossible = maxPossibleSum(emptyCount, usedNumbers);

    return remainingSum >= minPossible && remainingSum <= maxPossible;
  }

  /// 检查cage内是否有重复数字
  static bool hasDuplicateNumbers(KillerBoard board, KillerCage cage) {
    final filledCells = getFilledCells(board, cage);
    final numbers = filledCells.map((cell) => cell.value).toList();
    final uniqueNumbers = Set<int?>.from(numbers);
    return uniqueNumbers.length != numbers.length;
  }

  /// 获取cage内已使用的数字集合
  static Set<int> getUsedNumbers(KillerBoard board, KillerCage cage) =>
      getFilledCells(board, cage).map((cell) => cell.value!).toSet();

  /// 检查cage是否完成（所有格子都已填充）
  static bool isCageComplete(KillerBoard board, KillerCage cage) =>
      getEmptyCells(board, cage).isEmpty;

  /// 验证cage是否有效
  static bool isCageValid(
    KillerBoard board,
    KillerCage cage, {
    bool checkDuplicate = true,
  }) {
    final currentSum = cage.getCurrentSum(board);

    if (currentSum > cage.sum) return false;

    if (checkDuplicate && hasDuplicateNumbers(board, cage)) return false;

    if (cage.isComplete(board)) {
      return currentSum == cage.sum;
    }

    return true;
  }
}
