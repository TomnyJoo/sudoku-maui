import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

mixin GamePersistenceMixin<B extends Board, T extends GameState<B>> on ChangeNotifier {
  GameState<B> get gameState;
  set gameState(GameState<B> value);
  GameService<B> get gameService;
  
  Timer? saveDebounceTimer;
  
  Future<void> saveGameInternal() async {
    try {
      if (gameState.isCompleted) return;
      if (gameState.startTime == null) return;

      saveDebounceTimer?.cancel();
      saveDebounceTimer = Timer(const Duration(seconds: 1), () async {
        try {
          if (_isValidGameState(gameState)) {
            await gameService.saveGameState(gameState);
          }
        } catch (e) {
          _handleError('保存游戏失败', e);
        }
      });
    } catch (e) {
      _handleError('保存游戏失败', e);
    }
  }
  
  void saveGameFireAndForget() {
    try {
      if (gameState.isCompleted) return;
      if (gameState.startTime == null) return;
      
      if (_isValidGameState(gameState)) {
        gameService.saveGameState(gameState);
      }
    } catch (e) {
      _handleError('保存游戏失败', e);
    }
  }
  
  Future<void> loadGameInternal() async {
    try {
      final saveKey = '${gameService.gameType}_current';
      final savedState = await gameService.loadGameState(saveKey);
      
      if (savedState != null &&
          !savedState.isCompleted &&
          savedState.startTime != null) {
        gameState = savedState;
        notifyListeners();
      }
    } on RangeError catch (e) {
      _handleError('加载游戏失败：历史记录索引超出范围', e);
      await gameService.clearSavedGame('${gameService.gameType}_current');
    } catch (e) {
      _handleError('加载游戏失败', e);
    }
  }
  
  bool _isValidGameState(GameState<B> state) => GameValidator.isValidGameState(state);
  
  void _handleError(String message, dynamic error) {
    AppLogger.error(message, error, StackTrace.current);
  }
  
  void disposeSaveTimer() {
    saveDebounceTimer?.cancel();
  }
}
