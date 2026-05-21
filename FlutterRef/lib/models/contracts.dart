import 'package:flutter/material.dart';
import 'package:sudoku/models/board.dart';

/// 游戏专属动作描述
class GameSpecificAction {
  const GameSpecificAction({
    required this.icon,
    required this.labelKey,
    required this.action,
    this.isToggle = false,
  });

  final IconData icon;
  final String labelKey;
  final void Function(Board board) action;
  final bool isToggle;
}

/// 提示结果
class HintResult {
  const HintResult({
    required this.row,
    required this.col,
    required this.value,
    this.message,
  });

  final int row;
  final int col;
  final int value;
  final String? message;
}

/// 数独游戏逻辑抽象基类
/// 所有变体（标准、杀手、锯齿、对角线、窗口、武士等）均需实现此接口
abstract class BaseSudokuGame {
  /// 游戏唯一标识（对应配置中的 id）
  String get gameId;

  /// 棋盘行数
  int get boardRows;

  /// 棋盘列数
  int get boardCols;

  /// 区域类型描述
  String get regionType;

  /// 验证在指定位置填入某值是否违反基本规则
  bool isValidMove(Board board, int row, int col, int value);

  /// 判断当前盘面是否已完成并正确
  bool isPuzzleSolved(Board board);

  /// 获取提示
  HintResult? getHint(Board board, {int? row, int? col});

  /// 自动计算所有空白格的候选数
  void autoCandidates(Board board, {bool advanced = false});

  /// 用于难度评估的启发式方法（可选实现）
  double evaluateDifficulty(Board board) => 0.0;

  /// 获取游戏专属的特殊控制按钮列表
  List<GameSpecificAction> getSpecificActions() => [];
}
