using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Interfaces;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

public class DiggingAlgorithm(Random? random = null, IPuzzleSolver? solver = null)
{
    private readonly Random _random = random ?? new Random();
    private readonly IPuzzleSolver? _solver = solver;

    // 全局求解器单例
    private static readonly DLXSolver _dlxSolver = new();
    private static readonly JigsawBitSolver _jigsawSolver = new();

    public async Task<Board> GeneratePuzzle(Board solution, DiggingConfig config, Func<bool>? isCancelled)
    {
        if (config.UseSymmetry)
            return await GeneratePuzzleSymmetric(solution, config, isCancelled);
        else
            return await GeneratePuzzleRandom(solution, config, isCancelled);
    }

    private async Task<Board> GeneratePuzzleSymmetric(Board solution, DiggingConfig config, Func<bool>? isCancelled)
    {
        var size = solution.Size;
        var targetFilled = config.MaxFilledCells;
        var puzzle = ResetFixedCells(solution);
        var pairs = GenerateSymmetricPairs(size);

        puzzle = RandomDigPhaseSymmetric(puzzle, pairs, (size * size + config.MaxFilledCells) / 2, isCancelled);
        puzzle = SmartDigPhaseSymmetric(puzzle, pairs, targetFilled, config, isCancelled);

        var filled = CountFilledCells(puzzle);
        if (filled < config.MinFilledCells || filled > config.MaxFilledCells)
            puzzle = AdjustPuzzleDifficulty(puzzle, solution, targetFilled, config.MinFilledCells, config.MaxFilledCells, isCancelled);

        var result = SetFixedCells(puzzle);
        return result;
    }

    private async Task<Board> GeneratePuzzleRandom(Board solution, DiggingConfig config, Func<bool>? isCancelled)
    {
        var size = solution.Size;
        var targetFilled = config.MaxFilledCells;
        var puzzle = ResetFixedCells(solution);
        var cells = Enumerable.Range(0, size).SelectMany(i => Enumerable.Range(0, size).Select(j => (i, j))).ToList();

        puzzle = RandomDigPhaseRandom(puzzle, cells, (size * size + config.MaxFilledCells) / 2, isCancelled);
        puzzle = SmartDigPhaseRandom(puzzle, cells, targetFilled, config, isCancelled);

        var filled = CountFilledCells(puzzle);
        if (filled < config.MinFilledCells || filled > config.MaxFilledCells)
            puzzle = AdjustPuzzleDifficulty(puzzle, solution, targetFilled, config.MinFilledCells, config.MaxFilledCells, isCancelled);

        return SetFixedCells(puzzle);
    }

    #region 对称挖空实现

    private Board RandomDigPhaseSymmetric(Board puzzle, List<List<(int row, int col)>> pairs, int targetFilled, Func<bool>? isCancelled)
    {
        var result = puzzle;
        var filled = CountFilledCells(result);
        var shuffledPairs = pairs.OrderBy(_ => _random.Next()).ToList();

        foreach (var pair in shuffledPairs)
        {
            if (isCancelled?.Invoke() ?? false) return puzzle;
            if (filled <= targetFilled) break;
            if (!pair.Any(pos => result.GetCell(pos.row, pos.col).Value != null)) continue;

            var test = result;
            foreach (var (r, c) in pair)
                if (result.GetCell(r, c).Value != null)
                    test = SetCellValue(test, r, c, null);

            if (QuickCheck(test) && HasUniqueSolution(test, isCancelled))
            {
                result = test;
                filled = CountFilledCells(result);
            }
        }
        return result;
    }

