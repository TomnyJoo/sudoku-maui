import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

abstract class StatisticsViewModel extends ChangeNotifier {

  StatisticsViewModel(this.gameType) : _statistics = Statistics.empty(gameType);
  final String gameType;

  late final Statistics _statistics;
  bool _isLoading = false;
  String? _errorMessage;

  StatisticsTimeRange _timeRange = StatisticsTimeRange.week;
  StatisticsDisplayType _displayType = StatisticsDisplayType.time;

  Statistics get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StatisticsTimeRange get timeRange => _timeRange;
  StatisticsDisplayType get displayType => _displayType;

  List<GameRecord> get filteredStatistics => _getFilteredStatistics();
  Map<String, dynamic> get chartData => _prepareChartData();
  Map<String, dynamic> get trendAnalysis => _analyzeTrends();
  Map<String, dynamic> get summary => _calculateSummary();

  Future<void> loadStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistics = await doLoadStatistics();
    } catch (e) {
      _errorMessage = 'failedToLoadStats';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGameRecord({
    required final String difficulty,
    required final bool isCompleted,
    required final int time,
    required final int mistakes,
  }) async {
    try {
      await doAddGameRecord(
        difficulty: difficulty,
        isCompleted: isCompleted,
        time: time,
        mistakes: mistakes,
      );
      await loadStatistics();
    } catch (e) {
      _errorMessage = 'failedToAddGameRecord';
      notifyListeners();
    }
  }

  Future<void> clearStatistics() async {
    try {
      await doClearStatistics();
      _statistics = Statistics.empty(gameType);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'failedToClearStats';
      notifyListeners();
    }
  }

  Future<String> exportStatistics() async {
    try {
      return await doExportStatistics();
    } catch (e) {
      _errorMessage = 'failedToExportStats';
      notifyListeners();
      return '';
    }
  }

  Future<void> importStatistics(final String json) async {
    try {
      await doImportStatistics(json);
      await loadStatistics();
    } catch (e) {
      _errorMessage = 'failedToImportStats';
      notifyListeners();
    }
  }

  void setTimeRange(final StatisticsTimeRange range) {
    _timeRange = range;
    notifyListeners();
  }

  void setDisplayType(final StatisticsDisplayType type) {
    _displayType = type;
    notifyListeners();
  }

  Future<Statistics> doLoadStatistics();

  Future<void> doAddGameRecord({
    required final String difficulty,
    required final bool isCompleted,
    required final int time,
    required final int mistakes,
  });

  Future<void> doClearStatistics();

  Future<String> doExportStatistics();

  Future<void> doImportStatistics(final String json);

  List<GameRecord> _getFilteredStatistics() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    return _statistics.recentGames.where((record) {
      if (cutoffDate == null) return true;
      return record.timestamp.isAfter(cutoffDate);
    }).toList();
  }

  DateTime? _getCutoffDate(final DateTime now) {
    switch (_timeRange) {
      case StatisticsTimeRange.day:
        return now.subtract(AppConstants.statsDailyPeriod);
      case StatisticsTimeRange.week:
        return now.subtract(AppConstants.statsWeeklyPeriod);
      case StatisticsTimeRange.month:
        return now.subtract(AppConstants.statsMonthlyPeriod);
      case StatisticsTimeRange.year:
        return now.subtract(AppConstants.statsYearlyPeriod);
      case StatisticsTimeRange.all:
        return null;
    }
  }

  Map<String, dynamic> _prepareChartData() {
    final filtered = filteredStatistics;

    switch (_displayType) {
      case StatisticsDisplayType.time:
        return {
          'type': 'time',
          'data': filtered
              .map((record) => {
                    'time': record.time,
                    'timestamp': record.timestamp,
                  })
              .toList(),
        };
      case StatisticsDisplayType.accuracy:
        return {
          'type': 'accuracy',
          'data': filtered
              .map((record) => {
                    'mistakes': record.mistakes,
                    'timestamp': record.timestamp,
                  })
              .toList(),
        };
      case StatisticsDisplayType.difficulty:
        final difficultyCounts = <String, int>{};
        for (final record in filtered) {
          difficultyCounts[record.difficulty] =
              (difficultyCounts[record.difficulty] ?? 0) + 1;
        }
        return {
          'type': 'difficulty',
          'data': difficultyCounts,
        };
      case StatisticsDisplayType.completion:
        final completed = filtered.where((r) => r.isCompleted).length;
        return {
          'type': 'completion',
          'data': {
            'completed': completed,
            'total': filtered.length,
            'rate': filtered.isEmpty
                ? 0.0
                : (completed / filtered.length * 100).toDouble(),
          },
        };
    }
  }

  Map<String, dynamic> _analyzeTrends() {
    final filtered = filteredStatistics;
    if (filtered.length < 2) {
      return {
        'hasTrend': false,
        'message': 'notEnoughDataForTrend',
      };
    }

    final recent = filtered.take(10).toList();
    final recentAvgTime = recent.isEmpty
        ? 0.0
        : recent.map((r) => r.time).reduce((a, b) => a + b) / recent.length;

    final older = filtered.skip(10).take(10).toList();
    final olderAvgTime = older.isEmpty
        ? 0.0
        : older.map((r) => r.time).reduce((a, b) => a + b) / older.length;

    final timeTrend = recentAvgTime - olderAvgTime;
    final improvement = timeTrend < 0; // 时间减少表示进步

    return {
      'hasTrend': true,
      'timeTrend': timeTrend,
      'improvement': improvement,
      'message': improvement ? 'trendImprovement' : 'trendDecline',
    };
  }

  Map<String, dynamic> _calculateSummary() {
    final filtered = filteredStatistics;

    final totalTime = filtered.isEmpty
        ? 0
        : filtered.map((r) => r.time).reduce((a, b) => a + b);

    final bestTime = filtered.isEmpty
        ? 0
        : filtered.map((r) => r.time).reduce((a, b) => a < b ? a : b);

    final avgTime = filtered.isEmpty
        ? 0.0
        : totalTime / filtered.length;

    final avgMistakes = filtered.isEmpty
        ? 0.0
        : filtered.map((r) => r.mistakes).reduce((a, b) => a + b) /
            filtered.length;

    final completed = filtered.where((r) => r.isCompleted).length;
    final completionRate = filtered.isEmpty
        ? 0.0
        : (completed / filtered.length * 100);

    return {
      'totalGames': filtered.length,
      'completedGames': completed,
      'totalTime': totalTime,
      'bestTime': bestTime,
      'averageTime': avgTime,
      'averageMistakes': avgMistakes,
      'completionRate': completionRate,
    };
  }

  String getFormattedBestTime() {
    if (_statistics.bestTime == 0) return '--';
    final minutes = _statistics.bestTime ~/ 60;
    final seconds = _statistics.bestTime % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String getFormattedAverageTime() {
    if (_statistics.averageTime == 0) return '--';
    final minutes = _statistics.averageTime ~/ 60;
    final seconds = _statistics.averageTime % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String getFormattedAverageMistakes() => _statistics.averageMistakes.toStringAsFixed(1);

  List<DifficultyStats> getDifficultyStatsList() {
    final difficultyOrder = DifficultyExtension.allLevels.map((final d) => d.name).toList();
    final statsList = _statistics.difficultyStats.values.toList()
    ..sort((final a, final b) {
      final indexA = difficultyOrder.indexOf(a.difficulty);
      final indexB = difficultyOrder.indexOf(b.difficulty);
      if (indexA == -1 && indexB == -1) return a.difficulty.compareTo(b.difficulty);
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });
    return statsList;
  }

  String getFormattedCompletionRate() {
    final totalGames = _statistics.totalGames;
    if (totalGames == 0) return '0%';
    final rate = (_statistics.completedGames / totalGames * 100).toStringAsFixed(1);
    return '$rate%';
  }

  List<GameRecord> getRecentGamesList({final int limit = 10}) {
    final filtered = _getFilteredStatistics();
    final sorted = filtered.toList()
      ..sort((final a, final b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }
}

enum StatisticsTimeRange {
  day,
  week,
  month,
  year,
  all,
}

enum StatisticsDisplayType {
  time,
  accuracy,
  difficulty,
  completion,
}
