using System.Numerics;
using SudoKu.Helpers;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving.Solvers;

public class JigsawBitSolver
{
    private readonly List<List<int>>? _regionMatrix;
    private readonly int _size = StandardConstants.BoardSize;
    private readonly uint _fullMask = StandardConstants.FullMask;
    private readonly Random _random = new();
    
    // 预缓存：单元格到区域的映射
    private int[,]? _cellToRegion;

    public JigsawBitSolver()
    {
    }

    public JigsawBitSolver(List<List<int>> regionMatrix, Random? random = null)
    {
        _regionMatrix = regionMatrix;
        _random = random ?? new Random();
        InitRegionData();
    }

    /// <summary>
    /// 初始化区域数据缓存
    /// 在构造时调用一次，避免重复计算
    /// </summary>
    private void InitRegionData()
    {
        if (_regionMatrix == null) return;
        
        _cellToRegion = new int[_size, _size];
        for (int r = 0; r < _size; r++)
        {
            for (int c = 0; c < _size; c++)
            {
                _cellToRegion[r, c] = _regionMatrix[r][c];
            }
        }
    }

    /// <summary>
    /// 生成终盘
    /// 使用 MRV + 随机候选顺序生成有效终盘
    /// </summary>
    public int[,]? GenerateSolution(Func<bool>? isCancelled = null)
    {
        // 检查区域矩阵是否已设置
        if (_regionMatrix == null)
            return null;

        // 使用二维数组，避免索引计算
        var grid = new int[_size, _size];
        var rowMask = new uint[_size];
        var colMask = new uint[_size];
        var regionMask = new uint[9];

        bool found = false;

        try
        {
            bool Backtrack()
            {
                if (isCancelled?.Invoke() ?? false)
                    throw new OperationCanceledException();

                if (found) return true;

                // MRV：找到候选数最少的空单元格
                int minCount = _size + 1;
                int bestR = -1, bestC = -1;
                uint bestBits = 0;

                for (int r = 0; r < _size; r++)
                {
                    for (int c = 0; c < _size; c++)
                    {
                        if (grid[r, c] != 0) continue;

                        // 使用预缓存的区域映射
                        int rid = _cellToRegion?[r, c] ?? _regionMatrix[r][c];

                        uint usedMask = rowMask[r] | colMask[c] | regionMask[rid];
                        uint candidates = _fullMask & ~usedMask;

                        if (candidates == 0) return false;

                        int count = BitOperations.PopCount(candidates);
                        if (count < minCount)
                        {
                            minCount = count;
                            bestR = r;
                            bestC = c;
                            bestBits = candidates;
                            if (count == 1) break;
                        }
                    }
                    if (minCount == 1) break;
                }

                if (bestR == -1)
                {
                    found = true;
                    return true;
                }

                // 启发式排序：70%有序 + 30%随机
                var values = BitsToValues(bestBits);
                ShuffleWithHeuristic(values);

                int bestRid = _cellToRegion?[bestR, bestC] ?? _regionMatrix[bestR][bestC];

                foreach (var d in values)
                {
                    if (found) return true;

                    uint bit = 1u << (d - 1);

                    grid[bestR, bestC] = d;
                    rowMask[bestR] |= bit;
                    colMask[bestC] |= bit;
                    regionMask[bestRid] |= bit;

                    if (Backtrack()) return true;

                    // 回溯 - 使用位运算恢复
                    rowMask[bestR] &= ~bit;
                    colMask[bestC] &= ~bit;
                    regionMask[bestRid] &= ~bit;
                    grid[bestR, bestC] = 0;
                }

                return false;
            }

            Backtrack();
        }
        catch (OperationCanceledException)
        {
            return null;
        }

        return found ? grid : null;
    }

    /// <summary>
    /// 检查是否有唯一解
    /// </summary>
    public bool HasUniqueSolution(Board puzzle, Func<bool>? isCancelled = null)
    {
        return CountSolutions(puzzle, 2, isCancelled) == 1;
    }

