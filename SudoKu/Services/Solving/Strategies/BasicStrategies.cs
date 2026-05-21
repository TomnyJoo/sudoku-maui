using System.Linq;
using SudoKu.Models;

namespace SudoKu.Services.Solving.Strategies;

/// <summary>
/// 裸单策略
/// 参照 Flutter solving_strategies.dart NakedSingleStrategy
/// </summary>
public class NakedSingleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.NakedSingle;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Basic;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        bool changed = false;
        var n = context.Size;

        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (context.CellValue(r, c) != null) continue;

                var candidates = context.GetCandidates(r, c);
                if (candidates.Count == 1)
                {
                    var num = candidates.First();
                    // 从所有相关区域中移除该数字
                    foreach (var regIdx in context.CellToRegions[r][c])
                    {
                        var region = context.GetRegion(regIdx);
                        if (region.Cells.Count != context.Board.GetMaxNumber())
                        {
                            continue; // 只处理大小为9的区域
                        }

                        foreach (var cell in region.Cells)
                        {
                            var cr = cell.Row;
                            var cc = cell.Col;
                            if (cr == r && cc == c) continue;
                            if (context.CellValue(cr, cc) != null) continue;

                            if (context.HasCandidate(cr, cc, num))
                            {
                                context.RemoveCandidate(cr, cc, num);
                                changed = true;
                            }
                        }
                    }
                }
            }
        }
        return changed;
    }
}

/// <summary>
/// 隐单策略
/// 参照 Flutter solving_strategies.dart HiddenSingleStrategy
/// </summary>
public class HiddenSingleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.HiddenSingle;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Basic;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        bool changed = false;

        // 只处理1到maxNumber之间的数字
        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            for (int regIdx = 0; regIdx < context.RegionCellIndices.Count; regIdx++)
            {
                // 只处理大小为9的区域（行、列、宫、对角线等）
                var region = context.GetRegion(regIdx);
                if (region.Cells.Count != maxNumber) continue;

                int count = 0;
                SudokuCell? lastCell = null;

                // 遍历区域内的所有单元格，统计候选位置
                foreach (var cell in region.Cells)
                {
                    var cellValue = context.CellValue(cell.Row, cell.Col);
                    // 如果数字已填入该区域，跳过
                    if (cellValue == num)
                    {
                        count = 0;
                        break;
                    }

                    // 统计候选位置
                    if (cellValue == null && context.HasCandidate(cell.Row, cell.Col, num))
                    {
                        count++;
                        lastCell = cell;
                        if (count > 1) break;
                    }
                }

                // 如果只有一个候选位置，设置为该数字
                if (count == 1 && lastCell != null)
                {
                    var r = lastCell.Row;
                    var c = lastCell.Col;
                    var currentCandidates = context.GetCandidates(r, c);
                    if (currentCandidates.Count != 1 || !currentCandidates.Contains(num))
                    {
                        // 将该单元格的候选数设置为只包含这个数字
                        context.SetCandidates(r, c, new HashSet<int> { num });
                        changed = true;
                    }
                }
            }
        }
        return changed;
    }
}
