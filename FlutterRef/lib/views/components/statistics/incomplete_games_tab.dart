import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';
import 'package:sudoku/main.dart';

/// Summary：未完成游戏标签页组件
class IncompleteGamesTab extends StatefulWidget {
  const IncompleteGamesTab({super.key, required this.allStatistics});
  final Map<String, Statistics> allStatistics;

  @override
  State<IncompleteGamesTab> createState() => _IncompleteGamesTabState();
}

class _IncompleteGamesTabState extends State<IncompleteGamesTab> {
  List<SavedGameInfo> _savedGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedGames();
  }

  Future<void> _loadSavedGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final savedGames = await GameStorageService.getSavedGameInfos();
      setState(() {
        _savedGames = savedGames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = GameLocalizations.of(context);
    final l10n = AppLocalizations.of(context);
    final incompleteGames = _getIncompleteGames();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (incompleteGames.isEmpty && _savedGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.incomplete_circle, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noIncompleteGames,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 显示保存的游戏
          if (_savedGames.isNotEmpty)
            ..._savedGames.map(
              (savedGame) =>
                  _buildSavedGameCard(context, savedGame, localization, l10n),
            ),

          // 显示未完成的游戏记录
          if (incompleteGames.isNotEmpty)
            ...incompleteGames.map(
              (game) =>
                  _buildIncompleteGameCard(context, game, localization, l10n),
            ),
        ],
      ),
    );
  }

  List<GameRecord> _getIncompleteGames() {
    final incompleteGames = <GameRecord>[];
    for (final stats in widget.allStatistics.values) {
      incompleteGames.addAll(
        stats.recentGames.where((game) => !game.isCompleted),
      );
    }
    incompleteGames.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return incompleteGames;
  }

  Widget _buildSavedGameCard(
    BuildContext context,
    SavedGameInfo savedGame,
    GameLocalizations localization,
    AppLocalizations l10n,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getGameName(savedGame.gameType, localization),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '保存的游戏',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getDifficultyName(savedGame.difficulty, l10n),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.startTime} ${savedGame.timestamp.year}-${savedGame.timestamp.month.toString().padLeft(2, '0')}-${savedGame.timestamp.day.toString().padLeft(2, '0')} ${savedGame.timestamp.hour.toString().padLeft(2, '0')}:${savedGame.timestamp.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _continueGame(savedGame),
                icon: const Icon(Icons.play_arrow),
                label: const Text('继续游戏'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteSavedGame(savedGame),
                icon: const Icon(Icons.delete),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildIncompleteGameCard(
    BuildContext context,
    GameRecord game,
    GameLocalizations localization,
    AppLocalizations l10n,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getGameName(game.gameType, localization),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${game.completionPercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_getDifficultyName(game.difficulty, l10n)} · ${GameUtils.formatTime(game.time)} · ${game.mistakes} ${l10n.mistakes}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: game.completionPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.startTime} ${game.timestamp.year}-${game.timestamp.month.toString().padLeft(2, '0')}-${game.timestamp.day.toString().padLeft(2, '0')} ${game.timestamp.hour.toString().padLeft(2, '0')}:${game.timestamp.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );

  Future<void> _continueGame(SavedGameInfo savedGame) async {
    try {
      final gameType = GameType.values.firstWhere(
        (type) => type.toString().split('.').last == savedGame.gameType,
        orElse: () => GameType.standard,
      );

      // 创建游戏服务
      final service = GameFactory.createGameService(gameType, GameValidator());
      // 加载游戏状态
      final savedState = await service.loadGameState(savedGame.saveKey);
      if (savedState != null && mounted) {
        // 获取游戏路由
        final route = GameFactory.getGameRoute(gameType);
        // 导航到游戏页面并传入保存的游戏状态
        await Navigator.pushNamed(context, route, arguments: GameRouteArgs(gameType: gameType, initialState: savedState));
      }
    } catch (e) {
      AppLogger.error('继续游戏失败', e, StackTrace.current);
    }
  }

  Future<void> _deleteSavedGame(SavedGameInfo savedGame) async {
    await GameStorageService.clearGameState(savedGame.saveKey);
    await _loadSavedGames();
  }

  String _getGameName(String gameType, GameLocalizations localization) {
    try {
      final gameTypeEnum = GameType.values.firstWhere((e) => e.name == gameType);
      return gameTypeEnum.getLocalizedName(localization);
    } catch (e) {
      // 如果转换失败，返回原始字符串
      return gameType;
    }
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
}
