namespace SudoKu.Models;

using System.ComponentModel;
using global::SudoKu.Resources;

/// <summary>
/// 难度等级枚举，定义数独谜题的难度级别。
/// </summary>
public enum Difficulty
{
    /// <summary>入门级。</summary>
    Beginner,

    /// <summary>简单。</summary>
    Easy,

    /// <summary>中等。</summary>
    Medium,

    /// <summary>困难。</summary>
    Hard,

    /// <summary>专家。</summary>
    Expert,

    /// <summary>大师。</summary>
    Master,

    /// <summary>自定义难度。</summary>
    Custom
}

/// <summary>
/// 游戏类型难度配置，定义特定游戏类型在特定难度下的参数。
/// </summary>
public class GameTypeDifficultyConfig
{
    /// <summary>获取游戏类型。</summary>
    public GameType GameType { get; init; }

    /// <summary>获取最小已填单元格数量。</summary>
    public int MinFilledCells { get; init; }

    /// <summary>获取最大已填单元格数量。</summary>
    public int MaxFilledCells { get; init; }

    /// <summary>获取最小策略等级。</summary>
    public StrategyLevel MinStrategyLevel { get; init; }

    /// <summary>获取最大策略等级。</summary>
    public StrategyLevel MaxStrategyLevel { get; init; }

    /// <summary>获取解题所需的策略类型列表。</summary>
    public List<StrategyType> RequiredStrategies { get; init; } = [];
}

/// <summary>
/// 难度配置类，包含特定难度等级的完整配置信息。
/// </summary>
public class DifficultyConfig
{
    /// <summary>获取难度等级。</summary>
    public Difficulty Level { get; init; }

    /// <summary>获取难度名称。</summary>
    public string Name { get; init; } = string.Empty;

    /// <summary>获取该难度对应的最大策略等级。</summary>
    public StrategyLevel MaxStrategyLevel { get; init; }

    /// <summary>获取各游戏类型的特定难度配置。</summary>
    public Dictionary<GameType, GameTypeDifficultyConfig> GameTypeConfigs { get; init; } = [];

    /// <summary>获取难度评分（0.0到1.0）。</summary>
    public double DifficultyScore { get; init; }

    /// <summary>获取最小预期完成时间（秒）。</summary>
    public int MinExpectedTime { get; init; }

    /// <summary>获取最大预期完成时间（秒）。</summary>
    public int MaxExpectedTime { get; init; }

    private static readonly List<DifficultyConfig> _allConfigs = CreateConfigs();

    /// <summary>
    /// 获取所有预定义的难度配置。
    /// </summary>
    /// <returns>所有难度配置的只读列表。</returns>
    public static IReadOnlyList<DifficultyConfig> GetAllConfigs()
    {
        return _allConfigs.AsReadOnly();
    }

    /// <summary>
    /// 获取指定游戏类型的难度配置。
    /// </summary>
    /// <param name="type">游戏类型。</param>
    /// <returns>对应的游戏类型难度配置，如果不存在则返回 null。</returns>
    public GameTypeDifficultyConfig? GetGameTypeConfig(GameType type)
    {
        return GameTypeConfigs.TryGetValue(type, out var config) ? config : null;
    }

    /// <summary>
    /// 根据难度和游戏类型获取随机已填单元格数量。
    /// </summary>
    /// <param name="diff">难度等级。</param>
    /// <param name="type">游戏类型。</param>
    /// <returns>随机生成的已填单元格数量。</returns>
    public static int GetRandomFilledCount(Difficulty diff, GameType type)
    {
        var config = GetAllConfigs().FirstOrDefault(c => c.Level == diff);
        if (config is null)
            return 30;

        var typeConfig = config.GetGameTypeConfig(type);
        if (typeConfig is null)
            return 30;

        var random = new Random();
        return random.Next(typeConfig.MinFilledCells, typeConfig.MaxFilledCells + 1);
    }

