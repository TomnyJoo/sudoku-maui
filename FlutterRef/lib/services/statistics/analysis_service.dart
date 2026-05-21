import 'dart:math';
import 'package:sudoku/services/statistics/statistics.dart';

/// 统计分析服务，负责计算各种统计指标
class StatisticsAnalysisService {
  /// 计算连续完成天数和最长连续天数
  static (int, int) calculateStreaks(final List<GameRecord> completedGames) {
    if (completedGames.isEmpty) {
      return (0, 0);
    }

    // 提取所有完成日期并去重
    final completedDates = <DateTime>{};
    for (final record in completedGames) {
      if (record.completedDate != null) {
        completedDates.add(DateTime(
          record.completedDate!.year,
          record.completedDate!.month,
          record.completedDate!.day,
        ));
      }
    }

    if (completedDates.isEmpty) {
      return (0, 0);
    }

    // 转换为列表并排序
    final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));

    int consecutiveDays = 0;
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;

    for (final date in sortedDates) {
      if (previousDate == null) {
        // 第一个日期
        currentStreak = 1;
        consecutiveDays = 1;
      } else {
        final difference = previousDate.difference(date).inDays;
        if (difference == 1) {
          // 连续的一天
          currentStreak++;
        } else if (difference > 1) {
          // 连续中断
          currentStreak = 1;
        }
      }

      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      previousDate = date;
    }

    // 检查最近的连续天数是否延续到今天
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final mostRecentDate = sortedDates.first;
    final daysSinceLastCompletion = todayOnly.difference(mostRecentDate).inDays;

    if (daysSinceLastCompletion > 1) {
      // 如果最后一次完成不是今天或昨天，连续天数为0
      consecutiveDays = 0;
    }

    return (consecutiveDays, longestStreak);
  }

  /// 计算游戏时长分布
  static Map<String, int> calculateTimeDistribution(final List<GameRecord> completedGames) {
    final distribution = <String, int>{
      '0-5': 0,
      '5-10': 0,
      '10-15': 0,
      '15-20': 0,
      '20-30': 0,
      '30+': 0,
    };

    for (final game in completedGames) {
      if (game.isCompleted) {
        final minutes = game.time ~/ 60;
        if (minutes < 5) {
          distribution['0-5'] = (distribution['0-5'] ?? 0) + 1;
        } else if (minutes < 10) {
          distribution['5-10'] = (distribution['5-10'] ?? 0) + 1;
        } else if (minutes < 15) {
          distribution['10-15'] = (distribution['10-15'] ?? 0) + 1;
        } else if (minutes < 20) {
          distribution['15-20'] = (distribution['15-20'] ?? 0) + 1;
        } else if (minutes < 30) {
          distribution['20-30'] = (distribution['20-30'] ?? 0) + 1;
        } else {
          distribution['30+'] = (distribution['30+'] ?? 0) + 1;
        }
      }
    }

    return distribution;
  }

  /// 分析错误模式
  static Map<int, int> analyzeErrorPatterns(final List<GameRecord> games) {
    final errorPatterns = <int, int>{};

    for (final game in games) {
      if (game.errorDetails.isNotEmpty) {
        game.errorDetails.forEach((number, count) {
          errorPatterns[number] = (errorPatterns[number] ?? 0) + count;
        });
      }
    }

    return errorPatterns;
  }

  /// 计算推荐难度
  static String calculateRecommendedDifficulty(final List<GameRecord> recentGames, final String currentDifficulty) {
    // 至少需要3个已完成的游戏来计算推荐难度
    final completedGames = recentGames.where((game) => game.isCompleted).toList();
    if (completedGames.length < 3) {
      return currentDifficulty;
    }

    // 取最近3个已完成的游戏
    final recentCompletedGames = completedGames.take(3).toList();
    
    // 计算平均完成率和平均错误数
    final completionPercentages = recentCompletedGames.map((game) => game.completionPercentage).toList();
    final averageCompletionRate = completionPercentages.isNotEmpty 
        ? completionPercentages.reduce((a, b) => a + b) / completionPercentages.length 
        : 0.0;
    
    final mistakeCounts = recentCompletedGames.map((game) => game.mistakes).toList();
    final averageMistakes = mistakeCounts.isNotEmpty 
        ? mistakeCounts.reduce((a, b) => a + b) / mistakeCounts.length 
        : 0.0;
    
    // 难度级别顺序
    const difficultyLevels = ['easy', 'medium', 'hard', 'expert'];
    final currentIndex = difficultyLevels.indexOf(currentDifficulty);
    if (currentIndex == -1) return currentDifficulty;

    // 根据表现调整难度
    if (averageCompletionRate >= 95 && averageMistakes <= 2) {
      // 表现良好，尝试提高难度
      return currentIndex < difficultyLevels.length - 1 ? difficultyLevels[currentIndex + 1] : currentDifficulty;
    } else if (averageCompletionRate < 70 || averageMistakes > 5) {
      // 表现不佳，降低难度
      return currentIndex > 0 ? difficultyLevels[currentIndex - 1] : currentDifficulty;
    } else {
      // 表现稳定，保持当前难度
      return currentDifficulty;
    }
  }

  /// 计算最佳时间
  static int calculateBestTime(final List<Statistics> statsList) {
    int bestTime = 0;
    for (final stats in statsList) {
      if (stats.bestTime > 0) {
        if (bestTime == 0 || stats.bestTime < bestTime) {
          bestTime = stats.bestTime;
        }
      }
    }
    return bestTime;
  }

  /// 分析游戏趋势
  static Map<String, dynamic> analyzeGameTrends(final List<GameRecord> recentGames) {
    if (recentGames.isEmpty) {
      return {
        'averageTimeTrend': 0.0,
        'averageMistakesTrend': 0.0,
        'completionRateTrend': 0.0,
      };
    }

    // 按时间排序
    final sortedGames = [...recentGames]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // 计算时间趋势
    final timeValues = sortedGames.map((game) => game.time).toList();
    final timeTrend = _calculateTrend(timeValues);
    
    // 计算错误趋势
    final mistakesValues = sortedGames.map((game) => game.mistakes).toList();
    final mistakesTrend = _calculateTrend(mistakesValues);
    
    // 计算完成率趋势
    final completionValues = sortedGames.map((game) => game.completionPercentage).toList();
    final completionTrend = _calculateTrend(completionValues);

    return {
      'averageTimeTrend': timeTrend,
      'averageMistakesTrend': mistakesTrend,
      'completionRateTrend': completionTrend,
    };
  }

  /// 识别玩家强项和弱项
  static Map<String, dynamic> identifyStrengthsAndWeaknesses(final List<GameRecord> games) {
    if (games.isEmpty) {
      return {
        'strengths': [],
        'weaknesses': [],
      };
    }

    // 按难度分组分析
    final difficultyStats = <String, Map<String, dynamic>>{};
    
    for (final game in games) {
      if (!difficultyStats.containsKey(game.difficulty)) {
        difficultyStats[game.difficulty] = {
          'totalGames': 0,
          'completedGames': 0,
          'averageTime': 0,
          'averageMistakes': 0,
          'totalTime': 0,
          'totalMistakes': 0,
        };
      }
      
      final stats = difficultyStats[game.difficulty]!;
      stats['totalGames'] = (stats['totalGames'] as int) + 1;
      if (game.isCompleted) {
        stats['completedGames'] = (stats['completedGames'] as int) + 1;
        stats['totalTime'] = (stats['totalTime'] as int) + game.time;
        stats['totalMistakes'] = (stats['totalMistakes'] as int) + game.mistakes;
      }
    }

    // 计算每个难度的平均时间和错误数
    for (final difficulty in difficultyStats.keys) {
      final stats = difficultyStats[difficulty]!;
      final completedGames = stats['completedGames'] as int;
      if (completedGames > 0) {
        stats['averageTime'] = (stats['totalTime'] as int) / completedGames;
        stats['averageMistakes'] = (stats['totalMistakes'] as int) / completedGames;
      }
    }

    // 识别强项和弱项
    final strengths = <String>[];
    final weaknesses = <String>[];
    
    for (final difficulty in difficultyStats.keys) {
      final stats = difficultyStats[difficulty]!;
      final completionRate = (stats['completedGames'] as int) / (stats['totalGames'] as int);
      
      if (completionRate >= 0.8 && (stats['averageMistakes'] as double) <= 2) {
        strengths.add(difficulty);
      } else if (completionRate < 0.5 || (stats['averageMistakes'] as double) > 5) {
        weaknesses.add(difficulty);
      }
    }

    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
    };
  }

  /// 分析玩家技能曲线
  static Map<String, dynamic> analyzeSkillCurve(final List<GameRecord> games) {
    if (games.isEmpty) {
      return {
        'trend': 0.0,
        'improvement': 0.0,
        'consistency': 0.0,
      };
    }

    // 按时间排序
    final sortedGames = [...games]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // 计算技能曲线
    final times = sortedGames.map((game) => game.time).toList();
    final mistakes = sortedGames.map((game) => game.mistakes).toList();
    
    // 计算趋势
    final timeTrend = _calculateTrend(times);
    final _ = _calculateTrend(mistakes);
    
    // 计算改进率
    final improvement = _calculateImprovement(times, mistakes);
    
    // 计算一致性
    final consistency = _calculateConsistency(times, mistakes);
    
    return {
      'trend': timeTrend,
      'improvement': improvement,
      'consistency': consistency,
    };
  }

  /// 分析玩家数字强项和弱项
  static Map<String, List<int>> analyzeNumberStrengthsAndWeaknesses(final List<GameRecord> games) {
    if (games.isEmpty) {
      return {
        'strengths': [],
        'weaknesses': [],
      };
    }
    
    // 确定最大数字（默认9，可根据游戏类型调整）
    const int maxNumber = 9;
    
    // 初始化数字性能记录
    final numberPerformance = <int, List<int>>{};
    for (int i = 1; i <= maxNumber; i++) {
      numberPerformance[i] = [0, 0]; // [正确次数, 错误次数]
    }
    
    // 分析错误模式
    for (final game in games) {
      game.errorDetails.forEach((number, count) {
        if (numberPerformance.containsKey(number)) {
          numberPerformance[number]![1] += count;
        }
      });
    }
    
    // 分析完成游戏的数字使用
    final completedGames = games.where((game) => game.isCompleted).toList();
    for (final _ in completedGames) {
      // 每个完成的游戏中，每个数字应该使用的次数
      // 对于标准数独，每个数字在每行、每列、每个宫各出现一次，共9次
      for (int i = 1; i <= maxNumber; i++) {
        if (numberPerformance.containsKey(i)) {
          numberPerformance[i]![0] += maxNumber; // 每个数字使用maxNumber次
        }
      }
    }
    
    // 识别强项和弱项
    final strengths = <int>[];
    final weaknesses = <int>[];
    
    numberPerformance.forEach((number, performance) {
      final total = performance[0] + performance[1];
      if (total > 0) {
        final successRate = performance[0] / total;
        if (successRate > 0.8) {
          strengths.add(number);
        } else if (successRate < 0.4) {
          weaknesses.add(number);
        }
      }
    });
    
    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
    };
  }

  /// 计算趋势
  static double _calculateTrend(final List<num> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final sumX = n * (n - 1) / 2;
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = values.asMap().entries.fold(0.0, (sum, entry) => sum + entry.key * entry.value);
    final sumX2 = n * (n - 1) * (2 * n - 1) / 6;
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// 计算改进率
  static double _calculateImprovement(final List<int> times, final List<int> mistakes) {
    if (times.length < 2) return 0.0;
    
    final firstTime = times.first;
    final lastTime = times.last;
    final timeImprovement = (firstTime - lastTime) / firstTime;
    
    final firstMistakes = mistakes.first;
    final lastMistakes = mistakes.last;
    final mistakesImprovement = firstMistakes > 0 ? (firstMistakes - lastMistakes) / firstMistakes : 1.0;
    
    return (timeImprovement + mistakesImprovement) / 2;
  }

  /// 计算一致性
  static double _calculateConsistency(final List<int> times, final List<int> mistakes) {
    if (times.length < 2) return 1.0;
    
    final timeMean = times.reduce((a, b) => a + b) / times.length;
    final timeVariance = times.fold(0.0, (sum, time) => sum + (time - timeMean) * (time - timeMean)) / times.length;
    final timeStdDev = sqrt(timeVariance.toDouble());
    
    final mistakesMean = mistakes.reduce((a, b) => a + b) / mistakes.length;
    final mistakesVariance = mistakes.fold(0.0, (sum, mistake) => sum + (mistake - mistakesMean) * (mistake - mistakesMean)) / mistakes.length;
    final mistakesStdDev = sqrt(mistakesVariance.toDouble());
    
    // 计算变异系数
    final timeCV = timeMean > 0 ? timeStdDev / timeMean : 0.0;
    final mistakesCV = mistakesMean > 0 ? mistakesStdDev / mistakesMean : 0.0;
    
    // 一致性 = 1 - 平均变异系数
    final avgCV = (timeCV + mistakesCV) / 2;
    return 1.0 - avgCV;
  }
}
