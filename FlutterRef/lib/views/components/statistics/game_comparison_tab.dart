import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 游戏比较标签页组件
class GameComparisonTab extends StatefulWidget {
  const GameComparisonTab({super.key, required this.allStatistics});
  final Map<String, Statistics> allStatistics;

  @override
  State<GameComparisonTab> createState() => _GameComparisonTabState();
}

class _GameComparisonTabState extends State<GameComparisonTab> {
  List<String> gameTypes = [];
  bool isLoading = true;

  static const _gameColors = {
    'standard': Colors.blue,
    'jigsaw': Colors.purple,
    'diagonal': Colors.green,
    'window': Colors.orange,
    'killer': Colors.red,
    'samurai': Colors.teal,
  };

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
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationUtils.app(context);
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final activeTypes = gameTypes.where((t) {
      final s = widget.allStatistics[t];
      return s != null && s.totalGames > 0;
    }).toList();

    if (activeTypes.isEmpty) {
      return Center(child: Text(l10n.noGamesPlayed));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.gameComparison,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildComparisonSection(context, l10n, activeTypes, l10n.totalGames,
                  (s) => s.totalGames.toString(), lowerIsBetter: false),
              const Divider(height: 24),
              _buildComparisonSection(context, l10n, activeTypes, l10n.completedGames,
                  (s) => s.completedGames.toString(), lowerIsBetter: false),
              const Divider(height: 24),
              _buildComparisonSection(context, l10n, activeTypes, l10n.completionRate,
                  (s) => '${s.completionRate.toStringAsFixed(1)}%', lowerIsBetter: false),
              const Divider(height: 24),
              _buildComparisonSection(context, l10n, activeTypes, l10n.averageTime,
                  (s) => GameUtils.formatTime(s.averageTime), lowerIsBetter: true),
              const Divider(height: 24),
              _buildComparisonSection(context, l10n, activeTypes, l10n.bestTime,
                  (s) => s.bestTime > 0 ? GameUtils.formatTime(s.bestTime) : '--:--', lowerIsBetter: true),
              const Divider(height: 24),
              _buildComparisonSection(context, l10n, activeTypes, l10n.averageMistakes,
                  (s) => s.averageMistakes.toStringAsFixed(1), lowerIsBetter: true),
              const SizedBox(height: 16),
              _buildSummary(context, l10n, activeTypes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection(
    BuildContext context,
    dynamic l10n,
    List<String> types,
    String label,
    String Function(Statistics) getValue, {
    required bool lowerIsBetter,
  }) {
    final values = {for (final t in types) t: getValue(widget.allStatistics[t]!)};
    final bestType = _findBest(values, lowerIsBetter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final isBest = type == bestType;
            return _buildStatCard(context, type, values[type]!, isBest);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String type, String value, bool isBest) {
    final color = _gameColors[type] ?? Colors.grey;
    final localization = LocalizationUtils.game(context);
    final name = _getGameName(type, localization);

    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isBest ? AppColors.success : color.withAlpha(80), width: isBest ? 2 : 1),
      ),
      child: Column(
        children: [
          Text(name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold, color: color)),
          if (isBest) ...[
            const SizedBox(height: 2),
            const Icon(Icons.emoji_events, size: 14, color: AppColors.success),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, dynamic l10n, List<String> types) {
    final localization = LocalizationUtils.game(context);
    String? mostPlayedType;
    int maxGames = 0;
    for (final type in types) {
      final total = widget.allStatistics[type]!.totalGames;
      if (total > maxGames) {
        maxGames = total;
        mostPlayedType = type;
      }
    }

    final summaryText = mostPlayedType != null
        ? '${_getGameName(mostPlayedType, localization)} ${l10n.playedMore}'
        : l10n.noGamesPlayed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(child: Text(summaryText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success))),
      ]),
    );
  }

  String? _findBest(Map<String, String> values, bool lowerIsBetter) {
    String? bestType;
    num? bestValue;
    for (final entry in values.entries) {
      final numVal = double.tryParse(entry.value.replaceAll('%', '')) ?? 0;
      if (bestValue == null) {
        bestValue = numVal;
        bestType = entry.key;
      } else if (lowerIsBetter ? numVal < bestValue : numVal > bestValue) {
        bestValue = numVal;
        bestType = entry.key;
      }
    }
    return bestType;
  }

  String _getGameName(String gameType, GameLocalizations localization) {
    try {
      final e = GameType.values.firstWhere((e) => e.name == gameType);
      return e.getLocalizedName(localization);
    } catch (_) {
      return gameType;
    }
  }
}