    /// <summary>
    /// 计算解的数量（用于验证唯一解）
    /// </summary>
    public int CountSolutions(Board puzzle, int maxCount = 2, Func<bool>? isCancelled = null)
    {
        // 从 JigsawBoard 获取区域矩阵
        var regionMatrix = _regionMatrix;
        int[,]? localCellToRegion = _cellToRegion;
        
        if (puzzle is JigsawBoard jigsawBoard && jigsawBoard.RegionMatrix != null)
        {
            regionMatrix = [.. jigsawBoard.RegionMatrix.Select(row => row.ToList())];
            
            // 重新构建区域缓存
            localCellToRegion = new int[_size, _size];
            for (int r = 0; r < _size; r++)
            {
                for (int c = 0; c < _size; c++)
                {
                    localCellToRegion[r, c] = regionMatrix[r][c];
                }
            }
        }

        if (regionMatrix == null || localCellToRegion == null)
            return 0;

        // 从谜题加载初始值 - 使用二维数组
        var grid = new int[_size, _size];
        var rowMask = new uint[_size];
        var colMask = new uint[_size];
        var regionMask = new uint[9];

        for (int r = 0; r < _size; r++)
        {
            for (int c = 0; c < _size; c++)
            {
                var val = puzzle.GetCell(r, c).Value;
                if (val.HasValue)
                {
                    grid[r, c] = val.Value;
                    uint bit = 1u << (val.Value - 1);
                    rowMask[r] |= bit;
                    colMask[c] |= bit;
                    regionMask[localCellToRegion[r, c]] |= bit;
                }
            }
        }

        int solutionsFound = 0;

        bool Backtrack()
        {
            if (isCancelled?.Invoke() ?? false)
                throw new OperationCanceledException();

            if (solutionsFound >= maxCount) return true;

            // MRV
            int minCount = _size + 1;
            int bestR = -1, bestC = -1;
            uint bestBits = 0;

            for (int r = 0; r < _size; r++)
            {
                for (int c = 0; c < _size; c++)
                {
                    if (grid[r, c] != 0) continue;

                    int rid = localCellToRegion[r, c];
                    uint usedMask = rowMask[r] | colMask[c] | regionMask[rid];
                    uint candidates = _fullMask & ~usedMask;

                    if (candidates == 0) return false;

                    int count = BitOperations.PopCount(candidates);
                    if (count < minCount)
                    {
                        minCount = count;
                        bestR = r;
                        bestC = c;
                        bestBits = candidates;
                        if (count == 1) break;
                    }
                }
                if (minCount == 1) break;
            }

            if (bestR == -1)
            {
                solutionsFound++;
                return solutionsFound >= maxCount;
            }

            var values = BitsToValues(bestBits);
            int bestRid = localCellToRegion[bestR, bestC];

            foreach (var d in values)
            {
                uint bit = 1u << (d - 1);

                grid[bestR, bestC] = d;
                rowMask[bestR] |= bit;
                colMask[bestC] |= bit;
                regionMask[bestRid] |= bit;

                if (Backtrack()) return true;

                rowMask[bestR] &= ~bit;
                colMask[bestC] &= ~bit;
                regionMask[bestRid] &= ~bit;
                grid[bestR, bestC] = 0;
            }

            return false;
        }

        Backtrack();
        return solutionsFound;
    }

    private static List<int> BitsToValues(uint bits)
    {
        var values = new List<int>();
        for (int i = 0; i < StandardConstants.BoardSize; i++)
        {
            if ((bits & (1u << i)) != 0)
                values.Add(i + 1);
        }
        return values;
    }

    private void Shuffle(List<int> list)
    {
        var n = list.Count;
        for (int i = n - 1; i > 0; i--)
        {
            var j = _random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }

    private void ShuffleWithHeuristic(List<int> list)
    {
        list.Sort();
        for (int i = list.Count - 1; i > 0; i--)
        {
            if (_random.NextDouble() < 0.3)
            {
                var j = _random.Next(i + 1);
                (list[i], list[j]) = (list[j], list[i]);
            }
        }
    }
}