    private Board SmartDigPhaseSymmetric(Board puzzle, List<List<(int row, int col)>> pairs, int targetFilled, DiggingConfig config, Func<bool>? isCancelled)
    {
        var result = puzzle;
        var filled = CountFilledCells(result);
        int consecutiveFailures = 0;
        var maxConsecutive = config.MaxAttempts * 5;
        int iterations = 0;

        while (filled > targetFilled && consecutiveFailures < maxConsecutive && iterations < 500)
        {
            iterations++;
            if (isCancelled?.Invoke() ?? false) return puzzle;

            var scored = new List<(List<(int, int)> pair, int score)>();
            foreach (var pair in pairs)
            {
                if (!pair.Any(p => result.GetCell(p.row, p.col).Value != null)) continue;
                int score = 0;
                foreach (var (r, c) in pair)
                {
                    if (result.GetCell(r, c).Value != null)
                    {
                        var temp = SetCellValue(result, r, c, null);
                        var candCount = CalculateCandidateCountMask(temp, r, c, result.Size);
                        var balance = CalculateRegionBalanceScoreFast(result, r, c);
                        score += (int)(candCount * balance);
                    }
                }
                scored.Add((pair, score));
            }
            if (scored.Count == 0) break;
            scored.Sort((a, b) => b.score.CompareTo(a.score));

            var topCount = Math.Max(1, (int)Math.Ceiling(scored.Count * 0.5));
            bool success = false;
            for (int i = 0; i < topCount && !success; i++)
            {
                var pair = scored[i].pair;
                var test = result;
                foreach (var (r, c) in pair)
                    if (result.GetCell(r, c).Value != null)
                        test = SetCellValue(test, r, c, null);
                if (QuickCheck(test) && HasUniqueSolution(test, isCancelled))
                {
                    result = test;
                    filled = CountFilledCells(result);
                    success = true;
                    consecutiveFailures = 0;
                }
            }

            if (!success && scored.Count > topCount)
            {
                var remaining = scored.Skip(topCount).OrderBy(_ => _random.Next()).Take(10).ToList();
                foreach (var (pair, _) in remaining)
                {
                    var test = result;
                    foreach (var (r, c) in pair)
                        if (result.GetCell(r, c).Value != null)
                            test = SetCellValue(test, r, c, null);
                    if (QuickCheck(test) && HasUniqueSolution(test, isCancelled))
                    {
                        result = test;
                        filled = CountFilledCells(result);
                        success = true;
                        consecutiveFailures = 0;
                        break;
                    }
                }
            }
            if (!success) consecutiveFailures++;
        }
        return result;
    }

    #endregion

    #region 随机挖空实现

    private Board RandomDigPhaseRandom(Board puzzle, List<(int row, int col)> cells, int targetFilled, Func<bool>? isCancelled)
    {
        var result = puzzle;
        var filled = CountFilledCells(result);
        var shuffled = cells.OrderBy(_ => _random.Next()).ToList();

        foreach (var (r, c) in shuffled)
        {
            if (isCancelled?.Invoke() ?? false) return puzzle;
            if (filled <= targetFilled) break;
            var test = SetCellValue(result, r, c, null);
            if (HasUniqueSolution(test, isCancelled))
            {
                result = test;
                filled--;
            }
        }
        return result;
    }

    private Board SmartDigPhaseRandom(Board puzzle, List<(int row, int col)> cells, int targetFilled, DiggingConfig config, Func<bool>? isCancelled)
    {
        var result = puzzle;
        var filled = CountFilledCells(result);
        int consecutiveFailures = 0;
        var maxConsecutive = config.MaxAttempts * 5;
        int iterations = 0;

        while (filled > targetFilled && consecutiveFailures < maxConsecutive && iterations < 500)
        {
            iterations++;
            if (isCancelled?.Invoke() ?? false) return puzzle;

            var scored = new List<((int, int) cell, int score)>();
            foreach (var (r, c) in cells)
            {
                if (result.GetCell(r, c).Value == null) continue;
                var temp = SetCellValue(result, r, c, null);
                var candCount = CalculateCandidateCountMask(temp, r, c, result.Size);
                var balance = CalculateRegionBalanceScoreFast(result, r, c);
                scored.Add(((r, c), (int)(candCount * balance)));
            }
            if (scored.Count == 0) break;
            scored.Sort((a, b) => b.score.CompareTo(a.score));

            var topCount = Math.Max(1, (int)Math.Ceiling(scored.Count * 0.5));
            bool success = false;
            for (int i = 0; i < topCount && !success; i++)
            {
                var (r, c) = scored[i].cell;
                var test = SetCellValue(result, r, c, null);
                if (HasUniqueSolution(test, isCancelled))
                {
                    result = test;
                    filled--;
                    success = true;
                    consecutiveFailures = 0;
                }
            }

            if (!success && scored.Count > topCount)
            {
                var remaining = scored.Skip(topCount).OrderBy(_ => _random.Next()).Take(10).ToList();
                foreach (var ((r, c), _) in remaining)
                {
                    var test = SetCellValue(result, r, c, null);
                    if (HasUniqueSolution(test, isCancelled))
                    {
                        result = test;
                        filled--;
                        success = true;
                        consecutiveFailures = 0;
                        break;
                    }
                }
            }
            if (!success) consecutiveFailures++;
        }
        return result;
    }

