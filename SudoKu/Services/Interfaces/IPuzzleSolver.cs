using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Interfaces;

/// <summary>
/// 谜题求解器接口，定义数独谜题的求解、分析和提示功能。
/// </summary>
public interface IPuzzleSolver
{
    /// <summary>
    /// 异步验证谜题是否具有唯一解。
    /// </summary>
    /// <param name="puzzle">待验证的谜题棋盘。</param>
    /// <param name="token">取消令牌。</param>
    /// <returns>如果谜题有唯一解则为 true。</returns>
    Task<bool> IsUniqueSolutionAsync(Board puzzle, CancellationToken token = default);

    /// <summary>
    /// 异步分析谜题，返回解题所需的策略和难度信息。
    /// </summary>
    /// <param name="puzzle">待分析的谜题棋盘。</param>
    /// <param name="token">取消令牌。</param>
    /// <returns>谜题分析结果。</returns>
    Task<PuzzleAnalysisResult> AnalyzeAsync(Board puzzle, CancellationToken token = default);

    /// <summary>
    /// 根据当前棋盘状态和解答棋盘获取提示。
    /// </summary>
    /// <param name="current">当前棋盘状态。</param>
    /// <param name="solution">解答棋盘。</param>
    /// <returns>提示信息，包含行、列和建议填入的值；如果无法提供提示则返回 null。</returns>
    (int row, int col, int value)? GetHint(Board current, Board solution);

    /// <summary>
    /// 计算棋盘中所有空单元格的候选数。
    /// </summary>
    /// <param name="board">要计算候选数的棋盘。</param>
    /// <param name="useAdvancedStrategies">是否应用高级策略（Naked Single、Naked Pair、Hidden Single）来缩减候选数。</param>
    /// <returns>候选数已更新的新棋盘实例。</returns>
    Board CalculateCandidates(Board board, bool useAdvancedStrategies = false);

    /// <summary>
    /// 异步求解谜题，返回完整的求解结果。
    /// </summary>
    /// <param name="puzzle">待求解的谜题棋盘。</param>
    /// <param name="token">取消令牌。</param>
    /// <returns>求解结果，包含是否可解和使用的策略。</returns>
    Task<PuzzleAnalysisResult> SolveAsync(Board puzzle, CancellationToken token = default);
}
