using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving.Strategies;

/// <summary>
/// 杀手数独笼子约束策略
/// </summary>
public class KillerCageConstraintStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.KillerCageConstraint;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Basic;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new() { GameType.Killer };

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        var cages = context.KillerCages;
        if (cages == null || cages.Count == 0) return false;

        bool changed = false;

        foreach (var cage in cages)
        {
            var before = CaptureCageCandidates(context, cage);

            KillerCombinationChecker.ApplyCageConstraint(
                cage.Sum,
                cage.CellCoordinates.ToList(),
                (r, c) => context.GetCandidates(r, c),
                (r, c, candidates) => context.SetCandidates(r, c, candidates),
                (r, c) => context.Board.GetCell(r, c).Value,
                context.Board.GetMaxNumber()
            );

            var after = CaptureCageCandidates(context, cage);
            if (!CandidatesEqual(before, after))
            {
                changed = true;
            }
        }

        return changed;
    }

    private Dictionary<(int, int), HashSet<int>> CaptureCageCandidates(BoardContext context, KillerCage cage)
    {
        var result = new Dictionary<(int, int), HashSet<int>>();
        foreach (var (r, c) in cage.CellCoordinates)
        {
            result[(r, c)] = new HashSet<int>(context.GetCandidates(r, c));
        }
        return result;
    }

    private bool CandidatesEqual(Dictionary<(int, int), HashSet<int>> a, Dictionary<(int, int), HashSet<int>> b)
    {
        if (a.Count != b.Count) return false;
        foreach (var key in a.Keys)
        {
            if (!b.TryGetValue(key, out var bSet)) return false;
            if (!a[key].SetEquals(bSet)) return false;
        }
        return true;
    }
}

/// <summary>
/// 杀手数独45规则策略
/// 参照 Flutter killer_strategies.dart Killer45RuleStrategy
/// </summary>
public class Killer45RuleStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.Killer45Rule;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new() { GameType.Killer };

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        var cages = context.KillerCages;
        if (cages == null || cages.Count == 0) return false;

        bool changed = false;
        var n = context.Size;

        for (int i = 0; i < n; i++)
        {
            if (_Apply45RuleToLine(context, i, true)) changed = true;
            if (_Apply45RuleToLine(context, i, false)) changed = true;
            if (_Apply45RuleToBlock(context, i)) changed = true;
        }

        return changed;
    }

    private bool _Apply45RuleToLine(BoardContext context, int index, bool isRow)
    {
        var cells = new List<(int, int)>();
        for (int i = 0; i < context.Size; i++)
        {
            cells.Add(isRow ? (index, i) : (i, index));
        }
        return _Apply45RuleToCells(context, cells);
    }

    private bool _Apply45RuleToBlock(BoardContext context, int blockIndex)
    {
        var maxNumber = context.Board.GetMaxNumber();
        var blockSize = (int)Math.Sqrt(maxNumber);
        var boxRow = (blockIndex / blockSize) * blockSize;
        var boxCol = (blockIndex % blockSize) * blockSize;
        var cells = new List<(int, int)>();
        for (int r = boxRow; r < boxRow + blockSize; r++)
        {
            for (int c = boxCol; c < boxCol + blockSize; c++)
            {
                cells.Add((r, c));
            }
        }
        return _Apply45RuleToCells(context, cells);
    }

    private bool _Apply45RuleToCells(BoardContext context, List<(int, int)> cells)
    {
        var maxNumber = context.Board.GetMaxNumber();
        var targetSum = maxNumber * (maxNumber + 1) / 2;

        int filledSum = 0;
        var unfilled = new List<(int, int)>();
        foreach (var (r, c) in cells)
        {
            var val = context.CellValue(r, c);
            if (val != null)
            {
                filledSum += val.Value;
            }
            else
            {
                unfilled.Add((r, c));
            }
        }

        var cages = context.KillerCages ?? new List<KillerCage>();
        var fullyInside = new HashSet<KillerCage>();
        var partiallyInside = new HashSet<KillerCage>();

        foreach (var cage in cages)
        {
            int inside = 0;
            foreach (var coord in cage.CellCoordinates)
            {
                if (cells.Contains(coord)) inside++;
            }
            if (inside == cage.CellCoordinates.Count)
            {
                fullyInside.Add(cage);
            }
            else if (inside > 0)
            {
                partiallyInside.Add(cage);
            }
        }

        int internalCageRemainingSum = 0;
        foreach (var cage in fullyInside)
        {
            int cageFilled = 0;
            foreach (var coord in cage.CellCoordinates)
            {
                var val = context.CellValue(coord.Item1, coord.Item2);
                if (val != null) cageFilled += val.Value;
            }
            internalCageRemainingSum += cage.Sum - cageFilled;
        }

        // 自由单元格：不在任何笼子内的空单元格
        var freeCells = new List<(int, int)>();
        foreach (var cell in unfilled)
        {
            bool inAnyCage = false;
            foreach (var cage in cages)
            {
                if (cage.CellCoordinates.Contains(cell))
                {
                    inAnyCage = true;
                    break;
                }
            }
            if (!inAnyCage)
            {
                freeCells.Add(cell);
            }
        }

        if (partiallyInside.Count > 0)
        {
            return false;
        }

        var remainingSum = targetSum - filledSum - internalCageRemainingSum;
        if (remainingSum < 0) return false;

        if (freeCells.Count == 1)
        {
            var (r, c) = freeCells[0];
            var oldCandidates = new HashSet<int>(context.GetCandidates(r, c));
            if (remainingSum >= 1 && remainingSum <= maxNumber)
            {
                var newCandidates = new HashSet<int>(oldCandidates);
                newCandidates.IntersectWith(new[] { remainingSum });
                if (newCandidates.Count > 0 && newCandidates.Count != oldCandidates.Count)
                {
                    context.SetCandidates(r, c, newCandidates);
                    return true;
                }
            }
        }
        return false;
    }
}

