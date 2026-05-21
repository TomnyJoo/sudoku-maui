import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/exceptions/error_handler.dart';
import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/game_state.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 保存的游戏信息
class SavedGameInfo {
  SavedGameInfo({
    required this.gameType,
    required this.saveKey,
    required this.timestamp,
    required this.difficulty,
  });

  factory SavedGameInfo.fromJson(Map<String, dynamic> json) => SavedGameInfo(
        gameType: json['gameType'] as String,
        saveKey: json['saveKey'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        difficulty: json['difficulty'] as String,
      );

  final String gameType;
  final String saveKey;
  final DateTime timestamp;
  final String difficulty;

  Map<String, dynamic> toJson() => {
        'gameType': gameType,
        'saveKey': saveKey,
        'timestamp': timestamp.toIso8601String(),
        'difficulty': difficulty,
      };
}

/// 统一游戏存储服务
///
/// 整合游戏状态的序列化/反序列化、保存管理、查询功能。
/// 通过 Board.fromJson 工厂函数支持所有游戏类型的序列化/反序列化。
class GameStorageService {
  // ==================== 游戏状态读写 ====================

  /// 保存游戏状态
  static Future<void> saveGameState(GameState state, String saveKey) async {
    await ErrorHandler().handleAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(state.toJson());
      await prefs.setString(saveKey, stateJson);
    }, operationName: '保存游戏状态');
  }

  /// 加载游戏状态（泛型，支持具体 Board 子类型）
  static Future<GameState<B>?> loadGameState<B extends Board>(
    String saveKey,
    B Function(Map<String, dynamic>) boardFromJson,
  ) async => ErrorHandler().handleAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        final stateJson = prefs.getString(saveKey);
        if (stateJson == null) return null;
        try {
          final stateData = jsonDecode(stateJson);
          return GameState.fromJson(stateData, boardFromJson);
        } catch (e) {
          AppLogger.error('反序列化游戏状态失败: $saveKey', e, StackTrace.current);
          return null;
        }
      }, operationName: '加载游戏状态');

  /// 清除游戏状态
  static Future<void> clearGameState(String saveKey) async {
    await ErrorHandler().handleAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(saveKey);
    }, operationName: '清理保存数据');
  }

  /// 检查是否有保存的游戏
  static Future<bool> hasSavedGame(String saveKey) async => ErrorHandler().handleAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(saveKey);
    }, operationName: '检查是否有保存的游戏');

  // ==================== 保存游戏管理 ====================

  /// 获取所有保存的游戏原始数据
  static Future<List<Map<String, dynamic>>> getAllSavedGames() async => ErrorHandler().handleAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final games = <Map<String, dynamic>>[];
      for (final key in keys) {
        if (key.contains(AppConstants.currentGameKeySuffix) || key.contains(AppConstants.savedGameKeySuffix)) {
          final stateJson = prefs.getString(key);
          if (stateJson != null) {
            games.add({'key': key, 'data': jsonDecode(stateJson)});
          }
        }
      }
      return games;
    }, operationName: '获取所有保存的游戏');

  /// 获取所有保存的游戏信息列表（按时间倒序）
  static Future<List<SavedGameInfo>> getSavedGameInfos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final savedGames = <SavedGameInfo>[];

      for (final key in keys) {
        if (key.endsWith('_current')) {
          final gameType = key.replaceAll('_current', '');
          final stateJson = prefs.getString(key);
          if (stateJson != null) {
            try {
              final stateData = jsonDecode(stateJson);
              if (_isValidGameState(stateData)) {
                savedGames.add(SavedGameInfo(
                  gameType: gameType,
                  saveKey: key,
                  timestamp: stateData['startTime'] != null ? DateTime.parse(stateData['startTime'] as String) : DateTime.now(),
                  difficulty: stateData['difficulty'] ?? 'unknown',
                ));
              }
            } catch (_) {}
          }
        }
      }

      savedGames.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return savedGames;
    } catch (_) {
      return [];
    }
  }

  /// 检查是否有任何保存的游戏
  static Future<bool> hasAnySavedGames() async {
    final games = await getSavedGameInfos();
    return games.isNotEmpty;
  }

  /// 清除所有保存的游戏
  static Future<void> clearAllSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.endsWith('_current')) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  /// 检查游戏状态是否有效
  static bool _isValidGameState(Map<String, dynamic> stateData) {
    if (stateData['startTime'] == null) return false;
    if (stateData['isCompleted'] == true) return false;
    if (stateData['board'] == null) return false;
    final boardData = stateData['board'] as Map<String, dynamic>;
    if (boardData['cells'] == null) return false;
    if (boardData['cells'] is List) {
      final cells = boardData['cells'] as List;
      if (cells.isEmpty) return false;
    }
    return true;
  }
}
