using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving;

/// <summary>
/// 求解结果类，封装谜题求解过程的完整结果信息。
/// 包含求解是否成功、使用的策略、解答棋盘等数据。
/// </summary>
public class SolveResult
{
    /// <summary>获取求解是否成功。</summary>
    public bool Success { get; init; }

    /// <summary>获取求解后的棋盘实例，如果求解失败则为 null。</summary>
    public Board? SolvedBoard { get; init; }

    /// <summary>获取求解过程中使用的策略类型列表。</summary>
    public List<StrategyType> UsedStrategies { get; init; } = new();

    /// <summary>获取解题所需的最高策略等级。</summary>
    public StrategyLevel RequiredLevel { get; init; }

    /// <summary>获取谜题是否具有唯一解。</summary>
    public bool HasUniqueSolution { get; init; }

    /// <summary>获取找到的解的总数量（用于唯一性验证）。</summary>
    public int SolutionCount { get; init; }

    /// <summary>获取求解失败时的原因描述，如果成功则为 null。</summary>
    public string? FailureReason { get; init; }
}