/// <summary>
/// 杀手数独重叠消除策略
/// 参照 Flutter killer_strategies.dart KillerOverlapEliminationStrategy
/// </summary>
public class KillerOverlapEliminationStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.KillerOverlapElimination;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new() { GameType.Killer };

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        var cages = context.KillerCages;
        if (cages == null || cages.Count == 0) return false;

        bool changed = false;

        var adjacency = new Dictionary<int, HashSet<int>>();
        for (int i = 0; i < cages.Count; i++)
        {
            adjacency[i] = new HashSet<int>();
            for (int j = i + 1; j < cages.Count; j++)
            {
                if (_CagesOverlap(cages[i], cages[j]))
                {
                    adjacency[i].Add(j);
                    adjacency[j].Add(i);
                }
            }
        }

        var visited = new HashSet<int>();
        for (int i = 0; i < cages.Count; i++)
        {
            if (visited.Contains(i)) continue;
            var component = new List<int>();
            var queue = new Queue<int>();
            queue.Enqueue(i);
            while (queue.Count > 0)
            {
                var cur = queue.Dequeue();
                if (visited.Contains(cur)) continue;
                visited.Add(cur);
                component.Add(cur);
                foreach (var neighbor in adjacency[cur])
                {
                    if (!visited.Contains(neighbor))
                    {
                        queue.Enqueue(neighbor);
                    }
                }
            }
            if (component.Count > 1)
            {
                if (_ApplyCrossEliminationForCageGroup(context, component, cages))
                {
                    changed = true;
                }
            }
        }

        return changed;
    }

    private bool _CagesOverlap(KillerCage a, KillerCage b)
    {
        foreach (var cellA in a.CellCoordinates)
        {
            foreach (var cellB in b.CellCoordinates)
            {
                if (cellA.Equals(cellB)) return true;
            }
        }
        return false;
    }

    private bool _ApplyCrossEliminationForCageGroup(BoardContext context, List<int> cageIndices, List<KillerCage> cages)
    {
        bool changed = false;
        var cageGroup = cageIndices.Select(i => cages[i]).ToList();
        var cagePossibleDigits = new Dictionary<KillerCage, HashSet<int>>();
        foreach (var cage in cageGroup)
        {
            cagePossibleDigits[cage] = _GetPossibleDigitsForCage(context, cage);
        }

        var allCells = new HashSet<(int, int)>();
        foreach (var cage in cageGroup)
        {
            foreach (var coord in cage.CellCoordinates)
            {
                allCells.Add(coord);
            }
        }

        foreach (var (r, c) in allCells)
        {
            var relevantCages = cageGroup.Where(cage => cage.CellCoordinates.Contains((r, c))).ToList();
            if (relevantCages.Count < 2) continue;

            var oldSet = new HashSet<int>(context.GetCandidates(r, c));
            if (oldSet.Count == 0) continue;

            HashSet<int>? intersection = null;
            foreach (var cage in relevantCages)
            {
                var possibleDigits = cagePossibleDigits[cage];
                if (intersection == null)
                {
                    intersection = new HashSet<int>(possibleDigits);
                }
                else
                {
                    intersection.IntersectWith(possibleDigits);
                }
                if (intersection.Count == 0) break;
            }

            if (intersection != null && intersection.Count > 0)
            {
                var newSet = new HashSet<int>(oldSet);
                newSet.IntersectWith(intersection);
                if (newSet.Count > 0 && newSet.Count != oldSet.Count)
                {
                    context.SetCandidates(r, c, newSet);
                    changed = true;
                }
            }
        }

        return changed;
    }

    private HashSet<int> _GetPossibleDigitsForCage(BoardContext context, KillerCage cage)
    {
        var cells = cage.CellCoordinates.ToList();
        var sum = cage.Sum;
        var maxNumber = context.Board.GetMaxNumber();

        var filled = new HashSet<int>();
        int filledSum = 0;
        var emptyIndices = new List<int>();
        var emptyCandidates = new List<HashSet<int>>();

        for (int i = 0; i < cells.Count; i++)
        {
            var (r, c) = cells[i];
            var val = context.CellValue(r, c);
            if (val != null)
            {
                filled.Add(val.Value);
                filledSum += val.Value;
            }
            else
            {
                emptyIndices.Add(i);
                emptyCandidates.Add(new HashSet<int>(context.GetCandidates(r, c)));
            }
        }

        var remainingSum = sum - filledSum;
        if (remainingSum < 0 || emptyIndices.Count == 0) return new HashSet<int>();

        var basicPossible = KillerCombinationChecker.GetBasicPossibleDigits(emptyIndices.Count, remainingSum, filled, maxNumber);
        if (basicPossible.Count == 0) return new HashSet<int>();

        bool hasConstraint = false;
        foreach (var cands in emptyCandidates)
        {
            if (cands.Count < maxNumber)
            {
                hasConstraint = true;
                break;
            }
        }
        if (!hasConstraint) return basicPossible;

        var allCombos = KillerCombinationChecker.GetCombinations(emptyIndices.Count, remainingSum, maxNumber);

        var possibleDigits = new HashSet<int>();
        foreach (var combo in allCombos)
        {
            bool valid = true;
            foreach (var num in combo)
            {
                if (filled.Contains(num))
                {
                    valid = false;
                    break;
                }
            }
            if (!valid) continue;

            var assignments = KillerCombinationChecker.GetAssignments(combo, emptyCandidates);
            if (assignments.Count == 0) continue;

            foreach (var posDigits in assignments)
            {
                possibleDigits.UnionWith(posDigits);
            }
        }

        return possibleDigits;
    }
}

