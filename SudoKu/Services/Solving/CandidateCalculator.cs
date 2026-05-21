using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving;

/// <summary>
/// 候选数计算器
/// 参照 Flutter candidate_calculator.dart CandidateCalculator
/// </summary>
public class CandidateCalculator
{
    private readonly Board _board;
    private BoardContext _context;
    private readonly KillerBoard? _killerBoard;
    private string? _boardHash;

    /// <summary>
    /// 构造候选数计算器
    /// </summary>
    public CandidateCalculator(Board board)
    {
        var regions = board.Regions;
        if (regions.Count == 0)
        {
            throw new ArgumentException("棋盘至少要有一个区域");
        }

        _board = board;
        _context = BoardContext.FromBoard(board);
        _killerBoard = board as KillerBoard;
        _boardHash = ComputeBoardHash();
    }

    /// <summary>棋盘尺寸</summary>
    public int Size => _board.Size;

    /// <summary>棋盘上下文</summary>
    public BoardContext Context => _context;

    /// <summary>
    /// 获取最大数字
    /// </summary>
    public int GetMaxNumber() => _board.GetMaxNumber();

    /// <summary>
    /// 计算棋盘哈希（用于检测棋盘变化）
    /// </summary>
    private string ComputeBoardHash()
    {
        var buffer = new System.Text.StringBuilder();
        for (int row = 0; row < _board.Size; row++)
        {
            for (int col = 0; col < _board.Size; col++)
            {
                var cell = _board.GetCell(row, col);
                buffer.Append($"{cell.Value ?? 0};");
            }
        }
        return buffer.ToString();
    }

    /// <summary>
    /// 计算所有单元格的候选数
    /// </summary>
    public Dictionary<string, HashSet<int>> ComputeAllCandidates(bool useAdvancedStrategies = true)
    {
        try
        {
            // 检查棋盘是否变化，如果没变化则重用上下文
            var currentHash = ComputeBoardHash();
            if (_boardHash != currentHash)
            {
                _boardHash = currentHash;
                _context = BoardContext.FromBoard(_board);
            }

            // 第一步：初始化候选数为 {1,2,3,4,5,6,7,8,9}
            InitializeCandidates();

            // 第二步：应用区域互异约束（行、列、宫约束）
            // 必须先应用区域约束，移除同行/列/宫已填数字
            ApplyRegionConstraints();

            // 第三步：如果是杀手数独，设置笼子信息并应用笼子约束
            // 区域约束后候选数已缩小，笼子约束在此基础上进一步收缩
            if (_killerBoard != null)
            {
                _context.SetKillerCages([.. _killerBoard.Cages]);
                // 循环应用笼子约束和区域约束，直到无变化（确保约束充分传播）
                bool changed = true;
                int maxRounds = 5;
                while (changed && maxRounds-- > 0)
                {
                    changed = false;
                    var before = CaptureAllCandidates();
                    ApplyKillerCageConstraints();
                    ApplyRegionConstraints();
                    if (CandidatesChangedFrom(before))
                    {
                        changed = true;
                    }
                }
            }

            // 第四步：应用高级策略（统一使用策略系统）
            if (useAdvancedStrategies)
            {
                StrategyService.Initialize();
                if (_killerBoard != null)
                {
                    StrategyService.Instance.ApplyStrategiesForGame(_context, GameType.Killer);
                }
                else
                {
                    StrategyService.Instance.ApplyStrategies(_context);
                }
            }

            // 构建结果
            var result = new Dictionary<string, HashSet<int>>();

            for (int r = 0; r < _board.Size; r++)
            {
                for (int c = 0; c < _board.Size; c++)
                {
                    var candidates = _context.GetCandidates(r, c);
                    result[$"{r},{c}"] = [.. candidates];
                }
            }

            // 验证候选数一致性（仅记录警告，不阻断计算）
            ValidateCandidates(result);

            return result;
        }
        catch (Exception e)
        {
            System.Diagnostics.Debug.WriteLine($"候选数计算失败: {e}");
            // 返回空结果，表示无解
            return [];
        }
    }

