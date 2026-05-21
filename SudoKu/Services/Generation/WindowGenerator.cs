using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

/// <summary>
/// 窗口数独专用生成器
/// 
/// 完全参照 Flutter 的 window_generator.dart 实现
/// 使用 WindowDLXSolver (DLX + 窗口约束) 生成终盘，与 Flutter 一致
/// 支持并行生成以提高性能
/// </summary>
public class WindowGenerator : SudokuGenerator
{
    private readonly Random _random;
    private readonly DiggingAlgorithm _diggingAlgorithm;
    private readonly ParallelGenerator? _parallelGenerator;

    public WindowGenerator(Random? random = null, DiggingAlgorithm? diggingAlgorithm = null, bool useParallel = true)
    {
        _random = random ?? new Random();
        _diggingAlgorithm = diggingAlgorithm ?? new DiggingAlgorithm(_random);
        _parallelGenerator = useParallel ? new ParallelGenerator(random: _random) : null;
    }

    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    public override GameType SupportedGameType => GameType.Window;

    public override async Task<GenerationResult> GenerateAsync(
        Difficulty difficulty,
        int size,
        Func<bool>? isCancelled = null,
        Dictionary<string, object>? templateData = null,
        IProgress<GenerationStage>? progress = null)
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();

        Board solution;
        Board puzzle;

        try
        {
            // 窗口数独不能使用 rrn17 模板（不满足窗口约束）
            // 直接使用 DLX 求解器生成终盘
            progress?.Report(GenerationStage.GeneratingSolution);
            solution = await GenerateSolution(size, isCancelled);

            // 根据难度挖空生成谜题
            progress?.Report(GenerationStage.DiggingPuzzle);
            puzzle = await GeneratePuzzle(solution, difficulty, isCancelled);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowGenerator] Generation failed: {ex.Message}");
            throw;
        }

        stopwatch.Stop();

        // 【关键修复】确保solution的isFixed与puzzle一致
        var finalSolution = SetSolutionFixedCells(solution, puzzle);

        return new GenerationResult
        {
            Solution = finalSolution,
            Puzzle = puzzle,
            GenerationTime = stopwatch.ElapsedMilliseconds
        };
    }

    /// <summary>
    /// 生成随机终盘（使用 DLX 求解器）
    /// 
    /// 参照 Flutter 的 WindowGenerator._generateSolution
    /// </summary>
    private async Task<Board> GenerateSolution(int size, Func<bool>? isCancelled)
    {
        return await Task.Run(() =>
        {
            const int maxAttempts = 3;
            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                if (CheckCancelled(isCancelled)) return null!;

                var solver = WindowDLXSolver.Create(_random);
                var board = solver.GenerateSolution(() => isCancelled?.Invoke() ?? false);
                if (board != null)
                {
                    return ConvertToWindowBoard(board);
                }
            }
            throw new InvalidOperationException("无法生成窗口数独终盘");
        });
    }

    /// <summary>
    /// 挖空生成谜题（使用通用挖空算法）
    /// 
    /// 参照 Flutter 的 WindowGenerator._generatePuzzle
    /// 修复：确保GameType参数正确传递到DiggingConfig，isCancelled正确传递
    /// </summary>
    private async Task<Board> GeneratePuzzle(Board solution, Difficulty difficulty, Func<bool>? isCancelled)
    {
        var config = DiggingConfig.FromDifficulty(difficulty, GameType.Window);

        if (isCancelled?.Invoke() ?? false) return null!;

        var puzzle = await _diggingAlgorithm.GeneratePuzzle(solution, config, isCancelled);

        if (isCancelled?.Invoke() ?? false) return null!;

        return puzzle;
    }

    /// <summary>
    /// 将通用 Board 转换为窗口 Board（仅用于生成终盘，单元格不固定）
    /// 
    /// 参照 Flutter 的 WindowGenerator._convertToWindowBoard
    /// 【关键修复】确保区域单元格引用正确的 cells 对象
    /// </summary>
    private Board ConvertToWindowBoard(int[,] matrix)
    {
        var size = matrix.GetLength(0);
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                // 终盘单元格不固定，由挖空后SetSolutionFixedCells处理
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: matrix[r, c] == 0 ? null : matrix[r, c],
                    isFixed: false
                ));
            }
            cells.Add(row.AsReadOnly());
        }

        // 【关键修复】确保区域单元格引用与 cells 一致
        // 创建临时 Board，调用 CreateRegions() 生成区域，然后使用 CreateInstance 确保引用一致
        var windowBoard = new WindowBoard(size, cells, []);
        var regions = windowBoard.CreateRegions();
        
        // 【关键修复】使用 CreateInstance 确保 regions 中的单元格引用与 cells 一致
        return windowBoard.CreateInstance(cells, regions);
    }
}