/// <summary>
/// 杀手数独笼子阻塞策略
/// 参照 Flutter killer_strategies.dart KillerCageBlockingStrategy
/// </summary>
public class KillerCageBlockingStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.KillerCageBlocking;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Intermediate;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new() { GameType.Killer };

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        var cages = context.KillerCages;
        if (cages == null || cages.Count == 0) return false;

        bool changed = false;
        var maxNumber = context.Board.GetMaxNumber();

        foreach (var cage in cages)
        {
            // 收集笼子内的已填数字
            var filledNumbers = new HashSet<int>();
            var emptyCells = new List<(int r, int c)>();

            foreach (var (r, c) in cage.CellCoordinates)
            {
                var value = context.CellValue(r, c);
                if (value != null)
                {
                    filledNumbers.Add(value.Value);
                }
                else
                {
                    emptyCells.Add((r, c));
                }
            }

            if (emptyCells.Count == 0) continue;

            // 计算剩余和
            int filledSum = filledNumbers.Sum();
            int remainingSum = cage.Sum - filledSum;

            if (remainingSum <= 0) continue;

            // 获取剩余单元格的候选数
            var emptyCandidates = emptyCells
                .Select(cell => context.GetCandidates(cell.r, cell.c))
                .ToList();

            // 获取可能的组合
            var combos = KillerCombinationChecker.GetCombinations(
                emptyCells.Count, remainingSum, maxNumber);

            // 过滤掉包含已填数字的组合
            combos = combos.Where(combo => !combo.Any(n => filledNumbers.Contains(n))).ToList();

            if (combos.Count == 0) continue;

            // 计算每个位置可能的数字
            var positionPossible = new List<HashSet<int>>();
            for (int i = 0; i < emptyCells.Count; i++)
            {
                positionPossible.Add(new HashSet<int>());
            }

            foreach (var combo in combos)
            {
                var assignments = KillerCombinationChecker.GetAssignments(combo, emptyCandidates);
                if (assignments.Count > 0)
                {
                    for (int i = 0; i < emptyCells.Count; i++)
                    {
                        positionPossible[i].UnionWith(assignments[i]);
                    }
                }
            }

            // 应用约束
            for (int i = 0; i < emptyCells.Count; i++)
            {
                var (r, c) = emptyCells[i];
                var currentCandidates = context.GetCandidates(r, c);
                var newCandidates = new HashSet<int>(currentCandidates);
                newCandidates.IntersectWith(positionPossible[i]);

                if (newCandidates.Count > 0 && !newCandidates.SetEquals(currentCandidates))
                {
                    context.SetCandidates(r, c, newCandidates);
                    changed = true;
                }
            }
        }

        return changed;
    }
}