    /// <summary>
    /// 计算指定单元格的候选数
    /// </summary>
    public HashSet<int> ComputeCellCandidates(int row, int col, bool useAdvancedStrategies = true)
    {
        var candidates = ComputeAllCandidates(useAdvancedStrategies);
        return candidates.TryGetValue($"{row},{col}", out var result) ? result : new HashSet<int>();
    }

    /// <summary>
    /// 计算武士数独局部候选数（只计算指定子棋盘）
    /// </summary>
    public Dictionary<string, HashSet<int>> ComputeSamuraiCandidates(
        List<int> visibleSubBoards,
        bool useAdvancedStrategies = true)
    {
        var result = new Dictionary<string, HashSet<int>>();
        var maxNumber = _board.GetMaxNumber();

        foreach (var subBoardIndex in visibleSubBoards)
        {
            if (subBoardIndex < 0 || subBoardIndex >= SamuraiConstants.SubGridOffsets.Count)
                continue;

            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subBoardIndex];
            var virtualBoard = _CreateVirtualSubBoard(startRow, startCol);
            var subBoardCalculator = new CandidateCalculator(virtualBoard);
            var subBoardCandidates = subBoardCalculator.ComputeAllCandidates(useAdvancedStrategies);

            for (int subRow = 0; subRow < maxNumber; subRow++)
            {
                for (int subCol = 0; subCol < maxNumber; subCol++)
                {
                    var originalRow = startRow + subRow;
                    var originalCol = startCol + subCol;
                    var key = $"{originalRow},{originalCol}";
                    var subKey = $"{subRow},{subCol}";

                    if (!subBoardCandidates.TryGetValue(subKey, out var candidates))
                        continue;

                    if (!result.ContainsKey(key))
                    {
                        result[key] = new HashSet<int>(candidates);
                    }
                    else if (result[key].Count > 0)
                    {
                        result[key].IntersectWith(candidates);
                    }
                }
            }
        }

