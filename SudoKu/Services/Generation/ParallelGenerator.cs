using System.Collections.Immutable;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

/// <summary>
/// 并行数独生成器，利用多核CPU加速终盘生成
/// 
/// 参照 Flutter 的 parallel_generator.dart 实现
/// 使用多个线程并行尝试生成，第一个成功的结果即为最终结果
/// </summary>
public class ParallelGenerator
{
    private readonly int _concurrency;
    private readonly Random _random;

    /// <summary>
    /// 初始化并行生成器
    /// </summary>
    /// <param name="concurrency">并发线程数，默认为CPU核心数</param>
    /// <param name="random">随机数生成器</param>
    public ParallelGenerator(int concurrency = 0, Random? random = null)
    {
        _concurrency = concurrency > 0 ? concurrency : Environment.ProcessorCount;
        _random = random ?? new Random();
    }

    /// <summary>
    /// 并行生成标准数独终盘
    /// </summary>
    /// <param name="size">棋盘大小</param>
    /// <param name="isCancelled">取消检查回调</param>
    /// <returns>生成的棋盘，失败返回null</returns>
    public async Task<Board?> GenerateStandardSolution(int size, Func<bool>? isCancelled)
    {
        var tasks = new List<Task<Board?>>();
        using var cts = new CancellationTokenSource();
        
        // 启动多个并行任务
        for (int i = 0; i < _concurrency; i++)
        {
            tasks.Add(GenerateWithSeed(size, _random.Next(), isCancelled, cts.Token));
        }

        // 等待任一任务完成
        var completed = await Task.WhenAny(tasks);
        
        // 取消其他任务
        cts.Cancel();
        
        return completed.Result;
    }

    /// <summary>
    /// 并行生成对角线数独终盘
    /// </summary>
    public async Task<Board?> GenerateDiagonalSolution(int size, Func<bool>? isCancelled)
    {
        var tasks = new List<Task<Board?>>();
        using var cts = new CancellationTokenSource();
        
        for (int i = 0; i < _concurrency; i++)
        {
            tasks.Add(GenerateDiagonalWithSeed(size, _random.Next(), isCancelled, cts.Token));
        }

        var completed = await Task.WhenAny(tasks);
        cts.Cancel();
        
        return completed.Result;
    }

    /// <summary>
    /// 并行生成窗口数独终盘
    /// </summary>
    public async Task<Board?> GenerateWindowSolution(int size, Func<bool>? isCancelled)
    {
        var tasks = new List<Task<Board?>>();
        using var cts = new CancellationTokenSource();
        
        for (int i = 0; i < _concurrency; i++)
        {
            tasks.Add(GenerateWindowWithSeed(size, _random.Next(), isCancelled, cts.Token));
        }

        var completed = await Task.WhenAny(tasks);
        cts.Cancel();
        
        return completed.Result;
    }

    /// <summary>
    /// 使用指定种子生成标准数独
    /// </summary>
    private async Task<Board?> GenerateWithSeed(int size, int seed, Func<bool>? isCancelled, CancellationToken token)
    {
        return await Task.Run(() =>
        {
            var localRandom = new Random(seed);
            
            while (!token.IsCancellationRequested && !(isCancelled?.Invoke() ?? false))
            {
                var solver = StandardDLXSolver.Create(localRandom);
                var matrix = solver.GenerateSolution(() => token.IsCancellationRequested || (isCancelled?.Invoke() ?? false));
                
                if (matrix != null)
                {
                    return CreateStandardBoard(matrix, size);
                }
                
                // 更新种子继续尝试
                seed += 10000;
                localRandom = new Random(seed);
            }
            
            return null;
        }, token);
    }

    /// <summary>
    /// 使用指定种子生成对角线数独
    /// </summary>
    private async Task<Board?> GenerateDiagonalWithSeed(int size, int seed, Func<bool>? isCancelled, CancellationToken token)
    {
        return await Task.Run(() =>
        {
            var localRandom = new Random(seed);
            
            while (!token.IsCancellationRequested && !(isCancelled?.Invoke() ?? false))
            {
                var solver = StandardDLXSolver.Create(localRandom);
                var matrix = solver.GenerateSolution(() => token.IsCancellationRequested || (isCancelled?.Invoke() ?? false));
                
                if (matrix != null)
                {
                    var board = CreateStandardBoard(matrix, size);
                    // 验证对角线约束
                    if (ValidateDiagonalConstraints(board))
                    {
                        return board;
                    }
                }
                
                seed += 10000;
                localRandom = new Random(seed);
            }
            
            return null;
        }, token);
    }

    /// <summary>
    /// 使用指定种子生成窗口数独
    /// </summary>
    private async Task<Board?> GenerateWindowWithSeed(int size, int seed, Func<bool>? isCancelled, CancellationToken token)
    {
        return await Task.Run(() =>
        {
            var localRandom = new Random(seed);
            
            while (!token.IsCancellationRequested && !(isCancelled?.Invoke() ?? false))
            {
                var solver = StandardDLXSolver.Create(localRandom);
                var matrix = solver.GenerateSolution(() => token.IsCancellationRequested || (isCancelled?.Invoke() ?? false));
                
                if (matrix != null)
                {
                    var board = CreateStandardBoard(matrix, size);
                    // 验证窗口约束（中心3x3区域）
                    if (ValidateWindowConstraints(board))
                    {
                        return board;
                    }
                }
                
                seed += 10000;
                localRandom = new Random(seed);
            }
            
            return null;
        }, token);
    }

    /// <summary>
    /// 从矩阵创建标准棋盘
    /// </summary>
    private Board CreateStandardBoard(int[,] matrix, int size)
    {
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: matrix[r, c],
                    isFixed: false
                ));
            }
            cells.Add(row);
        }

        // 使用统一的 StandardBoard
        return new StandardBoard(size, cells);
    }

    /// <summary>
    /// 验证对角线约束
    /// </summary>
    private bool ValidateDiagonalConstraints(Board board)
    {
        var size = board.Size;
        var diag1 = new HashSet<int>();
        var diag2 = new HashSet<int>();
        
        for (int i = 0; i < size; i++)
        {
            var val1 = board.GetCell(i, i).Value;
            var val2 = board.GetCell(i, size - 1 - i).Value;
            
            if (val1.HasValue && !diag1.Add(val1.Value)) return false;
            if (val2.HasValue && !diag2.Add(val2.Value)) return false;
        }
        
        return true;
    }

    /// <summary>
    /// 验证窗口约束（中心3x3区域）
    /// </summary>
    private bool ValidateWindowConstraints(Board board)
    {
        // 窗口数独额外要求中心3x3区域包含1-9
        var size = board.Size;
        var blockSize = (int)Math.Sqrt(size);
        var center = blockSize / 2;
        
        var windowCells = new HashSet<int>();
        for (int r = center * blockSize; r < (center + 1) * blockSize; r++)
        {
            for (int c = center * blockSize; c < (center + 1) * blockSize; c++)
            {
                var val = board.GetCell(r, c).Value;
                if (val.HasValue && !windowCells.Add(val.Value)) return false;
            }
        }
        
        return windowCells.Count == size;
    }

    }
