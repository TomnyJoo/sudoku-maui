

using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Generation;

/// <summary>
/// 游戏生成器接口
/// 所有专用生成器必须实现此接口
/// 
/// 参照 Flutter 的 IGameGenerator 接口实现
/// </summary>
public interface IGameGenerator
{
    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    GameType SupportedGameType { get; }

    /// <summary>
    /// 生成游戏
    /// </summary>
    /// <param name="difficulty">难度等级</param>
    /// <param name="size">棋盘大小（通常为9）</param>
    /// <param name="isCancelled">取消回调函数</param>
    /// <param name="templateData">预加载的模板数据（可选）</param>
    /// <param name="progress">生成阶段更新回调（可选）</param>
    /// <returns>生成结果</returns>
    Task<GenerationResult> GenerateAsync(
        Difficulty difficulty,
        int size,
        Func<bool>? isCancelled = null,
        Dictionary<string, object>? templateData = null,
        IProgress<GenerationStage>? progress = null);
}

/// <summary>
/// 谜题生成器抽象基类
/// 
/// 参照 Flutter 架构：只定义通用辅助方法，不使用模板方法管线。
/// 每个具体生成器直接实现所有逻辑。
/// </summary>
public abstract class SudokuGenerator : IGameGenerator
{
    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    public abstract GameType SupportedGameType { get; }

    /// <summary>
    /// 生成谜题的抽象方法。由具体生成器实现。
    /// </summary>
    /// <param name="difficulty">难度等级</param>
    /// <param name="size">棋盘大小</param>
    /// <param name="isCancelled">取消回调</param>
    /// <param name="templateData">模板数据</param>
    /// <param name="progress">生成进度报告回调，可为 null。</param>
    /// <returns>生成结果，包含谜题棋盘和解答棋盘。</returns>
    public abstract Task<GenerationResult> GenerateAsync(
        Difficulty difficulty,
        int size,
        Func<bool>? isCancelled = null,
        Dictionary<string, object>? templateData = null,
        IProgress<GenerationStage>? progress = null);

    /// <summary>
    /// 设置解答的固定单元格标记（根据谜题）
    /// 
    /// 参照 Flutter 的 StandardGenerator._setSolutionFixedCells
    /// 【关键修复】同步更新 regions 中的 cell 引用
    /// </summary>
    /// <param name="solution">解答棋盘</param>
    /// <param name="puzzle">谜题棋盘</param>
    /// <returns>标记了固定单元格的解答棋盘</returns>
    protected static Board SetSolutionFixedCells(Board solution, Board puzzle)
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(solution.Size);
        for (int r = 0; r < solution.Size; r++)
        {
            var row = new List<SudokuCell>(solution.Size);
            for (int c = 0; c < solution.Size; c++)
            {
                var solutionCell = solution.GetCell(r, c);
                var puzzleCell = puzzle.GetCell(r, c);
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: solutionCell.Value,
                    isFixed: puzzleCell.IsFixed
                ));
            }
            newCells.Add(row);
        }
        // 【关键修复】同步更新 regions 中的 cell 引用，确保指向 newCells 中的对象
        var updatedRegions = UpdateRegionCellReferences(solution.Regions, newCells);
        return solution.CreateInstance(newCells, updatedRegions);
    }

    /// <summary>
    /// 同步更新 regions 中的 cell 引用，使其指向 newCells 中的对应对象
    /// </summary>
    internal static IReadOnlyList<SudokuRegion> UpdateRegionCellReferences(
        IReadOnlyList<SudokuRegion> regions,
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells)
    {
        if (regions.Count == 0) return regions;

        var updatedRegions = new List<SudokuRegion>(regions.Count);
        foreach (var region in regions)
        {
            var newRegionCells = new List<SudokuCell>(region.Cells.Count);
            foreach (var cell in region.Cells)
            {
                newRegionCells.Add(newCells[cell.Row][cell.Col]);
            }
            updatedRegions.Add(new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            ));
        }
        return updatedRegions;
    }

    /// <summary>
    /// 打乱列表顺序（Fisher-Yates 洗牌）
    /// </summary>
    protected static void Shuffle<T>(IList<T> list, Random random)
    {
        var n = list.Count;
        for (int i = n - 1; i > 0; i--)
        {
            var j = random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }

    /// <summary>
    /// 生成随机数字排列（1 到 n）
    /// </summary>
    protected static int[] GenerateRandomPermutation(int n, Random random)
    {
        var numbers = Enumerable.Range(1, n).ToList();
        Shuffle(numbers, random);
        return [.. numbers];
    }

    /// <summary>
    /// 计算位掩码中1的个数
    /// </summary>
    protected static int PopCount(int bits)
    {
        int count = 0;
        while (bits != 0)
        {
            count++;
            bits &= bits - 1;
        }
        return count;
    }

    /// <summary>
    /// 将位掩码转换为值列表
    /// </summary>
    protected static List<int> BitsToValues(int bits, int size = 9)
    {
        var values = new List<int>();
        for (int i = 0; i < size; i++)
        {
            if ((bits & (1 << i)) != 0)
                values.Add(i + 1);
        }
        return values;
    }

    /// <summary>
    /// 检查是否已取消
    /// </summary>
    protected static bool CheckCancelled(Func<bool>? isCancelled)
    {
        return isCancelled?.Invoke() ?? false;
    }
}
