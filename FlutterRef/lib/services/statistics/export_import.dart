import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sudoku/services/statistics/statistics.dart';
import 'package:sudoku/services/statistics/storage_service.dart';

class StatisticsExportImport {
  static const String _exportFileName = 'sudoku_statistics.json';

  /// 导出统计数据
  static Future<void> exportStatistics(BuildContext context) async {
    try {
      // 获取所有统计数据
      final allStatistics = await StatisticsStorageService.getAllStatistics();
      
      // 转换为可序列化的格式
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'statistics': allStatistics,
      };
      
      // 转换为JSON字符串
      final jsonString = json.encode(exportData);
      
      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$_exportFileName');
      await file.writeAsString(jsonString);
      
      // 分享文件
      await Share.shareXFiles([XFile(file.path)], text: '数独游戏统计数据');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  /// 导入统计数据
  static Future<bool> importStatistics(BuildContext context, File file) async {
    try {
      // 读取文件内容
      final jsonString = await file.readAsString();
      
      // 解析JSON
      final data = json.decode(jsonString);
      
      // 验证数据格式
      if (data is! Map || !data.containsKey('statistics')) {
        throw Exception('无效的文件格式');
      }
      
      // 转换为统计数据
      final Map<String, dynamic> statsData = data['statistics'];
      final Map<String, Statistics> statistics = {};
      
      statsData.forEach((key, value) {
        statistics[key] = Statistics.fromJson(value, key);
      });
      
      // 保存数据
      for (final entry in statistics.entries) {
        final storageKey = StatisticsStorageService.getStorageKey(entry.key);
        await StatisticsStorageService.saveStatistics(entry.value, storageKey);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功')),
        );
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
      return false;
    }
  }

  /// 导出统计数据为字符串（用于备份）
  static Future<String> exportStatisticsToString() async {
    final allStatistics = await StatisticsStorageService.getAllStatistics();
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'statistics': allStatistics,
    };
    return json.encode(exportData);
  }

  /// 从字符串导入统计数据（用于恢复）
  static Future<bool> importStatisticsFromString(String jsonString) async {
    try {
      final data = json.decode(jsonString);
      if (data is! Map || !data.containsKey('statistics')) {
        return false;
      }
      
      final Map<String, dynamic> statsData = data['statistics'];
      final Map<String, Statistics> statistics = {};
      
      statsData.forEach((key, value) {
        statistics[key] = Statistics.fromJson(value, key);
      });
      
      for (final entry in statistics.entries) {
        final storageKey = StatisticsStorageService.getStorageKey(entry.key);
        await StatisticsStorageService.saveStatistics(entry.value, storageKey);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
