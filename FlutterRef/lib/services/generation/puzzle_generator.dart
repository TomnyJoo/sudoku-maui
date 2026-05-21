import 'package:sudoku/index.dart';

/// 游戏生成服务
///
/// 负责游戏生成的统一入口，使用 Isolate 在后台线程执行
class PuzzleGenerator {
  /// 生成游戏（在 Isolate 中执行）
  ///
  /// [gameType] - 游戏类型
  /// [size] - 棋盘大小
  /// [difficulty] - 难度
  /// [onStageUpdate] - 生成阶段更新回调（在主线程中调用，提供基本的阶段更新）
  /// [isCancelled] - 取消回调（注意：在 Isolate 中无法实时检查，仅在开始前检查）
  static Future<GenerationResult> generateGame({
    required GameType gameType,
    required int size,
    required Difficulty difficulty,
    Function(GenerationStage)? onStageUpdate,
    bool Function()? isCancelled,
  }) async {
    // 在开始前检查是否已取消
    if (isCancelled?.call() ?? false) {
      throw GameGenerationCancelledException();
    }

    // 通知开始生成
    onStageUpdate?.call(GenerationStage.initializing);

    // 对于需要模板的游戏类型，先在主线程加载模板
    Map<String, dynamic>? templateData;
    bool templateLoaded = false;

    try {
      final templateManager = TemplateManager();
      // 检查模板加载状态，直接从缓存加载，不调用 initialize
      final loadStatus = templateManager.loadStatus;

      // 只有三种游戏类型需要加载模板：
      // 1. 锯齿数独 - 需要区域模板
      // 2. 杀手数独 - 需要笼子模板 + rrn17 模板
      // 3. 标准数独 - 需要 rrn17 模板
      // 其他类型（对角线、窗口、武士、自定义）不需要模板，直接使用 DLX 求解器生成
      if (gameType == GameType.jigsaw) {
        if (loadStatus.jigsawLoaded) {
          final regionMatrix = await templateManager.loadJigsawRegions();
          if (regionMatrix != null) {
            templateData = {'regionMatrix': regionMatrix};
            templateLoaded = true;
          }
        }
      } else if (gameType == GameType.killer) {
        // 杀手数独：rrn17 模板用于加速终盘生成，笼子由生成器动态划分
        if (loadStatus.rrn17Loaded) {
          final template = await templateManager.loadRrn17Solutions();
          if (template != null) {
            templateData = {'solutionData': template.solutionData};
          }
        }
        templateLoaded = true;
      } else if (gameType == GameType.standard) {
        // 标准数独可以使用 rrn17 模板
        if (loadStatus.rrn17Loaded) {
          final template = await templateManager.loadRrn17Solutions();
          if (template != null) {
            templateData = {
              'solutionData': template.solutionData,
            };
            templateLoaded = true;
          }
        }
      } else if (gameType == GameType.samurai) {
        // 武士数独使用 rrn17 模板作为中心盘答案
        if (loadStatus.rrn17Loaded) {
          final template = await templateManager.loadRrn17Solutions();
          if (template != null) {
            templateData = {
              'centerSolution': template.solutionData,
            };
            templateLoaded = true;
          }
        }
      } else {
        // 对角线、窗口、自定义数独不需要模板
        // 直接使用 DLX 求解器生成
        templateLoaded = true;
      }
    } catch (e) {
      AppLogger.error('加载模板失败: $e');
    }

    // 如果模板加载失败，直接回退到主线程生成
    if (!templateLoaded) {
      AppLogger.error('加载模板失败，回退到主线程生成');

      return _generateInMainThread(
        gameType: gameType,
        size: size,
        difficulty: difficulty,
        onStageUpdate: onStageUpdate,
        isCancelled: isCancelled,
        templateData: templateData,
      );
    }

    // 使用 Isolate 生成器
    try {
      final isolateGenerator = IsolateGameGenerator();
      final result = await isolateGenerator.generate(
        gameType: gameType,
        difficulty: difficulty,
        size: size,
        onStageUpdate: onStageUpdate,
        templateData: templateData,
      );

      // 通知生成完成
      onStageUpdate?.call(GenerationStage.completed);

      return result;
    } catch (e) {
      // 如果 Isolate 执行失败，回退到主线程
      AppLogger.error('Isolate 生成失败，回退到主线程生成: $e');
      return _generateInMainThread(
        gameType: gameType,
        size: size,
        difficulty: difficulty,
        onStageUpdate: onStageUpdate,
        isCancelled: isCancelled,
        templateData: templateData,
      );
    }
  }

  /// 在主线程生成游戏
  static Future<GenerationResult> _generateInMainThread({
    required GameType gameType,
    required int size,
    required Difficulty difficulty,
    Function(GenerationStage)? onStageUpdate,
    bool Function()? isCancelled,
    Map<String, dynamic>? templateData,
  }) async {
    final generator = GameGenerator();
    return generator.generate(
      gameType: gameType,
      difficulty: difficulty,
      size: size,
      isCancelled: isCancelled,
      onStageUpdate: onStageUpdate,
      templateData: templateData,
    );
  }
}
