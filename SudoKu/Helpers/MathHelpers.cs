namespace SudoKu.Helpers;

/// <summary>
/// 数学辅助工具类，提供组合数学、洗牌算法等常用数学操作。
/// </summary>
public static class MathHelpers
{
    /// <summary>
    /// Fisher-Yates 洗牌算法，原地随机打乱列表。
    /// </summary>
    /// <typeparam name="T">列表元素类型。</typeparam>
    /// <param name="list">要打乱的列表。</param>
    public static void Shuffle<T>(IList<T> list)
    {
        if (list is null)
            throw new ArgumentNullException(nameof(list));

        var random = new Random();
        for (int i = list.Count - 1; i > 0; i--)
        {
            int j = random.Next(0, i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }

    /// <summary>
    /// Fisher-Yates 洗牌算法，返回一个新的随机打乱的列表。
    /// </summary>
    /// <typeparam name="T">列表元素类型。</typeparam>
    /// <param name="source">源列表。</param>
    /// <returns>随机打乱后的新列表。</returns>
    public static List<T> Shuffled<T>(IEnumerable<T> source)
    {
        var list = source.ToList();
        Shuffle(list);
        return list;
    }

    /// <summary>
    /// 计算排列数 P(n, k) = n! / (n-k)!。
    /// </summary>
    /// <param name="n">总元素数。</param>
    /// <param name="k">选取元素数。</param>
    /// <returns>排列数。</returns>
    public static long Permutation(int n, int k)
    {
        if (k < 0 || k > n)
            return 0;
        if (k == 0)
            return 1;

        long result = 1;
        for (int i = 0; i < k; i++)
        {
            result *= (n - i);
        }
        return result;
    }

    /// <summary>
    /// 计算组合数 C(n, k) = n! / (k! * (n-k)!)。
    /// </summary>
    /// <param name="n">总元素数。</param>
    /// <param name="k">选取元素数。</param>
    /// <returns>组合数。</returns>
    public static long Combination(int n, int k)
    {
        if (k < 0 || k > n)
            return 0;
        if (k == 0 || k == n)
            return 1;

        // 使用较小的k值优化计算
        if (k > n - k)
            k = n - k;

        long result = 1;
        for (int i = 0; i < k; i++)
        {
            result = result * (n - i) / (i + 1);
        }
        return result;
    }

    /// <summary>
    /// 生成从 start 到 end（不含）的整数序列。
    /// </summary>
    /// <param name="start">起始值（包含）。</param>
    /// <param name="end">结束值（不包含）。</param>
    /// <returns>整数序列。</returns>
    public static IEnumerable<int> Range(int start, int end)
    {
        for (int i = start; i < end; i++)
        {
            yield return i;
        }
    }

    /// <summary>
    /// 生成从 1 到 count 的整数序列。
    /// </summary>
    /// <param name="count">数量。</param>
    /// <returns>从1开始的整数序列。</returns>
    public static IEnumerable<int> Range(int count)
    {
        return Range(1, count + 1);
    }

    /// <summary>
    /// 将值限制在指定范围内。
    /// </summary>
    /// <param name="value">输入值。</param>
    /// <param name="min">最小值。</param>
    /// <param name="max">最大值。</param>
    /// <returns>限制在 [min, max] 范围内的值。</returns>
    public static int Clamp(int value, int min, int max)
    {
        return Math.Max(min, Math.Min(max, value));
    }

    /// <summary>
    /// 将值限制在指定范围内。
    /// </summary>
    /// <param name="value">输入值。</param>
    /// <param name="min">最小值。</param>
    /// <param name="max">最大值。</param>
    /// <returns>限制在 [min, max] 范围内的值。</returns>
    public static double Clamp(double value, double min, double max)
    {
        return Math.Max(min, Math.Min(max, value));
    }

    /// <summary>
    /// 计算数独宫格的起始坐标。
    /// </summary>
    /// <param name="index">单元格索引（行或列）。</param>
    /// <param name="blockSize">宫格尺寸。</param>
    /// <returns>宫格起始坐标。</returns>
    public static int BlockStart(int index, int blockSize)
    {
        return (index / blockSize) * blockSize;
    }

    /// <summary>
    /// 获取指定坐标所在的宫格索引。
    /// </summary>
    /// <param name="row">行索引。</param>
    /// <param name="col">列索引。</param>
    /// <param name="blockSize">宫格尺寸。</param>
    /// <returns>宫格索引（0开始）。</returns>
    public static int GetBlockIndex(int row, int col, int blockSize)
    {
        int blockRow = row / blockSize;
        int blockCol = col / blockSize;
        return blockRow * blockSize + blockCol;
    }

    /// <summary>
    /// 生成指定范围内的随机整数。
    /// </summary>
    /// <param name="min">最小值（包含）。</param>
    /// <param name="max">最大值（不包含）。</param>
    /// <returns>随机整数。</returns>
    public static int RandomInt(int min, int max)
    {
        return new Random().Next(min, max);
    }

    /// <summary>
    /// 生成指定范围内的随机整数（使用共享随机实例，线程安全）。
    /// </summary>
    /// <param name="min">最小值（包含）。</param>
    /// <param name="max">最大值（不包含）。</param>
    /// <returns>随机整数。</returns>
    public static int ThreadSafeRandomInt(int min, int max)
    {
        lock (s_randomLock)
        {
            return s_sharedRandom.Next(min, max);
        }
    }

    private static readonly Random s_sharedRandom = new();
    private static readonly object s_randomLock = new();
}
