using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving.Solvers;

/// <summary>
/// 回溯算法数独求解器
/// 
/// 用于 PuzzleSolver 游戏求解功能
/// 包含标准数独、通用区域、杀手数独的回溯求解实现
/// </summary>

/// <summary>
/// 标准数独回溯求解器
/// </summary>
public class BacktrackingSolver
{
    private const int MaxSolutions = 1000;

    public List<int[,]> Solve(Board board, int maxSolutions = MaxSolutions, Func<bool>? isCancelled = null)
    {
        var solutions = new List<int[,]>();
        var grid = BoardToGrid(board);
        SolveGrid(grid, solutions, maxSolutions, isCancelled);
        return solutions;
    }

    public int[,]? SolveOne(Board board)
    {
        var solutions = Solve(board, 1);
        return solutions.Count > 0 ? solutions[0] : null;
    }

    public bool HasUniqueSolution(Board board)
    {
        var solutions = Solve(board, 2);
        return solutions.Count == 1;
    }

    public int CountSolutions(Board board, int maxCount = MaxSolutions, Func<bool>? isCancelled = null)
    {
        var solutions = new List<int[,]>();
        var grid = BoardToGrid(board);
        SolveGrid(grid, solutions, maxCount, isCancelled);
        return solutions.Count;
    }

    private int[,] BoardToGrid(Board board)
    {
        var n = board.Size;
        var grid = new int[n, n];
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                grid[r, c] = board.GetCell(r, c).Value ?? 0;
        return grid;
    }

    private void SolveGrid(int[,] grid, List<int[,]> solutions, int maxSolutions, Func<bool>? isCancelled)
    {
        var n = grid.GetLength(0);
        var emptyCells = new List<(int r, int c)>();
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                if (grid[r, c] == 0) emptyCells.Add((r, c));

        if (emptyCells.Count == 0)
        {
            if (IsValidGrid(grid)) solutions.Add((int[,])grid.Clone());
            return;
        }

        Backtrack(grid, emptyCells, 0, solutions, maxSolutions, n, isCancelled);
    }

    private bool Backtrack(int[,] grid, List<(int r, int c)> emptyCells, int index,
        List<int[,]> solutions, int maxSolutions, int n, Func<bool>? isCancelled)
    {
        if (isCancelled?.Invoke() ?? false) return true;
        if (solutions.Count >= maxSolutions) return true;
        if (index >= emptyCells.Count)
        {
            solutions.Add((int[,])grid.Clone());
            return solutions.Count >= maxSolutions;
        }

        var (r, c) = emptyCells[index];
        var candidates = GetCandidates(grid, r, c, n);

        foreach (var num in candidates)
        {
            grid[r, c] = num;
            if (IsValidPlacement(grid, r, c, n))
            {
                if (Backtrack(grid, emptyCells, index + 1, solutions, maxSolutions, n, isCancelled))
                {
                    grid[r, c] = 0;
                    return true;
                }
            }
            grid[r, c] = 0;
        }
        return false;
    }

    private List<int> GetCandidates(int[,] grid, int r, int c, int n)
    {
        var candidates = new List<int>();
        for (int num = 1; num <= n; num++)
            if (IsValidPlacement(grid, r, c, n, num)) candidates.Add(num);
        return candidates;
    }

    private bool IsValidPlacement(int[,] grid, int r, int c, int n, int num)
    {
        for (int col = 0; col < n; col++)
            if (col != c && grid[r, col] == num) return false;
        for (int row = 0; row < n; row++)
            if (row != r && grid[row, c] == num) return false;

        var boxSize = (int)Math.Sqrt(n);
        var boxRowStart = (r / boxSize) * boxSize;
        var boxColStart = (c / boxSize) * boxSize;
        for (int row = boxRowStart; row < boxRowStart + boxSize; row++)
            for (int col = boxColStart; col < boxColStart + boxSize; col++)
                if ((row != r || col != c) && grid[row, col] == num) return false;
        return true;
    }

    private bool IsValidPlacement(int[,] grid, int r, int c, int n) => IsValidPlacement(grid, r, c, n, grid[r, c]);

    private bool IsValidGrid(int[,] grid)
    {
        var n = grid.GetLength(0);
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                if (grid[r, c] != 0 && !IsValidPlacement(grid, r, c, n)) return false;
        return true;
    }
}

/// <summary>
/// 通用区域约束回溯求解器
/// 用于 Jigsaw 等不规则区域数独的游戏求解
/// </summary>
public class GeneralBacktrackingSolver
{
    private const int MaxSolutions = 1000;

    public List<int[,]> Solve(Board board, int maxSolutions = MaxSolutions)
    {
        var solutions = new List<int[,]>();
        var grid = BoardToGrid(board);
        var regions = board.Regions;
        BacktrackWithRegions(grid, regions, solutions, maxSolutions, board.Size, board.GetMaxNumber());
        return solutions;
    }

    private int[,] BoardToGrid(Board board)
    {
        var n = board.Size;
        var grid = new int[n, n];
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                grid[r, c] = board.GetCell(r, c).Value ?? 0;
        return grid;
    }

