import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

mixin GameLifecycleMixin<B extends Board, T extends GameState<B>> on ChangeNotifier {
  GameState<B> get gameState;
  set gameState(GameState<B> value);

  GameTimer get gameTimer;
  GameService<B> get gameService;

  bool get isCancelled;
  set isCancelled(bool value);

  bool get isLoading;
  set isLoading(bool value);

  GenerationStage get generationStage;
  set generationStage(GenerationStage value);

  AppSettings? get settings;

  /// 加载指定难度的最佳成绩（子类实现）
  Future<void> loadBestScore([String? difficulty]);

  /// isPlaying 和 isPaused 由使用此 mixin 的类提供
  bool get isPlaying;
  bool get isPaused;

  void updateGenerationStage(GenerationStage stage) {
    generationStage = stage;
    notifyListeners();
  }

  Future<void> startNewGameInternal(
    Difficulty difficulty, {
    required Future<void> Function(Difficulty) generateNewGame,
    required Future<void> Function() resetGameState,
  }) async {
    isCancelled = false;
    isLoading = true;
    generationStage = GenerationStage.generatingSolution;
    gameState = gameState.copyWith(isCompleted: false);
    notifyListeners();

    try {
      await resetGameState();
      gameTimer.reset();
      gameState = gameState.copyWith(
        mistakes: 0,
        elapsedTime: 0,
        isCompleted: false,
        difficulty: difficulty.name,
      );

      // 并行：生成游戏 + 加载最佳成绩（difficulty 直接传入，不依赖 gameState）
      await Future.wait([
        generateNewGame(difficulty),
        loadBestScore(difficulty.name),
      ]);

      gameState = gameState.copyWith(startTime: DateTime.now());
      gameTimer.start();

      // 确保在主线程中播放音效
      if (PlatformDispatcher.instance.implicitView != null) {
        final audioManager = AudioManager();
        await audioManager.playStartSound();
      }
    } catch (e) {
      await resetGameState();
      gameTimer.reset();
      gameState = gameState.copyWith(
        mistakes: 0,
        elapsedTime: 0,
        isCompleted: false,
      );
      notifyListeners();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pauseGameInternal({bool notify = true}) async {
    if (isPlaying) {
      gameTimer.pause();
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> resumeGameInternal() async {
    if (isPaused) {
      gameTimer.resume();
      notifyListeners();
    }
  }

  void cancelGameGenerationInternal() {
    isCancelled = true;
  }

  bool isValidGameState(GameState<B> state) => GameValidator.isValidGameState(state);
}
