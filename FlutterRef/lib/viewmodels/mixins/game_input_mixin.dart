import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

/// 游戏输入处理 Mixin
///
/// 处理用户输入操作，包括单元格选择、值设置、候选数切换等。
/// 注意：内部方法不调用 notifyListeners()，由调用者统一负责通知。
mixin GameInputMixin<B extends Board, T extends GameState<B>> on ChangeNotifier {
  GameState<B> get gameState;
  set gameState(GameState<B> value);
  GameService<B> get gameService;
  bool get isPlaying;

  /// 选择单元格
  void selectCell(final int row, final int col) => handleCellTap(row, col);

  /// 处理单元格选择
  void handleCellSelection(final int row, final int col) {
    if (!isPlaying) return;
    final newBoard = gameState.board.selectCell(row, col);
    gameState = gameService.updateBoard(gameState, newBoard as B);
  }

  Future<void> setCellValueInternal(
    int row,
    int col,
    int? value,
  ) async {
    final newState = gameService.setCellValue(
      gameState: gameState,
      row: row,
      col: col,
      value: value,
      isMarkMode: gameState.isMarkMode,
    );
    gameState = newState;
    // 不调用 notifyListeners()，由调用者负责
  }

  Future<void> toggleCandidateInternal(
    int row,
    int col,
    int candidate,
  ) async {
    final newState = gameService.setCellValue(
      gameState: gameState,
      row: row,
      col: col,
      value: candidate,
      isMarkMode: true,
    );
    gameState = newState;
    // 不调用 notifyListeners()，由调用者负责
  }

  Future<void> clearCellInternal(
    int row,
    int col,
  ) async {
    final cell = gameState.board.getCell(row, col);
    if (cell.isFixed) return;

    if (cell.value != null) {
      await setCellValueInternal(row, col, null);
    } else if (cell.candidates.isNotEmpty) {
      // 使用命令模式清除候选数
      final command = ClearCandidatesCommand(row: row, col: col);
      gameState = gameService.updateBoardWithCommand(gameState, command);
    }
    // 不调用 notifyListeners()，由调用者负责
  }

  /// 清除所有错误标记
  void clearAllErrors() {
    final newBoard = gameService.clearAllErrors(gameState);
    gameState = gameService.updateBoard(gameState, newBoard);
  }

  Future<void> handleCellTap(
    int row,
    int col,
  ) async {
    final cell = gameState.board.getCell(row, col);

    // 如果点击的是固定单元格，只更新选中状态
    if (cell.isFixed) {
      final newBoard = gameState.board.selectCell(row, col);
      gameState = gameService.updateBoard(gameState, newBoard as B);
      return;
    }

    // 如果点击的是已选中的单元格，取消选中
    if (cell.isSelected) {
      final newBoard = gameState.board.selectCell(-1, -1);
      gameState = gameService.updateBoard(gameState, newBoard as B);
      return;
    }

    // 否则选中该单元格
    final newBoard = gameState.board.selectCell(row, col);
    gameState = gameService.updateBoard(gameState, newBoard as B);
  }
}
