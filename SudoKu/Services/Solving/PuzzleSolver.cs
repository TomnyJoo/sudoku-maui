using System.Collections.Immutable;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Interfaces;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Solving;

/// <summary>
/// 数独求解器
/// 参照 Flutter puzzle_solver.dart PuzzleSolver
/// 
/// 统一入口，根据棋盘类型选择最优求解器
/// </summary>
public class PuzzleSolver : IPuzzleSolver
{
    private readonly DLXSolver _dlxSolver = new();
    private readonly GeneralBacktrackingSolver _generalSolver = new();
    private readonly KillerBacktrackingSolver _killerSolver = new();

    /// <summary>
    /// 求解数独，返回所有解
    /// </summary>
    public List<int[,]> Solve(Board board, int maxSolutions = 100)
    {
        return board switch
        {
            KillerBoard killerBoard => _killerSolver.Solve(killerBoard, maxSolutions),
            StandardBoard => _dlxSolver.Solve(board, maxSolutions),
            JigsawBoard => _generalSolver.Solve(board, maxSolutions),
            DiagonalBoard => _generalSolver.Solve(board, maxSolutions),
            WindowBoard => _generalSolver.Solve(board, maxSolutions),
            SamuraiBoard => _generalSolver.Solve(board, maxSolutions),
            _ => _generalSolver.Solve(board, maxSolutions)
        };
    }

    /// <summary>
    /// 求解数独，返回单个解（如果存在）
    /// </summary>
    public int[,]? SolveOne(Board board)
    {
        var solutions = Solve(board, 1);
        return solutions.Count > 0 ? solutions[0] : null;
    }

    /// <summary>
    /// 检查数独是否有唯一解
    /// </summary>
    public bool HasUniqueSolution(Board board)
    {
        var solutions = Solve(board, 2);
        return solutions.Count == 1;
    }

    /// <summary>
    /// 计算数独的解的数量
    /// 
    /// 根据棋盘类型选择最优求解器
    /// </summary>
    public int CountSolutions(Board board, int maxCount = 100, Func<bool>? isCancelled = null)
    {
        return board switch
        {
            KillerBoard killerBoard => _killerSolver.Solve(killerBoard, maxCount).Count,
            StandardBoard => _dlxSolver.CountSolutions(board, maxCount, isCancelled),
            JigsawBoard => CountJigsawSolutions(board as JigsawBoard, maxCount, isCancelled),
            DiagonalBoard => CountDiagonalSolutions(board, maxCount, isCancelled),
            WindowBoard => CountWindowSolutions(board, maxCount, isCancelled),
            SamuraiBoard => CountSamuraiSolutions(board, maxCount, isCancelled),
            _ => _generalSolver.Solve(board, maxCount).Count
        };
    }

    /// <summary>
    /// 计算锯齿数独的解数
    /// </summary>
    private int CountJigsawSolutions(JigsawBoard? board, int maxCount, Func<bool>? isCancelled)
    {
        if (board == null) return 0;
        
        List<List<int>> regionMatrix = [.. board.RegionMatrix!.Select(row => row.ToList())];
        var bitSolver = new JigsawBitSolver(regionMatrix);
        return bitSolver.CountSolutions(board, maxCount, isCancelled);
    }

    /// <summary>
    /// 计算对角线数独的解数
    /// </summary>
    private int CountDiagonalSolutions(Board board, int maxCount, Func<bool>? isCancelled)
    {
        var solver = new GeneralDLXSolver();
        return solver.Solve(board, maxCount).Count;
    }

    /// <summary>
    /// 计算窗口数独的解数
    /// </summary>
    private int CountWindowSolutions(Board board, int maxCount, Func<bool>? isCancelled)
    {
        var solver = new GeneralDLXSolver();
        return solver.Solve(board, maxCount).Count;
    }

    /// <summary>
    /// 计算武士数独的解数
    /// 
    /// 通过分别验证每个子盘是否有唯一解来判断整体唯一解
    /// 满足挖空算法要求（maxCount=2）
    /// </summary>
    private int CountSamuraiSolutions(Board board, int maxCount, Func<bool>? isCancelled)
    {
        if (board is not SamuraiBoard samuraiBoard) return 0;

        // 依次检查每个子盘
        for (int i = 0; i < 5; i++)
        {
            if (isCancelled?.Invoke() ?? false) return 0;
            var subBoard = samuraiBoard.GetSubBoard(i);
            // 每个子盘都是标准9x9数独，使用 DLX 求解器检查是否有唯一解
            var subSolver = new DLXSolver();
            if (!subSolver.HasUniqueSolution(subBoard, isCancelled))
            {
                // 出现多解，直接返回2（表示解数 >=2）
                return 2;
            }
        }
        // 所有子盘都有唯一解，则整体有唯一解
        return 1;
    }

