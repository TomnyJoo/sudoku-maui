import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/board_commands.dart';
import 'package:sudoku/models/cell.dart';
import 'package:sudoku/services/generation/progress_utils.dart';
import 'package:sudoku/services/history_manager.dart';
import 'package:sudoku/services/session_statistics.dart';

/// Summary：游戏状态泛型类，表示整个游戏的当前状态，包括棋盘、答案、计时、历史记录等信息
/// B: 棋盘类型，必须继承自Board
class GameState<B extends Board> {
  GameState({
    required this.board,
    required this.initialBoard,
    required this.solution,
    required this.difficulty,
    this.elapsedTime = 0,
    this.mistakes = 0,
    this.isCompleted = false,
    required this.history,
    required this.stats,
    this.startTime,
    this.completionTime,
    this.isShowingSolution = false,
    this.isMarkMode = false,
    this.isAutoMarkMode = false,
    this.hintsUsed = 0,
    this.savedBoard,
  }) {
    // 验证参数
    if (elapsedTime < 0) {
      throw ArgumentError('已消耗时间不能为负数: $elapsedTime');
    }

    if (mistakes < 0) {
      throw ArgumentError('错误次数不能为负数: $mistakes');
    }

    if (completionTime != null &&
        startTime != null &&
        completionTime!.isBefore(startTime!)) {
      throw ArgumentError('完成时间不能早于开始时间');
    }
  }

  /// 从JSON创建游戏状态
  /// boardFromJson: 用于从JSON创建特定类型棋盘的函数
  factory GameState.fromJson(
    Map<String, dynamic> json,
    B Function(Map<String, dynamic>) boardFromJson,
  ) {
    final common = parseCommonJsonFields(json);
    final initialBoard = boardFromJson(json['initialBoard'] as Map<String, dynamic>);

    // 构建历史记录（向后兼容：支持旧快照格式和新命令格式）
    HistoryManager history;
    final historyData = json['history'];
    if (historyData is Map && historyData['mode'] == 'command') {
      // 新格式：命令列表
      final commandsJson = historyData['commands'] as List? ?? [];
      final commands = commandsJson
          .map((c) => BoardCommand.fromJson(c as Map<String, dynamic>))
          .toList();
      history = HistoryManager(
        initialBoard: initialBoard,
        commands: commands,
        currentIndex: common['historyIndex'],
      );
    } else {
      // 旧格式：快照列表（向后兼容）
      final historyJson = historyData as List? ?? [];
      final historyStates = historyJson
          .map((b) => boardFromJson(b as Map<String, dynamic>))
          .toList();
      history = HistoryManager.fromSnapshotList(
        historyStates,
        currentIndex: common['historyIndex'],
      );
    }

    // 构建统计服务
    final board = boardFromJson(json['board'] as Map<String, dynamic>);
    final totalMoves = historyData is Map
        ? (historyData['commands'] as List?)?.length ?? 0
        : (historyData as List?)?.length ?? 1;
    final stats = SessionStatistics(
      board: board,
      mistakes: common['mistakes'],
      totalMoves: totalMoves - 1,
      isCompleted: common['isCompleted'],
      elapsedTime: common['elapsedTime'],
    );

    return GameState<B>(
      board: board,
      initialBoard: initialBoard,
      solution: boardFromJson(json['solution'] as Map<String, dynamic>),
      difficulty: common['difficulty'],
      elapsedTime: common['elapsedTime'],
      mistakes: common['mistakes'],
      isCompleted: common['isCompleted'],
      history: history,
      stats: stats,
      startTime: common['startTime'],
      completionTime: common['completionTime'],
      isShowingSolution: common['isShowingSolution'],
      isMarkMode: common['isMarkMode'],
      isAutoMarkMode: common['isAutoMarkMode'],
      hintsUsed: common['hintsUsed'],
    );
  }

  final B board;  /// 当前游戏棋盘
  final B initialBoard; /// 初始谜题棋盘（用于重置游戏）
  final B solution; /// 完整答案棋盘（仅用于显示答案，不可编辑）
  final String difficulty; /// 游戏难度等级
  final int elapsedTime;  /// 已消耗时间（秒）
  final int mistakes;   /// 错误计数（违反数独规则的次数）
  final bool isCompleted; /// 是否完成游戏标志
  final HistoryManager history; /// 历史记录管理器
  final SessionStatistics stats; /// 游戏统计服务
  final DateTime? startTime;  /// 游戏开始时间
  final DateTime? completionTime; /// 游戏完成时间
  final bool isShowingSolution; /// 是否正在显示答案
  final bool isMarkMode; /// 是否处于标记模式
  final bool isAutoMarkMode; /// 是否处于自动标记模式
  final int hintsUsed; /// 使用提示的次数

  /// 显示答案前保存的棋盘（用于隐藏答案时恢复）
  final B? savedBoard;

