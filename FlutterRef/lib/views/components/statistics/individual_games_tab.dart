import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// Summary：游戏个体标签页组件
class IndividualGamesTab extends StatefulWidget {
  const IndividualGamesTab({super.key, required this.allStatistics});
  final Map<String, Statistics> allStatistics;

  @override
  State<IndividualGamesTab> createState() => _IndividualGamesTabState();
}

class _IndividualGamesTabState extends State<IndividualGamesTab> {
  List<String> gameTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGameTypes();
  }

  Future<void> _loadGameTypes() async {
    try {
      final gameConfig = GameConfig();
      await gameConfig.initialize();
      final gameConfigs = gameConfig.getAllGameConfigs();
      setState(() {
        gameTypes = gameConfigs?.keys.toList() ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: gameTypes.map((type) {
          final stats = widget.allStatistics[type];
          if (stats == null || stats.totalGames == 0) {
            return const SizedBox.shrink();
          }
          return _buildGameStatisticsCard(context, type, stats);
        }).toList(),
      ),
    );
  }

  Widget _buildGameStatisticsCard(
    BuildContext context,
    String gameType,
    Statistics stats,
  ) {
    final localization = LocalizationUtils.game(context);
    final l10n = LocalizationUtils.app(context);
    String gameName;
    try {
      // 将字符串转换为 GameType 枚举，然后使用 getLocalizedName 方法
      final gameTypeEnum = GameType.values.firstWhere((e) => e.name == gameType);
      gameName = gameTypeEnum.getLocalizedName(localization);
    } catch (e) {
      // 如果转换失败，返回原始字符串
      gameName = gameType;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gameName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearDialog(context, gameType),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.totalGames,
                    stats.totalGames.toString(),
                    Icons.games,
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.completedGames,
                    stats.completedGames.toString(),
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
                    '${stats.completionRate.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    AppColors.accent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.averageTime,
                    GameUtils.formatTime(stats.averageTime),
                    Icons.timer,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.difficultyStats.isNotEmpty) ...[
              Text(
                l10n.difficultyStats,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...stats.difficultyStats.entries.map((entry) {
                final difficulty = entry.key;
                final difficultyStats = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDifficultyName(difficulty, l10n),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: difficultyStats.totalGames > 0
                            ? difficultyStats.completedGames /
                                  difficultyStats.totalGames
                            : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(difficultyStats.completionRate),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${difficultyStats.completedGames}/${difficultyStats.totalGames} - ${GameUtils.formatTime(difficultyStats.averageTime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ],

            // 推荐难度
            if (stats.recommendedDifficulty.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.recommendedDifficulty,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getDifficultyName(stats.recommendedDifficulty, l10n),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // 时间分布
            if (stats.timeDistribution.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.timeDistribution,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...stats.timeDistribution.entries.map((entry) {
                final range = entry.key;
                final count = entry.value;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.getTimeRangeLabel(range),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        l10n.gameCount(count),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ],

            // 错误模式
            if (stats.errorPatterns.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.commonErrors,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats.errorPatterns.entries.map((entry) {
                  final number = entry.key;
                  final count = entry.value;
                  return Chip(
                    label: Text('$number ($count)'),
                    backgroundColor: AppColors.error.withAlpha(20),
                    labelStyle: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showClearDialog(BuildContext context, String gameType) {
    final l10n = LocalizationUtils.app(context);
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearStatistics),
        content: Text(l10n.clearStatisticsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await StatisticsManager.clearGameStatistics(gameType);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              // Refresh the parent widget
              if (context.mounted) {
                // Trigger a refresh
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const GameStatisticsScreen(),
                  ),
                );
              }
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  String _getDifficultyName(String difficulty, AppLocalizations l10n) {
    try {
      final difficultyEnum = Difficulty.values.firstWhere((e) => e.name == difficulty);
      return difficultyEnum.config.getLocalizedDifficultyName(l10n);
    } catch (e) {
      // 如果转换失败，返回原始字符串
      return difficulty;
    }
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) => Column(
    children: [
      Icon(icon, size: 24, color: color),
      const SizedBox(height: 4),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    ],
  );

  Color _getProgressColor(double rate) {
    if (rate >= 80) return AppColors.success;
    if (rate >= 50) return AppColors.orange;
    return AppColors.error;
  }
}
