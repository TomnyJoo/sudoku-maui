namespace SudoKu.Models;

/// <summary>
/// 策略等级枚举，定义解题策略的难度等级。
/// </summary>
public enum StrategyLevel
{
    /// <summary>基础策略。</summary>
    Basic,

    /// <summary>中级策略。</summary>
    Intermediate,

    /// <summary>高级策略。</summary>
    Advanced,

    /// <summary>专家策略。</summary>
    Expert,

    /// <summary>大师策略。</summary>
    Master
}

/// <summary>
/// 策略类型枚举，定义所有支持的数独解题策略。
/// </summary>
public enum StrategyType
{
    /// <summary>基础填入。</summary>
    Basic,

    /// <summary>候选数标记。</summary>
    Candidate,

    /// <summary>裸单数（唯一候选数）。</summary>
    NakedSingle,

    /// <summary>隐单数。</summary>
    HiddenSingle,

    /// <summary>裸对。</summary>
    NakedPair,

    /// <summary>隐对。</summary>
    HiddenPair,

    /// <summary>裸三数。</summary>
    NakedTriple,

    /// <summary>隐三数。</summary>
    HiddenTriple,

    /// <summary>锁定候选数。</summary>
    LockedCandidate,

    /// <summary>X-Wing。</summary>
    XWing,

    /// <summary>Swordfish（剑鱼）。</summary>
    Swordfish,

    /// <summary>Jellyfish（水母）。</summary>
    Jellyfish,

    /// <summary>XY-Wing。</summary>
    XYWing,

    /// <summary>XYZ-Wing。</summary>
    XYZWing,

    /// <summary>唯一矩形。</summary>
    UniqueRectangle,

    /// <summary>双弦风筝。</summary>
    TwoStringKite,

    /// <summary>摩天楼。</summary>
    Skyscraper,

    /// <summary>空矩形。</summary>
    EmptyRectangle,

    /// <summary>带鳍X-Wing。</summary>
    FinnedXWing,

    /// <summary>带鳍Swordfish。</summary>
    FinnedSwordfish,

    /// <summary>杀手笼约束。</summary>
    KillerCageConstraint,

    /// <summary>杀手45规则。</summary>
    Killer45Rule,

    /// <summary>杀手重叠消除。</summary>
    KillerOverlapElimination,

    /// <summary>杀手笼阻塞。</summary>
    KillerCageBlocking,

    /// <summary>杀手隐式组合。</summary>
    KillerHiddenCombination,

    /// <summary>杀手笼分割。</summary>
    KillerCageSplitting
}

/// <summary>
/// 策略信息类，包含策略的元数据描述。
/// </summary>
public class StrategyInfo
{
    /// <summary>获取策略类型。</summary>
    public StrategyType Type { get; init; }

    /// <summary>获取策略名称。</summary>
    public string Name { get; init; } = string.Empty;

    /// <summary>获取策略描述。</summary>
    public string Description { get; init; } = string.Empty;

    /// <summary>获取策略所属的难度等级。</summary>
    public StrategyLevel Level { get; init; }

    /// <summary>获取策略适用的游戏类型列表。</summary>
    public List<GameType> ApplicableGameTypes { get; init; } = [];
}

/// <summary>
/// 策略元数据工具类，提供策略信息的查询功能。
/// </summary>
public static class StrategyMetadata
{
    private static readonly List<StrategyInfo> _allStrategies = CreateAllStrategies();

    /// <summary>获取已注册的策略总数。</summary>
    public static int Count => _allStrategies.Count;

    /// <summary>
    /// 获取指定策略类型的信息。
    /// </summary>
    /// <param name="type">策略类型。</param>
    /// <returns>对应的策略信息。</returns>
    /// <exception cref="ArgumentException">当策略类型未注册时抛出。</exception>
    public static StrategyInfo GetInfo(StrategyType type)
    {
        var info = _allStrategies.FirstOrDefault(s => s.Type == type);
        return info ?? throw new ArgumentException($"未注册的策略类型: {type}", nameof(type));
    }

    /// <summary>
    /// 获取所有已注册的策略信息。
    /// </summary>
    /// <returns>所有策略信息的只读列表。</returns>
    public static IReadOnlyList<StrategyInfo> GetAll()
    {
        return _allStrategies.AsReadOnly();
    }

    /// <summary>
    /// 获取指定等级的所有策略信息。
    /// </summary>
    /// <param name="level">策略等级。</param>
    /// <returns>该等级下所有策略信息的只读列表。</returns>
    public static IReadOnlyList<StrategyInfo> GetByLevel(StrategyLevel level)
    {
        return _allStrategies.Where(s => s.Level == level).ToList().AsReadOnly();
    }

