using System.Text.Json;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

/// <summary>
/// 标准数独专用生成器
/// 
/// 完全参照 Flutter 的 standard_generator.dart 实现
/// 终盘生成使用 DLX (Dancing Links) 算法，与 Flutter 一致
/// 支持并行生成以提高性能
/// </summary>
public class StandardGenerator : SudokuGenerator
{
    private readonly Random _random;
    private readonly DiggingAlgorithm _diggingAlgorithm;
    private readonly ParallelGenerator? _parallelGenerator;

    public StandardGenerator(Random? random = null, DiggingAlgorithm? diggingAlgorithm = null, bool useParallel = true)
    {
        _random = random ?? new Random();
        _diggingAlgorithm = diggingAlgorithm ?? new DiggingAlgorithm(_random);
        _parallelGenerator = useParallel ? new ParallelGenerator(random: _random) : null;
    }

    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    public override GameType SupportedGameType => GameType.Standard;

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
        bool usedTemplate = false;

        // 使用传入的模板数据（由 PuzzleGenerator 预加载）
        List<List<int?>>? solutionData = null;
        if (templateData != null && templateData.TryGetValue("solutionData", out var data))
        {
            solutionData = ConvertToSolutionData(data);
        }

        try
        {
            if (solutionData != null)
            {
                // 使用模板生成终盘
                progress?.Report(GenerationStage.ApplyingSubstitution);
                solution = CreateBoardFromTemplate(solutionData);

                // 根据难度挖空生成谜题
                progress?.Report(GenerationStage.DiggingPuzzle);
                puzzle = await GeneratePuzzle(solution, difficulty, isCancelled);

                usedTemplate = true;
            }
            else
            {
                // 没有预加载模板，使用 DLX 算法生成终盘
                progress?.Report(GenerationStage.GeneratingSolution);
                solution = await GenerateSolutionWithDLX(size, isCancelled);

                // 根据难度挖空生成谜题
                progress?.Report(GenerationStage.DiggingPuzzle);
                puzzle = await GeneratePuzzle(solution, difficulty, isCancelled);
            }
        }
        catch (OperationCanceledException)
        {
            // 取消操作，重新抛出让上层处理
            throw;
        }
        catch (Exception ex)
        {
            // 记录错误日志
            System.Diagnostics.Debug.WriteLine($"[StandardGenerator] Generation failed: {ex.Message}");
            throw;
        }

        stopwatch.Stop();

        var finalSolution = SetSolutionFixedCells(solution, puzzle);

        return new GenerationResult
        {
            Solution = finalSolution,
            Puzzle = puzzle,
            GenerationTime = stopwatch.ElapsedMilliseconds,
            UsedTemplate = usedTemplate
        };
    }

    /// <summary>
    /// 将模板数据转换为解决方案数据格式
    /// </summary>
    private List<List<int?>>? ConvertToSolutionData(object data)
    {
        try
        {
            if (data is List<List<int?>> list)
            {
                return list;
            }

            if (data is JsonElement jsonElement && jsonElement.ValueKind == JsonValueKind.Array)
            {
                var result = new List<List<int?>>();
                foreach (var row in jsonElement.EnumerateArray())
                {
                    var rowList = new List<int?>();
                    foreach (var val in row.EnumerateArray())
                    {
                        rowList.Add(val.ValueKind == JsonValueKind.Null ? null : val.GetInt32());
                    }
                    result.Add(rowList);
                }
                return result;
            }

            return null;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// 使用 DLX (Dancing Links) 算法生成随机终盘
    /// 
    /// 与 Flutter 的 StandardDLXSolver.create(random: _random).generateSolution() 完全一致
    /// 优先使用并行生成器以提高性能
    /// </summary>
    private async Task<Board> GenerateSolutionWithDLX(int size, Func<bool>? isCancelled)
    {
        // 优先使用并行生成器
        if (_parallelGenerator != null)
        {
            var result = await _parallelGenerator.GenerateStandardSolution(size, isCancelled);
            if (result != null)
            {
                return result;
            }
            // 并行生成失败，降级到单线程
        }

        // 降级到单线程生成
        return await Task.Run(() =>
        {
            const int maxAttempts = 3;
            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                if (CheckCancelled(isCancelled)) return null!;

                var solver = StandardDLXSolver.Create(_random);
                var matrix = solver.GenerateSolution(() => isCancelled?.Invoke() ?? false);
                if (matrix != null)
                {
                    return CreateBoardFromMatrix(matrix);
                }
            }
            throw new InvalidOperationException("无法生成标准数独终盘");
        });
    }

    /// <summary>
    /// 从二维矩阵创建 Board
    /// 修复：终盘单元格不固定，由挖空后SetSolutionFixedCells处理
    /// </summary>
    private Board CreateBoardFromMatrix(int[,] matrix)
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
                    isFixed: false));
            }
            cells.Add(row);
        }

        // 使用 StandardBoard 模型类
        var tempBoard = new StandardBoard(size, cells, new List<SudokuRegion>());
        return new StandardBoard(size, cells, tempBoard.CreateRegions());
    }

    /// <summary>
    /// 挖空生成谜题（使用通用挖空算法）
    /// 
    /// 参照 Flutter 的 StandardGenerator._generatePuzzle
    /// </summary>
    private Task<Board> GeneratePuzzle(Board solution, Difficulty difficulty, Func<bool>? isCancelled)
    {
        var config = DiggingConfig.FromDifficulty(difficulty);
        return _diggingAlgorithm.GeneratePuzzle(solution, config, isCancelled);
    }



    /// <summary>
    /// 从模板数据创建棋盘
    /// 
    /// 参照 Flutter 的 StandardGenerator._createBoardFromTemplate
    /// 修复：终盘全部 isFixed=false，由挖空后 SetFixedCells 统一处理
    /// </summary>
    private Board CreateBoardFromTemplate(List<List<int?>> data)
    {
        var size = data.Count;
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                var val = data[r][c];
                // 修复：终盘全部 isFixed=false，由挖空后 SetFixedCells 统一处理
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: val == 0 ? null : val,
                    isFixed: false
                ));
            }
            cells.Add(row);
        }

        // 使用 StandardBoard 模型类
        var tempBoard = new StandardBoard(size, cells, new List<SudokuRegion>());
        return new StandardBoard(size, cells, tempBoard.CreateRegions());
    }
}
