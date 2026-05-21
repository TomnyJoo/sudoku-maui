using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving.Solvers;

/// <summary>
/// 标准数独生成器求解器
/// 用于生成标准数独终盘
/// </summary>
public class StandardDLXSolver
{
    private readonly Random _random;

    private StandardDLXSolver(Random random)
    {
        _random = random;
    }

    public static StandardDLXSolver Create(Random random)
    {
        return new StandardDLXSolver(random);
    }

    public int[,]? GenerateSolution(Func<bool>? isCancelled = null)
    {
        return GenerateSudoku(_random, 9, isCancelled);
    }

    public int[,]? SolveFromGrid(int[,] initialGrid, Func<bool>? isCancelled = null)
    {
        int[,] grid = (int[,])initialGrid.Clone();
        if (FillGrid(grid, 9, _random, isCancelled))
        {
            return grid;
        }
        return null;
    }

    private int[,]? GenerateSudoku(Random random, int size, Func<bool>? isCancelled = null)
    {
        int[,] grid = new int[size, size];
        if (FillGrid(grid, size, random, isCancelled))
        {
            return grid;
        }
        return null;
    }

    private bool FillGrid(int[,] grid, int size, Random random, Func<bool>? isCancelled)
    {
        if (isCancelled?.Invoke() ?? false)
            return false;

        int boxSize = (int)Math.Sqrt(size);
        int emptyRow = -1;
        int emptyCol = -1;

        // 找到第一个空格
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (grid[r, c] == 0)
                {
                    emptyRow = r;
                    emptyCol = c;
                    break;
                }
            }
            if (emptyRow != -1)
                break;
        }

        // 如果没有空格，说明已经填满
        if (emptyRow == -1)
            return true;

        // 获取可用数字并随机排序
        var numbers = GetAvailableNumbers(grid, emptyRow, emptyCol, size, boxSize);
        if (numbers.Count == 0)
            return false;

        foreach (int num in numbers)
        {
            grid[emptyRow, emptyCol] = num;

            if (FillGrid(grid, size, random, isCancelled))
                return true;

            grid[emptyRow, emptyCol] = 0;
        }

        return false;
    }

    private List<int> GetAvailableNumbers(int[,] grid, int row, int col, int size, int boxSize)
    {
        bool[] used = new bool[size + 1];

        // 检查行
        for (int c = 0; c < size; c++)
            if (grid[row, c] != 0)
                used[grid[row, c]] = true;

        // 检查列
        for (int r = 0; r < size; r++)
            if (grid[r, col] != 0)
                used[grid[r, col]] = true;

        // 检查宫格
        int boxRow = (row / boxSize) * boxSize;
        int boxCol = (col / boxSize) * boxSize;
        for (int r = boxRow; r < boxRow + boxSize; r++)
            for (int c = boxCol; c < boxCol + boxSize; c++)
                if (grid[r, c] != 0)
                    used[grid[r, c]] = true;

        // 返回未使用的数字
        List<int> available = new List<int>();
        for (int i = 1; i <= size; i++)
            if (!used[i])
                available.Add(i);

        // 随机排序
        for (int i = available.Count - 1; i > 0; i--)
        {
            int j = _random.Next(i + 1);
            (available[i], available[j]) = (available[j], available[i]);
        }

        return available;
    }
}

