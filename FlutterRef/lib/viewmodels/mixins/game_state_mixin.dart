import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

mixin GameStateMixin<B extends Board, T extends GameState<B>> on ChangeNotifier {
  GameState<B> get gameState;
  set gameState(GameState<B> value);

  GameTimer get gameTimer;
  GameService<B> get gameService;

  bool get isPlaying => gameState.startTime != null && !gameState.isCompleted;
  bool get isPaused => gameState.startTime != null && !gameState.isCompleted && gameTimer.isPaused;
  bool get isCompleted => gameState.isCompleted;
  Duration get elapsedTime => Duration(seconds: gameState.elapsedTime);
  bool get isMarkMode => gameState.isMarkMode;
  bool get isAutoMarkMode => gameState.isAutoMarkMode;
  bool get showSolution => gameState.isShowingSolution;
  double get completionPercentage => gameState.completionPercentage;
  int get errorCount => gameState.mistakes;

  Future<void> toggleMarkMode() async {
    gameState = gameState.copyWith(isMarkMode: !gameState.isMarkMode);
    notifyListeners();
  }

  Future<void> toggleAutoMarkMode() async {
    gameState = gameState.copyWith(isAutoMarkMode: !gameState.isAutoMarkMode);
    notifyListeners();
  }

  Future<void> toggleShowSolution() async {
    if (gameState.isShowingSolution) {
      // 隐藏答案：从 savedBoard 恢复棋盘
      final savedBoard = gameState.savedBoard;
      if (savedBoard != null) {
        gameState = gameService.hideSolution(gameState).copyWith(board: savedBoard, savedBoard: null);
      } else {
        gameState = gameService.hideSolution(gameState);
      }
    } else {
      // 显示答案：保存当前棋盘
      gameState = gameService.showSolution(gameState).copyWith(
        savedBoard: gameState.board,
      );
    }
    notifyListeners();
  }

  Future<void> resetGame() async {
    gameState = gameService.resetGameState(gameState);
    gameTimer..reset()
    ..start();
    notifyListeners();
  }
}