    /// <summary>
    /// 获取适用于指定游戏类型的所有策略信息。
    /// </summary>
    /// <param name="type">游戏类型。</param>
    /// <returns>适用于该游戏类型的策略信息只读列表。</returns>
    public static IReadOnlyList<StrategyInfo> GetByGameType(GameType type)
    {
        return _allStrategies
            .Where(s => s.ApplicableGameTypes.Contains(type) || s.ApplicableGameTypes.Count == 0)
            .ToList()
            .AsReadOnly();
    }

    private static List<StrategyInfo> CreateAllStrategies()
    {
        var standardTypes = new List<GameType> { GameType.Standard, GameType.Diagonal, GameType.Window, GameType.Jigsaw };
        var killerTypes = new List<GameType> { GameType.Killer };

        return
        [
            new StrategyInfo
            {
                Type = StrategyType.Basic,
                Name = "Basic",
                Description = "基础填入策略，通过排除法确定唯一可填数字。",
                Level = StrategyLevel.Basic,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.Candidate,
                Name = "Candidate",
                Description = "候选数标记策略，记录每个单元格的可能数字。",
                Level = StrategyLevel.Basic,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.NakedSingle,
                Name = "Naked Single",
                Description = "裸单数策略，当单元格只有一个候选数时直接填入。",
                Level = StrategyLevel.Basic,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.HiddenSingle,
                Name = "Hidden Single",
                Description = "隐单数策略，当某数字在区域中只能填入一个位置时确定。",
                Level = StrategyLevel.Basic,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.NakedPair,
                Name = "Naked Pair",
                Description = "裸对策略，两个单元格共享相同两个候选数时排除。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.HiddenPair,
                Name = "Hidden Pair",
                Description = "隐对策略，两个数字在某区域中只能出现在两个单元格时排除其他候选数。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.NakedTriple,
                Name = "Naked Triple",
                Description = "裸三数策略，三个单元格共享相同三个候选数时排除。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.HiddenTriple,
                Name = "Hidden Triple",
                Description = "隐三数策略，三个数字在某区域中只能出现在三个单元格时排除其他候选数。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.LockedCandidate,
                Name = "Locked Candidate",
                Description = "锁定候选数策略，候选数被限制在区域的某行或某列时排除。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.XWing,
                Name = "X-Wing",
                Description = "X-Wing策略，利用两行两列的候选数模式排除。",
                Level = StrategyLevel.Advanced,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.Swordfish,
                Name = "Swordfish",
                Description = "Swordfish策略，利用三行三列的候选数模式排除。",
                Level = StrategyLevel.Advanced,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.Jellyfish,
                Name = "Jellyfish",
                Description = "Jellyfish策略，利用四行四列的候选数模式排除。",
                Level = StrategyLevel.Advanced,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.XYWing,
                Name = "XY-Wing",
                Description = "XY-Wing策略，利用三个单元格的候选数链排除。",
                Level = StrategyLevel.Expert,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.XYZWing,
                Name = "XYZ-Wing",
                Description = "XYZ-Wing策略，XY-Wing的扩展形式，利用三个候选数的交集排除。",
                Level = StrategyLevel.Expert,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.UniqueRectangle,
                Name = "Unique Rectangle",
                Description = "唯一矩形策略，利用数独唯一解的特性排除。",
                Level = StrategyLevel.Expert,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.TwoStringKite,
                Name = "Two String Kite",
                Description = "双弦风筝策略，利用两个强链的交集排除候选数。",
                Level = StrategyLevel.Master,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.Skyscraper,
                Name = "Skyscraper",
                Description = "摩天楼策略，利用两条平行强链排除候选数。",
                Level = StrategyLevel.Master,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.EmptyRectangle,
                Name = "Empty Rectangle",
                Description = "空矩形策略，利用空矩形的交叉点排除候选数。",
                Level = StrategyLevel.Master,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.FinnedXWing,
                Name = "Finned X-Wing",
                Description = "带鳍X-Wing策略，X-Wing的变体，处理额外的候选数。",
                Level = StrategyLevel.Master,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.FinnedSwordfish,
                Name = "Finned Swordfish",
                Description = "带鳍Swordfish策略，Swordfish的变体，处理额外的候选数。",
                Level = StrategyLevel.Master,
                ApplicableGameTypes = standardTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.KillerCageConstraint,
                Name = "Killer Cage Constraint",
                Description = "杀手笼约束策略，利用笼子的数字之和约束排除。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = killerTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.Killer45Rule,
                Name = "Killer 45 Rule",
                Description = "杀手45规则，利用行/列/宫的数字之和为固定值的特性。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = killerTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.KillerOverlapElimination,
                Name = "Killer Overlap Elimination",
                Description = "杀手重叠消除策略，利用笼子与区域重叠部分的约束。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = killerTypes
            },
            new StrategyInfo
            {
                Type = StrategyType.KillerCageBlocking,
                Name = "Killer Cage Blocking",
                Description = "杀手笼阻塞策略，利用笼子之间的相互约束排除候选数。",
                Level = StrategyLevel.Intermediate,
                ApplicableGameTypes = killerTypes
            }
        ];
    }
}
