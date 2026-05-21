import 'dart:convert';

class Statistics {
  Statistics({
    required this.gameType,
    required this.totalGames,
    required this.completedGames,
    required this.completionRate,
    required this.averageTime,
    required this.bestTime,
    required this.averageMistakes,
    required this.difficultyStats,
    required this.recentGames,
    this.consecutiveDays = 0,
    this.longestStreak = 0,
    this.timeDistribution = const {},
    this.errorPatterns = const {},
    this.recommendedDifficulty = 'easy',
  });
  factory Statistics.fromJsonString(
    final String jsonString,
    final String gameType,
  ) => Statistics.fromJson(
    jsonDecode(jsonString) as Map<String, dynamic>,
    gameType,
  );

  factory Statistics.fromJson(
    final Map<String, dynamic> json,
    final String gameType,
  ) {
    final difficultyStatsMap = <String, DifficultyStats>{};
    if (json['difficultyStats'] != null) {
      (json['difficultyStats'] as Map<String, dynamic>).forEach((
        final key,
        final value,
      ) {
        difficultyStatsMap[key] = DifficultyStats.fromJson(
          value as Map<String, dynamic>,
        );
      });
    }

    final recentGamesList = <GameRecord>[];
    if (json['recentGames'] != null) {
      recentGamesList.addAll(
        (json['recentGames'] as List).map((final e) {
          final recordJson = e as Map<String, dynamic>;
          if (recordJson['gameType'] == null) {
            recordJson['gameType'] = gameType;
          }
          return GameRecord.fromJson(recordJson);
        }),
      );
    }

    // 解析时长分布
    final timeDistributionMap = <String, int>{};
    if (json['timeDistribution'] != null) {
      (json['timeDistribution'] as Map<String, dynamic>).forEach((key, value) {
        timeDistributionMap[key] = value as int;
      });
    }

    // 解析错误模式
    final errorPatternsMap = <int, int>{};
    if (json['errorPatterns'] != null) {
      (json['errorPatterns'] as Map<String, dynamic>).forEach((key, value) {
        errorPatternsMap[int.parse(key)] = value as int;
      });
    }

    return Statistics(
      gameType: gameType,
      totalGames: json['totalGames'] as int? ?? 0,
      completedGames: json['completedGames'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      averageTime: json['averageTime'] as int? ?? 0,
      bestTime: json['bestTime'] as int? ?? 0,
      averageMistakes: (json['averageMistakes'] as num?)?.toDouble() ?? 0.0,
      difficultyStats: difficultyStatsMap,
      recentGames: recentGamesList,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      timeDistribution: timeDistributionMap,
      errorPatterns: errorPatternsMap,
      recommendedDifficulty: json['recommendedDifficulty'] as String? ?? 'easy',
    );
  }

  factory Statistics.empty(final String gameType) => Statistics(
    gameType: gameType,
    totalGames: 0,
    completedGames: 0,
    completionRate: 0,
    averageTime: 0,
    bestTime: 0,
    averageMistakes: 0,
    difficultyStats: {},
    recentGames: [],
  );

  final String gameType;
  final int totalGames;
  final int completedGames;
  final double completionRate;
  final int averageTime;
  final int bestTime;
  final double averageMistakes;
  final Map<String, DifficultyStats> difficultyStats;
  final List<GameRecord> recentGames;
  final int consecutiveDays;
  final int longestStreak;
  final Map<String, int> timeDistribution;
  final Map<int, int> errorPatterns;
  final String recommendedDifficulty;

  static double calculateCompletionRate(final int total, final int completed) {
    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  Map<String, dynamic> toJson() => {
    'totalGames': totalGames,
    'completedGames': completedGames,
    'completionRate': completionRate,
    'averageTime': averageTime,
    'bestTime': bestTime,
    'averageMistakes': averageMistakes,
    'difficultyStats': difficultyStats.map(
      (final key, final value) => MapEntry(key, value.toJson()),
    ),
    'recentGames': recentGames.map((final e) => e.toJson()).toList(),
    'consecutiveDays': consecutiveDays,
    'longestStreak': longestStreak,
    'timeDistribution': timeDistribution,
    'errorPatterns': errorPatterns.map((k, v) => MapEntry(k.toString(), v)),
    'recommendedDifficulty': recommendedDifficulty,
  };

  String toJsonString() => jsonEncode(toJson());
}

/// 最佳成绩完整记录（替代原 BestScore 系统）
class BestScoreRecord {
  const BestScoreRecord({
    required this.time,
    required this.mistakes,
    required this.timestamp,
  });

  factory BestScoreRecord.fromJson(Map<String, dynamic> json) => BestScoreRecord(
        time: (json['time'] as num?)?.toInt() ?? 0,
        mistakes: (json['mistakes'] as num?)?.toInt() ?? 0,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  final int time;
  final int mistakes;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'time': time,
        'mistakes': mistakes,
        'timestamp': timestamp.toIso8601String(),
      };
}

class DifficultyStats {
  DifficultyStats({
    required this.difficulty,
    required this.totalGames,
    required this.completedGames,
    required this.completionRate,
    required this.averageTime,
    required this.bestTime,
    required this.averageMistakes,
    this.bestScoreRecord,
  });

  factory DifficultyStats.fromJson(final Map<String, dynamic> json) =>
      DifficultyStats(
        difficulty: json['difficulty'] as String,
        totalGames: json['totalGames'] as int? ?? 0,
        completedGames: json['completedGames'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        averageTime: json['averageTime'] as int? ?? 0,
        bestTime: json['bestTime'] as int? ?? 0,
        averageMistakes: (json['averageMistakes'] as num?)?.toDouble() ?? 0.0,
        bestScoreRecord: json['bestScoreRecord'] != null
            ? BestScoreRecord.fromJson(json['bestScoreRecord'] as Map<String, dynamic>)
            : null,
      );

  factory DifficultyStats.empty(final String difficulty) => DifficultyStats(
    difficulty: difficulty,
    totalGames: 0,
    completedGames: 0,
    completionRate: 0.0,
    averageTime: 0,
    bestTime: 0,
    averageMistakes: 0.0,
  );

  final String difficulty;
  final int totalGames;
  final int completedGames;
  final double completionRate;
  final int averageTime;
  final int bestTime;
  final double averageMistakes;
  final BestScoreRecord? bestScoreRecord;

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'totalGames': totalGames,
    'completedGames': completedGames,
    'completionRate': completionRate,
    'averageTime': averageTime,
    'bestTime': bestTime,
    'averageMistakes': averageMistakes,
    if (bestScoreRecord != null) 'bestScoreRecord': bestScoreRecord!.toJson(),
  };
}

class GameRecord {
  GameRecord({
    required this.id,
    required this.gameType,
    required this.difficulty,
    required this.isCompleted,
    required this.time,
    required this.mistakes,
    required this.timestamp,
    this.completionPercentage = 0.0,
    this.completedDate,
    this.errorDetails = const {},
  });

  factory GameRecord.fromJson(final Map<String, dynamic> json) => GameRecord(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    gameType: json['gameType'] as String? ?? 'standard',
    difficulty: json['difficulty'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
    time: json['time'] as int? ?? 0,
    mistakes: json['mistakes'] as int? ?? 0,
    timestamp: DateTime.parse(json['timestamp'] as String),
    completionPercentage:
        (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
    completedDate: json['completedDate'] != null
        ? DateTime.parse(json['completedDate'] as String)
        : null,
    errorDetails: json['errorDetails'] != null
        ? Map<int, int>.from(
            (json['errorDetails'] as Map).map(
              (k, v) => MapEntry(int.parse(k as String), v as int),
            ),
          )
        : {},
  );

  factory GameRecord.create({
    required final String gameType,
    required final String difficulty,
    required final bool isCompleted,
    required final int time,
    required final int mistakes,
    double completionPercentage = 0.0,
    DateTime? completedDate,
    Map<int, int> errorDetails = const {},
  }) => GameRecord(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    gameType: gameType,
    difficulty: difficulty,
    isCompleted: isCompleted,
    time: time,
    mistakes: mistakes,
    timestamp: DateTime.now(),
    completionPercentage: completionPercentage,
    completedDate: isCompleted ? completedDate ?? DateTime.now() : null,
    errorDetails: errorDetails,
  );

  final String id;
  final String gameType;
  final String difficulty;
  final bool isCompleted;
  final int time;
  final int mistakes;
  final DateTime timestamp;
  final double completionPercentage;
  final DateTime? completedDate;
  final Map<int, int> errorDetails;

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameType': gameType,
    'difficulty': difficulty,
    'isCompleted': isCompleted,
    'time': time,
    'mistakes': mistakes,
    'timestamp': timestamp.toIso8601String(),
    'completionPercentage': completionPercentage,
    'completedDate': completedDate?.toIso8601String(),
    'errorDetails': errorDetails.map((k, v) => MapEntry(k.toString(), v)),
  };
}
