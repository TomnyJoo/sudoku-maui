using SudoKu.Models.Boards;

namespace SudoKu.Models;

/// <summary>
/// 谜题分析结果类，包含谜题可解性和策略使用情况的分析数据。
/// </summary>
public class PuzzleAnalysisResult
{
    /// <summary>获取或设置谜题是否可解。</summary>
    public bool IsSolvable { get; set; }

    /// <summary>获取或设置解题过程中使用的策略类型列表。</summary>
    public List<StrategyType> UsedStrategies { get; set; } = [];

    /// <summary>获取或设置解题所需的最高策略等级。</summary>
    public StrategyLevel RequiredLevel { get; set; }

    /// <summary>获取或设置各策略的使用次数统计。</summary>
    public Dictionary<StrategyType, int> StrategyUsageCount { get; set; } = [];

    /// <summary>获取或设置如果不可解时的失败原因。</summary>
    public string? FailureReason { get; set; }
}

/// <summary>
/// 谜题生成阶段枚举，定义谜题生成过程中的各个阶段。
/// </summary>
public enum GenerationStage
{
    /// <summary>初始化阶段。</summary>
    Initializing,

    /// <summary>加载模板阶段。</summary>
    LoadingTemplate,

    /// <summary>创建区域约束阶段。</summary>
    CreatingRegions,

    /// <summary>应用数字替换阶段。</summary>
    ApplyingSubstitution,

    /// <summary>生成完整解答阶段。</summary>
    GeneratingSolution,

    /// <summary>挖掘谜题（移除数字）阶段。</summary>
    DiggingPuzzle,

    /// <summary>验证谜题阶段。</summary>
    Validating,

    /// <summary>生成完成。</summary>
    Completed,

    /// <summary>生成失败。</summary>
    Failed
}

/// <summary>
/// 谜题生成结果类，包含生成的谜题和解答信息。
/// 参照 Flutter generation_contracts.dart GenerationResult
/// </summary>
public class GenerationResult
{
    /// <summary>获取生成的谜题棋盘。</summary>
    public Board? Puzzle { get; init; }

    /// <summary>获取谜题的完整解答棋盘。</summary>
    public Board? Solution { get; init; }

    /// <summary>获取生成耗时（毫秒）。</summary>
    public long GenerationTime { get; init; }

    /// <summary>获取是否使用了模板生成。</summary>
    public bool UsedTemplate { get; init; }

    /// <summary>获取生成是否被取消。</summary>
    public bool IsCancelled { get; init; }
}

/// <summary>
/// 挖掘配置记录，定义谜题挖掘（移除数字）过程的参数。
/// 使用 record 类型以支持 with 表达式创建副本。
/// 参照 Flutter 的 DiggingConfig：MaxAttempts 默认为 10。
/// </summary>
public record DiggingConfig
{
    /// <summary>获取最小已填单元格数量。</summary>
    public int MinFilledCells { get; init; }

    /// <summary>获取最大已填单元格数量。</summary>
    public int MaxFilledCells { get; init; }

    /// <summary>获取最大尝试次数。默认为 10，与 Flutter 的 DiggingConfig 一致。</summary>
    public int MaxAttempts { get; init; } = 10;

    /// <summary>获取或设置是否使用对称性挖掘。变体数独应设为 false。</summary>
    public bool UseSymmetry { get; init; } = true;

    /// <summary>
    /// 获取或设置第一阶段（快速挖掘，不验证唯一性）的比例。
    /// 值为 0.0 到 1.0，表示第一阶段移除的空格占总移除空格数的比例。
    /// 较高的值可以加快生成速度，但可能降低谜题质量。
    /// </summary>
    public double Phase1Ratio { get; init; } = 0.5;

    /// <summary>获取最小策略等级。</summary>
    public StrategyLevel MinStrategyLevel { get; init; } = StrategyLevel.Basic;

    /// <summary>获取最大策略等级。</summary>
    public StrategyLevel MaxStrategyLevel { get; init; } = StrategyLevel.Master;

    /// <summary>获取解题所需的策略类型列表。</summary>
    public List<StrategyType> RequiredStrategies { get; init; } = [];

    /// <summary>获取是否启用策略难度验证。</summary>
    public bool ValidateDifficulty { get; init; } = false;

    /// <summary>
    /// 根据难度等级创建挖掘配置。
    /// 参照 Flutter 的 DiggingConfig.fromDifficulty 实现。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <param name="gameType">游戏类型，默认为标准数独。</param>
    /// <returns>对应难度的挖掘配置。</returns>
    public static DiggingConfig FromDifficulty(Difficulty difficulty, GameType gameType = GameType.Standard)
    {
        var isVariant = gameType != GameType.Standard;
        var diffConfig = DifficultyConfig.GetAllConfigs().FirstOrDefault(c => c.Level == difficulty);
        var gameConfig = diffConfig?.GetGameTypeConfig(gameType);

        var (minFilled, maxFilled, phase1Ratio) = difficulty switch
        {
            Difficulty.Beginner => (45, 50, 0.3),
            Difficulty.Easy => (38, 44, 0.4),
            Difficulty.Medium => (30, 37, 0.5),
            Difficulty.Hard => (24, 29, 0.5),
            Difficulty.Expert => (20, 25, 0.6),
            Difficulty.Master => (17, 22, 0.6),
            Difficulty.Custom => (25, 35, 0.5),
            _ => (30, 37, 0.5)
        };

        if (gameConfig != null)
        {
            minFilled = gameConfig.MinFilledCells;
            maxFilled = gameConfig.MaxFilledCells;
        }

        var validateDifficulty = difficulty is Difficulty.Medium or Difficulty.Hard or Difficulty.Expert or Difficulty.Master;

        return new DiggingConfig
        {
            MinFilledCells = minFilled,
            MaxFilledCells = maxFilled,
            MaxAttempts = 10,
            UseSymmetry = !isVariant,
            Phase1Ratio = phase1Ratio,
            MinStrategyLevel = gameConfig?.MinStrategyLevel ?? StrategyLevel.Basic,
            MaxStrategyLevel = gameConfig?.MaxStrategyLevel ?? StrategyLevel.Master,
            RequiredStrategies = gameConfig?.RequiredStrategies ?? [],
            ValidateDifficulty = validateDifficulty
        };
    }
}
