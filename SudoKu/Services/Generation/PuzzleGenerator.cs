using SudoKu.Exceptions;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Interfaces;

namespace SudoKu.Services.Generation;

/// <summary>
/// 谜题生成器调度类，负责根据游戏类型选择并调用具体的生成逻辑。
/// 包含重试机制和超时保护，确保用户体验。
/// </summary>
/// <remarks>单次生成的超时时间（毫秒）</remarks>
public class PuzzleGenerator(IPuzzleSolver solver, TemplateManager templateManager)
{
    private readonly IPuzzleSolver _solver = solver;
    private readonly TemplateManager _templateManager = templateManager;
    private readonly Random _random = new();
    private const int MaxRetries = 5;   /// <summary>最大重试次数</summary>
    private const int GenerationTimeoutMs = 120000;

    /// <inheritdoc/>
    public async Task<GenerationResult> GenerateAsync(
        GameType gameType,  // 游戏类型
        Difficulty difficulty,  // 难度级别
        IProgress<GenerationStage>? progress = null,    // 进度报告接口
        CancellationToken cancellationToken = default)  // 取消令牌，支持外部取消生成过程
    {
        PerformanceMonitor.StartTrace("PuzzleGeneration");
        try
        {
            for (int attempt = 1; attempt <= MaxRetries; attempt++)
            {
                if (cancellationToken.IsCancellationRequested)
                    return new GenerationResult { GenerationTime = 0, IsCancelled = true };

                // 为每次尝试创建独立的超时控制
                using var attemptCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
                attemptCts.CancelAfter(GenerationTimeoutMs);

                try
                {
                    // 准备该游戏类型需要的模板数据
                    var templateData = PrepareTemplateData(gameType);

                    SudokuGenerator generator = gameType switch
                    {
                        GameType.Standard => new StandardGenerator(_random),
                        GameType.Jigsaw => new JigsawGenerator(_templateManager, _random),
                        GameType.Diagonal => new DiagonalGenerator(_random),
                        GameType.Window => new WindowGenerator(_random),
                        GameType.Killer => new KillerGenerator(_random),
                        GameType.Samurai => new SamuraiGenerator(_templateManager, _random),
                        _ => new StandardGenerator(_random)
                    };

                    var result = await generator.GenerateAsync(difficulty, size: 9, isCancelled: () =>
                        attemptCts.IsCancellationRequested, templateData: templateData, progress: progress);

                    if (result.Puzzle is not null && result.Solution is not null)
                    {
                        PerformanceMonitor.LogMetric("PuzzleGeneration", PerformanceMonitor.EndTrace("PuzzleGeneration"));
                        DebugLogger.Debug("PuzzleGenerator", $"生成了 {gameType} {difficulty} 难度谜题，耗时 {result.GenerationTime}ms");
                        return result;
                    }
                }
                catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
                {
                    // 单次尝试超时，继续重试
                }
                catch (PuzzleGenerationException ex)
                {
                    DebugLogger.Debug("PuzzleGenerator", $"生成异常: {ex.Message}");
                    // 继续重试
                }
            }

            // 所有重试均失败
            progress?.Report(GenerationStage.Failed);
            throw new PuzzleGenerationException("无法生成符合要求的数独谜题");
        }
        finally
        {
            PerformanceMonitor.EndTrace("PuzzleGeneration");
        }
    }

    /// <summary>
    /// 准备指定游戏类型需要的模板数据
    /// </summary>
    private Dictionary<string, object>? PrepareTemplateData(GameType gameType)
    {
        Dictionary<string, object>? templateData = null;

        switch (gameType)
        {
            case GameType.Standard:
                // 标准数独：使用 rrn17 终盘模板
                var solutionData = _templateManager.GetRrn17Template(_random);
                if (solutionData != null)
                {
                    templateData = new Dictionary<string, object> { ["solutionData"] = solutionData };
                }
                break;

            case GameType.Jigsaw:
                // 锯齿数独：使用区域模板
                var regionData = _templateManager.GetRegionTemplate(_random);
                if (regionData != null)
                {
                    templateData = new Dictionary<string, object> { ["regionMatrix"] = regionData };
                }
                break;

            case GameType.Killer:
                // 杀手数独：可选使用 rrn17 终盘模板
                var killerSolutionData = _templateManager.GetRrn17Template(_random);
                if (killerSolutionData != null)
                {
                    templateData = new Dictionary<string, object> { ["solutionData"] = killerSolutionData };
                }
                break;

            case GameType.Samurai:
                // 武士数独：可选使用 rrn17 中心盘模板
                var samuraiSolutionData = _templateManager.GetRrn17Template(_random);
                if (samuraiSolutionData != null)
                {
                    templateData = new Dictionary<string, object> { ["solutionData"] = samuraiSolutionData };
                }
                break;

            // Diagonal、Window 不使用模板
        }

        return templateData;
    }

    /// <inheritdoc/>
    public async Task<GenerationResult> GenerateCustomAsync(Board customBoard, CancellationToken cancellationToken = default)
    {
        var isUnique = await _solver.IsUniqueSolutionAsync(customBoard, cancellationToken);

        if (!isUnique)
        {
            return new GenerationResult { Puzzle = null, Solution = null };
        }

        // 使用求解器获取解答
        var analysis = await _solver.AnalyzeAsync(customBoard, cancellationToken);

        if (!analysis.IsSolvable)
        {
            return new GenerationResult { Puzzle = null, Solution = null };
        }

        return new GenerationResult
        {
            Puzzle = customBoard,
            Solution = customBoard // 自定义谜题的解答需要通过求解器获取
        };
    }
}
