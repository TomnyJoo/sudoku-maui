using System.Text.Json;
using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

public class JigsawGenerator : SudokuGenerator
{
    private readonly Random _random;
    private readonly DiggingAlgorithm _diggingAlgorithm;
    private readonly TemplateManager _templateManager;

    public JigsawGenerator(
        TemplateManager templateManager,
        Random? random = null, 
        DiggingAlgorithm? diggingAlgorithm = null)
    {
        _templateManager = templateManager;
        _random = random ?? new Random();
        _diggingAlgorithm = diggingAlgorithm ?? new DiggingAlgorithm(_random);
    }

    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    public override GameType SupportedGameType => GameType.Jigsaw;

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
            // 1. 加载区域模板
            progress?.Report(GenerationStage.LoadingTemplate);
            if (CheckCancelled(isCancelled)) return new GenerationResult { GenerationTime = 0 };
            var regionMatrix = LoadRegionMatrix(templateData);

            // 2. 创建区域约束
            var regions = CreateRegionsFromMatrix(regionMatrix);

            // 3. 生成终盘
            progress?.Report(GenerationStage.GeneratingSolution);
            solution = await GenerateSolution(regionMatrix, regions, isCancelled);

            // 4. 挖空生成谜题
            progress?.Report(GenerationStage.DiggingPuzzle);
            puzzle = await GeneratePuzzle(solution, difficulty, isCancelled);

            // 5. 验证谜题与答案匹配
            progress?.Report(GenerationStage.Validating);
            if (!ValidatePuzzleSolution(puzzle, solution))
                throw new InvalidOperationException("谜题验证失败");
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[JigsawGenerator] Generation failed: {ex.Message}");
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

    private List<List<int>> LoadRegionMatrix(Dictionary<string, object>? templateData)
    {
        if (templateData != null && templateData.TryGetValue("regionMatrix", out var data))
        {
            var regionMatrix = JigsawGenerator.ConvertToRegionMatrix(data);
            if (regionMatrix != null)
            {
                var ids = new HashSet<int>();
                for (int r = 0; r < StandardConstants.BoardSize; r++)
                {
                    for (int c = 0; c < StandardConstants.BoardSize; c++)
                    {
                        ids.Add(regionMatrix[r][c]);
                    }
                }

                if (ids.Count == StandardConstants.BoardSize)
                {
                    for (int i = 0; i < StandardConstants.BoardSize; i++)
                    {
                        if (!ids.Contains(i))
                            throw new InvalidOperationException($"区域模板无效：缺少区域ID {i}");
                    }
                    return regionMatrix;
                }
            }
        }

        var template = _templateManager.GetRegionTemplate(_random) ?? throw new InvalidOperationException("无法加载区域模板");
        return template;
    }

