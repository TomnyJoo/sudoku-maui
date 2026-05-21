import 'package:sudoku/models/board.dart';

/// 游戏统计数据模型，负责存储和计算游戏统计数据
class SessionStatistics {
  SessionStatistics({
    required this.board,
    required this.mistakes,
    required this.totalMoves,
    required this.isCompleted,
    required this.elapsedTime,
    this.difficulty = 'medium',
  });

  /// 创建空的游戏统计数据
  factory SessionStatistics.empty() => SessionStatistics(
      board: StandardBoard.empty(),
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

  final Board board;
  final int mistakes;
  final int totalMoves;
  final bool isCompleted;
  final int elapsedTime;
  final String difficulty;

  // 缓存计算结果
  double? _accuracy;
  double? _completionPercentage;
  double? _efficiency;
  int? _estimatedCompletionTime;

  /// 获取游戏准确率
  double get accuracy {
    _accuracy ??= _calculateAccuracy();
    return _accuracy!;
  }

  /// 获取游戏完成百分比
  double get completionPercentage {
    _completionPercentage ??= _calculateCompletionPercentage();
    return _completionPercentage!;
  }

  /// 获取游戏效率（每步平均时间）
  double get efficiency {
    _efficiency ??= _calculateEfficiency();
    return _efficiency!;
  }

  /// 获取预估完成时间（秒）
  int get estimatedCompletionTime {
    _estimatedCompletionTime ??= _calculateEstimatedCompletionTime();
    return _estimatedCompletionTime!;
  }

  /// 计算准确率
  double _calculateAccuracy() {
    if (totalMoves <= 0) return 1.0;
    final correctMoves = totalMoves - mistakes;
    return correctMoves / totalMoves;
  }

  /// 计算完成百分比
  double _calculateCompletionPercentage() {
    final totalCells = board.size * board.size;
    if (totalCells == 0) return 0.0;
    final filledCells = board.getFilledCells().length;
    return filledCells / totalCells;
  }

  /// 计算游戏效率（每步平均时间，秒）
  double _calculateEfficiency() {
    if (totalMoves <= 0) return 0.0;
    return elapsedTime / totalMoves;
  }

  /// 计算预估完成时间（秒）
  int _calculateEstimatedCompletionTime() {
    if (completionPercentage <= 0) return 0;
    final estimatedTotalTime = elapsedTime / completionPercentage;
    return (estimatedTotalTime - elapsedTime).round();
  }

  /// 更新棋盘状态
  SessionStatistics updateBoard(Board newBoard) => SessionStatistics(
      board: newBoard,
      mistakes: mistakes,
      totalMoves: totalMoves,
      isCompleted: isCompleted,
      elapsedTime: elapsedTime,
      difficulty: difficulty,
    );

  /// 更新错误计数
  SessionStatistics updateMistakes(int newMistakes) => SessionStatistics(
      board: board,
      mistakes: newMistakes,
      totalMoves: totalMoves,
      isCompleted: isCompleted,
      elapsedTime: elapsedTime,
      difficulty: difficulty,
    );

  /// 更新总移动次数
  SessionStatistics updateTotalMoves(int newTotalMoves) => SessionStatistics(
      board: board,
      mistakes: mistakes,
      totalMoves: newTotalMoves,
      isCompleted: isCompleted,
      elapsedTime: elapsedTime,
      difficulty: difficulty,
    );

  /// 更新游戏完成状态
  SessionStatistics updateCompletionStatus(bool completed) => SessionStatistics(
      board: board,
      mistakes: mistakes,
      totalMoves: totalMoves,
      isCompleted: completed,
      elapsedTime: elapsedTime,
      difficulty: difficulty,
    );

  /// 更新已消耗时间
  SessionStatistics updateElapsedTime(int newElapsedTime) => SessionStatistics(
      board: board,
      mistakes: mistakes,
      totalMoves: totalMoves,
      isCompleted: isCompleted,
      elapsedTime: newElapsedTime,
      difficulty: difficulty,
    );

  /// 更新难度
  SessionStatistics updateDifficulty(String newDifficulty) => SessionStatistics(
      board: board,
      mistakes: mistakes,
      totalMoves: totalMoves,
      isCompleted: isCompleted,
      elapsedTime: elapsedTime,
      difficulty: newDifficulty,
    );

  /// 检查游戏是否接近完成
  bool isNearlyCompleted() => completionPercentage >= 0.9;

  /// 检查游戏是否遇到困难
  bool isHavingDifficulty() => mistakes > totalMoves * 0.3;

  /// 获取游戏状态描述
  String getStatusDescription() {
    if (isCompleted) {
      return '游戏已完成';
    } else if (isNearlyCompleted()) {
      return '即将完成';
    } else if (isHavingDifficulty()) {
      return '遇到困难';
    } else {
      return '游戏进行中';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionStatistics &&
        other.board == board &&
        other.mistakes == mistakes &&
        other.totalMoves == totalMoves &&
        other.isCompleted == isCompleted &&
        other.elapsedTime == elapsedTime &&
        other.difficulty == difficulty;
  }

  @override
  int get hashCode => Object.hash(board, mistakes, totalMoves, isCompleted, elapsedTime, difficulty);

  @override
  String toString() => 'SessionStatistics(accuracy: $accuracy, completion: $completionPercentage, efficiency: $efficiency, mistakes: $mistakes, totalMoves: $totalMoves, elapsedTime: $elapsedTime, difficulty: $difficulty)';
}