    #endregion

    #region 公共性能优化方法

    public static bool QuickCheck(Board board)
    {
        // 利用 board.Regions 快速检查
        foreach (var region in board.Regions)
        {
            var seen = new HashSet<int>();
            foreach (var cell in region.Cells)
            {
                if (cell.Value.HasValue && !seen.Add(cell.Value.Value))
                    return false;
            }
        }
        return true;
    }

    public static bool HasUniqueSolution(Board puzzle, Func<bool>? isCancelled)
    {
        if (isCancelled?.Invoke() ?? false) return false;
        
        // 根据棋盘类型选择正确的求解器
        if (puzzle is JigsawBoard)
            return _jigsawSolver.HasUniqueSolution(puzzle, isCancelled);
        else
            return _dlxSolver.HasUniqueSolution(puzzle, isCancelled);
    }

    public static int CountFilledCells(Board board)
    {
        int count = 0;
        for (int r = 0; r < board.Size; r++)
            for (int c = 0; c < board.Size; c++)
                if (board.GetCell(r, c).Value != null) count++;
        return count;
    }

    public static Board ResetFixedCells(Board board)
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(board.Size);
        for (int r = 0; r < board.Size; r++)
        {
            var row = new List<SudokuCell>(board.Size);
            for (int c = 0; c < board.Size; c++)
            {
                var cell = board.GetCell(r, c);
                row.Add(SudokuCell.CreateInstance(r, c, cell.Value, isFixed: false));
            }
            newCells.Add(row);
        }
        var updatedRegions = UpdateRegionCellReferences(board.Regions, newCells);
        return board.CreateInstance(newCells, updatedRegions);
    }

    public static Board SetFixedCells(Board puzzle)
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(puzzle.Size);
        for (int r = 0; r < puzzle.Size; r++)
        {
            var row = new List<SudokuCell>(puzzle.Size);
            for (int c = 0; c < puzzle.Size; c++)
            {
                var cell = puzzle.GetCell(r, c);
                row.Add(SudokuCell.CreateInstance(r, c, cell.Value, isFixed: cell.Value.HasValue));
            }
            newCells.Add(row);
        }
        var updatedRegions = UpdateRegionCellReferences(puzzle.Regions, newCells);
        return puzzle.CreateInstance(newCells, updatedRegions);
    }

    public Board AdjustPuzzleDifficulty(Board puzzle, Board solution, int _, int minFilled, int maxFilled, Func<bool>? isCancelled)
    {
        var adjusted = puzzle;
        var filled = CountFilledCells(adjusted);
        int attempts = 0;
        const int maxAttempts = 500;

        while (filled > maxFilled && attempts < maxAttempts)
        {
            if (isCancelled?.Invoke() ?? false) break;
            var cells = FindRemovable(adjusted);
            if (cells.Count == 0) break;
            Shuffle(cells);
            bool success = false;
            foreach (var (r, c) in cells)
            {
                attempts++;
                if (attempts >= maxAttempts) break;
                var test = SetCellValue(adjusted, r, c, null);
                if (QuickCheck(test) && HasUniqueSolution(test, isCancelled))
                {
                    adjusted = test;
                    filled--;
                    success = true;
                    break;
                }
            }
            if (!success) break;
        }

        while (filled < minFilled)
        {
            if (isCancelled?.Invoke() ?? false) break;
            var cells = FindFillable(adjusted, solution);
            if (cells.Count == 0) break;
            var (r, c) = cells[_random.Next(cells.Count)];
            var val = solution.GetCell(r, c).Value;
            if (val.HasValue)
            {
                var test = SetCellValue(adjusted, r, c, val);
                if (QuickCheck(test) && HasUniqueSolution(test, isCancelled))
                {
                    adjusted = test;
                    filled++;
                }
                else break;
            }
        }
        return adjusted;
    }

    public static List<(int row, int col)> FindRemovable(Board puzzle)
    {
        var list = new List<(int, int)>();
        for (int r = 0; r < puzzle.Size; r++)
            for (int c = 0; c < puzzle.Size; c++)
                if (puzzle.GetCell(r, c).Value != null) list.Add((r, c));
        return list;
    }

    public static List<(int row, int col)> FindFillable(Board puzzle, Board _)
    {
        var list = new List<(int, int)>();
        for (int r = 0; r < puzzle.Size; r++)
            for (int c = 0; c < puzzle.Size; c++)
                if (puzzle.GetCell(r, c).Value == null) list.Add((r, c));
        return list;
    }

    // 候选数计算（位掩码版本）
    private static int CalculateCandidateCountMask(Board puzzle, int r, int c, int size)
    {
        if (puzzle.GetCell(r, c).Value != null) return 0;
        int mask = (1 << size) - 1;
        var cellRegions = puzzle.GetCellRegions(r, c); // 需要 Board 提供此方法
        foreach (var region in cellRegions)
        {
            foreach (var cell in region.Cells)
            {
                if (cell.Value.HasValue)
                    mask &= ~(1 << (cell.Value.Value - 1));
            }
        }
        return System.Numerics.BitOperations.PopCount((uint)mask);
    }

    // 区域平衡分数（带缓存）
    private readonly Dictionary<(int r, int c), double> _balanceCache = [];
    private double CalculateRegionBalanceScoreFast(Board puzzle, int r, int c)
    {
        var key = (r, c);
        if (_balanceCache.TryGetValue(key, out double cached))
            return cached;
        double lineBalance = 1.0, blockBalance = 1.0;
        var cellRegions = puzzle.GetCellRegions(r, c);
        foreach (var region in cellRegions)
        {
            var filled = region.Cells.Count(cell => cell.Value != null);
            var ratio = (double)filled / region.Cells.Count;
            if (region.Type == RegionType.Row || region.Type == RegionType.Column)
                lineBalance = Math.Min(lineBalance, ratio);
            else
                blockBalance = Math.Min(blockBalance, ratio);
        }
        double result = Math.Pow(lineBalance, 0.4) * Math.Pow(blockBalance, 0.6);
        _balanceCache[key] = result;
        return result;
    }

    private static Board SetCellValue(Board board, int row, int col, int? value)
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(board.Size);
        for (int r = 0; r < board.Size; r++)
        {
            var rowCells = new List<SudokuCell>(board.Size);
            for (int c = 0; c < board.Size; c++)
            {
                var cell = board.GetCell(r, c);
                if (r == row && c == col)
                    rowCells.Add(SudokuCell.CreateInstance(r, c, value, isFixed: false));
                else
                    rowCells.Add(cell);
            }
            newCells.Add(rowCells);
        }
        var updatedRegions = UpdateRegionCellReferences(board.Regions, newCells);
        return board.CreateInstance(newCells, updatedRegions);
    }

    private static IReadOnlyList<SudokuRegion> UpdateRegionCellReferences(
        IReadOnlyList<SudokuRegion> regions,
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells)
    {
        return SudokuGenerator.UpdateRegionCellReferences(regions, newCells);
    }

    private void Shuffle<T>(List<T> list)
    {
        for (int i = list.Count - 1; i > 0; i--)
        {
            int j = _random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }

    private static List<List<(int, int)>> GenerateSymmetricPairs(int size)
    {
        var pairs = new List<List<(int, int)>>();
        var processed = new HashSet<string>();
        for (int i = 0; i < size; i++)
        {
            for (int j = 0; j < size; j++)
            {
                var key = $"{i},{j}";
                if (processed.Contains(key)) continue;
                int si = size - 1 - i, sj = size - 1 - j;
                if (i == si && j == sj)
                    pairs.Add([(i, j)]);
                else
                {
                    pairs.Add([(i, j), (si, sj)]);
                    processed.Add($"{si},{sj}");
                }
                processed.Add(key);
            }
        }
        return pairs;
    }

    #endregion
}
