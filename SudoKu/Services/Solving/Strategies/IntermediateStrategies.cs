using System.Linq;
using SudoKu.Models;

namespace SudoKu.Services.Solving.Strategies;

/// <summary>
/// 裸双策略
/// 参照 Flutter solving_strategies.dart NakedPairStrategy
/// </summary>
public class NakedPairStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.NakedPair;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        bool changed = false;

        for (int regIdx = 0; regIdx < context.RegionCellIndices.Count; regIdx++)
        {
            // 只处理大小为9的区域（行、列、宫、对角线等）
            var region = context.GetRegion(regIdx);
            if (region.Cells.Count != context.Board.GetMaxNumber()) continue;

            // 实时获取候选集，不使用快照
            var cellsWithCandidates = new List<SudokuCell>();
            foreach (var cell in region.Cells)
            {
                if (context.GetCandidates(cell.Row, cell.Col).Count > 0)
                {
                    cellsWithCandidates.Add(cell);
                }
            }

            for (int i = 0; i < cellsWithCandidates.Count - 1; i++)
            {
                for (int j = i + 1; j < cellsWithCandidates.Count; j++)
                {
                    var cell1 = cellsWithCandidates[i];
                    var cell2 = cellsWithCandidates[j];

                    // 实时获取候选集
                    var candidates1 = context.GetCandidates(cell1.Row, cell1.Col);
                    var candidates2 = context.GetCandidates(cell2.Row, cell2.Col);

                    // 裸双：两个单元格候选数完全相同且大小为2
                    if (candidates1.Count == 2 && candidates1.SetEquals(candidates2))
                    {
                        foreach (var cell in region.Cells)
                        {
                            if (cell.Row == cell1.Row && cell.Col == cell1.Col) continue;
                            if (cell.Row == cell2.Row && cell.Col == cell2.Col) continue;

                            var oldCandidates = context.GetCandidates(cell.Row, cell.Col);
                            var newCandidates = new HashSet<int>(oldCandidates);
                            newCandidates.ExceptWith(candidates1);

                            if (newCandidates.Count != oldCandidates.Count && newCandidates.Count > 0)
                            {
                                context.SetCandidates(cell.Row, cell.Col, newCandidates);
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
/// 隐对策略
/// 参照 Flutter solving_strategies.dart HiddenPairStrategy
/// </summary>
public class HiddenPairStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.HiddenPair;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        bool changed = false;

        for (int regIdx = 0; regIdx < context.RegionCellIndices.Count; regIdx++)
        {
            // 只处理大小为9的区域（行、列、宫、对角线等）
            var region = context.GetRegion(regIdx);
            if (region.Cells.Count != context.Board.GetMaxNumber()) continue;

            // 遍历所有可能的数字对（共36对）
            var maxNumber = context.Board.GetMaxNumber();
            for (int num1 = 1; num1 <= maxNumber - 1; num1++)
            {
                for (int num2 = num1 + 1; num2 <= maxNumber; num2++)
                {
                    // 实时检查这两个数字的位置
                    var cellsForNum1 = new List<SudokuCell>();
                    var cellsForNum2 = new List<SudokuCell>();

                    foreach (var cell in region.Cells)
                    {
                        if (context.HasCandidate(cell.Row, cell.Col, num1))
                        {
                            cellsForNum1.Add(cell);
                        }
                        if (context.HasCandidate(cell.Row, cell.Col, num2))
                        {
                            cellsForNum2.Add(cell);
                        }
                    }

                    // 检查两个数字是否恰好出现在相同的两个格子中
                    if (cellsForNum1.Count == 2 && cellsForNum2.Count == 2)
                    {
                        var set1 = new HashSet<(int, int)> { (cellsForNum1[0].Row, cellsForNum1[0].Col), (cellsForNum1[1].Row, cellsForNum1[1].Col) };
                        var set2 = new HashSet<(int, int)> { (cellsForNum2[0].Row, cellsForNum2[0].Col), (cellsForNum2[1].Row, cellsForNum2[1].Col) };
                        if (!set1.SetEquals(set2)) continue;
                        var pair = new HashSet<int> { num1, num2 };

                        // 设置这两个格子的候选数为这对数字
                        foreach (var cell in cellsForNum1)
                        {
                            var currentCandidates = context.GetCandidates(cell.Row, cell.Col);
                            if (!currentCandidates.SetEquals(pair))
                            {
                                context.SetCandidates(cell.Row, cell.Col, new HashSet<int>(pair));
                                changed = true;
                            }
                        }

                        // 从区域内的其他格子中删除这些数字
                        foreach (var cell in region.Cells)
                        {
                            if (cellsForNum1.Contains(cell)) continue;

                            var currentCandidates = context.GetCandidates(cell.Row, cell.Col);
                            var newCandidates = new HashSet<int>(currentCandidates);
                            newCandidates.ExceptWith(pair);

                            if (newCandidates.Count != currentCandidates.Count && newCandidates.Count > 0)
                            {
                                context.SetCandidates(cell.Row, cell.Col, newCandidates);
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
/// 锁定候选数策略
/// 参照 Flutter solving_strategies.dart LockedCandidateStrategy
/// </summary>
public class LockedCandidateStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.LockedCandidate;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalBlocks) return false;
        bool changed = false;
        var n = context.Size;

        // 查找所有宫格区域的索引
        var blockRegionIndices = new List<int>();
        for (int i = 0; i < context.Board.Regions.Count; i++)
        {
            if (context.Board.Regions[i].Type == RegionType.Block)
            {
                blockRegionIndices.Add(i);
            }
        }

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            foreach (var boxIdx in blockRegionIndices)
            {
                var region = context.GetRegion(boxIdx);

                // 检查该数字是否已经在宫格中被填入
                bool numAlreadyFilled = false;
                foreach (var cell in region.Cells)
                {
                    if (context.CellValue(cell.Row, cell.Col) == num)
                    {
                        numAlreadyFilled = true;
                        break;
                    }
                }
                if (numAlreadyFilled) continue;

                var rowsInBox = new HashSet<int>();
                var colsInBox = new HashSet<int>();

                foreach (var cell in region.Cells)
                {
                    if (context.HasCandidate(cell.Row, cell.Col, num))
                    {
                        rowsInBox.Add(cell.Row);
                        colsInBox.Add(cell.Col);
                    }
                }

                if (rowsInBox.Count == 1)
                {
                    var row = rowsInBox.First();
                    // 获取当前宫格区域的所有列
                    var boxCols = new HashSet<int>();
                    foreach (var cell in region.Cells)
                    {
                        boxCols.Add(cell.Col);
                    }

                    for (int c = 0; c < n; c++)
                    {
                        if (boxCols.Contains(c)) continue;
                        // 检查目标单元格是否为空
                        if (context.CellValue(row, c) != null) continue;
                        // 检查目标单元格是否有该候选数
                        if (context.HasCandidate(row, c, num))
                        {
                            // 验证移除后不会导致候选数为空
                            var currentCandidates = context.GetCandidates(row, c);
                            if (currentCandidates.Count > 1)
                            {
                                context.RemoveCandidate(row, c, num);
                                changed = true;
                            }
                        }
                    }
                }

                if (colsInBox.Count == 1)
                {
                    var col = colsInBox.First();
                    // 获取当前宫格区域的所有行
                    var boxRows = new HashSet<int>();
                    foreach (var cell in region.Cells)
                    {
                        boxRows.Add(cell.Row);
                    }

                    for (int r = 0; r < n; r++)
                    {
                        if (boxRows.Contains(r)) continue;
                        // 检查目标单元格是否为空
                        if (context.CellValue(r, col) != null) continue;
                        // 检查目标单元格是否有该候选数
                        if (context.HasCandidate(r, col, num))
                        {
                            // 验证移除后不会导致候选数为空
                            var currentCandidates = context.GetCandidates(r, col);
                            if (currentCandidates.Count > 1)
                            {
                                context.RemoveCandidate(r, col, num);
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
/// 裸三数集策略
/// 参照 Flutter solving_strategies.dart NakedTripleStrategy
/// </summary>
public class NakedTripleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.NakedTriple;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        bool changed = false;

        for (int regIdx = 0; regIdx < context.RegionCellIndices.Count; regIdx++)
        {
            // 只处理大小为9的区域（行、列、宫、对角线等）
            var region = context.GetRegion(regIdx);
            if (region.Cells.Count != context.Board.GetMaxNumber()) continue;

            // 实时获取候选集，只包含候选数个数<=3的单元格
            var cellsWithCandidates = new List<SudokuCell>();
            foreach (var cell in region.Cells)
            {
                var candidates = context.GetCandidates(cell.Row, cell.Col);
                if (candidates.Count > 0 && candidates.Count <= 3)
                {
                    cellsWithCandidates.Add(cell);
                }
            }

            for (int i = 0; i < cellsWithCandidates.Count - 2; i++)
            {
                for (int j = i + 1; j < cellsWithCandidates.Count - 1; j++)
                {
                    for (int k = j + 1; k < cellsWithCandidates.Count; k++)
                    {
                        var cell1 = cellsWithCandidates[i];
                        var cell2 = cellsWithCandidates[j];
                        var cell3 = cellsWithCandidates[k];

                        // 实时获取候选集
                        var candidates1 = context.GetCandidates(cell1.Row, cell1.Col);
                        var candidates2 = context.GetCandidates(cell2.Row, cell2.Col);
                        var candidates3 = context.GetCandidates(cell3.Row, cell3.Col);

                        var union = new HashSet<int>();
                        union.UnionWith(candidates1);
                        union.UnionWith(candidates2);
                        union.UnionWith(candidates3);

                        // 裸三：并集大小为3，且每个单元格的候选数都是并集的子集
                        if (union.Count == 3 &&
                            union.IsSupersetOf(candidates1) &&
                            union.IsSupersetOf(candidates2) &&
                            union.IsSupersetOf(candidates3))
                        {
                            foreach (var cell in region.Cells)
                            {
                                if (cell.Row == cell1.Row && cell.Col == cell1.Col) continue;
                                if (cell.Row == cell2.Row && cell.Col == cell2.Col) continue;
                                if (cell.Row == cell3.Row && cell.Col == cell3.Col) continue;

                                var oldCandidates = context.GetCandidates(cell.Row, cell.Col);
                                var newCandidates = new HashSet<int>(oldCandidates);
                                newCandidates.ExceptWith(union);

                                if (newCandidates.Count != oldCandidates.Count && newCandidates.Count > 0)
                                {
                                    context.SetCandidates(cell.Row, cell.Col, newCandidates);
                                    changed = true;
                                }
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
/// 隐三数集策略
/// 参照 Flutter solving_strategies.dart HiddenTripleStrategy
/// </summary>
public class HiddenTripleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.HiddenTriple;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Advanced;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        bool changed = false;

        for (int regIdx = 0; regIdx < context.RegionCellIndices.Count; regIdx++)
        {
            // 只处理大小为9的区域（行、列、宫、对角线等）
            var region = context.GetRegion(regIdx);
            if (region.Cells.Count != context.Board.GetMaxNumber()) continue;

            // 遍历所有可能的数字三元组
            var maxNumber = context.Board.GetMaxNumber();
            for (int num1 = 1; num1 <= maxNumber - 2; num1++)
            {
                for (int num2 = num1 + 1; num2 <= maxNumber - 1; num2++)
                {
                    for (int num3 = num2 + 1; num3 <= maxNumber; num3++)
                    {
                        // 实时检查这三个数字的位置
                        var cellsForNum1 = new List<SudokuCell>();
                        var cellsForNum2 = new List<SudokuCell>();
                        var cellsForNum3 = new List<SudokuCell>();

                        foreach (var cell in region.Cells)
                        {
                            if (context.HasCandidate(cell.Row, cell.Col, num1))
                            {
                                cellsForNum1.Add(cell);
                            }
                            if (context.HasCandidate(cell.Row, cell.Col, num2))
                            {
                                cellsForNum2.Add(cell);
                            }
                            if (context.HasCandidate(cell.Row, cell.Col, num3))
                            {
                                cellsForNum3.Add(cell);
                            }
                        }

                        // 检查三个数字是否都有至少一个候选位置
                        if (cellsForNum1.Count == 0 || cellsForNum2.Count == 0 || cellsForNum3.Count == 0)
                        {
                            continue;
                        }

                        // 收集所有出现这三个数字的格子
                        var allCells = new HashSet<SudokuCell>();
                        foreach (var cell in cellsForNum1) allCells.Add(cell);
                        foreach (var cell in cellsForNum2) allCells.Add(cell);
                        foreach (var cell in cellsForNum3) allCells.Add(cell);

                        // 隐三定义：三个数字的候选位置总共出现在三个格子中
                        if (allCells.Count == 3)
                        {
                            var triple = new HashSet<int> { num1, num2, num3 };

                            // 设置这三个格子的候选数为这三个数字的交集
                            foreach (var cell in allCells)
                            {
                                var oldCandidates = context.GetCandidates(cell.Row, cell.Col);
                                var newCandidates = new HashSet<int>(oldCandidates);
                                newCandidates.IntersectWith(triple);

                                if (newCandidates.Count > 0 && !newCandidates.SetEquals(oldCandidates))
                                {
                                    context.SetCandidates(cell.Row, cell.Col, newCandidates);
                                    changed = true;
                                }
                            }

                            // 从区域内的其他格子中删除这些数字
                            foreach (var cell in region.Cells)
                            {
                                if (allCells.Contains(cell)) continue;

                                var currentCandidates = context.GetCandidates(cell.Row, cell.Col);
                                var newCandidates = new HashSet<int>(currentCandidates);
                                newCandidates.ExceptWith(triple);

                                if (!newCandidates.SetEquals(currentCandidates))
                                {
                                    context.SetCandidates(cell.Row, cell.Col, newCandidates);
                                    changed = true;
                                }
                            }
                        }
                    }
                }
            }
        }
        return changed;
    }
}
