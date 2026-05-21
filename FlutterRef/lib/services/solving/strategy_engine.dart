import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/strategies/advanced_strategies.dart';
import 'package:sudoku/services/solving/strategies/killer_strategies.dart';
import 'package:sudoku/services/solving/strategies/solving_strategies.dart';

/// 策略抽象基类
/// 所有求解策略必须继承此类并实现 apply 方法
abstract class Strategy {
  const Strategy();

  /// 策略类型
  StrategyType get type;

  /// 策略级别
  StrategyLevel get level;

  /// 适用的游戏类型
  Set<GameType> get applicableGames;

  /// 应用策略到棋盘上下文
  /// 返回 true 表示有候选数被修改
  bool apply(BoardContext context);
}

/// 策略注册表
class StrategyRegistry {
  static final Map<StrategyType, Strategy> _strategies = {};

  /// 按执行优先级排序的策略类型列表（注册顺序即执行顺序）
  static final List<StrategyType> _executionOrder = [];

  static void register(Strategy strategy) {
    _strategies[strategy.type] = strategy;
    if (!_executionOrder.contains(strategy.type)) {
      _executionOrder.add(strategy.type);
    }
  }

  static Strategy? get(StrategyType type) => _strategies[type];

  /// 获取所有已注册的策略（按注册顺序）
  static List<Strategy> getAllStrategies() =>
      _executionOrder.map((type) => _strategies[type]).whereType<Strategy>().toList();

  /// 获取适用于指定游戏类型的策略（按注册顺序）
  static List<Strategy> getForGame(GameType gameType) =>
      _executionOrder
          .map((type) => _strategies[type])
          .whereType<Strategy>()
          .where((s) => s.applicableGames.contains(gameType))
          .toList();

  static List<Strategy> getForLevel(StrategyLevel maxLevel) =>
      getAllStrategies()
          .where((s) => s.level.index <= maxLevel.index)
          .toList();

  static List<Strategy> getForGameAndLevel(
    GameType gameType,
    StrategyLevel maxLevel,
  ) => getForGame(gameType)
      .where((s) => s.level.index <= maxLevel.index)
      .toList();
}

/// 策略服务 - 负责初始化和执行策略
class StrategyService {
  StrategyService._();
  static StrategyService? _instance;

  static StrategyService get instance {
    _instance ??= StrategyService._();
    return _instance!;
  }

  bool _isInitialized = false;

  /// 初始化策略服务，注册所有策略
  static void initialize() {
    if (instance._isInitialized) return;
    instance.._registerAllStrategies()
    .._isInitialized = true;
  }

  void _registerAllStrategies() {
    // 按执行优先级注册（注册顺序即执行顺序）
    // 基础
    StrategyRegistry.register(const KillerCageConstraintStrategy());
    StrategyRegistry.register(const NakedSingleStrategy());
    StrategyRegistry.register(const HiddenSingleStrategy());
    // 中级
    StrategyRegistry.register(const NakedPairStrategy());
    StrategyRegistry.register(const HiddenPairStrategy());
    StrategyRegistry.register(const LockedCandidateStrategy());
    StrategyRegistry.register(const Killer45RuleStrategy());
    StrategyRegistry.register(const KillerOverlapEliminationStrategy());
    StrategyRegistry.register(const KillerCageBlockingStrategy());
    // 高级
    StrategyRegistry.register(const NakedTripleStrategy());
    StrategyRegistry.register(const HiddenTripleStrategy());
    StrategyRegistry.register(const XWingStrategy());
    StrategyRegistry.register(const SwordfishStrategy());
    StrategyRegistry.register(const JellyfishStrategy());
    StrategyRegistry.register(const XYWingStrategy());
    StrategyRegistry.register(const XYZWingStrategy());
    StrategyRegistry.register(const UniqueRectangleStrategy());
    StrategyRegistry.register(const TwoStringKiteStrategy());
    StrategyRegistry.register(const SkyscraperStrategy());
    StrategyRegistry.register(const EmptyRectangleStrategy());
    StrategyRegistry.register(const FinnedXWingStrategy());
    StrategyRegistry.register(const FinnedSwordfishStrategy());
  }

  /// 应用所有策略到棋盘上下文（迭代执行直到无变化）
  void applyStrategies(BoardContext context, {int maxIterations = 20}) {
    final strategies = StrategyRegistry.getAllStrategies();

    int iterations = 0;
    bool changed = true;
    while (changed && iterations < maxIterations) {
      changed = false;
      for (final strategy in strategies) {
        if (strategy.apply(context)) {
          changed = true;
          break;
        }
      }
      iterations++;
    }
  }

  /// 应用指定游戏类型的策略（迭代执行直到无变化）
  /// 基础策略使用 break 模式，中级以上策略使用 continue 模式
  void applyStrategiesForGame(BoardContext context, GameType gameType, {int maxIterations = 50}) {
    final strategies = StrategyRegistry.getForGame(gameType);

    // 分离基础策略和中级以上策略（保持注册顺序）
    final basicStrategies = strategies.where((s) => s.level == StrategyLevel.basic).toList();
    final advancedStrategies = strategies.where((s) => s.level != StrategyLevel.basic).toList();

    int iterations = 0;
    bool changed = true;
    while (changed && iterations < maxIterations) {
      changed = false;

      // 阶段1：基础策略使用 break 模式
      for (final strategy in basicStrategies) {
        if (strategy.apply(context)) {
          changed = true;
          break;
        }
      }

      if (!changed) {
        // 阶段2：中级以上策略使用 continue 模式
        for (final strategy in advancedStrategies) {
          if (strategy.apply(context)) {
            changed = true;
          }
        }
      }

      iterations++;
    }
  }
}