        return result;
    }

    /// <summary>
    /// 创建子棋盘的虚拟数独棋盘
    /// </summary>
    private StandardBoard _CreateVirtualSubBoard(int startRow, int startCol)
    {
        var maxNumber = _board.GetMaxNumber();
        var cells = new List<IReadOnlyList<SudokuCell>>();
        for (int row = 0; row < maxNumber; row++)
        {
            var rowCells = new List<SudokuCell>();
            for (int col = 0; col < maxNumber; col++)
            {
                var originalCell = _board.GetCell(startRow + row, startCol + col);
                rowCells.Add(new SudokuCell(
                    row: row,
                    col: col,
                    value: originalCell.Value,
                    isFixed: originalCell.IsFixed,
                    isError: originalCell.IsError,
                    candidates: originalCell.Candidates
                ));
            }
            cells.Add(rowCells);
        }

        var regions = _BuildStandardRegions(cells.Cast<List<SudokuCell>>().ToList(), maxNumber);
        return new StandardBoard(size: maxNumber, cells: cells, regions: regions);
    }

    /// <summary>
    /// 构建标准数独区域（行、列、宫）
    /// </summary>
    private List<SudokuRegion> _BuildStandardRegions(List<List<SudokuCell>> cells, int size)
    {
        var regions = new List<SudokuRegion>();
        int blockSize = (int)Math.Sqrt(size);

        for (int r = 0; r < size; r++)
        {
            regions.Add(new SudokuRegion(
                id: $"row_{r}",
                type: RegionType.Row,
                name: $"第{r + 1}行",
                cells: cells[r].ToList()
            ));
        }

        for (int c = 0; c < size; c++)
        {
            var colCells = new List<SudokuCell>();
            for (int r = 0; r < size; r++)
            {
                colCells.Add(cells[r][c]);
            }
            regions.Add(new SudokuRegion(
                id: $"col_{c}",
                type: RegionType.Column,
                name: $"第{c + 1}列",
                cells: colCells
            ));
        }

        int blocksPerSide = size / blockSize;
        int blockId = 0;
        for (int br = 0; br < blocksPerSide; br++)
        {
            for (int bc = 0; bc < blocksPerSide; bc++)
            {
                var blockCells = new List<SudokuCell>();
                for (int r = br * blockSize; r < (br + 1) * blockSize; r++)
                {
                    for (int c = bc * blockSize; c < (bc + 1) * blockSize; c++)
                    {
                        blockCells.Add(cells[r][c]);
                    }
                }
                regions.Add(new SudokuRegion(
                    id: $"block_{blockId}",
                    type: RegionType.Block,
                    name: $"第{blockId + 1}宫",
                    cells: blockCells
                ));
                blockId++;
            }
        }

        return regions;
    }

    /// <summary>
    /// 初始化候选数为 {1,2,3,4,5,6,7,8,9}
    /// </summary>
    private void InitializeCandidates()
    {
        var maxNumber = _board.GetMaxNumber();
        var fullSet = new HashSet<int>(Enumerable.Range(1, maxNumber));

        var n = _board.Size;
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (_board.GetCell(r, c).Value != null)
                {
                    _context.SetCandidates(r, c, new HashSet<int>());
                }
                else
                {
                    _context.SetCandidates(r, c, new HashSet<int>(fullSet));
                }
            }
        }
    }

    /// <summary>
    /// 应用区域互异约束（行、列、宫约束）
    /// </summary>
    private void ApplyRegionConstraints()
    {
        var n = _board.Size;

        // 预先构建每个区域的已填数字集合
        var regionFilledNumbers = new Dictionary<int, HashSet<int>>();
        for (int regIdx = 0; regIdx < _context.RegionCellIndices.Count; regIdx++)
        {
            var region = _context.GetRegion(regIdx);
            var filledNumbers = new HashSet<int>();
            foreach (var cell in region.Cells)
            {
                var value = _context.CellValue(cell.Row, cell.Col);
                if (value != null)
                {
                    filledNumbers.Add(value.Value);
                }
            }
            regionFilledNumbers[regIdx] = filledNumbers;
        }

        // 为每个空单元格应用区域约束
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                // 跳过已填单元格
                if (_context.CellValue(r, c) != null) continue;

                // 获取当前候选数
                var candidates = new HashSet<int>(_context.GetCandidates(r, c));

                // 从候选数中移除所有相关区域的已填数字
                foreach (var regIdx in _context.CellToRegions[r][c])
                {
                    candidates.ExceptWith(regionFilledNumbers[regIdx]);
                }

                _context.SetCandidates(r, c, candidates);
            }
        }
    }

    /// <summary>
    /// 应用杀手数独笼子约束（基础约束）
    /// </summary>
    private void ApplyKillerCageConstraints()
    {
        var cages = _context.KillerCages;
        if (cages == null) return;

        foreach (var cage in cages)
        {
            KillerCombinationChecker.ApplyCageConstraint(
                cage.Sum,
                cage.CellCoordinates.ToList(),
                (r, c) => _context.GetCandidates(r, c),
                (r, c, candidates) => _context.SetCandidates(r, c, candidates),
                (r, c) => _board.GetCell(r, c).Value,
                _board.GetMaxNumber()
            );
        }
    }

    /// <summary>
    /// 验证候选数一致性
    /// </summary>
    private bool ValidateCandidates(Dictionary<string, HashSet<int>> result)
    {
        bool valid = true;
        for (int r = 0; r < _board.Size; r++)
        {
            for (int c = 0; c < _board.Size; c++)
            {
                if (_board.GetCell(r, c).Value != null) continue;

                if (!result.TryGetValue($"{r},{c}", out var candidates) || candidates.Count == 0)
                {
                    System.Diagnostics.Debug.WriteLine($"空候选数 ({r},{c}): 棋盘状态不一致");
                    valid = false;
                }
            }
        }
        return valid;
    }

    /// <summary>
    /// 快照所有候选数（用于检测变化）
    /// </summary>
    private Dictionary<string, HashSet<int>> CaptureAllCandidates()
    {
        var snapshot = new Dictionary<string, HashSet<int>>();
        for (int r = 0; r < _board.Size; r++)
        {
            for (int c = 0; c < _board.Size; c++)
            {
                snapshot[$"{r},{c}"] = new HashSet<int>(_context.GetCandidates(r, c));
            }
        }
        return snapshot;
    }

    /// <summary>
    /// 检查候选数是否与快照不同
    /// </summary>
    private bool CandidatesChangedFrom(Dictionary<string, HashSet<int>> snapshot)
    {
        for (int r = 0; r < _board.Size; r++)
        {
            for (int c = 0; c < _board.Size; c++)
            {
                var key = $"{r},{c}";
                var current = _context.GetCandidates(r, c);
                if (!snapshot.TryGetValue(key, out var before)) return true;
                if (current.Count != before.Count) return true;
                foreach (var num in current)
                {
                    if (!before.Contains(num)) return true;
                }
            }
        }
        return false;
    }
}

