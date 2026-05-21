import 'package:sudoku/services/game_config.dart';
import 'package:sudoku/services/session_statistics.dart';
import 'package:sudoku/services/statistics/analysis_service.dart';
import 'package:sudoku/services/statistics/statistics.dart';
import 'package:sudoku/services/statistics/storage_service.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 统计管理器，作为统计功能的统一入口
class StatisticsManager {
  /// 添加游戏记录
  static Future<void> addGameRecord({
    required final String gameType,
    required final String difficulty,
    required final bool isCompleted,
    required final int time,
    required final int mistakes,
    final double completionPercentage = 0.0,
    final Map<int, int> errorDetails = const {},
  }) async {
    try {
      final storageKey = StatisticsStorageService.getStorageKey(gameType);
      final statistics = await StatisticsStorageService.loadStatistics(gameType, storageKey) ?? Statistics.empty(gameType);
      
      final record = GameRecord.create(
        gameType: gameType,
        difficulty: difficulty,
        isCompleted: isCompleted,
        time: time,
        mistakes: mistakes,
        completionPercentage: completionPercentage,
        errorDetails: errorDetails,
      );

      final newTotalGames = statistics.totalGames + 1;
      final newCompletedGames = statistics.completedGames + (isCompleted ? 1 : 0);
      final newCompletionRate = Statistics.calculateCompletionRate(
        newTotalGames,
        newCompletedGames,
      );

      final totalTime = statistics.averageTime * statistics.completedGames + (isCompleted ? time : 0);
      final newAverageTime = newCompletedGames > 0
          ? (totalTime / newCompletedGames).round()
          : 0;

      final newBestTime = statistics.bestTime == 0
          ? (isCompleted ? time : statistics.bestTime)
          : (isCompleted && time < statistics.bestTime ? time : statistics.bestTime);

      final totalMistakes = statistics.averageMistakes * statistics.completedGames + (isCompleted ? mistakes : 0);
      final newAverageMistakes = newCompletedGames > 0
          ? totalMistakes / newCompletedGames
          : 0.0;

      final difficultyStats = statistics.difficultyStats[difficulty] ?? DifficultyStats.empty(difficulty);
      final newDifficultyTotalGames = difficultyStats.totalGames + 1;
      final newDifficultyCompletedGames = difficultyStats.completedGames + (isCompleted ? 1 : 0);
      final newDifficultyCompletionRate = Statistics.calculateCompletionRate(
        newDifficultyTotalGames,
        newDifficultyCompletedGames,
      );

      final difficultyTotalTime = difficultyStats.averageTime * difficultyStats.completedGames + (isCompleted ? time : 0);
      final newDifficultyAverageTime = newDifficultyCompletedGames > 0
          ? (difficultyTotalTime / newDifficultyCompletedGames).round()
          : 0;

      final bool isNewBest = isCompleted &&
          (difficultyStats.bestTime == 0 || time < difficultyStats.bestTime);
      final newDifficultyBestTime = isNewBest ? time : difficultyStats.bestTime;

      final difficultyTotalMistakes = difficultyStats.averageMistakes * difficultyStats.completedGames + (isCompleted ? mistakes : 0);
      final newDifficultyAverageMistakes = newDifficultyCompletedGames > 0
          ? difficultyTotalMistakes / newDifficultyCompletedGames
          : 0.0;

      final updatedDifficultyStats = DifficultyStats(
        difficulty: difficulty,
        totalGames: newDifficultyTotalGames,
        completedGames: newDifficultyCompletedGames,
        completionRate: newDifficultyCompletionRate,
        averageTime: newDifficultyAverageTime,
        bestTime: newDifficultyBestTime,
        averageMistakes: newDifficultyAverageMistakes,
        bestScoreRecord: isNewBest
            ? BestScoreRecord(time: time, mistakes: mistakes, timestamp: DateTime.now())
            : difficultyStats.bestScoreRecord,
      );

      final newRecentGames = [record, ...statistics.recentGames].take(20).toList();

      // 计算连续完成天数
      final completedGames = newRecentGames.where((game) => game.isCompleted).toList();
      final (consecutiveDays, longestStreak) = StatisticsAnalysisService.calculateStreaks(completedGames);
      
      // 计算游戏时长分布
      final timeDistribution = StatisticsAnalysisService.calculateTimeDistribution(completedGames);
      
      // 分析错误模式
      final errorPatterns = StatisticsAnalysisService.analyzeErrorPatterns(newRecentGames);
      
      // 计算推荐难度
      final recommendedDifficulty = StatisticsAnalysisService.calculateRecommendedDifficulty(newRecentGames, difficulty);

      final newStatistics = Statistics(
        gameType: gameType,
        totalGames: newTotalGames,
        completedGames: newCompletedGames,
        completionRate: newCompletionRate,
        averageTime: newAverageTime,
        bestTime: newBestTime,
        averageMistakes: newAverageMistakes,
        difficultyStats: {
          ...statistics.difficultyStats,
          difficulty: updatedDifficultyStats,
        },
        recentGames: newRecentGames,
        consecutiveDays: consecutiveDays,
        longestStreak: longestStreak,
        timeDistribution: timeDistribution,
        errorPatterns: errorPatterns,
        recommendedDifficulty: recommendedDifficulty,
      );

      await StatisticsStorageService.saveStatistics(newStatistics, storageKey);
    } catch (e) {
      AppLogger.error('添加游戏记录失败', e);
      // 记录错误但不中断流程
    }
  }

