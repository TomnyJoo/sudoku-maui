import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// Summary：总览标签页组件
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.allStatistics});
  final Map<String, Statistics> allStatistics;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationUtils.app(context);
    final totalGames = allStatistics.values.fold<int>(
      0,
      (sum, s) => sum + s.totalGames,
    );

    if (totalGames == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noStatistics,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final completedGames = allStatistics.values.fold<int>(
      0,
      (sum, s) => sum + s.completedGames,
    );
    final totalTime = allStatistics.values.fold<int>(
      0,
      (sum, s) => sum + s.averageTime * s.completedGames,
    );
    final avgTime = completedGames > 0 ? totalTime ~/ completedGames : 0;
    final completionRate = totalGames > 0
        ? (completedGames / totalGames * 100).toStringAsFixed(1)
        : '0.0';
    final bestTime = allStatistics.values
        .where((s) => s.bestTime > 0)
        .fold<int>(
          0,
          (min, s) => min == 0 || s.bestTime < min ? s.bestTime : min,
        );
    final totalMistakes = allStatistics.values.fold<int>(
      0,
      (sum, s) => sum + (s.averageMistakes * s.completedGames).round(),
    );
    final avgMistakes = completedGames > 0
        ? totalMistakes / completedGames
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallSummaryCard(
            context,
            totalGames,
            completedGames,
            completionRate,
            avgTime,
          ),
          const SizedBox(height: 16),
          _buildDetailCard(context, bestTime, avgMistakes, allStatistics),
        ],
      ),
    );
  }

  Widget _buildOverallSummaryCard(
    BuildContext context,
    int totalGames,
    int completedGames,
    String completionRate,
    int avgTime,
  ) {
    final l10n = LocalizationUtils.app(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.overview,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.totalGames,
                    totalGames.toString(),
                    Icons.games,
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.completedGames,
                    completedGames.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.completionRate,
                    '$completionRate%',
                    Icons.pie_chart,
                    AppColors.accent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.averageTime,
                    GameUtils.formatTime(avgTime),
                    Icons.timer,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    int bestTime,
    double avgMistakes,
    Map<String, Statistics> allStatistics,
  ) {
    final l10n = LocalizationUtils.app(context);
    final activeGameTypes = allStatistics.values
        .where((s) => s.totalGames > 0)
        .length;

    // 计算连续天数和最长连续天数
    int maxConsecutiveDays = 0;
    int maxLongestStreak = 0;
    for (final stats in allStatistics.values) {
      if (stats.consecutiveDays > maxConsecutiveDays) {
        maxConsecutiveDays = stats.consecutiveDays;
      }
      if (stats.longestStreak > maxLongestStreak) {
        maxLongestStreak = stats.longestStreak;
      }
    }

    // 收集所有游戏记录用于图表
    final allRecords = <GameRecord>[];
    final timeDistribution = <String, int>{
      '0-5': 0,
      '5-10': 0,
      '10-15': 0,
      '15-20': 0,
      '20-30': 0,
      '30+': 0,
    };

    for (final stats in allStatistics.values) {
      allRecords.addAll(stats.recentGames);
      // 合并时间分布
      stats.timeDistribution.forEach((key, value) {
        timeDistribution[key] = (timeDistribution[key] ?? 0) + value;
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summary,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              context,
              l10n.bestTime,
              bestTime > 0 ? GameUtils.formatTime(bestTime) : '--',
              Icons.emoji_events,
            ),
            const Divider(),
            _buildDetailItem(
              context,
              l10n.averageMistakes,
              avgMistakes.toStringAsFixed(1),
              Icons.error_outline,
            ),
            const Divider(),
            _buildDetailItem(
              context,
              l10n.activeGameTypes,
              activeGameTypes.toString(),
              Icons.category,
            ),
            const Divider(),
            _buildDetailItem(
              context,
              l10n.consecutiveDays,
              maxConsecutiveDays.toString(),
              Icons.calendar_today,
            ),
            const Divider(),
            _buildDetailItem(
              context,
              l10n.longestStreak,
              maxLongestStreak.toString(),
              Icons.local_fire_department,
            ),
            const SizedBox(height: 24),
            // 添加时间分布图表
            Text(
              l10n.timeDistribution,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ChartUtils.createTimeDistributionChart(timeDistribution),
            ),
            const SizedBox(height: 24),
            // 添加技能曲线图表
            Text(
              '技能曲线',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ChartUtils.createSkillCurveChart(allRecords),
            ),
            const SizedBox(height: 24),
            // 添加错误模式图表
            Text(
              '错误模式',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ChartUtils.createErrorPatternChart(
                _getErrorPatterns(allStatistics),
              ),
            ),
            const SizedBox(height: 24),
            // 添加难度分布图表
            Text(
              '难度分布',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ChartUtils.createDifficultyDistributionChart(
                context,
                _getCombinedDifficultyStats(allStatistics),
              ),
            ),
            const SizedBox(height: 24),
            // 最近游戏记录
            _buildRecentGamesSection(context, allRecords),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) => Column(
    children: [
      Icon(icon, size: 32, color: color),
      const SizedBox(height: 8),
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    ],
  );

  Map<int, int> _getErrorPatterns(Map<String, Statistics> allStatistics) {
    final errorPatterns = <int, int>{};
    for (final stats in allStatistics.values) {
      stats.errorPatterns.forEach((number, count) {
        errorPatterns[number] = (errorPatterns[number] ?? 0) + count;
      });
    }
    return errorPatterns;
  }

  Map<String, DifficultyStats> _getCombinedDifficultyStats(
    Map<String, Statistics> allStatistics,
  ) {
    final combinedStats = <String, DifficultyStats>{};
    for (final stats in allStatistics.values) {
      stats.difficultyStats.forEach((difficulty, diffStats) {
        final existing = combinedStats[difficulty];
        if (existing != null) {
          combinedStats[difficulty] = DifficultyStats(
            difficulty: difficulty,
            totalGames: existing.totalGames + diffStats.totalGames,
            completedGames: existing.completedGames + diffStats.completedGames,
            completionRate: Statistics.calculateCompletionRate(
              existing.totalGames + diffStats.totalGames,
              existing.completedGames + diffStats.completedGames,
            ),
            averageTime:
                (existing.averageTime * existing.completedGames +
                    diffStats.averageTime * diffStats.completedGames) ~/
                (existing.completedGames + diffStats.completedGames),
            bestTime: existing.bestTime == 0
                ? diffStats.bestTime
                : (diffStats.bestTime == 0
                      ? existing.bestTime
                      : (existing.bestTime < diffStats.bestTime
                            ? existing.bestTime
                            : diffStats.bestTime)),
            averageMistakes:
                (existing.averageMistakes * existing.completedGames +
                    diffStats.averageMistakes * diffStats.completedGames) /
                (existing.completedGames + diffStats.completedGames),
          );
        } else {
          combinedStats[difficulty] = diffStats;
        }
      });
    }
    return combinedStats;
  }

  /// 构建最近游戏记录区域
  Widget _buildRecentGamesSection(
    BuildContext context,
    List<GameRecord> allRecords,
  ) {
    final l10n = LocalizationUtils.app(context);
    final gameLocalization = LocalizationUtils.game(context);

    // 按时间倒序排序，取最近 10 条
    final sorted = List<GameRecord>.from(allRecords)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = sorted.take(10).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentGames,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...recent.map((record) => _buildRecentGameItem(context, record, gameLocalization)),
      ],
    );
  }

  /// 构建单条最近游戏记录
  Widget _buildRecentGameItem(
    BuildContext context,
    GameRecord record,
    GameLocalizations gameLocalization,
  ) {
    final gameName = _getGameTypeName(record.gameType, gameLocalization);
    final color = _getGameTypeColor(record.gameType);
    final timeStr = GameUtils.formatTime(record.time);
    final dateStr = _formatDate(record.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：游戏类型 + 难度 + 完成状态
            Row(
              children: [
                // 游戏类型标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gameName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                // 难度
                Text(
                  _getLocalizedDifficulty(record.difficulty, context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Spacer(),
                // 完成状态
                if (record.isCompleted)
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success)
                else
                  Icon(Icons.close, size: 16, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 4),
            // 第二行：用时 + 错误数 + 日期
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Icon(Icons.error_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(
                  '${record.mistakes}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取游戏类型中文名
  String _getGameTypeName(String gameType, GameLocalizations localization) {
    try {
      final e = GameType.values.firstWhere((e) => e.name == gameType);
      return e.getLocalizedName(localization);
    } catch (_) {
      return gameType;
    }
  }

  /// 获取游戏类型颜色
  static const _gameTypeColors = {
    'standard': Colors.blue,
    'jigsaw': Colors.purple,
    'diagonal': Colors.green,
    'window': Colors.orange,
    'killer': Colors.red,
    'samurai': Colors.teal,
  };

  Color _getGameTypeColor(String gameType) =>
      _gameTypeColors[gameType] ?? Colors.grey;

  /// 格式化日期为 MM/dd HH:mm
  String _formatDate(DateTime dt) =>
     '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// 将难度字符串本地化
  String _getLocalizedDifficulty(String difficulty, BuildContext context) {
    final l10n = LocalizationUtils.app(context);
    return switch (difficulty.toLowerCase()) {
      'beginner' => l10n.difficultyBeginner,
      'easy' => l10n.difficultyEasy,
      'medium' => l10n.difficultyMedium,
      'hard' => l10n.difficultyHard,
      'expert' => l10n.difficultyExpert,
      'master' => l10n.difficultyMaster,
      'custom' => l10n.difficultyCustom,
      _ => difficulty,
    };
  }
}