    private static List<DifficultyConfig> CreateConfigs()
    {
        return
        [
            new DifficultyConfig
            {
                Level = Difficulty.Beginner,
                Name = "Difficulty_Beginner",
                MaxStrategyLevel = StrategyLevel.Basic,
                DifficultyScore = 0.1,
                MinExpectedTime = 60,
                MaxExpectedTime = 300,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 45,
                        MaxFilledCells = 50,
                        MinStrategyLevel = StrategyLevel.Basic,
                        MaxStrategyLevel = StrategyLevel.Basic,
                        RequiredStrategies = { StrategyType.Basic }
                    }
                }
            },
            new DifficultyConfig
            {
                Level = Difficulty.Easy,
                Name = "Difficulty_Easy",
                MaxStrategyLevel = StrategyLevel.Basic,
                DifficultyScore = 0.25,
                MinExpectedTime = 120,
                MaxExpectedTime = 600,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 38,
                        MaxFilledCells = 44,
                        MinStrategyLevel = StrategyLevel.Basic,
                        MaxStrategyLevel = StrategyLevel.Basic,
                        RequiredStrategies = { StrategyType.NakedSingle, StrategyType.HiddenSingle }
                    }
                }
            },
            new DifficultyConfig
            {
                Level = Difficulty.Medium,
                Name = "Difficulty_Medium",
                MaxStrategyLevel = StrategyLevel.Intermediate,
                DifficultyScore = 0.45,
                MinExpectedTime = 300,
                MaxExpectedTime = 900,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 30,
                        MaxFilledCells = 37,
                        MinStrategyLevel = StrategyLevel.Basic,
                        MaxStrategyLevel = StrategyLevel.Intermediate,
                        RequiredStrategies = { StrategyType.NakedSingle, StrategyType.HiddenSingle, StrategyType.NakedPair, StrategyType.HiddenPair }
                    }
                }
            },
            new DifficultyConfig
            {
                Level = Difficulty.Hard,
                Name = "Difficulty_Hard",
                MaxStrategyLevel = StrategyLevel.Advanced,
                DifficultyScore = 0.65,
                MinExpectedTime = 600,
                MaxExpectedTime = 1800,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 24,
                        MaxFilledCells = 29,
                        MinStrategyLevel = StrategyLevel.Intermediate,
                        MaxStrategyLevel = StrategyLevel.Advanced,
                        RequiredStrategies = { StrategyType.NakedPair, StrategyType.HiddenPair, StrategyType.NakedTriple, StrategyType.HiddenTriple, StrategyType.LockedCandidate }
                    }
                }
            },
            new DifficultyConfig
            {
                Level = Difficulty.Expert,
                Name = "Difficulty_Expert",
                MaxStrategyLevel = StrategyLevel.Expert,
                DifficultyScore = 0.8,
                MinExpectedTime = 900,
                MaxExpectedTime = 3600,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 20,
                        MaxFilledCells = 25,
                        MinStrategyLevel = StrategyLevel.Advanced,
                        MaxStrategyLevel = StrategyLevel.Expert,
                        RequiredStrategies = { StrategyType.XWing, StrategyType.Swordfish, StrategyType.XYWing, StrategyType.UniqueRectangle }
                    }
                }
            },
            new DifficultyConfig
            {
                Level = Difficulty.Master,
                Name = "Difficulty_Master",
                MaxStrategyLevel = StrategyLevel.Master,
                DifficultyScore = 0.95,
                MinExpectedTime = 1800,
                MaxExpectedTime = 7200,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 17,
                        MaxFilledCells = 22,
                        MinStrategyLevel = StrategyLevel.Expert,
                        MaxStrategyLevel = StrategyLevel.Master,
                        RequiredStrategies = { StrategyType.XYWing, StrategyType.XYZWing, StrategyType.Jellyfish, StrategyType.TwoStringKite, StrategyType.Skyscraper, StrategyType.EmptyRectangle }
                    }
                }
            },
            new DifficultyConfig
            {
                Level = Difficulty.Custom,
                Name = "Difficulty_Custom",
                MaxStrategyLevel = StrategyLevel.Intermediate,
                DifficultyScore = 0.5,
                MinExpectedTime = 60,
                MaxExpectedTime = 3600,
                GameTypeConfigs = new Dictionary<GameType, GameTypeDifficultyConfig>
                {
                    [GameType.Standard] = new GameTypeDifficultyConfig
                    {
                        GameType = GameType.Standard,
                        MinFilledCells = 25,
                        MaxFilledCells = 45,
                        MinStrategyLevel = StrategyLevel.Basic,
                        MaxStrategyLevel = StrategyLevel.Intermediate,
                        RequiredStrategies = { StrategyType.NakedSingle, StrategyType.HiddenSingle }
                    }
                }
            }
        ];
    }
}

