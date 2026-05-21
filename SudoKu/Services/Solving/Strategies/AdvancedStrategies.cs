using System.Linq;
using SudoKu.Models;

namespace SudoKu.Services.Solving.Strategies;

/// <summary>
/// 策略辅助方法
/// </summary>
public static class StrategyHelpers
{
    /// <summary>
    /// 通用可见性判断：两个单元格是否共享至少一个区域
    /// 参照 Flutter advanced_strategies.dart _shareRegion
    /// </summary>
    public static bool ShareRegion(BoardContext context, int r1, int c1, int r2, int c2)
    {
        if (r1 == r2 || c1 == c2) return true; // 同行或同列必然共享区域

        // 检查是否在任意同一个区域（宫、锯齿、对角线、窗口等）
        foreach (var regIdx in context.CellToRegions[r1][c1])
        {
            if (context.CellToRegions[r2][c2].Contains(regIdx))
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 检查在指定单元格设置单候选数后，是否会在同一区域内创建重复的单候选数
    /// 返回 true 表示会创建重复（不应移除），返回 false 表示可以安全移除
    /// 参照 Flutter solving_strategies.dart _wouldCreateDuplicateSingle
    /// </summary>
    public static bool WouldCreateDuplicateSingle(BoardContext context, int r, int c, int num)
    {
        // 检查该单元格所属的所有区域
        foreach (var regIdx in context.CellToRegions[r][c])
        {
            var region = context.GetRegion(regIdx);
            int singleCount = 0;

            foreach (var cell in region.Cells)
            {
                // 跳过当前单元格
                if (cell.Row == r && cell.Col == c) continue;

                // 如果该单元格已有值且等于num，则说明已经存在冲突
                if (context.CellValue(cell.Row, cell.Col) == num) return true;

                // 检查是否已有单候选数等于num
                var candidates = context.GetCandidates(cell.Row, cell.Col);
                if (candidates.Count == 1 && candidates.Contains(num))
                {
                    singleCount++;
                    if (singleCount >= 1) return true;
                }
            }
        }
        return false;
    }

    /// <summary>
    /// 安全地移除候选数，如果移除后会导致候选数为空或产生冲突，则不移除
    /// 参照 Flutter solving_strategies.dart _safeRemoveCandidate
    /// </summary>
    public static bool SafeRemoveCandidate(BoardContext context, int r, int c, int num)
    {
        var currentCandidates = context.GetCandidates(r, c);

        // 如果当前候选数已经只有一个，不移除（避免空白候选）
        if (currentCandidates.Count <= 1) return false;

        // 如果没有该候选数，不需要移除
        if (!currentCandidates.Contains(num)) return false;

        var newCandidates = new HashSet<int>(currentCandidates);
        newCandidates.Remove(num);

        // 如果移除后候选数为空，不移除
        if (newCandidates.Count == 0) return false;

        // 如果移除后变成单候选数，检查是否会产生冲突
        if (newCandidates.Count == 1)
        {
            if (WouldCreateDuplicateSingle(context, r, c, newCandidates.First()))
            {
                return false;
            }
        }

        // 安全移除
        context.RemoveCandidate(r, c, num);
        return true;
    }
}

/// <summary>
/// X-Wing策略
/// 参照 Flutter solving_strategies.dart XWingStrategy
/// </summary>
public class XWingStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.XWing;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Expert;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns) return false;
        bool changed = false;
        var n = context.Size;

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            // 按行查找 X-Wing
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count == 2)
                {
                    rowPositions[r] = positions;
                }
            }

            var rows = rowPositions.Keys.ToList();
            for (int i = 0; i < rows.Count - 1; i++)
            {
                for (int j = i + 1; j < rows.Count; j++)
                {
                    var r1 = rows[i];
                    var r2 = rows[j];
                    if (rowPositions[r1][0] == rowPositions[r2][0] &&
                        rowPositions[r1][1] == rowPositions[r2][1])
                    {
                        var c1 = rowPositions[r1][0];
                        var c2 = rowPositions[r1][1];
                        for (int r = 0; r < n; r++)
                        {
                            if (r == r1 || r == r2) continue;
                            if (StrategyHelpers.SafeRemoveCandidate(context, r, c1, num))
                            {
                                changed = true;
                            }
                            if (StrategyHelpers.SafeRemoveCandidate(context, r, c2, num))
                            {
                                changed = true;
                            }
                        }
                    }
                }
            }

            // 按列查找 X-Wing
            var colPositions = new Dictionary<int, List<int>>();
            for (int c = 0; c < n; c++)
            {
                var positions = new List<int>();
                for (int r = 0; r < n; r++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(r);
                    }
                }
                if (positions.Count == 2)
                {
                    colPositions[c] = positions;
                }
            }

            var cols = colPositions.Keys.ToList();
            for (int i = 0; i < cols.Count - 1; i++)
            {
                for (int j = i + 1; j < cols.Count; j++)
                {
                    var c1 = cols[i];
                    var c2 = cols[j];
                    if (colPositions[c1][0] == colPositions[c2][0] &&
                        colPositions[c1][1] == colPositions[c2][1])
                    {
                        var r1 = colPositions[c1][0];
                        var r2 = colPositions[c1][1];
                        for (int c = 0; c < n; c++)
                        {
                            if (c == c1 || c == c2) continue;
                            if (StrategyHelpers.SafeRemoveCandidate(context, r1, c, num))
                            {
                                changed = true;
                            }
                            if (StrategyHelpers.SafeRemoveCandidate(context, r2, c, num))
                            {
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
/// Swordfish策略
/// 参照 Flutter solving_strategies.dart SwordfishStrategy
/// </summary>
public class SwordfishStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.Swordfish;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Expert;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns) return false;
        bool changed = false;
        var n = context.Size;

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            // 按行查找 Swordfish
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count >= 2 && positions.Count <= 3)
                {
                    rowPositions[r] = positions;
                }
            }

            var rows = rowPositions.Keys.ToList();
            for (int i = 0; i < rows.Count - 2; i++)
            {
                for (int j = i + 1; j < rows.Count - 1; j++)
                {
                    for (int k = j + 1; k < rows.Count; k++)
                    {
                        var r1 = rows[i];
                        var r2 = rows[j];
                        var r3 = rows[k];

                        var cols = new HashSet<int>();
                        cols.UnionWith(rowPositions[r1]);
                        cols.UnionWith(rowPositions[r2]);
                        cols.UnionWith(rowPositions[r3]);

                        if (cols.Count == 3)
                        {
                            // 检查每个列在三行中出现的次数，标准剑鱼要求每个列至少出现2次
                            var colCounts = new Dictionary<int, int>();
                            foreach (var c in rowPositions[r1])
                                colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                            foreach (var c in rowPositions[r2])
                                colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                            foreach (var c in rowPositions[r3])
                                colCounts[c] = colCounts.GetValueOrDefault(c) + 1;

                            // 验证每个列至少出现2次
                            bool validSwordfish = true;
                            foreach (var c in cols)
                            {
                                if (colCounts.GetValueOrDefault(c) < 2)
                                {
                                    validSwordfish = false;
                                    break;
                                }
                            }

                            if (validSwordfish)
                            {
                                for (int r = 0; r < n; r++)
                                {
                                    if (r == r1 || r == r2 || r == r3) continue;
                                    foreach (var c in cols)
                                    {
                                        if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                        {
                                            changed = true;
                                        }
                                    }
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
/// Jellyfish策略
/// 参照 Flutter advanced_strategies.dart JellyfishStrategy
/// </summary>
public class JellyfishStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.Jellyfish;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Advanced;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns) return false;
        bool changed = false;
        var n = context.Size;

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            // 行方向
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count >= 2 && positions.Count <= 4)
                {
                    rowPositions[r] = positions;
                }
            }

            var rows = rowPositions.Keys.ToList();
            for (int i = 0; i < rows.Count - 3; i++)
            {
                for (int j = i + 1; j < rows.Count - 2; j++)
                {
                    for (int k = j + 1; k < rows.Count - 1; k++)
                    {
                        for (int l = k + 1; l < rows.Count; l++)
                        {
                            var r1 = rows[i];
                            var r2 = rows[j];
                            var r3 = rows[k];
                            var r4 = rows[l];

                            var cols = new HashSet<int>();
                            cols.UnionWith(rowPositions[r1]);
                            cols.UnionWith(rowPositions[r2]);
                            cols.UnionWith(rowPositions[r3]);
                            cols.UnionWith(rowPositions[r4]);

                            if (cols.Count == 4)
                            {
                                var colCounts = new Dictionary<int, int>();
                                foreach (var c in rowPositions[r1])
                                    colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                                foreach (var c in rowPositions[r2])
                                    colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                                foreach (var c in rowPositions[r3])
                                    colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                                foreach (var c in rowPositions[r4])
                                    colCounts[c] = colCounts.GetValueOrDefault(c) + 1;

                                bool validJellyfish = true;
                                foreach (var c in cols)
                                {
                                    if (colCounts.GetValueOrDefault(c) < 2)
                                    {
                                        validJellyfish = false;
                                        break;
                                    }
                                }

                                if (validJellyfish)
                                {
                                    for (int r = 0; r < n; r++)
                                    {
                                        if (r == r1 || r == r2 || r == r3 || r == r4) continue;
                                        foreach (var c in cols)
                                        {
                                            if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                            {
                                                changed = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 列方向
            var colPositions = new Dictionary<int, List<int>>();
            for (int c = 0; c < n; c++)
            {
                var positions = new List<int>();
                for (int r = 0; r < n; r++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(r);
                    }
                }
                if (positions.Count >= 2 && positions.Count <= 4)
                {
                    colPositions[c] = positions;
                }
            }

            var colsList = colPositions.Keys.ToList();
            for (int i = 0; i < colsList.Count - 3; i++)
            {
                for (int j = i + 1; j < colsList.Count - 2; j++)
                {
                    for (int k = j + 1; k < colsList.Count - 1; k++)
                    {
                        for (int l = k + 1; l < colsList.Count; l++)
                        {
                            var c1 = colsList[i];
                            var c2 = colsList[j];
                            var c3 = colsList[k];
                            var c4 = colsList[l];

                            var rowSet = new HashSet<int>();
                            rowSet.UnionWith(colPositions[c1]);
                            rowSet.UnionWith(colPositions[c2]);
                            rowSet.UnionWith(colPositions[c3]);
                            rowSet.UnionWith(colPositions[c4]);

                            if (rowSet.Count == 4)
                            {
                                var rowCountMap = new Dictionary<int, int>();
                                foreach (var r in colPositions[c1])
                                    rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;
                                foreach (var r in colPositions[c2])
                                    rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;
                                foreach (var r in colPositions[c3])
                                    rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;
                                foreach (var r in colPositions[c4])
                                    rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;

                                bool validJellyfishCol = true;
                                foreach (var r in rowSet)
                                {
                                    if (rowCountMap.GetValueOrDefault(r) < 2)
                                    {
                                        validJellyfishCol = false;
                                        break;
                                    }
                                }

                                if (validJellyfishCol)
                                {
                                    for (int c = 0; c < n; c++)
                                    {
                                        if (c == c1 || c == c2 || c == c3 || c == c4) continue;
                                        foreach (var r in rowSet)
                                        {
                                            if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                            {
                                                changed = true;
                                            }
                                        }
                                    }
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
/// XY-Wing策略
/// 参照 Flutter advanced_strategies.dart XYWingStrategy
/// </summary>
public class XYWingStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.XYWing;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Expert;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns) return false;
        bool changed = false;
        var n = context.Size;

        var bivalueCells = new List<(int r, int c, HashSet<int> candidates)>();
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (context.CellValue(r, c) != null) continue;
                var candidates = context.GetCandidates(r, c);
                if (candidates.Count == 2)
                {
                    bivalueCells.Add((r, c, new HashSet<int>(candidates)));
                }
            }
        }

        for (int bIdx = 0; bIdx < bivalueCells.Count; bIdx++)
        {
            var (br, bc, bCands) = bivalueCells[bIdx];
            var bList = bCands.ToList();
            var x = bList[0];
            var y = bList[1];

            for (int aIdx = 0; aIdx < bivalueCells.Count; aIdx++)
            {
                if (aIdx == bIdx) continue;
                var (ar, ac, aCands) = bivalueCells[aIdx];
                if (!StrategyHelpers.ShareRegion(context, ar, ac, br, bc)) continue;
                if (!aCands.Contains(x) || aCands.Contains(y)) continue;

                var aList = aCands.ToList();
                var z = aList[0] == x ? aList[1] : aList[0];

                for (int cIdx = 0; cIdx < bivalueCells.Count; cIdx++)
                {
                    if (cIdx == bIdx || cIdx == aIdx) continue;
                    var (cr, cc, cCands) = bivalueCells[cIdx];
                    if (!StrategyHelpers.ShareRegion(context, cr, cc, br, bc)) continue;
                    if (!cCands.Contains(y) || cCands.Contains(x)) continue;
                    if (!cCands.Contains(z)) continue;

                    for (int r = 0; r < n; r++)
                    {
                        for (int c = 0; c < n; c++)
                        {
                            if (r == ar && c == ac) continue;
                            if (r == br && c == bc) continue;
                            if (r == cr && c == cc) continue;
                            if (context.CellValue(r, c) != null) continue;
                            if (!StrategyHelpers.ShareRegion(context, r, c, ar, ac)) continue;
                            if (!StrategyHelpers.ShareRegion(context, r, c, cr, cc)) continue;

                            if (StrategyHelpers.SafeRemoveCandidate(context, r, c, z))
                            {
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
/// XYZ-Wing策略
/// 参照 Flutter advanced_strategies.dart XYZWingStrategy
/// </summary>
public class XYZWingStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.XYZWing;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Expert;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns) return false;
        bool changed = false;
        var n = context.Size;

        var bivalueCells = new List<(int r, int c, HashSet<int> candidates)>();
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (context.CellValue(r, c) != null) continue;
                var candidates = context.GetCandidates(r, c);
                if (candidates.Count == 2)
                {
                    bivalueCells.Add((r, c, new HashSet<int>(candidates)));
                }
            }
        }

        var trivalueCells = new List<(int r, int c, HashSet<int> candidates)>();
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (context.CellValue(r, c) != null) continue;
                var candidates = context.GetCandidates(r, c);
                if (candidates.Count == 3)
                {
                    trivalueCells.Add((r, c, new HashSet<int>(candidates)));
                }
            }
        }

        foreach (var (ar, ac, aCands) in trivalueCells)
        {
            foreach (var (br, bc, bCands) in bivalueCells)
            {
                if (!StrategyHelpers.ShareRegion(context, ar, ac, br, bc)) continue;
                if (!aCands.IsSupersetOf(bCands)) continue;

                foreach (var (cr, cc, cCands) in bivalueCells)
                {
                    if (br == cr && bc == cc) continue;
                    if (!StrategyHelpers.ShareRegion(context, ar, ac, cr, cc)) continue;
                    if (!aCands.IsSupersetOf(cCands)) continue;

                    var commonBC = new HashSet<int>(bCands);
                    commonBC.IntersectWith(cCands);
                    if (commonBC.Count != 1) continue;
                    var z = commonBC.First();

                    var unionBC = new HashSet<int>(bCands);
                    unionBC.UnionWith(cCands);
                    if (!unionBC.SetEquals(aCands)) continue;

                    for (int r = 0; r < n; r++)
                    {
                        for (int c = 0; c < n; c++)
                        {
                            if (r == ar && c == ac) continue;
                            if (r == br && c == bc) continue;
                            if (r == cr && c == cc) continue;
                            if (context.CellValue(r, c) != null) continue;
                            if (!StrategyHelpers.ShareRegion(context, r, c, ar, ac)) continue;
                            if (!StrategyHelpers.ShareRegion(context, r, c, br, bc)) continue;
                            if (!StrategyHelpers.ShareRegion(context, r, c, cr, cc)) continue;

                            if (StrategyHelpers.SafeRemoveCandidate(context, r, c, z))
                            {
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
/// 唯一矩形策略
/// 参照 Flutter advanced_strategies.dart UniqueRectangleStrategy
/// </summary>
public class UniqueRectangleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.UniqueRectangle;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Expert;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        // 限制只在标准数独上执行（检查是否有标准行列宫约束）
        if (!context.HasGlobalRowsAndColumns || !context.HasGlobalBlocks) return false;

        bool changed = false;
        var n = context.Size;

        var pairCells = new List<(int r, int c, int a, int b)>();
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (context.CellValue(r, c) != null) continue;
                var candidates = context.GetCandidates(r, c);
                if (candidates.Count == 2)
                {
                    var list = candidates.OrderBy(x => x).ToList();
                    pairCells.Add((r, c, list[0], list[1]));
                }
            }
        }

        var pairMap = new Dictionary<(int, int), List<(int, int)>>();
        foreach (var (r, c, a, b) in pairCells)
        {
            var key = (a, b);
            if (!pairMap.ContainsKey(key))
            {
                pairMap[key] = new List<(int, int)>();
            }
            pairMap[key].Add((r, c));
        }

        foreach (var entry in pairMap)
        {
            var cells = entry.Value;
            if (cells.Count < 3) continue;

            for (int i = 0; i < cells.Count - 1; i++)
            {
                for (int j = i + 1; j < cells.Count; j++)
                {
                    var (r1, c1) = cells[i];
                    var (r2, c2) = cells[j];
                    if (r1 == r2 || c1 == c2) continue;

                    var cand12 = context.GetCandidates(r1, c2);
                    var cand21 = context.GetCandidates(r2, c1);

                    var pair = entry.Key;
                    var pairSet = new HashSet<int> { pair.Item1, pair.Item2 };

                    if (context.CellValue(r1, c2) != null) continue;
                    if (context.CellValue(r2, c1) != null) continue;
                    if (!pairSet.IsSubsetOf(cand12) || !pairSet.IsSubsetOf(cand21)) continue;

                    var fourCorners = new List<HashSet<int>>
                    {
                        context.GetCandidates(r1, c1),
                        context.GetCandidates(r2, c2),
                        cand12,
                        cand21
                    };

                    int exactPairCount = 0;
                    int extraIndex = -1;
                    for (int idx = 0; idx < 4; idx++)
                    {
                        if (fourCorners[idx].SetEquals(pairSet))
                        {
                            exactPairCount++;
                        }
                        else if (fourCorners[idx].Count > 2 &&
                            pairSet.IsSupersetOf(fourCorners[idx]))
                        {
                            if (extraIndex == -1)
                            {
                                extraIndex = idx;
                            }
                            else
                            {
                                extraIndex = -2;
                            }
                        }
                    }

                    if (exactPairCount == 3 && extraIndex >= 0)
                    {
                        int er, ec;
                        switch (extraIndex)
                        {
                            case 0: er = r1; ec = c1; break;
                            case 1: er = r2; ec = c2; break;
                            case 2: er = r1; ec = c2; break;
                            case 3: er = r2; ec = c1; break;
                            default: continue;
                        }

                        var currentCandidates = context.GetCandidates(er, ec);
                        if (currentCandidates.Count > 1)
                        {
                            var newCandidates = new HashSet<int>(currentCandidates);
                            newCandidates.IntersectWith(pairSet);

                            if (newCandidates.Count != currentCandidates.Count)
                            {
                                if (newCandidates.Count == 1)
                                {
                                    if (!StrategyHelpers.WouldCreateDuplicateSingle(context, er, ec, newCandidates.First()))
                                    {
                                        context.SetCandidates(er, ec, newCandidates);
                                        changed = true;
                                    }
                                }
                                else
                                {
                                    context.SetCandidates(er, ec, newCandidates);
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
/// 双弦风筝策略
/// 参照 Flutter advanced_strategies.dart TwoStringKiteStrategy
/// </summary>
public class TwoStringKiteStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.TwoStringKite;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Master;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns || !context.HasGlobalBlocks) return false;
        bool changed = false;
        var n = context.Size;

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count == 2)
                {
                    rowPositions[r] = positions;
                }
            }

            var colPositions = new Dictionary<int, List<int>>();
            for (int c = 0; c < n; c++)
            {
                var positions = new List<int>();
                for (int r = 0; r < n; r++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(r);
                    }
                }
                if (positions.Count == 2)
                {
                    colPositions[c] = positions;
                }
            }

            bool SameBlock(int r1, int c1, int r2, int c2)
            {
                foreach (var regIdx in context.CellToRegions[r1][c1])
                {
                    if (context.GetRegionType(regIdx) == RegionType.Block)
                    {
                        var region = context.GetRegion(regIdx);
                        if (region.ContainsCoordinate(r2, c2)) return true;
                    }
                }
                return false;
            }

            bool Sees(int r1, int c1, int r2, int c2)
            {
                if (r1 == r2 || c1 == c2) return true;
                return SameBlock(r1, c1, r2, c2);
            }

            foreach (var rowEntry in rowPositions)
            {
                var row = rowEntry.Key;
                var cols = rowEntry.Value;
                var c1 = cols[0];
                var c2 = cols[1];

                foreach (var colEntry in colPositions)
                {
                    var col = colEntry.Key;
                    if (col == c1 || col == c2) continue;

                    var rows = colEntry.Value;
                    var r1 = rows[0];
                    var r2 = rows[1];

                    if (SameBlock(r1, c1, r2, c2))
                    {
                        for (int r = 0; r < n; r++)
                        {
                            for (int c = 0; c < n; c++)
                            {
                                if (r == r1 && c == c1) continue;
                                if (r == r2 && c == c2) continue;
                                if (r == row && (c == c1 || c == c2)) continue;
                                if (c == col && (r == r1 || r == r2)) continue;
                                if (context.CellValue(r, c) != null) continue;
                                if (!Sees(r, c, r1, c1)) continue;
                                if (!Sees(r, c, r2, c2)) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                {
                                    changed = true;
                                }
                            }
                        }
                    }

                    if (SameBlock(r1, c2, r2, c1))
                    {
                        for (int r = 0; r < n; r++)
                        {
                            for (int c = 0; c < n; c++)
                            {
                                if (r == r1 && c == c2) continue;
                                if (r == r2 && c == c1) continue;
                                if (r == row && (c == c1 || c == c2)) continue;
                                if (c == col && (r == r1 || r == r2)) continue;
                                if (context.CellValue(r, c) != null) continue;
                                if (!Sees(r, c, r1, c2)) continue;
                                if (!Sees(r, c, r2, c1)) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                {
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
/// 摩天楼策略
/// 参照 Flutter advanced_strategies.dart SkyscraperStrategy
/// </summary>
public class SkyscraperStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.Skyscraper;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Master;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns || !context.HasGlobalBlocks) return false;
        bool changed = false;
        var n = context.Size;

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count == 2)
                {
                    rowPositions[r] = positions;
                }
            }

            var rows = rowPositions.Keys.ToList();
            for (int i = 0; i < rows.Count - 1; i++)
            {
                for (int j = i + 1; j < rows.Count; j++)
                {
                    var r1 = rows[i];
                    var r2 = rows[j];
                    var cols1 = rowPositions[r1];
                    var cols2 = rowPositions[r2];

                    if (cols1.Intersect(cols2).Any()) continue;

                    var combinations = new List<(int, int)>
                    {
                        (cols1[0], cols2[0]),
                        (cols1[0], cols2[1]),
                        (cols1[1], cols2[0]),
                        (cols1[1], cols2[1])
                    };

                    foreach (var (baseCol, topCol) in combinations)
                    {
                        bool InSameBlock(int rA, int cA, int rB, int cB)
                        {
                            foreach (var regIdx in context.CellToRegions[rA][cA])
                            {
                                if (context.GetRegionType(regIdx) == RegionType.Block)
                                {
                                    var region = context.GetRegion(regIdx);
                                    if (region.ContainsCoordinate(rB, cB)) return true;
                                }
                            }
                            return false;
                        }

                        if (InSameBlock(r1, baseCol, r2, topCol))
                        {
                            foreach (var regIdx in context.CellToRegions[r2][topCol])
                            {
                                if (context.GetRegionType(regIdx) != RegionType.Block) continue;
                                var region = context.GetRegion(regIdx);
                                foreach (var cell in region.Cells)
                                {
                                    if (cell.Col != baseCol) continue;
                                    if (cell.Row == r1 && cell.Col == baseCol) continue;
                                    if (context.CellValue(cell.Row, cell.Col) != null) continue;

                                    if (StrategyHelpers.SafeRemoveCandidate(context, cell.Row, cell.Col, num))
                                    {
                                        changed = true;
                                    }
                                }
                            }

                            foreach (var regIdx in context.CellToRegions[r1][baseCol])
                            {
                                if (context.GetRegionType(regIdx) != RegionType.Block) continue;
                                var region = context.GetRegion(regIdx);
                                foreach (var cell in region.Cells)
                                {
                                    if (cell.Col != topCol) continue;
                                    if (cell.Row == r2 && cell.Col == topCol) continue;
                                    if (context.CellValue(cell.Row, cell.Col) != null) continue;

                                    if (StrategyHelpers.SafeRemoveCandidate(context, cell.Row, cell.Col, num))
                                    {
                                        changed = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 列方向
            var colPositions = new Dictionary<int, List<int>>();
            for (int c = 0; c < n; c++)
            {
                var positions = new List<int>();
                for (int r = 0; r < n; r++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(r);
                    }
                }
                if (positions.Count == 2)
                {
                    colPositions[c] = positions;
                }
            }

            var cols = colPositions.Keys.ToList();
            for (int i = 0; i < cols.Count - 1; i++)
            {
                for (int j = i + 1; j < cols.Count; j++)
                {
                    var c1 = cols[i];
                    var c2 = cols[j];
                    var rows1 = colPositions[c1];
                    var rows2 = colPositions[c2];

                    if (rows1.Intersect(rows2).Any()) continue;

                    var combinations = new List<(int, int)>
                    {
                        (rows1[0], rows2[0]),
                        (rows1[0], rows2[1]),
                        (rows1[1], rows2[0]),
                        (rows1[1], rows2[1])
                    };

                    foreach (var (baseRow, topRow) in combinations)
                    {
                        bool InSameBlock(int rA, int cA, int rB, int cB)
                        {
                            foreach (var regIdx in context.CellToRegions[rA][cA])
                            {
                                if (context.GetRegionType(regIdx) == RegionType.Block)
                                {
                                    var region = context.GetRegion(regIdx);
                                    if (region.ContainsCoordinate(rB, cB)) return true;
                                }
                            }
                            return false;
                        }

                        if (InSameBlock(baseRow, c1, topRow, c2))
                        {
                            foreach (var regIdx in context.CellToRegions[topRow][c2])
                            {
                                if (context.GetRegionType(regIdx) != RegionType.Block) continue;
                                var region = context.GetRegion(regIdx);
                                foreach (var cell in region.Cells)
                                {
                                    if (cell.Row != baseRow) continue;
                                    if (cell.Row == baseRow && cell.Col == c1) continue;
                                    if (context.CellValue(cell.Row, cell.Col) != null) continue;

                                    if (StrategyHelpers.SafeRemoveCandidate(context, cell.Row, cell.Col, num))
                                    {
                                        changed = true;
                                    }
                                }
                            }

                            foreach (var regIdx in context.CellToRegions[baseRow][c1])
                            {
                                if (context.GetRegionType(regIdx) != RegionType.Block) continue;
                                var region = context.GetRegion(regIdx);
                                foreach (var cell in region.Cells)
                                {
                                    if (cell.Row != topRow) continue;
                                    if (cell.Row == topRow && cell.Col == c2) continue;
                                    if (context.CellValue(cell.Row, cell.Col) != null) continue;

                                    if (StrategyHelpers.SafeRemoveCandidate(context, cell.Row, cell.Col, num))
                                    {
                                        changed = true;
                                    }
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
/// 空矩形策略
/// 参照 Flutter advanced_strategies.dart EmptyRectangleStrategy
/// </summary>
public class EmptyRectangleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.EmptyRectangle;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Master;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalBlocks) return false;
        bool changed = false;
        var n = context.Size;

        // 查找所有block区域
        var blockRegionIndices = new List<int>();
        for (int i = 0; i < context.Board.Regions.Count; i++)
        {
            if (context.Board.Regions[i].Type == RegionType.Block)
            {
                blockRegionIndices.Add(i);
            }
        }

        var maxNumber = context.Board.GetMaxNumber();
        foreach (var boxIdx in blockRegionIndices)
        {
            var region = context.GetRegion(boxIdx);

            var maxNumberLocal = context.Board.GetMaxNumber();
            for (int num = 1; num <= maxNumberLocal; num++)
            {
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

                // 收集宫格中num的候选位置
                var candidateCells = new List<(int r, int c)>();
                foreach (var cell in region.Cells)
                {
                    if (context.HasCandidate(cell.Row, cell.Col, num))
                    {
                        candidateCells.Add((cell.Row, cell.Col));
                    }
                }

                if (candidateCells.Count < 2) continue;

                // 收集宫格中的行和列
                var boxRows = new HashSet<int>();
                var boxCols = new HashSet<int>();
                foreach (var cell in region.Cells)
                {
                    boxRows.Add(cell.Row);
                    boxCols.Add(cell.Col);
                }

                // 收集候选数所在的行和列
                var candRows = new HashSet<int>();
                var candCols = new HashSet<int>();
                foreach (var (r, c) in candidateCells)
                {
                    candRows.Add(r);
                    candCols.Add(c);
                }

                // 空矩形模式：宫格中num不在某些行/列形成矩形
                var missingRows = boxRows.Except(candRows).ToList();
                var missingCols = boxCols.Except(candCols).ToList();

                if (missingRows.Count >= 2 && missingCols.Count >= 2)
                {
                    for (int i = 0; i < missingRows.Count; i++)
                    {
                        for (int j = i + 1; j < missingRows.Count; j++)
                        {
                            var emptyR1 = missingRows[i];
                            var emptyR2 = missingRows[j];

                            for (int k = 0; k < missingCols.Count; k++)
                            {
                                for (int l = k + 1; l < missingCols.Count; l++)
                                {
                                    var row1Positions = new List<int>();
                                    for (int c = 0; c < n; c++)
                                    {
                                        if (boxCols.Contains(c)) continue;
                                        if (context.HasCandidate(emptyR1, c, num))
                                        {
                                            row1Positions.Add(c);
                                        }
                                    }

                                    var row2Positions = new List<int>();
                                    for (int c = 0; c < n; c++)
                                    {
                                        if (boxCols.Contains(c)) continue;
                                        if (context.HasCandidate(emptyR2, c, num))
                                        {
                                            row2Positions.Add(c);
                                        }
                                    }

                                    if (row1Positions.Count == 2 && row2Positions.Count == 2 &&
                                        row1Positions.ToHashSet().SetEquals(row2Positions.ToHashSet()))
                                    {
                                        foreach (var c in row1Positions)
                                        {
                                            for (int r = 0; r < n; r++)
                                            {
                                                if (r == emptyR1 || r == emptyR2) continue;
                                                if (boxRows.Contains(r)) continue;
                                                if (context.HasCandidate(r, c, num))
                                                {
                                                    var currentCandidates = context.GetCandidates(r, c);
                                                    if (currentCandidates.Count > 1)
                                                    {
                                                        if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                                        {
                                                            changed = true;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
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
/// 带鳍X-Wing策略
/// 参照 Flutter advanced_strategies.dart FinnedXWingStrategy
/// </summary>
public class FinnedXWingStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.FinnedXWing;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Master;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns || !context.HasGlobalBlocks) return false;
        bool changed = false;
        var n = context.Size;

        var blockRegionIndices = new List<int>();
        for (int i = 0; i < context.Board.Regions.Count; i++)
        {
            if (context.Board.Regions[i].Type == RegionType.Block)
            {
                blockRegionIndices.Add(i);
            }
        }

        var cellToBlock = new Dictionary<(int, int), int>();
        foreach (var boxIdx in blockRegionIndices)
        {
            var region = context.GetRegion(boxIdx);
            foreach (var cell in region.Cells)
            {
                cellToBlock[(cell.Row, cell.Col)] = boxIdx;
            }
        }

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            // 行方向
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count == 2 || positions.Count == 3)
                {
                    rowPositions[r] = positions;
                }
            }

            var rows = rowPositions.Keys.ToList();
            for (int i = 0; i < rows.Count - 1; i++)
            {
                for (int j = i + 1; j < rows.Count; j++)
                {
                    var r1 = rows[i];
                    var r2 = rows[j];
                    var cols1 = rowPositions[r1];
                    var cols2 = rowPositions[r2];

                    var commonCols = cols1.Intersect(cols2).ToList();
                    if (commonCols.Count != 1) continue;

                    var baseCol = commonCols[0];
                    var fin1 = cols1.Where(c => c != baseCol).ToList();
                    var fin2 = cols2.Where(c => c != baseCol).ToList();

                    if (fin1.Count == 0 && fin2.Count == 1)
                    {
                        var finCol = fin2[0];
                        if (cellToBlock.TryGetValue((r1, baseCol), out var blockOfBase1) &&
                            cellToBlock.TryGetValue((r2, finCol), out var blockOfFin) &&
                            blockOfBase1 == blockOfFin)
                        {
                            for (int r = 0; r < n; r++)
                            {
                                if (r == r1 || r == r2) continue;
                                if (cellToBlock.TryGetValue((r, baseCol), out var blockOfR) &&
                                    blockOfR == blockOfBase1) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, r, baseCol, num))
                                {
                                    changed = true;
                                }
                            }
                        }
                    }
                    else if (fin2.Count == 0 && fin1.Count == 1)
                    {
                        var finCol = fin1[0];
                        if (cellToBlock.TryGetValue((r2, baseCol), out var blockOfBase2) &&
                            cellToBlock.TryGetValue((r1, finCol), out var blockOfFin) &&
                            blockOfBase2 == blockOfFin)
                        {
                            for (int r = 0; r < n; r++)
                            {
                                if (r == r1 || r == r2) continue;
                                if (cellToBlock.TryGetValue((r, baseCol), out var blockOfR) &&
                                    blockOfR == blockOfBase2) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, r, baseCol, num))
                                {
                                    changed = true;
                                }
                            }
                        }
                    }
                }
            }

            // 列方向
            var colPositions = new Dictionary<int, List<int>>();
            for (int c = 0; c < n; c++)
            {
                var positions = new List<int>();
                for (int r = 0; r < n; r++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(r);
                    }
                }
                if (positions.Count == 2 || positions.Count == 3)
                {
                    colPositions[c] = positions;
                }
            }

            var colsList = colPositions.Keys.ToList();
            for (int i = 0; i < colsList.Count - 1; i++)
            {
                for (int j = i + 1; j < colsList.Count; j++)
                {
                    var c1 = colsList[i];
                    var c2 = colsList[j];
                    var rows1 = colPositions[c1];
                    var rows2 = colPositions[c2];

                    var commonRows = rows1.Intersect(rows2).ToList();
                    if (commonRows.Count != 1) continue;

                    var baseRow = commonRows[0];
                    var fin1 = rows1.Where(r => r != baseRow).ToList();
                    var fin2 = rows2.Where(r => r != baseRow).ToList();

                    if (fin1.Count == 0 && fin2.Count == 1)
                    {
                        var finRow = fin2[0];
                        if (cellToBlock.TryGetValue((baseRow, c1), out var blockOfBase1) &&
                            cellToBlock.TryGetValue((finRow, c2), out var blockOfFin) &&
                            blockOfBase1 == blockOfFin)
                        {
                            for (int c = 0; c < n; c++)
                            {
                                if (c == c1 || c == c2) continue;
                                if (cellToBlock.TryGetValue((baseRow, c), out var blockOfC) &&
                                    blockOfC == blockOfBase1) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, baseRow, c, num))
                                {
                                    changed = true;
                                }
                            }
                        }
                    }
                    else if (fin2.Count == 0 && fin1.Count == 1)
                    {
                        var finRow = fin1[0];
                        if (cellToBlock.TryGetValue((baseRow, c2), out var blockOfBase2) &&
                            cellToBlock.TryGetValue((finRow, c1), out var blockOfFin) &&
                            blockOfBase2 == blockOfFin)
                        {
                            for (int c = 0; c < n; c++)
                            {
                                if (c == c1 || c == c2) continue;
                                if (cellToBlock.TryGetValue((baseRow, c), out var blockOfC) &&
                                    blockOfC == blockOfBase2) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, baseRow, c, num))
                                {
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
/// 带鳍Swordfish策略
/// 参照 Flutter advanced_strategies.dart FinnedSwordfishStrategy
/// </summary>
public class FinnedSwordfishStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.FinnedSwordfish;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Master;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new(Enum.GetValues<GameType>());

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        if (!context.HasGlobalRowsAndColumns || !context.HasGlobalBlocks) return false;
        bool changed = false;
        var n = context.Size;

        var blockRegionIndices = new List<int>();
        for (int i = 0; i < context.Board.Regions.Count; i++)
        {
            if (context.Board.Regions[i].Type == RegionType.Block)
            {
                blockRegionIndices.Add(i);
            }
        }

        var cellToBlock = new Dictionary<(int, int), int>();
        foreach (var boxIdx in blockRegionIndices)
        {
            var region = context.GetRegion(boxIdx);
            foreach (var cell in region.Cells)
            {
                cellToBlock[(cell.Row, cell.Col)] = boxIdx;
            }
        }

        var maxNumber = context.Board.GetMaxNumber();
        for (int num = 1; num <= maxNumber; num++)
        {
            // 行方向
            var rowPositions = new Dictionary<int, List<int>>();
            for (int r = 0; r < n; r++)
            {
                var positions = new List<int>();
                for (int c = 0; c < n; c++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(c);
                    }
                }
                if (positions.Count >= 2 && positions.Count <= 4)
                {
                    rowPositions[r] = positions;
                }
            }

            var rows = rowPositions.Keys.ToList();
            for (int i = 0; i < rows.Count - 2; i++)
            {
                for (int j = i + 1; j < rows.Count - 1; j++)
                {
                    for (int k = j + 1; k < rows.Count; k++)
                    {
                        var r1 = rows[i];
                        var r2 = rows[j];
                        var r3 = rows[k];

                        var allCols = new HashSet<int>();
                        allCols.UnionWith(rowPositions[r1]);
                        allCols.UnionWith(rowPositions[r2]);
                        allCols.UnionWith(rowPositions[r3]);

                        if (allCols.Count < 3 || allCols.Count > 4) continue;
                        if (allCols.Count == 3) continue; // 标准Swordfish已在别处处理

                        var colCounts = new Dictionary<int, int>();
                        foreach (var c in rowPositions[r1])
                            colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                        foreach (var c in rowPositions[r2])
                            colCounts[c] = colCounts.GetValueOrDefault(c) + 1;
                        foreach (var c in rowPositions[r3])
                            colCounts[c] = colCounts.GetValueOrDefault(c) + 1;

                        var finCols = new List<int>();
                        var baseCols = new List<int>();
                        foreach (var c in allCols)
                        {
                            if (colCounts.GetValueOrDefault(c) == 1)
                            {
                                finCols.Add(c);
                            }
                            else
                            {
                                baseCols.Add(c);
                            }
                        }

                        if (finCols.Count != 1 || baseCols.Count != 3) continue;

                        var finCol = finCols[0];
                        int? finRow = null;
                        if (rowPositions[r1].Contains(finCol)) finRow = r1;
                        else if (rowPositions[r2].Contains(finCol)) finRow = r2;
                        else finRow = r3;

                        bool validFinned = false;
                        int? finBlock = null;
                        foreach (var baseC in baseCols)
                        {
                            if (cellToBlock.TryGetValue((finRow.Value, finCol), out var blockOfFin) &&
                                cellToBlock.TryGetValue((finRow.Value, baseC), out var blockOfBase) &&
                                blockOfFin == blockOfBase)
                            {
                                validFinned = true;
                                finBlock = blockOfFin;
                                break;
                            }
                        }

                        if (!validFinned || finBlock == null) continue;

                        foreach (var c in baseCols)
                        {
                            for (int r = 0; r < n; r++)
                            {
                                if (r == r1 || r == r2 || r == r3) continue;
                                if (cellToBlock.TryGetValue((r, c), out var blockOfR) &&
                                    blockOfR == finBlock) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                {
                                    changed = true;
                                }
                            }
                        }
                    }
                }
            }

            // 列方向
            var colPositions = new Dictionary<int, List<int>>();
            for (int c = 0; c < n; c++)
            {
                var positions = new List<int>();
                for (int r = 0; r < n; r++)
                {
                    if (context.HasCandidate(r, c, num))
                    {
                        positions.Add(r);
                    }
                }
                if (positions.Count >= 2 && positions.Count <= 4)
                {
                    colPositions[c] = positions;
                }
            }

            var colsList = colPositions.Keys.ToList();
            for (int i = 0; i < colsList.Count - 2; i++)
            {
                for (int j = i + 1; j < colsList.Count - 1; j++)
                {
                    for (int k = j + 1; k < colsList.Count; k++)
                    {
                        var c1 = colsList[i];
                        var c2 = colsList[j];
                        var c3 = colsList[k];

                        var allRows = new HashSet<int>();
                        allRows.UnionWith(colPositions[c1]);
                        allRows.UnionWith(colPositions[c2]);
                        allRows.UnionWith(colPositions[c3]);

                        if (allRows.Count < 3 || allRows.Count > 4) continue;
                        if (allRows.Count == 3) continue;

                        var rowCountMap = new Dictionary<int, int>();
                        foreach (var r in colPositions[c1])
                            rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;
                        foreach (var r in colPositions[c2])
                            rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;
                        foreach (var r in colPositions[c3])
                            rowCountMap[r] = rowCountMap.GetValueOrDefault(r) + 1;

                        var finRows = new List<int>();
                        var baseRows = new List<int>();
                        foreach (var r in allRows)
                        {
                            if (rowCountMap.GetValueOrDefault(r) == 1)
                            {
                                finRows.Add(r);
                            }
                            else
                            {
                                baseRows.Add(r);
                            }
                        }

                        if (finRows.Count != 1 || baseRows.Count != 3) continue;

                        var finRow = finRows[0];
                        int? finCol = null;
                        if (colPositions[c1].Contains(finRow)) finCol = c1;
                        else if (colPositions[c2].Contains(finRow)) finCol = c2;
                        else finCol = c3;

                        bool validFinnedCol = false;
                        int? finBlockCol = null;
                        foreach (var baseR in baseRows)
                        {
                            if (cellToBlock.TryGetValue((finRow, finCol.Value), out var blockOfFin) &&
                                cellToBlock.TryGetValue((baseR, finCol.Value), out var blockOfBase) &&
                                blockOfFin == blockOfBase)
                            {
                                validFinnedCol = true;
                                finBlockCol = blockOfFin;
                                break;
                            }
                        }

                        if (!validFinnedCol || finBlockCol == null) continue;

                        foreach (var r in baseRows)
                        {
                            for (int c = 0; c < n; c++)
                            {
                                if (c == c1 || c == c2 || c == c3) continue;
                                if (cellToBlock.TryGetValue((r, c), out var blockOfC) &&
                                    blockOfC == finBlockCol) continue;

                                if (StrategyHelpers.SafeRemoveCandidate(context, r, c, num))
                                {
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
