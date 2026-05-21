import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/game_factory.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 游戏生成器统一入口
class GameGenerator {
  GameGenerator();

  final Map<GameType, IGameGenerator> _generators = {};
  bool _initialized = false;

  /// 初始化生成器，注册所有游戏类型的专用生成器
  void initialize() {
    if (_initialized) return;

    // 遍历所有游戏类型
    for (final gameType in GameType.values) {
      try {
        // 使用 GameFactory 创建生成器
        final generator = GameFactory.createGameGenerator(gameType);
        if (generator is IGameGenerator) {
          _generators[gameType] = generator;
        } else {
          AppLogger.warning('创建游戏类型 $gameType 生成器失败');
        }
      } catch (e) {
        AppLogger.error('初始化游戏类型 $gameType 生成器失败: $e');
      }
    }

    _initialized = true;
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// 生成游戏
  Future<GenerationResult> generate({
    required GameType gameType,
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    _ensureInitialized();

    final generator = _generators[gameType];
    if (generator == null) {
      throw GameGenerationException('不支持的游戏类型: $gameType');
    }

    return generator.generate(
      difficulty: difficulty,
      size: size,
      isCancelled: isCancelled,
      onStageUpdate: onStageUpdate,
      templateData: templateData,
    );
  }

  /// 销毁生成器
  void dispose() {
    _generators.clear();
    _initialized = false;
  }
}
