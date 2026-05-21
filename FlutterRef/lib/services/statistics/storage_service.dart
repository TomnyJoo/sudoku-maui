import 'dart:collection';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/services/game_config.dart';
import 'package:sudoku/services/statistics/statistics.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 统计存储服务，负责统计数据的持久化
class StatisticsStorageService {
  // 缓存管理
  static final Map<String, Statistics> _cache = HashMap();
  static const int _maxCacheSize = 10;
  
  /// 添加到缓存
  static void _addToCache(String key, Statistics value) {
    if (_cache.length >= _maxCacheSize) {
      // 移除最早的项
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[key] = value;
  }
  
  /// 从缓存获取
  static Statistics? _getFromCache(String key) => _cache[key];
  
  /// 从缓存移除
  static void _removeFromCache(String key) {
    _cache.remove(key);
  }
  
  /// 清空缓存
  static void _clearCache() {
    _cache.clear();
  }
  
  /// 检查是否在缓存中
  static bool _isInCache(String key) => _cache.containsKey(key);

  /// 保存游戏统计
  static Future<void> saveStatistics(
    final Statistics statistics,
    final String key,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(statistics.toJson());
      await prefs.setString(key, json);
      
      // 更新缓存
      _addToCache(statistics.gameType, statistics);
    } catch (e) {
      AppLogger.error('保存统计数据失败', e);
      rethrow;
    }
  }

  /// 加载游戏统计
  static Future<Statistics?> loadStatistics(
    final String gameType,
    final String key,
  ) async {
    try {
      // 检查缓存
      if (_isInCache(gameType)) {
        return _getFromCache(gameType);
      }

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(key);

      if (json == null) {
        return null;
      }

      final statistics = Statistics.fromJson(jsonDecode(json), gameType);
      
      // 更新缓存
      _addToCache(gameType, statistics);
      
      return statistics;
    } catch (e) {
      AppLogger.error('加载统计数据失败', e);
      return null;
    }
  }

  /// 清除游戏统计
  static Future<void> clearStatistics(final String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      
      // 清除缓存
      _removeFromCache(_getGameTypeFromKey(key));
    } catch (e) {
      AppLogger.error('清除统计数据失败', e);
      rethrow;
    }
  }

  /// 清除所有游戏统计
  static Future<void> clearAllStatistics() async {
    try {
      final gameConfig = GameConfig();
      await gameConfig.initialize();
      
      // 从配置中获取所有游戏类型
      final gameConfigs = gameConfig.getAllGameConfigs();
      final gameTypes = gameConfigs?.keys.toList() ?? [];
      
      final prefs = await SharedPreferences.getInstance();
      for (final gameType in gameTypes) {
        final key = getStorageKey(gameType);
        await prefs.remove(key);
      }
      
      // 清除所有缓存
      _clearCache();
    } catch (e) {
      AppLogger.error('清除所有统计数据失败', e);
      rethrow;
    }
  }

  /// 导出所有游戏统计
  static Future<String> exportAllStatistics() async {
    try {
      final allStats = await getAllStatistics();
      final exportData = <String, dynamic>{
        'exportedAt': DateTime.now().toIso8601String(),
      };
      
      // 添加所有游戏类型的统计数据
      allStats.forEach((gameType, stats) {
        exportData[gameType] = stats.toJson();
      });
      
      final json = jsonEncode(exportData);
      return json;
    } catch (e) {
      AppLogger.error('导出所有统计数据失败', e);
      rethrow;
    }
  }

  /// 导入所有游戏统计
  static Future<void> importAllStatistics(final String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      
      // 排除导出时间字段，只处理游戏类型统计数据
      final gameTypeKeys = data.keys.where((key) => key != 'exportedAt');
      
      for (final gameType in gameTypeKeys) {
        try {
          final statsData = data[gameType];
          if (statsData != null) {
            final stats = Statistics.fromJson(statsData, gameType);
            final key = getStorageKey(gameType);
            await saveStatistics(stats, key);
          }
        } catch (e) {
          AppLogger.error('导入统计数据失败: $gameType', e);
          // 继续处理其他游戏类型
        }
      }
    } catch (e) {
      AppLogger.error('导入所有统计数据失败', e);
      rethrow;
    }
  }

  /// 获取所有游戏统计
  static Future<Map<String, Statistics>> getAllStatistics() async {
    final gameConfig = GameConfig();
    await gameConfig.initialize();
    
    // 从配置中获取所有游戏类型
    final gameConfigs = gameConfig.getAllGameConfigs();
    final gameTypes = gameConfigs?.keys.toList() ?? [];
    
    final statisticsMap = <String, Statistics>{};
    for (final gameType in gameTypes) {
      final key = getStorageKey(gameType);
      final stats = await loadStatistics(gameType, key);
      statisticsMap[gameType] = stats ?? Statistics.empty(gameType);
    }
    
    return statisticsMap;
  }

  /// 获取存储键
  static String getStorageKey(String gameType) => '${gameType}_game_statistics';

  /// 从存储键获取游戏类型，移除 '_game_statistics' 后缀
  static String _getGameTypeFromKey(String key) {
    if (key.endsWith('_game_statistics')) {
      return key.substring(0, key.length - '_game_statistics'.length);
    }
    return '';
  }

  /// 清除缓存
  static void clearCache() => _clearCache();

  /// 批量保存统计数据
  static Future<void> saveStatisticsBatch(
    final Map<String, Statistics> statisticsMap,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in statisticsMap.entries) {
        final key = getStorageKey(entry.key);
        final json = jsonEncode(entry.value.toJson());
        await prefs.setString(key, json);
        _addToCache(entry.key, entry.value);
      }
    } catch (e) {
      AppLogger.error('保存所有统计数据失败', e);
      rethrow;
    }
  }
} 
