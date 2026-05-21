import 'package:sudoku/models/board.dart';

/// 棋盘操作命令接口
abstract class BoardCommand {
  /// 命令类型标识
  String get type;

  /// 执行命令，返回新棋盘
  Board execute(Board board);

  /// 序列化为 JSON
  Map<String, dynamic> toJson();

  /// 从 JSON 反序列化
  static BoardCommand fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'setValue':
        return SetValueCommand._fromJson(json);
      case 'toggleCandidate':
        return ToggleCandidateCommand._fromJson(json);
      case 'clearCell':
        return ClearCellCommand._fromJson(json);
      case 'clearCandidates':
        return ClearCandidatesCommand._fromJson(json);
      default:
        return SetValueCommand._fromJson(json);
    }
  }
}

/// 设置单元格值命令（含错误标记）
class SetValueCommand extends BoardCommand {
  SetValueCommand({
    required this.row,
    required this.col,
    this.value,
    this.isError = false,
  });

  SetValueCommand._fromJson(Map<String, dynamic> json)
    : row = json['row'] as int,
      col = json['col'] as int,
      value = json['value'] as int?,
      isError = json['isError'] as bool? ?? false;

  final int row;
  final int col;
  final int? value;
  final bool isError;

  @override
  String get type => 'setValue';

  @override
  Board execute(Board board) {
    var newBoard = board.setCellValue(row, col, value);
    if (isError) {
      newBoard = newBoard.setCellError(row, col, true);
    }
    return newBoard;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'row': row,
    'col': col,
    'value': value,
    'isError': isError,
  };
}

/// 切换候选数命令
class ToggleCandidateCommand extends BoardCommand {
  ToggleCandidateCommand({required this.row, required this.col, required this.candidate});

  ToggleCandidateCommand._fromJson(Map<String, dynamic> json)
    : row = json['row'] as int,
      col = json['col'] as int,
      candidate = json['candidate'] as int;

  final int row;
  final int col;
  final int candidate;

  @override
  String get type => 'toggleCandidate';

  @override
  Board execute(Board board) => board.toggleCellCandidate(row, col, candidate);

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'row': row,
    'col': col,
    'candidate': candidate,
  };
}

/// 清除单元格命令
class ClearCellCommand extends BoardCommand {
  ClearCellCommand({required this.row, required this.col});

  ClearCellCommand._fromJson(Map<String, dynamic> json)
    : row = json['row'] as int,
      col = json['col'] as int;

  final int row;
  final int col;

  @override
  String get type => 'clearCell';

  @override
  Board execute(Board board) => board.clearCell(row, col);

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'row': row,
    'col': col,
  };
}

/// 清除候选数命令
class ClearCandidatesCommand extends BoardCommand {
  ClearCandidatesCommand({required this.row, required this.col});

  ClearCandidatesCommand._fromJson(Map<String, dynamic> json)
    : row = json['row'] as int,
      col = json['col'] as int;

  final int row;
  final int col;

  @override
  String get type => 'clearCandidates';

  @override
  Board execute(Board board) => board.setCellCandidates(row, col, <int>{});

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'row': row,
    'col': col,
  };
}