/// <summary>
/// 杀手数独隐式组合策略
/// 参照 Flutter killer_strategies.dart KillerHiddenCombinationStrategy
/// </summary>
public class KillerHiddenCombinationStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.KillerHiddenCombination;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Advanced;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new() { GameType.Killer };

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        var cages = context.KillerCages;
        if (cages == null || cages.Count == 0) return false;

        bool changed = false;
        var maxNumber = context.Board.GetMaxNumber();

        foreach (var cage in cages)
        {
            if (_ApplyHiddenCombination(context, cage, maxNumber))
            {
                changed = true;
            }
        }

        return changed;
    }

    private bool _ApplyHiddenCombination(BoardContext context, KillerCage cage, int maxNumber)
    {
        var cells = cage.CellCoordinates.ToList();
        var sum = cage.Sum;

        var filled = new HashSet<int>();
        int filledSum = 0;
        var emptyIndices = new List<int>();
        var emptyCandidates = new List<HashSet<int>>();

        for (int i = 0; i < cells.Count; i++)
        {
            var (r, c) = cells[i];
            var val = context.CellValue(r, c);
            if (val != null)
            {
                filled.Add(val.Value);
                filledSum += val.Value;
            }
            else
            {
                emptyIndices.Add(i);
                emptyCandidates.Add(new HashSet<int>(context.GetCandidates(r, c)));
            }
        }

        var remainingSum = sum - filledSum;
        if (remainingSum < 0 || emptyIndices.Count == 0) return false;

        var allCombos = KillerCombinationChecker.GetCombinations(emptyIndices.Count, remainingSum, maxNumber);
        if (allCombos.Count == 0) return false;

        var validCombos = new List<List<int>>();
        foreach (var combo in allCombos)
        {
            bool valid = true;
            foreach (var num in combo)
            {
                if (filled.Contains(num))
                {
                    valid = false;
                    break;
                }
            }
            if (!valid) continue;

            var assignments = KillerCombinationChecker.GetAssignments(combo, emptyCandidates);
            if (assignments.Count == 0) continue;

            validCombos.Add(combo);
        }

        if (validCombos.Count == 0) return false;

        HashSet<int>? commonDigits = null;
        foreach (var combo in validCombos)
        {
            if (commonDigits == null)
            {
                commonDigits = new HashSet<int>(combo);
            }
            else
            {
                commonDigits.IntersectWith(combo);
            }
            if (commonDigits.Count == 0) break;
        }

        if (commonDigits == null || commonDigits.Count == 0) return false;

        var blockSize = (int)Math.Sqrt(maxNumber);
        var firstRow = cells[0].Item1;
        var firstCol = cells[0].Item2;
        var firstBlock = (firstRow / blockSize) * blockSize + (firstCol / blockSize);

        bool sameRow = cells.All(c => c.Item1 == firstRow);
        bool sameCol = cells.All(c => c.Item2 == firstCol);
        bool sameBlock = cells.All(c => (c.Item1 / blockSize) * blockSize + (c.Item2 / blockSize) == firstBlock);

        if (!sameRow && !sameCol && !sameBlock) return false;

        var modifications = new List<(int, int, HashSet<int>)>();

        if (sameRow)
        {
            int row = firstRow;
            for (int c = 0; c < context.Size; c++)
            {
                if (cells.Any(cell => cell.Item2 == c)) continue;
                var oldSet = new HashSet<int>(context.GetCandidates(row, c));
                var newSet = new HashSet<int>(oldSet);
                newSet.ExceptWith(commonDigits);
                if (newSet.Count == 0) continue;
                if (newSet.Count != oldSet.Count)
                {
                    modifications.Add((row, c, newSet));
                }
            }
        }
        else if (sameCol)
        {
            int col = firstCol;
            for (int r = 0; r < context.Size; r++)
            {
                if (cells.Any(cell => cell.Item1 == r)) continue;
                var oldSet = new HashSet<int>(context.GetCandidates(r, col));
                var newSet = new HashSet<int>(oldSet);
                newSet.ExceptWith(commonDigits);
                if (newSet.Count == 0) continue;
                if (newSet.Count != oldSet.Count)
                {
                    modifications.Add((r, col, newSet));
                }
            }
        }
        else if (sameBlock)
        {
            int blockRow = firstRow / blockSize;
            int blockCol = firstCol / blockSize;
            for (int r = blockRow * blockSize; r < (blockRow + 1) * blockSize; r++)
            {
                for (int c = blockCol * blockSize; c < (blockCol + 1) * blockSize; c++)
                {
                    if (cells.Any(cell => cell.Item1 == r && cell.Item2 == c)) continue;
                    var oldSet = new HashSet<int>(context.GetCandidates(r, c));
                    var newSet = new HashSet<int>(oldSet);
                    newSet.ExceptWith(commonDigits);
                    if (newSet.Count == 0) continue;
                    if (newSet.Count != oldSet.Count)
                    {
                        modifications.Add((r, c, newSet));
                    }
                }
            }
        }

        if (modifications.Count == 0) return false;

        foreach (var (r, c, newSet) in modifications)
        {
            context.SetCandidates(r, c, newSet);
        }
        return true;
    }
}