  /// 从 SessionStatistics 创建并添加游戏记录
  static Future<void> addGameRecordFromGameStats({
    required final String gameType,
    required final String difficulty,
    required final SessionStatistics gameStats,
  }) async {
    await addGameRecord(
      gameType: gameType,
      difficulty: difficulty,
      isCompleted: gameStats.isCompleted,
      time: gameStats.elapsedTime,
      mistakes: gameStats.mistakes,
      completionPercentage: gameStats.completionPercentage * 100,
    );
  }

  /// 记录未完成游戏
  static Future<void> recordIncompleteGame({
    required final String gameType,
    required final String difficulty,
    required final int time,
    required final int mistakes,
    required final double completionPercentage,
  }) async {
    await addGameRecord(
      gameType: gameType,
      difficulty: difficulty,
      isCompleted: false,
      time: time,
      mistakes: mistakes,
      completionPercentage: completionPercentage,
    );
  }

  /// 获取游戏统计
  static Future<Statistics> getGameStatistics(final String gameType) async {
    final storageKey = StatisticsStorageService.getStorageKey(gameType);
    final statistics = await StatisticsStorageService.loadStatistics(gameType, storageKey);
    return statistics ?? Statistics.empty(gameType);
  }

  /// 获取所有游戏统计
  static Future<Map<String, Statistics>> getAllGameStatistics() =>
      StatisticsStorageService.getAllStatistics();

  /// 获取合并的游戏统计
  static Future<Statistics> getCombinedGameStatistics() async {
    final allStats = await StatisticsStorageService.getAllStatistics();
    final gameConfig = GameConfig();
    await gameConfig.initialize();
    
    // 从配置中获取所有游戏类型
    final gameConfigs = gameConfig.getAllGameConfigs();
    final gameTypes = gameConfigs?.keys.toList() ?? [];
    
    // 收集所有游戏统计
    final allGameStats = <Statistics>[];
    final combinedRecentGames = <GameRecord>[];
    int totalGames = 0;
    int totalCompletedGames = 0;
    int totalTime = 0;
    double totalMistakes = 0.0;
    
    for (final gameType in gameTypes) {
      final stats = allStats[gameType] ?? Statistics.empty(gameType);
      allGameStats.add(stats);
      combinedRecentGames.addAll(stats.recentGames);
      totalGames += stats.totalGames;
      totalCompletedGames += stats.completedGames;
      totalTime += stats.averageTime * stats.completedGames;
      totalMistakes += stats.averageMistakes * stats.completedGames;
    }
    
    // 排序并限制最近游戏记录
    combinedRecentGames.sort((final a, final b) => b.timestamp.compareTo(a.timestamp));
    final limitedRecentGames = combinedRecentGames.take(20).toList();

    final combinedDifficultyStats = <String, DifficultyStats>{};
    
    // 合并难度统计
    for (final stats in allGameStats) {
      stats.difficultyStats.forEach((final key, final value) {
        final existing = combinedDifficultyStats[key];
        if (existing != null) {
          combinedDifficultyStats[key] = DifficultyStats(
            difficulty: key,
            totalGames: existing.totalGames + value.totalGames,
            completedGames: existing.completedGames + value.completedGames,
            completionRate: Statistics.calculateCompletionRate(
              existing.totalGames + value.totalGames,
              existing.completedGames + value.completedGames,
            ),
            averageTime: 
                (existing.averageTime * existing.completedGames +
                    value.averageTime * value.completedGames) ~/
                (existing.completedGames + value.completedGames),
            bestTime: existing.bestTime == 0
                ? value.bestTime
                : value.bestTime == 0
                ? existing.bestTime
                : existing.bestTime < value.bestTime
                ? existing.bestTime
                : value.bestTime,
            averageMistakes: 
                (existing.averageMistakes * existing.completedGames +
                    value.averageMistakes * value.completedGames) /
                (existing.completedGames + value.completedGames),
          );
        } else {
          combinedDifficultyStats[key] = value;
        }
      });
    }

    final averageTime = totalCompletedGames > 0 ? totalTime ~/ totalCompletedGames : 0;
    final averageMistakes = totalCompletedGames > 0 ? totalMistakes / totalCompletedGames : 0.0;

    return Statistics(
      gameType: 'combined',
      totalGames: totalGames,
      completedGames: totalCompletedGames,
      completionRate: Statistics.calculateCompletionRate(totalGames, totalCompletedGames),
      averageTime: averageTime,
      bestTime: StatisticsAnalysisService.calculateBestTime(allGameStats),
      averageMistakes: averageMistakes,
      difficultyStats: combinedDifficultyStats,
      recentGames: limitedRecentGames,
    );
  }

