import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/board_commands.dart';

/// 基于命令模式的历史记录管理器
///
/// 通过记录操作命令而非棋盘快照来实现撤销/重做。
/// 撤销时从 initialBoard 重放命令列表到目标索引。
class HistoryManager {
  HistoryManager({required this.initialBoard, List<BoardCommand>? commands, int? currentIndex})
    : _commands = commands ?? [],
      _currentIndex = currentIndex ?? -1;

  /// 从旧版快照列表创建（向后兼容反序列化）
  /// 旧存档加载后历史记录被重置，无法撤销到中间状态
  // ignore: avoid_unused_constructor_parameters
  factory HistoryManager.fromSnapshotList(List<Board> states, {int currentIndex = -1}) {
    final initialBoard = states.isNotEmpty ? states.first : throw ArgumentError('states不能为空');
    // 使用最后一个快照作为当前棋盘，但历史记录为空
    // 旧存档加载后可以正常游戏，但无法撤销到加载前的中间状态
    return HistoryManager(initialBoard: initialBoard);
  }

  final Board initialBoard;
  final List<BoardCommand> _commands;
  final int _currentIndex;

  static const int defaultMaxSize = 50;
  int maxSize = defaultMaxSize;

  /// 添加命令（截断后续命令）
  HistoryManager addCommand(BoardCommand cmd) {
    final newCommands = List<BoardCommand>.from(_commands);
    newCommands..removeRange(_currentIndex + 1, newCommands.length)..add(cmd);
    final newIndex = newCommands.length - 1;
    
    if (newCommands.length > maxSize) {
      final excessCount = newCommands.length - maxSize;
      var newInitialBoard = initialBoard;
      
      // 重放被删除的命令到初始棋盘，使initialBoard更新为删除这些命令后的状态
      for (int i = 0; i < excessCount; i++) {
        newInitialBoard = newCommands[i].execute(newInitialBoard);
      }
      
      // 从头部删除多余的命令
      final trimmedCommands = newCommands.sublist(excessCount);
      final trimmedIndex = newIndex - excessCount;
      
      return HistoryManager(
        initialBoard: newInitialBoard,
        commands: trimmedCommands,
        currentIndex: trimmedIndex,
      );
    }
    
    return HistoryManager(initialBoard: initialBoard, commands: newCommands, currentIndex: newIndex);
  }

  /// 撤销
  (HistoryManager, Board?) undo() {
    if (_currentIndex < 0) return (this, null);
    final newIndex = _currentIndex - 1;
    return (
      HistoryManager(initialBoard: initialBoard, commands: _commands, currentIndex: newIndex),
      _replay(newIndex),
    );
  }

  /// 重做
  (HistoryManager, Board?) redo() {
    if (_currentIndex >= _commands.length - 1) return (this, null);
    final newIndex = _currentIndex + 1;
    return (
      HistoryManager(initialBoard: initialBoard, commands: _commands, currentIndex: newIndex),
      _replay(newIndex),
    );
  }

  /// 重放命令到指定索引
  Board _replay(int upToIndex) {
    var board = initialBoard;
    for (int i = 0; i <= upToIndex; i++) {
      board = _commands[i].execute(board);
    }
    return board;
  }

  bool canUndo() => _currentIndex >= 0;
  bool canRedo() => _currentIndex < _commands.length - 1;
  int get length => _currentIndex + 1;

  /// 获取当前棋盘（通过重放命令）
  Board get currentBoard {
    if (_currentIndex < 0) return initialBoard;
    return _replay(_currentIndex);
  }

  /// 清空历史
  HistoryManager clear() => HistoryManager(initialBoard: initialBoard);

  /// 获取命令列表（用于序列化）
  List<BoardCommand> get commands => List.unmodifiable(_commands);
  int get currentIndex => _currentIndex;

  /// 生成快照列表（用于向后兼容序列化）
  List<Board> get states {
    final result = <Board>[initialBoard];
    var board = initialBoard;
    for (final cmd in _commands) {
      board = cmd.execute(board);
      result.add(board);
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HistoryManager) return false;
    return _currentIndex == other._currentIndex;
  }

  @override
  int get hashCode => _currentIndex.hashCode;
}