/// <summary>
/// 难度枚举扩展方法类，提供难度相关的便捷查询方法。
/// </summary>
public static class DifficultyExtension
{
    /// <summary>
    /// 获取难度的显示名称。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <returns>显示名称字符串。</returns>
    public static string GetDisplayName(this Difficulty difficulty)
    {
        var config = DifficultyConfig.GetAllConfigs().FirstOrDefault(c => c.Level == difficulty);
        return config != null ? AppResources.GetString(config.Name) : difficulty.ToString();
    }

    /// <summary>
    /// 获取难度的评分。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <returns>难度评分（0.0到1.0）。</returns>
    public static double GetDifficultyScore(this Difficulty difficulty)
    {
        var config = DifficultyConfig.GetAllConfigs().FirstOrDefault(c => c.Level == difficulty);
        return config?.DifficultyScore ?? 0.5;
    }

    /// <summary>
    /// 获取难度的最大策略等级。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <returns>最大策略等级。</returns>
    public static StrategyLevel GetMaxStrategyLevel(this Difficulty difficulty)
    {
        var config = DifficultyConfig.GetAllConfigs().FirstOrDefault(c => c.Level == difficulty);
        return config?.MaxStrategyLevel ?? StrategyLevel.Basic;
    }

    /// <summary>
    /// 获取难度的最小预期完成时间（秒）。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <returns>最小预期时间（秒）。</returns>
    public static int GetMinExpectedTime(this Difficulty difficulty)
    {
        var config = DifficultyConfig.GetAllConfigs().FirstOrDefault(c => c.Level == difficulty);
        return config?.MinExpectedTime ?? 60;
    }

    /// <summary>
    /// 获取难度的最大预期完成时间（秒）。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <returns>最大预期时间（秒）。</returns>
    public static int GetMaxExpectedTime(this Difficulty difficulty)
    {
        var config = DifficultyConfig.GetAllConfigs().FirstOrDefault(c => c.Level == difficulty);
        return config?.MaxExpectedTime ?? 300;
    }
}

/// <summary>
/// 难度显示模型，用于UI层展示难度信息。
/// 实现 INotifyPropertyChanged 以支持数据绑定。
/// </summary>
/// <remarks>
/// 初始化难度显示模型的新实例。
/// </remarks>
/// <param name="level">难度等级。</param>
/// <param name="displayName">显示名称。</param>
/// <param name="color">主题颜色。</param>
/// <param name="index">序号（从1开始）。</param>
public partial class DifficultyDisplay(Difficulty level, string displayName, Color color, int index = 0) : INotifyPropertyChanged
{
    private string _displayName = displayName;
    private Color _color = color;
    private int _index = index;
    private string _stars = GetStarsForDifficulty(level);

    /// <summary>获取难度等级。</summary>
    public Difficulty Level { get; } = level;

    /// <summary>获取难度等级（用于XAML绑定）。</summary>
    public Difficulty Difficulty => Level;

    /// <summary>获取序号（从1开始）。</summary>
    public int Index
    {
        get => _index;
        set { _index = value; OnPropertyChanged(); }
    }

    /// <summary>获取星级显示字符串。</summary>
    public string Stars
    {
        get => _stars;
        set { _stars = value; OnPropertyChanged(); }
    }

    /// <summary>获取或设置显示名称。</summary>
    public string DisplayName
    {
        get => _displayName;
        set { _displayName = value; OnPropertyChanged(); }
    }

    /// <summary>获取或设置主题颜色。</summary>
    public Color Color
    {
        get => _color;
        set { _color = value; OnPropertyChanged(); }
    }

    /// <summary>获取难度颜色（用于XAML绑定，与Color相同）。</summary>
    public Color DifficultyColor => _color;

    /// <summary>
    /// 根据难度等级获取星级字符串。
    /// </summary>
    private static string GetStarsForDifficulty(Difficulty difficulty)
    {
        return difficulty switch
        {
            Difficulty.Beginner => "★☆☆☆☆",
            Difficulty.Easy => "★★☆☆☆",
            Difficulty.Medium => "★★★☆☆",
            Difficulty.Hard => "★★★★☆",
            Difficulty.Expert => "★★★★★",
            Difficulty.Master => "★★★★★+",
            _ => "★★★☆☆"
        };
    }

    /// <summary>
    /// 刷新显示信息（从配置重新加载）。
    /// </summary>
    public void Refresh()
    {
        DisplayName = Level.GetDisplayName();
    }

    /// <summary>属性更改事件。</summary>
    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
