using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Strategies;

namespace SudoKu.Services.Solving;

/// <summary>
/// 策略抽象基类
/// 所有求解策略必须继承此类并实现 Apply 方法
/// 参照 Flutter strategy_engine.dart Strategy
/// </summary>
public abstract class Strategy
{
    /// <summary>策略类型</summary>
    public abstract StrategyType Type { get; }

    /// <summary>策略级别</summary>
    public abstract StrategyLevel Level { get; }

    /// <summary>适用的游戏类型</summary>
    public abstract HashSet<GameType> ApplicableGames { get; }

    /// <summary>
    /// 应用策略到棋盘上下文
    /// 返回 true 表示有候选数被修改
    /// </summary>
    public abstract bool Apply(BoardContext context);
}

/// <summary>
/// 策略注册表
/// 参照 Flutter strategy_engine.dart StrategyRegistry
/// </summary>
public static class StrategyRegistry
{
    private static readonly Dictionary<StrategyType, Strategy> _strategies = new();

    /// <summary>
    /// 按执行优先级排序的策略类型列表（注册顺序即执行顺序）
    /// </summary>
    private static readonly List<StrategyType> _executionOrder = new();

    /// <summary>
    /// 注册策略
    /// </summary>
    public static void Register(Strategy strategy)
    {
        _strategies[strategy.Type] = strategy;
        if (!_executionOrder.Contains(strategy.Type))
        {
            _executionOrder.Add(strategy.Type);
        }
    }

    /// <summary>
    /// 获取指定类型的策略
    /// </summary>
    public static Strategy? Get(StrategyType type) =>
        _strategies.TryGetValue(type, out var strategy) ? strategy : null;

    /// <summary>
    /// 获取所有已注册的策略（按注册顺序）
    /// </summary>
    public static List<Strategy> GetAllStrategies() =>
        _executionOrder
            .Select(type => _strategies.TryGetValue(type, out var s) ? s : null)
            .Where(s => s != null)
            .Cast<Strategy>()
            .ToList();

    /// <summary>
    /// 获取适用于指定游戏类型的策略（按注册顺序）
    /// </summary>
    public static List<Strategy> GetForGame(GameType gameType) =>
        _executionOrder
            .Select(type => _strategies.TryGetValue(type, out var s) ? s : null)
            .Where(s => s != null)
            .Cast<Strategy>()
            .Where(s => s.ApplicableGames.Contains(gameType))
            .ToList();

    /// <summary>
    /// 获取指定级别及以下的策略
    /// </summary>
    public static List<Strategy> GetForLevel(StrategyLevel maxLevel) =>
        GetAllStrategies()
            .Where(s => (int)s.Level <= (int)maxLevel)
            .ToList();

    /// <summary>
    /// 获取适用于指定游戏类型和级别的策略
    /// </summary>
    public static List<Strategy> GetForGameAndLevel(GameType gameType, StrategyLevel maxLevel) =>
        GetForGame(gameType)
            .Where(s => (int)s.Level <= (int)maxLevel)
            .ToList();

    /// <summary>
    /// 清除所有注册的策略
    /// </summary>
    public static void Clear()
    {
        _strategies.Clear();
        _executionOrder.Clear();
    }
}

/// <summary>
/// 策略服务 - 负责初始化和执行策略
/// 参照 Flutter strategy_engine.dart StrategyService
/// </summary>
public class StrategyService
{
    private StrategyService() { }

    private static StrategyService? _instance;

    /// <summary>
    /// 获取单例实例
    /// </summary>
    public static StrategyService Instance
    {
        get
        {
            _instance ??= new StrategyService();
            return _instance;
        }
    }

    private bool _isInitialized;

    /// <summary>
    /// 初始化策略服务，注册所有策略
    /// </summary>
    public static void Initialize()
    {
        if (Instance._isInitialized) return;
        Instance.RegisterAllStrategies();
        Instance._isInitialized = true;
    }

    private void RegisterAllStrategies()
    {
        // 按执行优先级注册（注册顺序即执行顺序）
        // 基础
        StrategyRegistry.Register(new KillerCageConstraintStrategy());
        StrategyRegistry.Register(new NakedSingleStrategy());
        StrategyRegistry.Register(new HiddenSingleStrategy());
        // 中级
        StrategyRegistry.Register(new NakedPairStrategy());
        StrategyRegistry.Register(new HiddenPairStrategy());
        StrategyRegistry.Register(new LockedCandidateStrategy());
        StrategyRegistry.Register(new Killer45RuleStrategy());
        StrategyRegistry.Register(new KillerOverlapEliminationStrategy());
        StrategyRegistry.Register(new KillerCageBlockingStrategy());
        StrategyRegistry.Register(new KillerHiddenCombinationStrategy());
        StrategyRegistry.Register(new KillerCageSplittingStrategy());
        // 高级
        StrategyRegistry.Register(new NakedTripleStrategy());
        StrategyRegistry.Register(new HiddenTripleStrategy());
        StrategyRegistry.Register(new XWingStrategy());
        StrategyRegistry.Register(new SwordfishStrategy());
        StrategyRegistry.Register(new JellyfishStrategy());
        StrategyRegistry.Register(new XYWingStrategy());
        StrategyRegistry.Register(new XYZWingStrategy());
        StrategyRegistry.Register(new UniqueRectangleStrategy());
        StrategyRegistry.Register(new TwoStringKiteStrategy());
        StrategyRegistry.Register(new SkyscraperStrategy());
        StrategyRegistry.Register(new EmptyRectangleStrategy());
        StrategyRegistry.Register(new FinnedXWingStrategy());
        StrategyRegistry.Register(new FinnedSwordfishStrategy());
    }

    /// <summary>
    /// 应用所有策略到棋盘上下文（迭代执行直到无变化）
    /// </summary>
    public void ApplyStrategies(BoardContext context, int maxIterations = 20)
    {
        var strategies = StrategyRegistry.GetAllStrategies();

        int iterations = 0;
        bool changed = true;
        while (changed && iterations < maxIterations)
        {
            changed = false;
            foreach (var strategy in strategies)
            {
                if (strategy.Apply(context))
                {
                    changed = true;
                    break;
                }
            }
            iterations++;
        }
    }

    /// <summary>
    /// 应用指定游戏类型的策略（迭代执行直到无变化）
    /// 基础策略使用 break 模式，中级以上策略使用 continue 模式
    /// </summary>
    public void ApplyStrategiesForGame(BoardContext context, GameType gameType, int maxIterations = 50)
    {
        var strategies = StrategyRegistry.GetForGame(gameType);

        // 分离基础策略和中级以上策略（保持注册顺序）
        var basicStrategies = strategies.Where(s => s.Level == StrategyLevel.Basic).ToList();
        var advancedStrategies = strategies.Where(s => s.Level != StrategyLevel.Basic).ToList();

        int iterations = 0;
        bool changed = true;
        while (changed && iterations < maxIterations)
        {
            changed = false;

            // 阶段1：基础策略使用 break 模式
            foreach (var strategy in basicStrategies)
            {
                if (strategy.Apply(context))
                {
                    changed = true;
                    break;
                }
            }

            if (!changed)
            {
                // 阶段2：中级以上策略使用 continue 模式
                foreach (var strategy in advancedStrategies)
                {
                    if (strategy.Apply(context))
                    {
                        changed = true;
                    }
                }
            }

            iterations++;
        }
    }
}
