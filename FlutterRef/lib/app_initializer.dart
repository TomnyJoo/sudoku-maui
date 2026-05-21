import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/services/game_config.dart';
import 'package:sudoku/services/generation/template_manager.dart';
import 'package:sudoku/utils/app_logger.dart';

/// Summary: 初始化状态枚举
enum InitializationStatus {
  uninitialized, /// 未初始化
  initializing, /// 正在初始化
  completed, /// 初始化完成
  failed, /// 初始化失败
}

/// Summary: 应用初始化器
class AppInitializer {
  /// 当前初始化状态
  static InitializationStatus _status = InitializationStatus.uninitialized;
  
  /// 获取当前初始化状态
  static InitializationStatus get status => _status;
  
  /// 执行应用初始化，返回初始化是否成功
  static Future<bool> initialize() async {
    // 设置初始化状态为正在初始化
    _status = InitializationStatus.initializing;
    // 开始计时
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 初始化基础服务
      await _initializeBaseServices();
      // 2. 预加载资源
      await _preloadResources();
      // 3. 预加载模板
      await _preloadTemplates();
      
      // 设置初始化状态为完成
      _status = InitializationStatus.completed;
      // 停止计时
      stopwatch.stop();
      // 初始化成功
      return true;
    } catch (e) {
      // 初始化失败
      _status = InitializationStatus.failed;
      return false;
    }
  }
  
  /// 初始化基础服务
  static Future<void> _initializeBaseServices() async {
    // 确保 ServicesBinding 已初始化
    WidgetsFlutterBinding.ensureInitialized();
    // 初始化 SharedPreferences
    await SharedPreferences.getInstance();
    // 初始化游戏配置
    await GameConfig().initialize();
  }
  
  /// 预加载资源
  static Future<void> _preloadResources() async {
    // 需要预加载的资源列表
    final resources = [
      'assets/images/sudoku.svg',
      'assets/images/sudoku.png',
    ];
    
    // 并行加载所有资源
    await Future.wait(
      resources.map((path) => rootBundle.load(path).catchError((e) {
        // 加载失败时记录警告
        AppLogger.warning('预加载资源失败，资源路径: $path');
        return ByteData(0);
      })),
    );
  }
  
  /// 预加载模板
  static Future<void> _preloadTemplates() async {
    // 创建模板管理器
    final templateManager = TemplateManager();
    // 初始化模板管理器
    await templateManager.initialize();
  }
}
