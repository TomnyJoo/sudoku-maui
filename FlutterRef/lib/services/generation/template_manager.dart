import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/utils/app_logger.dart';

/// Summary: 模板数据类
class GameTemplate {
  GameTemplate({
    this.puzzleData, /// 谜题数据
    required this.solutionData, /// 答案数据
    DateTime? createdAt, /// 创建时间
    this.regionMatrix, /// 区域数据（锯齿游戏使用）
  }) : createdAt = createdAt ?? DateTime.now();
  final List<List<int?>>? puzzleData;
  final List<List<int>> solutionData;
  final DateTime createdAt;
  final List<List<int>>? regionMatrix;
}

/// Summary: 模板管理器，负责模板的预加载和管理，使用静态变量缓存
class TemplateManager {
  factory TemplateManager() => _instance;
  TemplateManager._internal();
  static final TemplateManager _instance = TemplateManager._internal();
  final Random _random = Random();

  // 静态缓存
  static List<String>? _rrn17Solutions; /// rrn17 答案模板  
  static List<List<List<int>>>? _jigsawRegions; /// 锯齿数独区域模板
  /// 是否初始化
  static bool _initialized = false;

  /// 获取模板加载状态
  TemplateLoadStatus get loadStatus => TemplateLoadStatus(
    rrn17Loaded: _rrn17Solutions != null && _rrn17Solutions!.isNotEmpty,
    jigsawLoaded: _jigsawRegions != null && _jigsawRegions!.isNotEmpty,
  );

  /// 初始化模板管理器（预加载所有模板），应该在应用启动时调用
  Future<void> initialize() async {
    if (_initialized) return;

    // 并行加载所有模板
    await Future.wait([
      _loadRrn17SolutionsInternal(),
      _loadJigsawRegionsInternal(),
    ]);

    _initialized = true;
  }

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  /// 加载 rrn17 答案模板并应用随机数字替换，返回包含交换后答案的 GameTemplate
  Future<GameTemplate?> loadRrn17Solutions() async {
    if (_rrn17Solutions == null || _rrn17Solutions!.isEmpty) return null;

    final solutions = _rrn17Solutions!;
    final randomSolution = solutions[_random.nextInt(solutions.length)];

    final solutionData = List.generate(
      9,
      (row) => List.generate(9, (col) {
        final char = randomSolution[row * 9 + col];
        final value = int.tryParse(char);
        return (value != null && value >= 1 && value <= 9) ? value : 0;
      }),
    );

    final substitutionMap = _generateNumberSubstitutionMap();
    final substitutedData = solutionData
        .map((row) => row.map((value) => substitutionMap[value]!).toList())
        .toList();

    return GameTemplate(
      solutionData: substitutedData,
    );
  }

  /// 加载锯齿数独区域模板，返回随机选择的区域矩阵
  Future<List<List<int>>?> loadJigsawRegions() async {
    if (_jigsawRegions == null || _jigsawRegions!.isEmpty) return null;
    return _jigsawRegions![_random.nextInt(_jigsawRegions!.length)];
  }

  /// 内部加载 rrn17 答案模板
  Future<void> _loadRrn17SolutionsInternal() async {
    if (_rrn17Solutions == null) {
      const int maxRetries = AppConstants.templateLoadMaxRetries;
      int attempts = 0;
      
      while (attempts < maxRetries) {
        try {
          final content = await rootBundle.loadString(
            'assets/templates/rrn17_solutions.json',
          );
          final jsonData = json.decode(content) as Map<String, dynamic>;
          final solutions = jsonData['solutions'] as List?;
          if (solutions != null) {
            _rrn17Solutions = solutions.cast<String>();
            return;
          }
        } catch (e) {
          AppLogger.warning('加载rrn17 答案模板失败 (尝试 ${attempts + 1}): $e');
          attempts++;
          if (attempts < maxRetries) {
            await Future.delayed(AppConstants.templateLoadRetryDelay);
          }
        }
      }
    }
  }

  /// 内部加载锯齿数独区域模板
  Future<void> _loadJigsawRegionsInternal() async {
    if (_jigsawRegions == null) {
      const int maxRetries = AppConstants.templateLoadMaxRetries;
      int attempts = 0;
      
      while (attempts < maxRetries) {
        try {
          final content = await rootBundle.loadString(
            'assets/templates/regions.json',
          );
          final jsonData = json.decode(content) as Map<String, dynamic>;

          final allRegions = <List<List<int>>>[];

          if (jsonData.containsKey('templates')) {
            final templates = jsonData['templates'] as List;
            for (final template in templates) {
              final templateMap = template as Map<String, dynamic>;
              if (templateMap.containsKey('regionMatrix')) {
                final regionMatrix = (templateMap['regionMatrix'] as List)
                    .map((row) => (row as List).map((v) => v as int).toList())
                    .toList();
                allRegions.add(regionMatrix);
              }
            }
          } else {
            for (final entry in jsonData.entries) {
              if (entry.value is List) {
                final regionMatrix = (entry.value as List)
                    .map((row) => (row as List).map((v) => v as int).toList())
                    .toList();
                allRegions.add(regionMatrix);
              }
            }
          }

          _jigsawRegions = allRegions;
          return;
        } catch (e) {
          AppLogger.warning('加载锯齿数独区域模板失败 (尝试 ${attempts + 1}): $e');
          attempts++;
          if (attempts < maxRetries) {
            await Future.delayed(AppConstants.templateLoadRetryDelay);
          }
        }
      }
    }
  }

  /// 生成1-9的随机替换映射表
  Map<int, int> _generateNumberSubstitutionMap() {
    final numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
    return {
      1: numbers[0],
      2: numbers[1],
      3: numbers[2],
      4: numbers[3],
      5: numbers[4],
      6: numbers[5],
      7: numbers[6],
      8: numbers[7],
      9: numbers[8],
    };
  }

  /// 清除缓存（用于测试）
  void clearCache() {
    _rrn17Solutions = null;
    _jigsawRegions = null;
    _initialized = false;
  }
}

/// 模板加载状态
class TemplateLoadStatus {
  
  const TemplateLoadStatus({
    required this.rrn17Loaded,
    required this.jigsawLoaded,
  });
  final bool rrn17Loaded;
  final bool jigsawLoaded;
  
  bool get allLoaded => rrn17Loaded && jigsawLoaded;
}
