import 'package:flutter/material.dart';
import 'package:sudoku/models/game_type.dart';
import 'package:sudoku/services/game_config.dart';
import 'package:sudoku/services/game_factory.dart';
import 'package:sudoku/services/game_storage_service.dart';

/// 首页 ViewModel
///
/// 管理首页状态：当前选中的游戏类型、页面导航等
class HomeViewModel extends ChangeNotifier {
  HomeViewModel();

  int _currentPage = 0;
  String _selectedGameName = '';

  /// 当前页面索引（0=游戏类型列表, 1=难度选择）
  int get currentPage => _currentPage;

  /// 当前选中的游戏名称
  String get selectedGameName => _selectedGameName;

  /// 是否显示自定义游戏按钮
  bool showCustomGame(String gameType) {
    final type = GameType.values.firstWhere(
      (t) => t.name == gameType,
      orElse: () => GameType.standard,
    );
    return GameConfig().showCustomGame(type);
  }

  /// 是否有保存的游戏
  Future<bool> hasSavedGame(String gameType) async =>
      GameStorageService.hasSavedGame('${gameType}_current');

  /// 切换到难度选择页面
  void navigateToDifficulty(String gameName) {
    _selectedGameName = gameName;
    _currentPage = 1;
    notifyListeners();
  }

  /// 返回游戏类型列表
  void backToGames() {
    _currentPage = 0;
    notifyListeners();
  }

  /// 获取游戏类型列表
  List<Map<String, dynamic>> getGameTypes() {
    final allConfigs = GameConfig().getAllGameConfigs();
    if (allConfigs == null) return [];
    return allConfigs.entries
        .map((entry) => <String, dynamic>{'id': entry.key, ...entry.value})
        .toList();
  }

  /// 获取指定游戏类型的难度列表
  List<String> getDifficultyLevels(String gameType) =>
      GameFactory.getDifficultyLevels(
        GameType.values.firstWhere(
            (t) => t.name == gameType, orElse: () => GameType.standard),
      );
}
