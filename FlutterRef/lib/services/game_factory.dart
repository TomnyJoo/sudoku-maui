import 'package:sudoku/index.dart';

/// 游戏工厂类，负责创建不同类型的游戏服务和生成器
class GameFactory {
  /// 私有构造函数
  GameFactory._();

  // ========== 注册制支持 ==========

  /// 已注册的游戏逻辑构建器
  static final Map<String, BaseSudokuGame Function()> _gameRegistry = {};

  /// 已注册的游戏服务构建器
  static final Map<GameType, GameService Function(GameValidator)> _serviceRegistry = {};

  /// 已注册的游戏生成器构建器
  static final Map<GameType, Object Function()> _generatorRegistry = {};

  /// 注册游戏逻辑
  static void register(String gameId, BaseSudokuGame Function() builder) {
    _gameRegistry[gameId] = builder;
  }

  /// 注册游戏服务构建器
  static void registerService(GameType gameType, GameService Function(GameValidator) builder) {
    _serviceRegistry[gameType] = builder;
  }

  /// 注册游戏生成器构建器
  static void registerGenerator(GameType gameType, Object Function() builder) {
    _generatorRegistry[gameType] = builder;
  }

  /// 创建已注册的游戏逻辑实例
  static BaseSudokuGame? createRegistered(String gameId) {
    final builder = _gameRegistry[gameId];
    return builder != null ? builder() : null;
  }

  /// 获取所有已注册的游戏 ID
  static List<String> getRegisteredGameIds() => _gameRegistry.keys.toList();

  // ========== 配置代理方法 ==========

  /// 获取游戏本地化名称
  static String getLocalizedGameName(GameType gameType, dynamic localizations) =>
      gameType.getLocalizedName(localizations);

  /// 获取难度级别列表
  static List<String> getDifficultyLevels(GameType gameType) =>
      GameConfig().getDifficultyLevels(gameType);

  /// 是否显示自定义游戏按钮
  static bool showCustomGame(GameType gameType) =>
      GameConfig().showCustomGame(gameType);

  /// 获取自定义游戏路由
  static String getCustomGameRoute(GameType gameType) =>
      GameConfig().getCustomGameRoute(gameType) ?? '/custom_game';

  // ========== 核心工厂方法 ==========

  /// 创建游戏服务，[gameType] - 游戏类型，[validator] - 游戏验证器
  static GameService createGameService(
    GameType gameType,
    GameValidator validator,
  ) {
    // 优先使用注册表查找
    final serviceBuilder = _serviceRegistry[gameType];
    if (serviceBuilder != null) {
      return serviceBuilder(validator);
    }

    // 回退到默认实现
    switch (gameType) {
      case GameType.standard:
        return GameService<StandardBoard>(
          gameType: 'standard',
          validator: validator,
          boardFromJson: StandardBoard.fromJson,
        );
      case GameType.diagonal:
        return GameService<DiagonalBoard>(
          gameType: 'diagonal',
          validator: validator,
          boardFromJson: DiagonalBoard.fromJson,
        );
      case GameType.window:
        return GameService<WindowBoard>(
          gameType: 'window',
          validator: validator,
          boardFromJson: WindowBoard.fromJson,
        );
      case GameType.jigsaw:
        return GameService<JigsawBoard>(
          gameType: 'jigsaw',
          validator: validator,
          boardFromJson: JigsawBoard.fromJson,
        );
      case GameType.killer:
        return GameService<KillerBoard>(
          gameType: 'killer',
          validator: validator,
          boardFromJson: KillerBoard.fromJson,
        );
      case GameType.samurai:
        return GameService<SamuraiBoard>(
          gameType: 'samurai',
          validator: validator,
          boardFromJson: SamuraiBoard.fromJson,
        );
    }
  }

  /// 创建游戏生成器，[gameType] - 游戏类型
  static Object createGameGenerator(GameType gameType) {
    // 优先使用注册表查找
    final generatorBuilder = _generatorRegistry[gameType];
    if (generatorBuilder != null) {
      return generatorBuilder();
    }

    // 回退到默认实现
    switch (gameType) {
      case GameType.standard:
        return StandardGenerator();
      case GameType.diagonal:
        return DiagonalGenerator();
      case GameType.window:
        return WindowGenerator();
      case GameType.jigsaw:
        return JigsawGenerator();
      case GameType.killer:
        return KillerGenerator();
      case GameType.samurai:
        return SamuraiGenerator();
    }
  }

  /// 获取游戏类型对应的路由名称
  static String getGameRoute(GameType gameType) => '/game';

  /// 创建游戏验证器
  static GameValidator createGameValidator(GameType gameType) {
    if (gameType == GameType.killer) {
      return KillerGameValidator();
    }
    return GameValidator();
  }
}

/// 杀手数独专用验证器，在标准验证基础上增加笼子约束验证
class KillerGameValidator extends GameValidator {
  @override
  bool validateBoard(Board board) {
    if (!super.validateBoard(board)) return false;
    if (board is! KillerBoard) return false;
    return board.areAllCagesValid;
  }
}