/// <summary>
/// 通用区域数独生成器求解器
/// 用于生成对角线、窗口等数独终盘
/// </summary>
public class GeneralDLXSolver
{
    public List<int[,]> Solve(Board puzzle, int maxSolutions = 2)
    {
        var solutions = new List<int[,]>();
        var grid = BoardToGrid(puzzle);
        SolveGrid(grid, solutions, maxSolutions, puzzle.Size, puzzle.GetMaxNumber(), puzzle.Regions);
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

    private void SolveGrid(int[,] grid, List<int[,]> solutions, int maxSolutions, int n, int maxNumber,
        IReadOnlyList<SudokuRegion> regions)
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
                SolveGrid(grid, solutions, maxSolutions, n, maxNumber, regions);
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

    private bool IsValidPlacementWithRegions(int[,] grid, int r, int c, int num,
        IReadOnlyList<SudokuRegion> regions)
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
/// 杀手数独生成器求解器
/// 用于生成杀手数独终盘
/// </summary>
public class KillerDLXSolver
{
    public List<int[,]> Solve(KillerBoard board, int maxSolutions = 2)
    {
        var solutions = new List<int[,]>();
        var grid = BoardToGrid(board);
        SolveGrid(grid, solutions, maxSolutions, board.Size, board.GetMaxNumber(), board.Regions, board.Cages);
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

    private void SolveGrid(int[,] grid, List<int[,]> solutions, int maxSolutions, int n, int maxNumber,
        IReadOnlyList<SudokuRegion> regions, IReadOnlyList<KillerCage> cages)
    {
        if (solutions.Count >= maxSolutions) return;

        (int r, int c) = FindNextEmpty(grid, n);
        if (r == -1)
        {
            if (ValidateCages(grid, cages))
                solutions.Add((int[,])grid.Clone());
            return;
        }

        for (int num = 1; num <= maxNumber; num++)
        {
            if (IsValidPlacementWithRegions(grid, r, c, num, regions))
            {
                grid[r, c] = num;
                SolveGrid(grid, solutions, maxSolutions, n, maxNumber, regions, cages);
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

    private bool IsValidPlacementWithRegions(int[,] grid, int r, int c, int num,
        IReadOnlyList<SudokuRegion> regions)
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

    private bool ValidateCages(int[,] grid, IReadOnlyList<KillerCage> cages)
    {
        foreach (var cage in cages)
        {
            int sum = 0;
            foreach (var cell in cage.Cells)
                sum += grid[cell.Row, cell.Col];
            if (sum != cage.Sum) return false;
        }
        return true;
    }
}

/// <summary>
/// 对角线数独生成器求解器
/// 用于生成对角线数独终盘
/// </summary>
public class DiagonalDLXSolver
{
    private readonly Random _random;

    private DiagonalDLXSolver(Random random)
    {
        _random = random;
    }

    public static DiagonalDLXSolver Create(Random random)
    {
        return new DiagonalDLXSolver(random);
    }

    public int[,]? GenerateSolution(Func<bool>? isCancelled = null)
    {
        int[,] grid = new int[9, 9];
        if (FillGridWithDiagonals(grid, 9, isCancelled))
        {
            return grid;
        }
        return null;
    }

    private bool FillGridWithDiagonals(int[,] grid, int size, Func<bool>? isCancelled)
    {
        if (isCancelled?.Invoke() ?? false)
            return false;

        int boxSize = 3;
        int emptyRow = -1;
        int emptyCol = -1;

        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (grid[r, c] == 0)
                {
                    emptyRow = r;
                    emptyCol = c;
                    break;
                }
            }
            if (emptyRow != -1)
                break;
        }

        if (emptyRow == -1)
            return true;

        var numbers = GetAvailableNumbersWithDiagonals(grid, emptyRow, emptyCol, size, boxSize);
        if (numbers.Count == 0)
            return false;

        foreach (int num in numbers)
        {
            grid[emptyRow, emptyCol] = num;

            if (FillGridWithDiagonals(grid, size, isCancelled))
                return true;

            grid[emptyRow, emptyCol] = 0;
        }

        return false;
    }

    private List<int> GetAvailableNumbersWithDiagonals(int[,] grid, int row, int col, int size, int boxSize)
    {
        bool[] used = new bool[size + 1];

        // 检查行
        for (int c = 0; c < size; c++)
            if (grid[row, c] != 0)
                used[grid[row, c]] = true;

        // 检查列
        for (int r = 0; r < size; r++)
            if (grid[r, col] != 0)
                used[grid[r, col]] = true;

        // 检查宫格
        int boxRow = (row / boxSize) * boxSize;
        int boxCol = (col / boxSize) * boxSize;
        for (int r = boxRow; r < boxRow + boxSize; r++)
            for (int c = boxCol; c < boxCol + boxSize; c++)
                if (grid[r, c] != 0)
                    used[grid[r, c]] = true;

        // 检查主对角线 (top-left to bottom-right)
        if (row == col)
        {
            for (int i = 0; i < size; i++)
                if (grid[i, i] != 0)
                    used[grid[i, i]] = true;
        }

        // 检查副对角线 (top-right to bottom-left)
        if (row + col == size - 1)
        {
            for (int i = 0; i < size; i++)
                if (grid[i, size - 1 - i] != 0)
                    used[grid[i, size - 1 - i]] = true;
        }

        List<int> available = new List<int>();
        for (int i = 1; i <= size; i++)
            if (!used[i])
                available.Add(i);

        // 随机排序
        for (int i = available.Count - 1; i > 0; i--)
        {
            int j = _random.Next(i + 1);
            (available[i], available[j]) = (available[j], available[i]);
        }

        return available;
    }
}

/// <summary>
/// 窗口数独生成器求解器
/// 用于生成窗口数独终盘
/// </summary>
public class WindowDLXSolver
{
    private readonly Random _random;

    private WindowDLXSolver(Random random)
    {
        _random = random;
    }

    public static WindowDLXSolver Create(Random random)
    {
        return new WindowDLXSolver(random);
    }

    public int[,]? GenerateSolution(Func<bool>? isCancelled = null)
    {
        int[,] grid = new int[9, 9];
        if (FillGridWithWindows(grid, isCancelled))
        {
            return grid;
        }
        return null;
    }

    private bool FillGridWithWindows(int[,] grid, Func<bool>? isCancelled)
    {
        if (isCancelled?.Invoke() ?? false)
            return false;

        int size = 9;
        int boxSize = 3;
        int emptyRow = -1;
        int emptyCol = -1;

        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (grid[r, c] == 0)
                {
                    emptyRow = r;
                    emptyCol = c;
                    break;
                }
            }
            if (emptyRow != -1)
                break;
        }

        if (emptyRow == -1)
            return true;

        var numbers = GetAvailableNumbersWithWindows(grid, emptyRow, emptyCol, size, boxSize);
        if (numbers.Count == 0)
            return false;

        foreach (int num in numbers)
        {
            grid[emptyRow, emptyCol] = num;

            if (FillGridWithWindows(grid, isCancelled))
                return true;

            grid[emptyRow, emptyCol] = 0;
        }

        return false;
    }

    private List<int> GetAvailableNumbersWithWindows(int[,] grid, int row, int col, int size, int boxSize)
    {
        bool[] used = new bool[size + 1];

        // 检查行
        for (int c = 0; c < size; c++)
            if (grid[row, c] != 0)
                used[grid[row, c]] = true;

        // 检查列
        for (int r = 0; r < size; r++)
            if (grid[r, col] != 0)
                used[grid[r, col]] = true;

        // 检查宫格
        int boxRow = (row / boxSize) * boxSize;
        int boxCol = (col / boxSize) * boxSize;
        for (int r = boxRow; r < boxRow + boxSize; r++)
            for (int c = boxCol; c < boxCol + boxSize; c++)
                if (grid[r, c] != 0)
                    used[grid[r, c]] = true;

        // 检查窗口区域 (窗口数独的额外约束)
        CheckWindowConstraint(grid, row, col, size, used);

        List<int> available = new List<int>();
        for (int i = 1; i <= size; i++)
            if (!used[i])
                available.Add(i);

        // 随机排序
        for (int i = available.Count - 1; i > 0; i--)
        {
            int j = _random.Next(i + 1);
            (available[i], available[j]) = (available[j], available[i]);
        }

        return available;
    }

    private void CheckWindowConstraint(int[,] grid, int row, int col, int size, bool[] used)
    {
        foreach (var windowRegion in WindowConstants.WindowRegions)
        {
            if (row >= windowRegion.StartRow && row <= windowRegion.EndRow &&
                col >= windowRegion.StartCol && col <= windowRegion.EndCol)
            {
                for (int r = windowRegion.StartRow; r <= windowRegion.EndRow; r++)
                    for (int c = windowRegion.StartCol; c <= windowRegion.EndCol; c++)
                        if (grid[r, c] != 0)
                            used[grid[r, c]] = true;
                break;
            }
        }
    }
}