    /// <summary>
    /// 检查数独是否有解
    /// </summary>
    public bool HasSolution(Board board)
    {
        return SolveOne(board) != null;
    }

    /// <summary>
    /// 获取提示（返回一个可以填入的单元格及其值）
    /// </summary>
    public (int row, int col, int value)? GetHint(Board board)
    {
        var solution = SolveOne(board);
        if (solution == null) return null;

        var n = board.Size;
        var candidates = new CandidateCalculator(board).ComputeAllCandidates(false);

        int minCandidates = int.MaxValue;
        (int row, int col)? bestCell = null;

        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (board.GetCell(r, c).Value != null) continue;

                if (candidates.TryGetValue($"{r},{c}", out var cellCandidates))
                {
                    if (cellCandidates.Count > 0 && cellCandidates.Count < minCandidates)
                    {
                        minCandidates = cellCandidates.Count;
                        bestCell = (r, c);
                    }
                }
            }
        }

        if (bestCell == null) return null;

        var (row, col) = bestCell.Value;
        return (row, col, solution[row, col]);
    }

    /// <summary>
    /// 获取下一个逻辑步骤（使用策略引擎）
    /// </summary>
    public SolveStep? GetNextStep(Board board)
    {
        StrategyService.Initialize();
        var calculator = new CandidateCalculator(board);
        var candidates = calculator.ComputeAllCandidates(true);
        var context = calculator.Context;

        // 检查是否有单候选数可以填入
        for (int r = 0; r < board.Size; r++)
        {
            for (int c = 0; c < board.Size; c++)
            {
                if (board.GetCell(r, c).Value != null) continue;

                if (candidates.TryGetValue($"{r},{c}", out var cellCandidates) && cellCandidates.Count == 1)
                {
                    return new SolveStep
                    {
                        Type = SolveStepType.NakedSingle,
                        Row = r,
                        Col = c,
                        Value = cellCandidates.First(),
                        Description = $"单元格 ({r + 1}, {c + 1}) 只有一个候选数 {cellCandidates.First()}"
                    };
                }
            }
        }

        // 检查隐单
        for (int num = 1; num <= board.GetMaxNumber(); num++)
        {
            foreach (var region in board.Regions)
            {
                if (region.Cells.Count != board.GetMaxNumber()) continue;

                int count = 0;
                SudokuCell? lastCell = null;

                foreach (var cell in region.Cells)
                {
                    if (board.GetCell(cell.Row, cell.Col).Value == num)
                    {
                        count = 0;
                        break;
                    }

                    if (board.GetCell(cell.Row, cell.Col).Value == null &&
                        candidates.TryGetValue($"{cell.Row},{cell.Col}", out var cands) &&
                        cands.Contains(num))
                    {
                        count++;
                        lastCell = cell;
                        if (count > 1) break;
                    }
                }

                if (count == 1 && lastCell != null)
                {
                    return new SolveStep
                    {
                        Type = SolveStepType.HiddenSingle,
                        Row = lastCell.Row,
                        Col = lastCell.Col,
                        Value = num,
                        Description = $"数字 {num} 在 {region.Type} 中只有一个位置 ({lastCell.Row + 1}, {lastCell.Col + 1})"
                    };
                }
            }
        }

        return null;
    }

    /// <summary>
    /// 验证当前棋盘状态是否有效
    /// </summary>
    public bool Validate(Board board)
    {
        foreach (var region in board.Regions)
        {
            var numbers = new HashSet<int>();
            foreach (var cell in region.Cells)
            {
                var value = board.GetCell(cell.Row, cell.Col).Value;
                if (value != null)
                {
                    if (numbers.Contains(value.Value))
                    {
                        return false;
                    }
                    numbers.Add(value.Value);
                }
            }
        }

        var calculator = new CandidateCalculator(board);
        var candidates = calculator.ComputeAllCandidates(false);

        for (int r = 0; r < board.Size; r++)
        {
            for (int c = 0; c < board.Size; c++)
            {
                if (board.GetCell(r, c).Value != null) continue;

                if (!candidates.TryGetValue($"{r},{c}", out var cellCandidates) || cellCandidates.Count == 0)
                {
                    return false;
                }
            }
        }

        return true;
    }

    /// <summary>
    /// 检查棋盘是否已完成
    /// </summary>
    public bool IsComplete(Board board)
    {
        for (int r = 0; r < board.Size; r++)
        {
            for (int c = 0; c < board.Size; c++)
            {
                if (board.GetCell(r, c).Value == null)
                {
                    return false;
                }
            }
        }

        return Validate(board);
    }

    /// <summary>
    /// 获取所有错误单元格
    /// </summary>
    public List<(int row, int col, string error)> GetErrors(Board board)
    {
        var errors = new List<(int row, int col, string error)>();

        for (int regIdx = 0; regIdx < board.Regions.Count; regIdx++)
        {
            var region = board.Regions[regIdx];
            var valuePositions = new Dictionary<int, List<SudokuCell>>();

            foreach (var cell in region.Cells)
            {
                var value = board.GetCell(cell.Row, cell.Col).Value;
                if (value != null)
                {
                    if (!valuePositions.ContainsKey(value.Value))
                    {
                        valuePositions[value.Value] = new List<SudokuCell>();
                    }
                    valuePositions[value.Value].Add(cell);
                }
            }

            foreach (var entry in valuePositions)
            {
                if (entry.Value.Count > 1)
                {
                    foreach (var cell in entry.Value)
                    {
                        errors.Add((cell.Row, cell.Col, $"{region.Type}中数字{entry.Key}重复"));
                    }
                }
            }
        }

        return errors;
    }

    /// <summary>
    /// 获取指定单元格的候选数
    /// </summary>
    public HashSet<int> GetCandidates(Board board, int row, int col)
    {
        var calculator = new CandidateCalculator(board);
        var candidates = calculator.ComputeAllCandidates(true);
        return candidates.TryGetValue($"{row},{col}", out var result) ? result : new HashSet<int>();
    }

    /// <summary>
    /// 获取所有单元格的候选数
    /// </summary>
    public Dictionary<string, HashSet<int>> GetAllCandidates(Board board)
    {
        var calculator = new CandidateCalculator(board);
        return calculator.ComputeAllCandidates(true);
    }

    #region IPuzzleSolver 接口实现

    /// <summary>
    /// 异步验证谜题是否具有唯一解
    /// </summary>
    public Task<bool> IsUniqueSolutionAsync(Board puzzle, CancellationToken token = default)
    {
        return Task.Run(() =>
        {
            var solutions = Solve(puzzle, 2);
            return solutions.Count == 1;
        }, token);
    }

    /// <summary>
    /// 异步分析谜题，返回解题所需的策略和难度信息
    /// </summary>
    public Task<PuzzleAnalysisResult> AnalyzeAsync(Board puzzle, CancellationToken token = default)
    {
        return Task.Run(() =>
        {
            var result = new PuzzleAnalysisResult();

            var solution = SolveOne(puzzle);
            if (solution == null)
            {
                return new PuzzleAnalysisResult
                {
                    IsSolvable = false,
                    FailureReason = "谜题无解"
                };
            }

            var strategies = new List<StrategyType>();
            var strategyCounts = new Dictionary<StrategyType, int>();

            var testBoard = puzzle;
            bool progress = true;
            var maxLevel = StrategyLevel.Basic;

            while (progress && !IsComplete(testBoard))
            {
                progress = false;
                var step = GetNextStep(testBoard);
                if (step != null)
                {
                    var strategyType = ConvertSolveStepTypeToStrategyType(step.Type);
                    strategies.Add(strategyType);
                    if (!strategyCounts.ContainsKey(strategyType))
                        strategyCounts[strategyType] = 0;
                    strategyCounts[strategyType]++;

                    var level = GetStrategyLevel(strategyType);
                    if (level > maxLevel)
                        maxLevel = level;

                    var newCells = new List<IReadOnlyList<SudokuCell>>(testBoard.Size);
                    for (int r = 0; r < testBoard.Size; r++)
                    {
                        var row = new List<SudokuCell>(testBoard.Size);
                        for (int c = 0; c < testBoard.Size; c++)
                        {
                            var cell = testBoard.GetCell(r, c);
                            if (r == step.Row && c == step.Col)
                            {
                                row.Add(SudokuCell.CreateInstance(r, c, step.Value, false));
                            }
                            else
                            {
                                row.Add(cell);
                            }
                        }
                        newCells.Add(row);
                    }
                    testBoard = testBoard.CreateInstance(newCells, testBoard.Regions);
                    progress = true;
                }
            }

            return new PuzzleAnalysisResult
            {
                IsSolvable = true,
                UsedStrategies = strategies.Distinct().ToList(),
                RequiredLevel = maxLevel,
                StrategyUsageCount = strategyCounts
            };
        }, token);
    }

    /// <summary>
    /// 根据当前棋盘状态和解答棋盘获取提示
    /// </summary>
    public (int row, int col, int value)? GetHint(Board current, Board solution)
    {
        var n = current.Size;

        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                if (current.GetCell(r, c).Value == null)
                {
                    var val = solution.GetCell(r, c).Value;
                    if (val.HasValue)
                    {
                        return (r, c, val.Value);
                    }
                }
            }
        }

        return null;
    }

    /// <summary>
    /// 计算棋盘中所有空单元格的候选数
    /// </summary>
    public Board CalculateCandidates(Board board, bool useAdvancedStrategies = false)
    {
        var calculator = new CandidateCalculator(board);
        var candidates = calculator.ComputeAllCandidates(useAdvancedStrategies);

        var newCells = new List<IReadOnlyList<SudokuCell>>(board.Size);
        for (int r = 0; r < board.Size; r++)
        {
            var row = new List<SudokuCell>(board.Size);
            for (int c = 0; c < board.Size; c++)
            {
                var cell = board.GetCell(r, c);
                var cellCandidates = candidates.TryGetValue($"{r},{c}", out var cands) 
                    ? cands.ToImmutableHashSet() 
                    : ImmutableHashSet<int>.Empty;
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: cell.Value,
                    isFixed: cell.IsFixed,
                    candidates: cellCandidates
                ));
            }
            newCells.Add(row);
        }

        return board.CreateInstance(newCells, board.Regions);
    }

    /// <summary>
    /// 异步求解谜题，返回完整的求解结果
    /// </summary>
    public Task<PuzzleAnalysisResult> SolveAsync(Board puzzle, CancellationToken token = default)
    {
        return AnalyzeAsync(puzzle, token);
    }

    #endregion

    #region 静态方法

    /// <summary>
    /// 快速计算解的数量（用于挖空算法验证唯一解）
    /// </summary>
    public static void CountSolutionsFast(Board puzzle, ref int count, int maxCount, Func<bool>? isCancelled = null)
    {
        var solver = new PuzzleSolver();
        count = solver.CountSolutions(puzzle, maxCount, isCancelled);
    }

    #endregion

    #region 私有辅助方法

    private static StrategyType ConvertSolveStepTypeToStrategyType(SolveStepType stepType)
    {
        return stepType switch
        {
            SolveStepType.NakedSingle => StrategyType.NakedSingle,
            SolveStepType.HiddenSingle => StrategyType.HiddenSingle,
            SolveStepType.NakedPair => StrategyType.NakedPair,
            SolveStepType.HiddenPair => StrategyType.HiddenPair,
            SolveStepType.LockedCandidate => StrategyType.LockedCandidate,
            SolveStepType.NakedTriple => StrategyType.NakedTriple,
            SolveStepType.HiddenTriple => StrategyType.HiddenTriple,
            SolveStepType.XWing => StrategyType.XWing,
            SolveStepType.Swordfish => StrategyType.Swordfish,
            SolveStepType.XYWing => StrategyType.XYWing,
            SolveStepType.XYZWing => StrategyType.XYZWing,
            SolveStepType.UniqueRectangle => StrategyType.UniqueRectangle,
            SolveStepType.KillerCageConstraint => StrategyType.KillerCageConstraint,
            SolveStepType.Killer45Rule => StrategyType.Killer45Rule,
            _ => StrategyType.Basic
        };
    }

    private static StrategyLevel GetStrategyLevel(StrategyType strategyType)
    {
        return strategyType switch
        {
            StrategyType.NakedSingle or StrategyType.HiddenSingle => StrategyLevel.Basic,
            StrategyType.NakedPair or StrategyType.HiddenPair or StrategyType.LockedCandidate => StrategyLevel.Intermediate,
            StrategyType.NakedTriple or StrategyType.HiddenTriple or StrategyType.XWing => StrategyLevel.Advanced,
            StrategyType.Swordfish or StrategyType.XYWing or StrategyType.XYZWing => StrategyLevel.Expert,
            StrategyType.UniqueRectangle => StrategyLevel.Master,
            _ => StrategyLevel.Basic
        };
    }

    #endregion
}

/// <summary>
/// 求解步骤
/// </summary>
public class SolveStep
{
    public SolveStepType Type { get; set; }
    public int Row { get; set; }
    public int Col { get; set; }
    public int Value { get; set; }
    public string Description { get; set; } = string.Empty;
    public List<(int row, int col)> RelatedCells { get; set; } = new();
    public HashSet<int> RelatedCandidates { get; set; } = new();
}

/// <summary>
/// 求解步骤类型
/// </summary>
public enum SolveStepType
{
    NakedSingle,
    HiddenSingle,
    NakedPair,
    HiddenPair,
    LockedCandidate,
    NakedTriple,
    HiddenTriple,
    XWing,
    Swordfish,
    XYWing,
    XYZWing,
    UniqueRectangle,
    KillerCageConstraint,
    Killer45Rule,
    Unknown
}
