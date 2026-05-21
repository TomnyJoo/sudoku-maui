namespace SudoKu.Models;

/// <summary>
/// 数独区域类型枚举
/// </summary>
public enum RegionType
{
    Block,     // 宫格/块（标准数独的3x3宫格）
    Row,       // 行
    Column,    // 列
    Diagonal,  // 对角线
    Window,    // 窗口（窗口数独的特殊区域）
    Jigsaw,    // 锯齿（锯齿数独的不规则区域）
    Cage,      // 笼子（杀手数独的笼子区域）
    Custom,    // 自定义区域
}

/// <summary>
/// 数独区域具体类，表示数独棋盘中的逻辑区域，如行、列、宫格、对角线等
/// </summary>
public sealed record SudokuRegion
{
    /// <summary>
    /// 构造区域
    /// </summary>
    public SudokuRegion(string id, RegionType type, string name, IReadOnlyList<SudokuCell> cells)
    {
        Id = id;
        Type = type;
        Name = name;
        Cells = cells;
    }

    /// <summary>
    /// 从JSON创建区域
    /// </summary>
    public static SudokuRegion FromJson(Dictionary<string, object> json)
    {
        var typeStr = (string)json["type"];
        var type = Enum.TryParse<RegionType>(typeStr, out var t) ? t : RegionType.Custom;

        var cellsJson = (List<object>)json["cells"];
        var cells = cellsJson
            .Select(cellJson => SudokuCell.FromJson((Dictionary<string, object>)cellJson))
            .ToList();

        return new SudokuRegion(
            id: (string)json["id"],
            type: type,
            name: (string)json["name"],
            cells: cells
        );
    }

    /// <summary>
    /// 区域标识符
    /// </summary>
    public string Id { get; }

    /// <summary>
    /// 区域类型
    /// </summary>
    public RegionType Type { get; }

    /// <summary>
    /// 区域名称（用于显示）
    /// </summary>
    public string Name { get; }

    /// <summary>
    /// 区域内的单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> Cells { get; }

    /// <summary>
    /// 检查区域是否包含指定单元格
    /// </summary>
    public bool Contains(SudokuCell cell) => Cells.Any(c => c.Row == cell.Row && c.Col == cell.Col);

    /// <summary>
    /// 检查区域是否包含指定坐标的单元格
    /// </summary>
    public bool ContainsCoordinate(int row, int col)
    {
        return Cells.Any(cell => cell.Row == row && cell.Col == col);
    }

    /// <summary>
    /// 获取区域中已填数字的集合
    /// </summary>
    public IReadOnlySet<int> GetFilledNumbers()
    {
        var numbers = new HashSet<int>();
        foreach (var cell in Cells)
        {
            if (cell.Value != null)
            {
                numbers.Add(cell.Value.Value);
            }
        }
        return numbers;
    }

    /// <summary>
    /// 获取区域中未填数字的集合
    /// </summary>
    public IReadOnlySet<int> GetMissingNumbers(int maxNumber)
    {
        if (maxNumber < 1)
        {
            throw new ArgumentException($"最大数字必须大于0: {maxNumber}");
        }
        var filledNumbers = GetFilledNumbers();
        var allNumbers = new HashSet<int>(Enumerable.Range(1, maxNumber));
        allNumbers.ExceptWith(filledNumbers);
        return allNumbers;
    }

    /// <summary>
    /// 检查区域是否完整（所有单元格已填且不重复）
    /// </summary>
    public bool IsComplete()
    {
        var filledNumbers = GetFilledNumbers();
        return filledNumbers.Count == Cells.Count;
    }

    /// <summary>
    /// 检查区域是否有效（无重复数字）
    /// </summary>
    public bool IsValid()
    {
        var seenValues = new HashSet<int>();
        foreach (var cell in Cells)
        {
            var value = cell.Value;
            if (value != null)
            {
                if (!seenValues.Add(value.Value))
                {
                    return false;
                }
            }
        }
        return true;
    }