    private void BacktrackWithRegions(int[,] grid, IReadOnlyList<SudokuRegion> regions,
        List<int[,]> solutions, int maxSolutions, int n, int maxNumber)
    {
        if (solutions.Count >= maxSolutions) return;

        (int r, int c) = FindNextEmpty(grid, n);
        if (r == -1)
        {
            solutions.Add((int[,])grid.Clone());
            return;
        }

        for (int num = 1; num <= maxNumber; num++)
        {
            if (IsValidPlacementWithRegions(grid, r, c, num, regions))
            {
                grid[r, c] = num;
                BacktrackWithRegions(grid, regions, solutions, maxSolutions, n, maxNumber);
                grid[r, c] = 0;
                if (solutions.Count >= maxSolutions) return;
            }
        }
    }

    private (int r, int c) FindNextEmpty(int[,] grid, int n)
    {
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                if (grid[r, c] == 0) return (r, c);
        return (-1, -1);
    }

    private bool IsValidPlacementWithRegions(int[,] grid, int r, int c, int num, IReadOnlyList<SudokuRegion> regions)
    {
        foreach (var region in regions)
        {
            if (!region.ContainsCoordinate(r, c)) continue;
            foreach (var cell in region.Cells)
            {
                if (cell.Row == r && cell.Col == c) continue;
                if (grid[cell.Row, cell.Col] == num) return false;
            }
        }
        return true;
    }
}

/// <summary>
/// 杀手数独回溯求解器
/// 用于 Killer 数独的游戏求解
/// </summary>
public class KillerBacktrackingSolver
{
    private const int MaxSolutions = 100;

    public List<int[,]> Solve(KillerBoard board, int maxSolutions = MaxSolutions)
    {
        var solutions = new List<int[,]>();
        var grid = BoardToGrid(board);
        var regions = board.Regions;
        var cages = board.Cages;
        BacktrackWithCages(grid, regions, cages, solutions, maxSolutions, board.Size, board.GetMaxNumber());
        return solutions;
    }

    private int[,] BoardToGrid(KillerBoard board)
    {
        var n = board.Size;
        var grid = new int[n, n];
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                grid[r, c] = board.GetCell(r, c).Value ?? 0;
        return grid;
    }

    private void BacktrackWithCages(int[,] grid, IReadOnlyList<SudokuRegion> regions,
        IReadOnlyList<KillerCage> cages, List<int[,]> solutions, int maxSolutions, int n, int maxNumber)
    {
        if (solutions.Count >= maxSolutions) return;

        (int r, int c) = FindNextEmpty(grid, n);
        if (r == -1)
        {
            if (ValidateAllCages(grid, cages)) solutions.Add((int[,])grid.Clone());
            return;
        }

        for (int num = 1; num <= maxNumber; num++)
        {
            if (IsValidPlacementWithCages(grid, r, c, num, regions, cages, maxNumber))
            {
                grid[r, c] = num;
                BacktrackWithCages(grid, regions, cages, solutions, maxSolutions, n, maxNumber);
                grid[r, c] = 0;
                if (solutions.Count >= maxSolutions) return;
            }
        }
    }

    private (int r, int c) FindNextEmpty(int[,] grid, int n)
    {
        for (int r = 0; r < n; r++)
            for (int c = 0; c < n; c++)
                if (grid[r, c] == 0) return (r, c);
        return (-1, -1);
    }

    private bool IsValidPlacementWithCages(int[,] grid, int r, int c, int num,
        IReadOnlyList<SudokuRegion> regions, IReadOnlyList<KillerCage> cages, int maxNumber)
    {
        foreach (var region in regions)
        {
            if (!region.ContainsCoordinate(r, c)) continue;
            foreach (var cell in region.Cells)
            {
                if (cell.Row == r && cell.Col == c) continue;
                if (grid[cell.Row, cell.Col] == num) return false;
            }
        }

        foreach (var cage in cages)
        {
            if (!cage.ContainsCoordinate(r, c)) continue;

            int currentSum = num;
            int filledCount = 1;
            var usedNumbers = new HashSet<int> { num };

            foreach (var (cr, cc) in cage.CellCoordinates)
            {
                if (cr == r && cc == c) continue;
                var val = grid[cr, cc];
                if (val != 0)
                {
                    if (usedNumbers.Contains(val)) return false;
                    usedNumbers.Add(val);
                    currentSum += val;
                    filledCount++;
                }
            }

            if (currentSum > cage.Sum) return false;
            if (filledCount == cage.CellCoordinates.Count && currentSum != cage.Sum) return false;

            int remainingSum = cage.Sum - currentSum;
            int remainingCells = cage.CellCoordinates.Count - filledCount;
            if (remainingCells > 0)
            {
                int minPossible = remainingCells * (remainingCells + 1) / 2;
                int maxPossible = remainingCells * (2 * maxNumber - remainingCells + 1) / 2;
                if (remainingSum < minPossible || remainingSum > maxPossible) return false;
            }
        }
        return true;
    }

    private bool ValidateAllCages(int[,] grid, IReadOnlyList<KillerCage> cages)
    {
        foreach (var cage in cages)
        {
            int sum = 0;
            var usedNumbers = new HashSet<int>();
            foreach (var (r, c) in cage.CellCoordinates)
            {
                var val = grid[r, c];
                if (val == 0) return false;
                if (usedNumbers.Contains(val)) return false;
                usedNumbers.Add(val);
                sum += val;
            }
            if (sum != cage.Sum) return false;
        }
        return true;
    }
}