/// <summary>
/// 杀手数独组合检查器
/// 参照 Flutter killer_strategies.dart KillerCombinationChecker
/// </summary>
public static class KillerCombinationChecker
{
    private static readonly Dictionary<string, List<List<int>>> _comboCache = new();

    /// <summary>
    /// 获取满足和值要求的所有可能数字组合
    /// </summary>
    public static List<List<int>> GetCombinations(int k, int sum, int maxNumber = SudokuConstants.MaxNumber)
    {
        if (k <= 0 || sum <= 0) return new List<List<int>>();

        var cacheKey = $"{k},{sum},{maxNumber}";
        if (_comboCache.TryGetValue(cacheKey, out var cached))
        {
            return cached;
        }

        var result = new List<List<int>>();
        EnumerateCombinations(1, k, sum, new List<int>(), result, maxNumber);
        _comboCache[cacheKey] = result;
        return result;
    }

    private static void EnumerateCombinations(int startNum, int remaining, int targetSum,
        List<int> current, List<List<int>> result, int maxNumber)
    {
        if (remaining == 0)
        {
            if (targetSum == 0)
            {
                result.Add(new List<int>(current));
            }
            return;
        }

        var minPossible = startNum * remaining + remaining * (remaining - 1) / 2;
        if (minPossible > targetSum) return;

        var maxPossible = maxNumber * remaining - remaining * (remaining - 1) / 2;
        if (maxPossible < targetSum) return;

        for (int num = startNum; num <= maxNumber; num++)
        {
            if (num > targetSum) break;
            current.Add(num);
            EnumerateCombinations(num + 1, remaining - 1, targetSum - num, current, result, maxNumber);
            current.RemoveAt(current.Count - 1);
        }
    }

    /// <summary>
    /// 获取组合的有效分配
    /// </summary>
    public static List<HashSet<int>> GetAssignments(List<int> combo, List<HashSet<int>> candidates)
    {
        var k = combo.Count;
        var assignment = new int[k];
        Array.Fill(assignment, -1);
        var positionDigits = new List<List<int>>();
        for (int i = 0; i < k; i++)
        {
            positionDigits.Add(new List<int>());
        }

        EnumerateAssignments(0, combo, candidates, assignment, positionDigits);

        if (positionDigits.All(d => d.Count == 0)) return new List<HashSet<int>>();
        return positionDigits.Select(d => new HashSet<int>(d)).ToList();
    }