    /// <summary>
    /// 获取区域中指定数字的单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetCellsWithNumber(int number)
    {
        if (number < 1 || number > 9)
        {
            throw new ArgumentException($"数字必须在1-9范围内: {number}");
        }
        return [.. Cells.Where(cell => cell.Value == number)];
    }

    /// <summary>
    /// 获取区域中的空单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetEmptyCells() =>
        [.. Cells.Where(cell => cell.IsEmpty)];

    /// <summary>
    /// 获取区域中的已填单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetFilledCells() =>
        [.. Cells.Where(cell => !cell.IsEmpty)];

    /// <summary>
    /// 转换为JSON格式，用于持久化存储
    /// </summary>
    public Dictionary<string, object> ToJson()
    {
        return new Dictionary<string, object>
        {
            ["id"] = Id,
            ["type"] = Type.ToString(),
            ["name"] = Name,
            ["cells"] = Cells.Select(cell => cell.ToJson()).ToList()
        };
    }

    /// <summary>
    /// 创建区域实例
    /// </summary>
    public static SudokuRegion CreateInstance(string id, RegionType type, string name, IReadOnlyList<SudokuCell> cells)
    {
        return new SudokuRegion(id, type, name, cells);
    }

    /// <summary>
    /// 获取用于调试的字符串表示（不依赖国际化）
    /// </summary>
    public string ToDebugString() =>
        $"SudokuRegion(id: {Id}, type: {Type}, name: {Name}, cells: {Cells.Count})";

    public override string ToString() => ToDebugString();
}

/// <summary>
/// 区域集合工具类，提供区域集合的通用操作和验证方法
/// </summary>
public static class RegionCollectionUtils
{
    /// <summary>
    /// 获取包含指定单元格的区域
    /// </summary>
    public static IReadOnlyList<SudokuRegion> GetRegionsForCell(IReadOnlyList<SudokuRegion> regions, SudokuCell cell) =>
        [.. regions.Where(region => region.Contains(cell))];

    /// <summary>
    /// 获取包含指定坐标的区域
    /// </summary>
    public static IReadOnlyList<SudokuRegion> GetRegionsForCoordinate(IReadOnlyList<SudokuRegion> regions, int row, int col) =>
        [.. regions.Where(region => region.ContainsCoordinate(row, col))];

    /// <summary>
    /// 获取指定类型的所有区域
    /// </summary>
    public static IReadOnlyList<SudokuRegion> GetRegionsByType(IReadOnlyList<SudokuRegion> regions, RegionType type) =>
        [.. regions.Where(region => region.Type == type)];

    /// <summary>
    /// 检查所有区域是否完整
    /// </summary>
    public static bool AreAllRegionsComplete(IReadOnlyList<SudokuRegion> regions) =>
        regions.All(region => region.IsComplete());

    /// <summary>
    /// 检查所有区域是否有效
    /// </summary>
    public static bool AreAllRegionsValid(IReadOnlyList<SudokuRegion> regions) =>
        regions.All(region => region.IsValid());

    /// <summary>
    /// 获取区域数量统计
    /// </summary>
    public static Dictionary<RegionType, int> GetRegionCountByType(IReadOnlyList<SudokuRegion> regions)
    {
        var counts = new Dictionary<RegionType, int>();
        foreach (var region in regions)
        {
            counts[region.Type] = counts.GetValueOrDefault(region.Type) + 1;
        }
        return counts;
    }

    /// <summary>
    /// 转换为JSON格式，用于持久化存储
    /// </summary>
    public static Dictionary<string, object> ToJson(IReadOnlyList<SudokuRegion> regions, int boardSize)
    {
        return new Dictionary<string, object>
        {
            ["boardSize"] = boardSize,
            ["regions"] = regions.Select(region => region.ToJson()).ToList()
        };
    }

    /// <summary>
    /// 获取用于调试的字符串表示（不依赖国际化）
    /// </summary>
    public static string ToDebugString(IReadOnlyList<SudokuRegion> regions, int boardSize) =>
        $"RegionCollection(regions: {regions.Count}, boardSize: {boardSize})";
}
