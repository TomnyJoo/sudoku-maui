using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

/// <summary>
/// 对角线数独专用生成器
/// 
/// 完全参照 Flutter 的 diagonal_generator.dart 实现
/// 使用 DiagonalDLXSolver (DLX + 对角线约束) 生成终盘，与 Flutter 一致
/// 支持并行生成以提高性能
/// </summary>
public class DiagonalGenerator : SudokuGenerator
{
    private readonly Random _random;
    private readonly DiggingAlgorithm _diggingAlgorithm;
    private readonly ParallelGenerator? _parallelGenerator;

    public DiagonalGenerator(Random? random = null, DiggingAlgorithm? diggingAlgorithm = null, bool useParallel = true)
    {
        _random = random ?? new Random();
        _diggingAlgorithm = diggingAlgorithm ?? new DiggingAlgorithm(_random);
        _parallelGenerator = useParallel ? new ParallelGenerator(random: _random) : null;
    }

    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    public override GameType SupportedGameType => GameType.Diagonal;

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
            // 对角线数独不能使用 rrn17 模板（不满足对角线约束）
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
            System.Diagnostics.Debug.WriteLine($"[DiagonalGenerator] Generation failed: {ex.Message}");
            throw;
        }

        stopwatch.Stop();

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
    /// </summary>
    private async Task<Board> GenerateSolution(int _, Func<bool>? isCancelled)
    {
        return await Task.Run(() =>
        {
            const int maxAttempts = 3;
            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                if (CheckCancelled(isCancelled)) return null!;

                var solver = DiagonalDLXSolver.Create(_random);
                var board = solver.GenerateSolution(() => isCancelled?.Invoke() ?? false);
                if (board != null)
                {
                    return DiagonalGenerator.ConvertToDiagonalBoard(board);
                }
            }
            throw new InvalidOperationException("无法生成对角线数独终盘");
        });
    }

    /// <summary>
    /// 挖空生成谜题（使用通用挖空算法）
    /// 
    /// 参照 Flutter 的 DiagonalGenerator._generatePuzzle
    /// 修复：确保GameType参数正确传递到DiggingConfig
    /// </summary>
    private async Task<Board> GeneratePuzzle(Board solution, Difficulty difficulty, Func<bool>? isCancelled)
    {
        var config = DiggingConfig.FromDifficulty(difficulty, GameType.Diagonal);

        if (isCancelled?.Invoke() ?? false) return null!;

        var puzzle = await _diggingAlgorithm.GeneratePuzzle(solution, config, isCancelled);

        if (isCancelled?.Invoke() ?? false) return null!;

        return puzzle;
    }

    /// <summary>
    /// 将通用 Board 转换为对角线 Board
    /// 
    /// 参照 Flutter 的 DiagonalGenerator._convertToDiagonalBoard
    /// 修复：终盘单元格不固定，由挖空后SetSolutionFixedCells处理
    /// </summary>
    private static DiagonalBoard ConvertToDiagonalBoard(int[,] matrix)
    {
        var size = matrix.GetLength(0);
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                // 修复：终盘单元格不固定，由挖空后SetSolutionFixedCells处理
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: matrix[r, c] == 0 ? null : matrix[r, c],
                    isFixed: false
                ));
            }
            cells.Add(row);
        }

        // 使用 DiagonalBoard 模型类
        var tempBoard = new DiagonalBoard(size, cells, []);
        return new DiagonalBoard(size, cells, tempBoard.CreateRegions());
    }
}