    private static void EnumerateAssignments(int index, List<int> combo, List<HashSet<int>> candidates,
        int[] assignment, List<List<int>> positionDigits)
    {
        if (index == combo.Count)
        {
            for (int i = 0; i < combo.Count; i++)
            {
                positionDigits[assignment[i]].Add(combo[i]);
            }
            return;
        }

        var num = combo[index];
        for (int pos = 0; pos < candidates.Count; pos++)
        {
            if (assignment[pos] != -1) continue;
            if (!candidates[pos].Contains(num)) continue;

            assignment[pos] = index;
            EnumerateAssignments(index + 1, combo, candidates, assignment, positionDigits);
            assignment[pos] = -1;
        }
    }

    /// <summary>
    /// 获取基础可能数字
    /// </summary>
    public static HashSet<int> GetBasicPossibleDigits(int k, int sum, HashSet<int> excluded, int maxNumber = SudokuConstants.MaxNumber)
    {
        if (k <= 0 || sum <= 0) return new HashSet<int>();

        var combos = GetCombinations(k, sum, maxNumber);
        var digits = new HashSet<int>();
        foreach (var combo in combos)
        {
            digits.UnionWith(combo);
        }
        digits.ExceptWith(excluded);
        return digits;
    }

    /// <summary>
    /// 应用笼子约束
    /// </summary>
    public static void ApplyCageConstraint(
        int sum,
        List<(int Row, int Col)> cellCoordinates,
        Func<int, int, HashSet<int>> getCandidates,
        Action<int, int, HashSet<int>> setCandidates,
        Func<int, int, int?> getCellValue,
        int maxNumber = SudokuConstants.MaxNumber)
    {
        var filled = new HashSet<int>();
        int filledSum = 0;
        var emptyIndices = new List<int>();
        var emptyCandidates = new List<HashSet<int>>();

        for (int i = 0; i < cellCoordinates.Count; i++)
        {
            var (r, c) = cellCoordinates[i];
            var val = getCellValue(r, c);
            if (val != null)
            {
                filled.Add(val.Value);
                filledSum += val.Value;
            }
            else
            {
                emptyIndices.Add(i);
                emptyCandidates.Add(getCandidates(r, c));
            }
        }

        var remainingSum = sum - filledSum;
        if (remainingSum < 0 || emptyIndices.Count == 0) return;

        var k = emptyIndices.Count;

        // 快速路径：所有空单元格候选集均为完整 {1..maxNumber}
        var fullSet = new HashSet<int>(Enumerable.Range(1, maxNumber));
        var allFull = emptyCandidates.All(cands =>
            cands.Count == maxNumber && cands.IsSupersetOf(fullSet));

        if (allFull)
        {
            var basicPossible = GetBasicPossibleDigits(k, remainingSum, filled, maxNumber);
            for (int i = 0; i < k; i++)
            {
                var (r, c) = cellCoordinates[emptyIndices[i]];
                var newCandidates = new HashSet<int>(emptyCandidates[i]);
                newCandidates.IntersectWith(basicPossible);
                if (newCandidates.Count > 0)
                {
                    setCandidates(r, c, newCandidates);
                }
            }
            return;
        }

        var allCombos = GetCombinations(k, remainingSum, maxNumber);
        var positionPossible = new List<HashSet<int>>();
        for (int i = 0; i < k; i++)
        {
            positionPossible.Add(new HashSet<int>());
        }
        bool hasValidCombo = false;

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

            var assignments = GetAssignments(combo, emptyCandidates);
            if (assignments.Count == 0) continue;

            hasValidCombo = true;
            for (int i = 0; i < k; i++)
            {
                positionPossible[i].UnionWith(assignments[i]);
            }
        }

        if (!hasValidCombo) return;

        var updates = new List<(int, int, HashSet<int>)>();
        for (int i = 0; i < k; i++)
        {
            var (r, c) = cellCoordinates[emptyIndices[i]];
            var newCandidates = new HashSet<int>(emptyCandidates[i]);
            newCandidates.IntersectWith(positionPossible[i]);
            if (newCandidates.Count == 0) continue;
            updates.Add((r, c, newCandidates));
        }

        foreach (var (r, c, candidates) in updates)
        {
            setCandidates(r, c, candidates);
        }
    }
}