    /// <summary>
    /// 将模板数据转换为区域矩阵
    /// </summary>
    private static List<List<int>>? ConvertToRegionMatrix(object data)
    {
        try
        {
            if (data is List<List<int>> matrix)
            {
                return matrix;
            }
            if (data is int[][] arrayMatrix)
            {
                return [.. arrayMatrix.Select(row => row.ToList())];
            }

            if (data is JsonElement jsonElement && jsonElement.ValueKind == JsonValueKind.Array)
            {
                var result = new List<List<int>>();
                foreach (var row in jsonElement.EnumerateArray())
                {
                    var rowList = new List<int>();
                    foreach (var val in row.EnumerateArray())
                    {
                        rowList.Add(val.GetInt32());
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
    /// 从区域矩阵创建区域约束列表
    /// </summary>
    private List<SudokuRegion> CreateRegionsFromMatrix(List<List<int>> regionMatrix)
    {
        var regions = new List<SudokuRegion>();
        var regionMap = new Dictionary<int, List<(int row, int col)>>();

        var uniqueIds = new HashSet<int>();
        for (int r = 0; r < StandardConstants.BoardSize; r++)
        {
            for (int c = 0; c < StandardConstants.BoardSize; c++)
            {
                uniqueIds.Add(regionMatrix[r][c]);
            }
        }

        if (uniqueIds.Count != StandardConstants.BoardSize)
        {
            throw new InvalidOperationException($"区域模板必须包含{StandardConstants.BoardSize}个区域，实际有{uniqueIds.Count}个");
        }

        var sortedIds = uniqueIds.OrderBy(id => id).ToList();
        var idMapping = new Dictionary<int, int>();
        for (int i = 0; i < sortedIds.Count; i++)
            idMapping[sortedIds[i]] = i;

        for (int r = 0; r < StandardConstants.BoardSize; r++)
        {
            for (int c = 0; c < StandardConstants.BoardSize; c++)
            {
                var mappedId = idMapping[regionMatrix[r][c]];

                if (!regionMap.ContainsKey(mappedId))
                    regionMap[mappedId] = [];
                regionMap[mappedId].Add((r, c));
            }
        }

        foreach (var (regionId, cells) in regionMap)
        {
            if (cells.Count != StandardConstants.BoardSize)
            {
                throw new InvalidOperationException($"区域 {regionId} 必须有{StandardConstants.BoardSize}个单元格，实际有{cells.Count}个");
            }
        }

        // 存储区域坐标映射供后续使用
        _regionCoordinates = regionMap.ToDictionary(
            kvp => kvp.Key,
            kvp => kvp.Value.ToList()
        );

        // 区域将在Board创建后重新生成，这里先返回空列表
        // 实际的区域约束会在JigsawBoard.CreateRegions中创建
        return regions;
    }

    private Dictionary<int, List<(int row, int col)>>? _regionCoordinates;

    /// <summary>
    /// 使用 JigsawBitSolver 生成终盘
    /// </summary>
    private async Task<Board> GenerateSolution(List<List<int>> regionMatrix, IReadOnlyList<SudokuRegion> _, Func<bool>? isCancelled)
    {
        return await Task.Run(() =>
        {
            const int maxAttempts = 10; // 增加到10次尝试
            Exception? lastException = null;

            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                try
                {
                    if (isCancelled?.Invoke() ?? false) return null!;

                    var solver = new JigsawBitSolver(regionMatrix, _random);
                    var solution = solver.GenerateSolution(() => isCancelled?.Invoke() ?? false);

                    if (solution != null)
                        {
                            var resultCells = new List<IReadOnlyList<SudokuCell>>(StandardConstants.BoardSize);
                            for (int r = 0; r < StandardConstants.BoardSize; r++)
                            {
                                var row = new List<SudokuCell>(StandardConstants.BoardSize);
                                for (int c = 0; c < StandardConstants.BoardSize; c++)
                                {
                                    var value = solution[r, c];
                                    row.Add(SudokuCell.CreateInstance(row: r, col: c, value: value == 0 ? null : value, isFixed: false));
                                }
                                resultCells.Add(row);
                            }
                            var tempBoard = new JigsawBoard(StandardConstants.BoardSize, resultCells, regionMatrix: regionMatrix);
                            var completeRegions = tempBoard.CreateRegions();
                            return new JigsawBoard(StandardConstants.BoardSize, resultCells, completeRegions, regionMatrix);
                        }
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    lastException = ex;
                    // 继续尝试
                }
            }

            throw new InvalidOperationException($"无法生成锯齿数独终盘，已尝试{maxAttempts}次", lastException);
        });
    }

    /// <summary>
    /// 挖空生成谜题（使用 SmartRandomDiggingAlgorithm）
    /// </summary>
    private async Task<Board> GeneratePuzzle(Board solution, Difficulty difficulty, Func<bool>? isCancelled)
    {
        var config = DiggingConfig.FromDifficulty(difficulty, GameType.Jigsaw);

        if (isCancelled?.Invoke() ?? false) return null!;

        var puzzle = await _diggingAlgorithm.GeneratePuzzle(solution, config, isCancelled);

        if (isCancelled?.Invoke() ?? false) return null!;

        return puzzle;
    }

    /// <summary>
    /// 验证谜题与答案匹配
    /// </summary>
    private static bool ValidatePuzzleSolution(Board puzzle, Board solution)
    {
        for (int r = 0; r < puzzle.Size; r++)
        {
            for (int c = 0; c < puzzle.Size; c++)
            {
                var puzzleCell = puzzle.GetCell(r, c);
                if (puzzleCell.IsFixed && puzzleCell.Value.HasValue)
                {
                    var solutionCell = solution.GetCell(r, c);
                    if (solutionCell.Value != puzzleCell.Value)
                        return false;
                }
            }
        }
        return true;
    }

}
