import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// Summary：游戏统计页面
class GameStatisticsScreen extends StatefulWidget {
  const GameStatisticsScreen({super.key});

  @override
  State<GameStatisticsScreen> createState() => _GameStatisticsScreenState();
}

/// Summary：游戏统计页面状态管理
class _GameStatisticsScreenState extends State<GameStatisticsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, Statistics> _allStatistics = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await StatisticsManager.getAllGameStatistics();
      setState(() {
        _allStatistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showClearAllDialog(BuildContext pageContext) {
    final l10n = LocalizationUtils.app(pageContext);
    final scaffoldMessenger = ScaffoldMessenger.of(pageContext);
    return showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearStatistics),
        content: Text(l10n.clearAllStatsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await StatisticsManager.clearAllGameStatistics();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              // 刷新统计数据
              if (mounted) {
                await _loadAllStatistics();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.statsCleared)),
                  );
                }
              }
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationUtils.app(context);
    final isDarkMode = context.isDarkMode;
    final iconColor = isDarkMode
        ? Colors.white.withAlpha(200)
        : AppColors.mutedText;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: iconColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                ? AppColors.homeBackgroundGradientDark
                : AppColors.homeBackgroundGradientLight,
            ),
          ),
        ),
        title: Text(
          l10n.statisticsTitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.darkText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: iconColor),
            onPressed: _loadAllStatistics,
          ),
          PopupMenuButton<String>(
            color: isDarkMode
                ? AppColors.darkUnselectedBackground
                : AppColors.lightCard,
            icon: Icon(Icons.more_vert, color: iconColor),
            onSelected: (String result) async {
              if (result == 'export') {
                await StatisticsExportImport.exportStatistics(context);
              } else if (result == 'import') {
                // 这里需要实现文件选择器来选择导入文件
                // 暂时只显示提示
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('导入功能开发中')));
                }
              } else if (result == 'clearAll') {
                if (mounted) {
                  await _showClearAllDialog(context);
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'export',
                child: Text(l10n.exportStatistics),
              ),
              const PopupMenuItem<String>(value: 'import', child: Text('导入统计')),
              PopupMenuItem<String>(
                value: 'clearAll',
                child: Text(l10n.clearStatistics),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDarkMode ? Colors.white : AppColors.darkText,
          unselectedLabelColor: isDarkMode
              ? Colors.white70
              : AppColors.mutedText,
          indicatorColor: isDarkMode ? Colors.white : AppColors.buttonPrimary,
          tabs: [
            Tab(text: l10n.overview),
            Tab(text: l10n.gameComparison),
            Tab(text: l10n.individualGameStats),
            Tab(text: l10n.incompleteGames),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? AppColors.homeBackgroundGradientDark
                : AppColors.homeBackgroundGradientLight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          OverviewTab(allStatistics: _allStatistics),
                          GameComparisonTab(allStatistics: _allStatistics),
                          IndividualGamesTab(allStatistics: _allStatistics),
                          IncompleteGamesTab(allStatistics: _allStatistics),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