  /// 复制游戏状态，允许覆盖指定属性
  GameState<B> copyWith({
    B? board,
    B? initialBoard,
    B? solution,
    String? difficulty,
    int? elapsedTime,
    int? mistakes,
    bool? isCompleted,
    HistoryManager? history,
    SessionStatistics? stats,
    DateTime? startTime,
    DateTime? completionTime,
    bool? isShowingSolution,
    bool? isMarkMode,
    bool? isAutoMarkMode,
    int? hintsUsed,
    B? savedBoard,
  }) => GameState<B>(
    board: board ?? this.board,
    initialBoard: initialBoard ?? this.initialBoard,
    solution: solution ?? this.solution,
    difficulty: difficulty ?? this.difficulty,
    elapsedTime: elapsedTime ?? this.elapsedTime,
    mistakes: mistakes ?? this.mistakes,
    isCompleted: isCompleted ?? this.isCompleted,
    history: history ?? this.history,
    stats: stats ?? this.stats,
    startTime: startTime ?? this.startTime,
    completionTime: completionTime ?? this.completionTime,
    isShowingSolution: isShowingSolution ?? this.isShowingSolution,
    isMarkMode: isMarkMode ?? this.isMarkMode,
    isAutoMarkMode: isAutoMarkMode ?? this.isAutoMarkMode,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    savedBoard: savedBoard ?? this.savedBoard,
  );

  /// 创建游戏状态实例
  GameState<B> createInstance({
    required B board,
    required B initialBoard,
    required B solution,
    required String difficulty,
    int elapsedTime = 0,
    int mistakes = 0,
    bool isCompleted = false,
    required HistoryManager history,
    required SessionStatistics stats,
    DateTime? startTime,
    DateTime? completionTime,
    bool isShowingSolution = false,
    bool isMarkMode = false,
    bool isAutoMarkMode = false,
    int hintsUsed = 0,
    B? savedBoard,
  }) => GameState<B>(
    board: board,
    initialBoard: initialBoard,
    solution: solution,
    difficulty: difficulty,
    elapsedTime: elapsedTime,
    mistakes: mistakes,
    isCompleted: isCompleted,
    history: history,
    stats: stats,
    startTime: startTime,
    completionTime: completionTime,
    isShowingSolution: isShowingSolution,
    isMarkMode: isMarkMode,
    isAutoMarkMode: isAutoMarkMode,
    hintsUsed: hintsUsed,
    savedBoard: savedBoard,
  );

  /// 获取游戏准确率
  double get accuracy => stats.accuracy;
  /// 获取游戏完成百分比
  double get completionPercentage => stats.completionPercentage;

  /// 获取选中的单元格
  Cell? getSelectedCell() {
    for (final row in board.cells) {
      for (final cell in row) {
        if (cell.isSelected) return cell;
      }
    }
    return null;
  }

  /// 转换为JSON格式（命令模式序列化）
  Map<String, dynamic> toJson() => {
    'board': board.toJson(),
    'initialBoard': initialBoard.toJson(),
    'solution': solution.toJson(),
    'difficulty': difficulty,
    'elapsedTime': elapsedTime,
    'mistakes': mistakes,
    'isCompleted': isCompleted,
    'history': {
      'mode': 'command',
      'commands': history.commands.map((cmd) => cmd.toJson()).toList(),
      'currentIndex': history.currentIndex,
    },
    'historyIndex': history.currentIndex,
    'startTime': startTime?.toIso8601String(),
    'completionTime': completionTime?.toIso8601String(),
    'isShowingSolution': isShowingSolution,
    'isMarkMode': isMarkMode,
    'isAutoMarkMode': isAutoMarkMode,
    'hintsUsed': hintsUsed,
  };

  /// 解析通用 JSON 字段的辅助方法
  static Map<String, dynamic> parseCommonJsonFields(Map<String, dynamic> json) {
    final historyIndex = json['historyIndex'] as int? ?? 0;

    // 兼容旧格式（history 是 List）和新格式（history 是 Map）
    int historyLength = 0;
    final historyData = json['history'];
    if (historyData is List) {
      historyLength = historyData.length;
    } else if (historyData is Map) {
      historyLength = (historyData['commands'] as List?)?.length ?? 0;
    }

    final safeHistoryIndex = historyIndex >= historyLength
        ? (historyLength <= 1 ? 0 : historyLength - 1)
        : historyIndex;

    return {
      'difficulty': json['difficulty'] as String? ?? 'medium',
      'elapsedTime': json['elapsedTime'] as int? ?? 0,
      'mistakes': json['mistakes'] as int? ?? 0,
      'isCompleted': json['isCompleted'] as bool? ?? false,
      'historyIndex': safeHistoryIndex,
      'startTime': json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      'completionTime': json['completionTime'] != null
          ? DateTime.parse(json['completionTime'] as String)
          : null,
      'isShowingSolution': json['isShowingSolution'] as bool? ?? false,
      'isMarkMode': json['isMarkMode'] as bool? ?? false,
      'isAutoMarkMode': json['isAutoMarkMode'] as bool? ?? false,
      'hintsUsed': json['hintsUsed'] as int? ?? 0,
    };
  }

  /// 获取用于调试的字符串表示（不依赖国际化）
  String toDebugString() {
    final timeStr = GameUtils.formatTime(elapsedTime);
    return 'GameState(difficulty: $difficulty, time: $timeStr, '
        'mistakes: $mistakes, completed: $isCompleted, history: ${history.length}, showingSolution: $isShowingSolution, '
        'isMarkMode: $isMarkMode, isAutoMarkMode: $isAutoMarkMode)';
  }

  @override
  String toString() => toDebugString();
}