/// <summary>
/// 杀手数独笼子分割策略
/// 参照 Flutter killer_strategies.dart KillerCageSplittingStrategy
/// </summary>
public class KillerCageSplittingStrategy : Strategy
{
    /// <inheritdoc/>
    public override StrategyType Type => StrategyType.KillerCageSplitting;

    /// <inheritdoc/>
    public override StrategyLevel Level => StrategyLevel.Expert;

    /// <inheritdoc/>
    public override HashSet<GameType> ApplicableGames => new() { GameType.Killer };

    /// <inheritdoc/>
    public override bool Apply(BoardContext context)
    {
        var cages = context.KillerCages;
        if (cages == null || cages.Count == 0) return false;

        bool changed = false;
        var maxNumber = context.Board.GetMaxNumber();

        foreach (var cage in cages)
        {
            if (_ApplyCageSplitting(context, cage, maxNumber))
            {
                changed = true;
            }
        }

        return changed;
    }

    private bool _ApplyCageSplitting(BoardContext context, KillerCage cage, int maxNumber)
    {
        var cells = cage.CellCoordinates.ToList();
        var sum = cage.Sum;

        var filled = new HashSet<int>();
        int filledSum = 0;
        var emptyIndices = new List<int>();
        var emptyCells = new List<(int, int)>();

        for (int i = 0; i < cells.Count; i++)
        {
            var (r, c) = cells[i];
            var val = context.CellValue(r, c);
            if (val != null)
            {
                filled.Add(val.Value);
                filledSum += val.Value;
            }
            else
            {
                emptyIndices.Add(i);
                emptyCells.Add((r, c));
            }
        }

        if (emptyCells.Count <= 1) return false;

        var components = FindConnectedComponents(emptyCells, context);
        if (components.Count <= 1) return false;

        var remainingSum = sum - filledSum;
        if (remainingSum <= 0) return false;

        var componentCombos = new Dictionary<int, List<List<int>>>();
        bool allComponentsValid = true;

        foreach (var (index, component) in components.Select((comp, idx) => (idx, comp)))
        {
            var k = component.Count;
            var possibleSums = new List<int>();

            for (int s = k * (k + 1) / 2; s <= k * maxNumber - k * (k - 1) / 2; s++)
            {
                possibleSums.Add(s);
            }

            var combos = new List<List<int>>();
            foreach (var s in possibleSums)
            {
                var c = KillerCombinationChecker.GetCombinations(k, s, maxNumber);
                combos.AddRange(c.Where(combo => !combo.Any(n => filled.Contains(n))));
            }

            if (combos.Count == 0)
            {
                allComponentsValid = false;
                break;
            }

            componentCombos[index] = combos;
        }

        if (!allComponentsValid) return false;

        bool changed = false;

        foreach (var (index, component) in components.Select((comp, idx) => (idx, comp)))
        {
            var k = component.Count;
            var possibleSums = new List<int>();

            for (int s = k * (k + 1) / 2; s <= k * maxNumber - k * (k - 1) / 2; s++)
            {
                int remainingForOthers = remainingSum - s;
                bool valid = true;

                foreach (var (otherIdx, otherComp) in components.Select((comp, idx) => (idx, comp)))
                {
                    if (otherIdx == index) continue;
                    var otherK = otherComp.Count;
                    var minSum = otherK * (otherK + 1) / 2;
                    var maxSum = otherK * maxNumber - otherK * (otherK - 1) / 2;

                    if (remainingForOthers < minSum || remainingForOthers > maxSum)
                    {
                        valid = false;
                        break;
                    }
                    remainingForOthers -= minSum;
                }

                if (valid)
                {
                    possibleSums.Add(s);
                }
            }

            if (possibleSums.Count == 0) continue;

            var possibleDigits = new HashSet<int>();
            foreach (var s in possibleSums)
            {
                var combos = KillerCombinationChecker.GetCombinations(k, s, maxNumber);
                foreach (var combo in combos)
                {
                    if (combo.Any(n => filled.Contains(n))) continue;
                    possibleDigits.UnionWith(combo);
                }
            }

            if (possibleDigits.Count == 0) continue;

            foreach (var (r, c) in component)
            {
                var oldCandidates = new HashSet<int>(context.GetCandidates(r, c));
                var newCandidates = new HashSet<int>(oldCandidates);
                newCandidates.IntersectWith(possibleDigits);

                if (newCandidates.Count > 0 && !newCandidates.SetEquals(oldCandidates))
                {
                    context.SetCandidates(r, c, newCandidates);
                    changed = true;
                }
            }
        }

        return changed;
    }

    private List<List<(int, int)>> FindConnectedComponents(List<(int, int)> cells, BoardContext context)
    {
        var result = new List<List<(int, int)>>();
        var visited = new HashSet<(int, int)>();
        var cellSet = cells.ToHashSet();

        foreach (var cell in cells)
        {
            if (visited.Contains(cell)) continue;

            var component = new List<(int, int)>();
            var stack = new Stack<(int, int)>();
            stack.Push(cell);

            while (stack.Count > 0)
            {
                var current = stack.Pop();
                if (visited.Contains(current)) continue;

                visited.Add(current);
                component.Add(current);

                foreach (var other in cells)
                {
                    if (visited.Contains(other)) continue;
                    if (AreAdjacent(current, other, context))
                    {
                        stack.Push(other);
                    }
                }
            }

            if (component.Count > 0)
            {
                result.Add(component);
            }
        }

        return result;
    }

    private bool AreAdjacent((int r, int c) a, (int r, int c) b, BoardContext context)
    {
        if (a.r == b.r || a.c == b.c) return true;

        foreach (var regIdx in context.CellToRegions[a.r][a.c])
        {
            if (context.CellToRegions[b.r][b.c].Contains(regIdx))
            {
                return true;
            }
        }

        return false;
    }
}
