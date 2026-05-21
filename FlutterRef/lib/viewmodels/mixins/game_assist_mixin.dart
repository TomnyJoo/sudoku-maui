import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

mixin GameAssistMixin<B extends Board, T extends GameState<B>> on ChangeNotifier {
  GameState<B> get gameState;
  set gameState(GameState<B> value);

  GameService<B> get gameService;
  bool get isPlaying;
  bool get useAdvancedStrategy;
  AppSettings? get settings;

  /// 最后一次提示消息（由视图层监听并显示 SnackBar）
  String? lastHintMessage;

  Timer? autoMarkDebounceTimer;
  bool isCalculatingCandidates = false;

  Future<void> autoMarkCandidates({List<int>? visibleSubBoards}) async {
    autoMarkDebounceTimer?.cancel();

    autoMarkDebounceTimer = Timer(AppConstants.autoMarkDebounceDelay, () async {
      if (isCalculatingCandidates) {
        return;
      }

      try {
        isCalculatingCandidates = true;

        if (!hasListeners) {
          return;
        }

        // 计算候选数
        final calculator = CandidateCalculator(gameState.board);
        final candidates = gameState.board is SamuraiBoard && visibleSubBoards != null
            ? calculator.computeSamuraiCandidates(
                visibleSubBoards,
                useAdvancedStrategies: useAdvancedStrategy,
              )
            : calculator.computeAllCandidates(
                useAdvancedStrategies: useAdvancedStrategy,
              );

        // 更新棋盘候选数
        var newBoard = gameState.board;

        // 如果是武士数独且有可见子棋盘，只更新可见子棋盘的候选数
        if (gameState.board is SamuraiBoard && visibleSubBoards != null) {
          for (final subBoardIndex in visibleSubBoards) {
            final (startRow, startCol) = SamuraiBoard.subGridOffsets[subBoardIndex];
            for (int row = startRow; row < startRow + 9; row++) {
              for (int col = startCol; col < startCol + 9; col++) {
                final key = '$row,$col';
                if (candidates.containsKey(key)) {
                  newBoard = newBoard.setCellCandidates(row, col, candidates[key]!) as B;
                }
              }
            }
          }
        } else {
          // 否则更新整个棋盘的候选数
          for (int row = 0; row < newBoard.size; row++) {
            for (int col = 0; col < newBoard.size; col++) {
              final key = '$row,$col';
              if (candidates.containsKey(key)) {
                newBoard = newBoard.setCellCandidates(row, col, candidates[key]!) as B;
              }
            }
          }
        }

        gameState = gameService.updateBoard(gameState, newBoard);
        notifyListeners();
      } finally {
        isCalculatingCandidates = false;
      }
    });
  }

  Future<void> clearAllCandidates() async {
    var newBoard = gameState.board;

    for (int row = 0; row < gameState.board.size; row++) {
      for (int col = 0; col < gameState.board.size; col++) {
        final cell = gameState.board.getCell(row, col);
        if (!cell.isFixed && cell.value == null) {
          newBoard = newBoard.setCellCandidates(row, col, <int>{}) as B;
        }
      }
    }

    gameState = gameService.updateBoard(gameState, newBoard);
    notifyListeners();
  }

  void disposeAutoMarkTimer() {
    autoMarkDebounceTimer?.cancel();
  }

  /// 提示 - 直接填入答案
  /// 设置 lastHintMessage 供视图层监听并显示 SnackBar
  Future<void> hint() async {
    final selectedCell = gameState.getSelectedCell();

    // 优先处理选中的单元格
    if (selectedCell != null && selectedCell.value == null && !selectedCell.isFixed) {
      final solutionValue = gameState.solution.getCell(selectedCell.row, selectedCell.col).value;
      if (solutionValue != null) {
        // 选中单元格
        final newBoard = gameState.board.selectCell(selectedCell.row, selectedCell.col);
        gameState = gameService.updateBoard(gameState, newBoard as B);

        // 填入答案
        await setCellValueForHint(selectedCell.row, selectedCell.col, solutionValue);
        return;
      }
    }

    // 查找第一个空单元格
    for (int row = 0; row < gameState.board.size; row++) {
      for (int col = 0; col < gameState.board.size; col++) {
        final cell = gameState.board.getCell(row, col);
        if (cell.value == null && !cell.isFixed) {
          final solutionValue = gameState.solution.getCell(row, col).value;
          if (solutionValue != null) {
            // 选中单元格
            final newBoard = gameState.board.selectCell(row, col);
            gameState = gameService.updateBoard(gameState, newBoard as B);

            // 填入答案
            await setCellValueForHint(row, col, solutionValue);
            return;
          }
        }
      }
    }

    // 设置无可用提示的消息，由视图层监听并显示
    lastHintMessage = 'noHintAvailable';
  }

  // 由使用此mixin的类实现
  Future<void> setCellValueForHint(int row, int col, int value);
}