  /// 清除游戏统计
  static Future<void> clearGameStatistics(final String gameType) {
    final storageKey = StatisticsStorageService.getStorageKey(gameType);
    return StatisticsStorageService.clearStatistics(storageKey);
  }

  /// 清除所有游戏统计
  static Future<void> clearAllGameStatistics() =>
      StatisticsStorageService.clearAllStatistics();

  /// 导出所有游戏统计
  static Future<String> exportAllGameStatistics() =>
      StatisticsStorageService.exportAllStatistics();

  /// 导入所有游戏统计
  static Future<void> importAllGameStatistics(final String json) =>
      StatisticsStorageService.importAllStatistics(json);

  /// 获取最近的游戏记录
  static Future<List<GameRecord>> getRecentGameRecords({final int limit = 20}) async {
    final allStats = await StatisticsStorageService.getAllStatistics();
    final gameConfig = GameConfig();
    await gameConfig.initialize();
    
    // 从配置中获取所有游戏类型
    final gameConfigs = gameConfig.getAllGameConfigs();
    final gameTypes = gameConfigs?.keys.toList() ?? [];
    
    // 收集所有游戏记录
    final allRecords = <GameRecord>[];
    for (final gameType in gameTypes) {
      final stats = allStats[gameType] ?? Statistics.empty(gameType);
      allRecords.addAll(stats.recentGames);
    }
    
    // 排序并限制数量
    allRecords.sort((final a, final b) => b.timestamp.compareTo(a.timestamp));
    return allRecords.take(limit).toList();
  }

  /// 分析游戏趋势
  static Future<Map<String, dynamic>> analyzeGameTrends() async {
    final recentGames = await getRecentGameRecords(limit: 30);
    return StatisticsAnalysisService.analyzeGameTrends(recentGames);
  }

  /// 识别玩家强项和弱项
  static Future<Map<String, dynamic>> identifyStrengthsAndWeaknesses() async {
    final recentGames = await getRecentGameRecords(limit: 50);
    return StatisticsAnalysisService.identifyStrengthsAndWeaknesses(recentGames);
  }

  /// 分析玩家技能曲线
  static Future<Map<String, dynamic>> analyzeSkillCurve() async {
    final recentGames = await getRecentGameRecords(limit: 50);
    return StatisticsAnalysisService.analyzeSkillCurve(recentGames);
  }

  /// 分析玩家数字强项和弱项
  static Future<Map<String, List<int>>> analyzeNumberStrengthsAndWeaknesses() async {
    final recentGames = await getRecentGameRecords(limit: 50);
    return StatisticsAnalysisService.analyzeNumberStrengthsAndWeaknesses(recentGames);
  }

  /// 批量添加游戏记录
  static Future<void> addGameRecordsBatch(
    final List<Map<String, dynamic>> records,
  ) async {
    for (final record in records) {
      await addGameRecord(
        gameType: record['gameType'] as String,
        difficulty: record['difficulty'] as String,
        isCompleted: record['isCompleted'] as bool,
        time: record['time'] as int,
        mistakes: record['mistakes'] as int,
      );
    }
  }

  /// 批量保存统计数据
  static Future<void> saveStatisticsBatch(
    final Map<String, Statistics> statisticsMap,
  ) async {
    await StatisticsStorageService.saveStatisticsBatch(statisticsMap);
  }
}
