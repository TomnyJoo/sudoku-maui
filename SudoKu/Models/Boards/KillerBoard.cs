using System.Collections.Immutable;

namespace SudoKu.Models.Boards;

/// <summary>
/// 杀手数独笼子模型
/// 杀手数独将棋盘划分为多个笼子，每个笼子包含一组单元格和一个和值
///
/// 优化说明：
/// 1. 存储坐标而非Cell引用，避免引用问题
/// 2. 添加缓存机制，提升性能
/// 3. 提供灵活的验证方法
/// </summary>
public sealed record KillerCage
{
    /// <summary>
    /// 主要构造函数
    /// </summary>
    public KillerCage(
        string id,
        IReadOnlyList<(int Row, int Col)> cellCoordinates,
        int sum,
        string? @operator = null)
    {
        Id = id;
        CellCoordinates = cellCoordinates;
        Sum = sum;
        Operator = @operator;
    }

    /// <summary>
    /// 从JSON创建笼子
    /// </summary>
    public static KillerCage FromJson(Dictionary<string, object> json)
    {
        var coordsJson = (List<object>)json["cellCoordinates"];
        var cellCoordinates = coordsJson.Select(coordJson =>
        {
            var map = (Dictionary<string, object>)coordJson;
            return ((int)map["row"], (int)map["col"]);
        }).ToList();

        return new KillerCage(
            id: (string)json["id"],
            cellCoordinates: cellCoordinates,
            sum: (int)json["sum"],
            @operator: json.TryGetValue("operator", out var op) ? (string?)op : null
        );
    }

    /// <summary>
    /// 简化构造函数，使用cells参数
    /// </summary>
    public KillerCage(
        IReadOnlyList<(int Row, int Col)> cells,
        int sum,
        string? @operator = null)
    {
        Id = $"cage_{DateTimeOffset.Now.ToUnixTimeMilliseconds()}";
        CellCoordinates = cells;
        Sum = sum;
        Operator = @operator;
    }

    public string Id { get; }
    public IReadOnlyList<(int Row, int Col)> CellCoordinates { get; }
    public int Sum { get; }
    public string? Operator { get; }

    /// <summary>
    /// 获取单元格坐标
    /// </summary>
    public IReadOnlyList<(int Row, int Col)> Cells => CellCoordinates;

    // 缓存机制
    private int? _cachedSum;
    private int? _cachedBoardStateHash;

    /// <summary>
    /// 检查坐标是否在笼子内
    /// </summary>
    public bool ContainsCoordinate(int row, int col)
    {
        foreach (var (Row, Col) in CellCoordinates)
        {
            if (Row == row && Col == col)
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 获取笼子包含的单元格数量
    /// </summary>
    public int CellCount => CellCoordinates.Count;

    /// <summary>
    /// 计算当前和值 - 带缓存优化
    ///
    /// 参数：
    /// - board: 当前棋盘状态
    ///
    /// 返回：笼子内所有已填单元格的和
    /// </summary>
    public int GetCurrentSum(Board board)
    {
        // 使用棋盘状态哈希判断是否需要重新计算（仅KillerBoard支持StateHash）
        var currentHash = board is KillerBoard kb ? kb.StateHash : (int?)null;
        if (currentHash != null && _cachedSum != null && _cachedBoardStateHash == currentHash)
        {
            return _cachedSum.Value;
        }

        var sum = CellCoordinates.Aggregate(0, (total, coord) =>
        {
            var cell = board.GetCell(coord.Row, coord.Col);
            return total + (cell.Value ?? 0);
        });

        _cachedSum = sum;
        if (currentHash != null)
        {
            _cachedBoardStateHash = currentHash;
        }

        return sum;
    }

    /// <summary>
    /// 检查笼子是否已完成（所有单元格已填）
    /// </summary>
    public bool IsComplete(Board board)
    {
        foreach (var (Row, Col) in CellCoordinates)
        {
            var cell = board.GetCell(Row, Col);
            if (cell.Value == null) return false;
        }
        return true;
    }

    /// <summary>
    /// 验证笼子约束是否满足
    ///
    /// 规则：
    /// 1. 已填数字之和不能超过目标和
    /// 2. 完成后和必须等于目标和
    /// 3. 笼子内数字绝对不能重复（杀手数独硬性规则）
    /// </summary>
    public bool IsValid(Board board)
    {
        var currentSum = GetCurrentSum(board);

        // 如果当前和已经超过目标和，无效
        if (currentSum > Sum) return false;

        // 检查笼子内数字是否重复（硬性规则）
        if (HasDuplicateValues(board))
        {
            return false;
        }

        // 如果笼子已完成，和必须等于目标和
        if (IsComplete(board))
        {
            return currentSum == Sum;
        }

        return true;
    }

    /// <summary>
    /// 检查笼子内是否有重复数字
    ///
    /// 杀手数独硬性规则：笼子内数字绝对不能重复
    /// </summary>
    private bool HasDuplicateValues(Board board)
    {
        var values = new HashSet<int>();

        foreach (var (Row, Col) in CellCoordinates)
        {
            var cell = board.GetCell(Row, Col);
            var value = cell.Value;

            if (value != null)
            {
                // 如果值已存在，说明有重复
                if (values.Contains(value.Value))
                {
                    return true;
                }
                values.Add(value.Value);
            }
        }

        return false;
    }

    /// <summary>
    /// 检查笼子内数字是否有重复（公开方法）
    ///
    /// 用于验证和调试
    /// </summary>
    public bool HasDuplicateValuesPublic(Board board) => HasDuplicateValues(board);

    /// <summary>
    /// 获取笼子在棋盘上的单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetCells(Board board) =>
        [.. CellCoordinates.Select(coord => board.GetCell(coord.Row, coord.Col))];

    /// <summary>
    /// 获取笼子的第一个单元格（用于显示和值）
    /// </summary>
    public SudokuCell GetFirstCell(Board board)
    {
        var (Row, Col) = CellCoordinates[0];
        return board.GetCell(Row, Col);
    }

    public Dictionary<string, object?> ToJson()
    {
        return new Dictionary<string, object?>
        {
            ["id"] = Id,
            ["cellCoordinates"] = CellCoordinates
                .Select(coord => new Dictionary<string, object> { ["row"] = coord.Row, ["col"] = coord.Col })
                .ToList(),
            ["sum"] = Sum,
            ["operator"] = Operator
        };
    }

    public override string ToString() =>
        $"KillerCage(id: {Id}, sum: {Sum}, cells: {CellCoordinates.Count})";
}

/// <summary>
/// 杀手数独棋盘
/// </summary>
public sealed record KillerBoard : Board
{
    /// <summary>
    /// 笼子列表
    /// </summary>
    public IReadOnlyList<KillerCage> Cages { get; }

    // Cage查找缓存 - 提升性能
    private Dictionary<string, KillerCage>? _cageLookupCache;
    private int? _cageLookupCacheHash;

    public KillerBoard(
        int size,
        IReadOnlyList<IReadOnlyList<SudokuCell>> cells,
        IReadOnlyList<SudokuRegion>? regions = null,
        IReadOnlyList<KillerCage>? cages = null)
        : base(size: size, cells: cells, regions: regions)
    {
        Cages = cages ?? [.. new List<KillerCage>()];
    }

    public override string GameType => "killer";

    /// <summary>
    /// 从JSON创建杀手数独棋盘
    /// </summary>
    public static KillerBoard FromJson(Dictionary<string, object> json)
    {
        var size = (int)json["size"];
        var cellsJson = (List<object>)json["cells"];
        var cells = cellsJson.Select(row =>
        {
            var rowList = (List<object>)row;
            return rowList
                .Select(cellJson => SudokuCell.FromJson((Dictionary<string, object>)cellJson))
                .ToList();
        }).ToList();

        var regionsJson = json.TryGetValue("regions", out var r) ? r as List<object> : null;
        List<SudokuRegion>? regions = null;
        if (regionsJson != null && regionsJson.Count > 0)
        {
            regions = [.. regionsJson.Select(regionJson => SudokuRegion.FromJson((Dictionary<string, object>)regionJson))];
        }

        var cagesJson = json.TryGetValue("cages", out var c) ? c as List<object> : null;
        var cages = cagesJson
            ?.Select(cageJson => KillerCage.FromJson((Dictionary<string, object>)cageJson))
            .ToList() ?? [];

        var board = new KillerBoard(size: size, cells: cells, regions: regions, cages: cages);
        // 如果没有区域信息，生成区域
        if (regions == null || regions.Count == 0)
        {
            var generatedRegions = board.CreateRegions();
            return new KillerBoard(size: size, cells: cells, regions: generatedRegions, cages: cages);
        }

        return board;
    }

    public override Board CreateInstance(
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells,
        IReadOnlyList<SudokuRegion>? regions = null)
    {
        // 如果regions为null或空，需要重新创建区域（包含笼子区域）
        var actualRegions = regions;
        if (actualRegions == null || actualRegions.Count == 0)
        {
            // 创建临时实例来生成区域
            var tempBoard = new KillerBoard(Size, newCells, cages: Cages);
            actualRegions = tempBoard.CreateRegions();
        }
        return new KillerBoard(
            size: Size,
            cells: newCells,
            regions: actualRegions,
            cages: Cages);
    }

    public override ImmutableList<SudokuRegion> CreateRegions(Dictionary<string, object>? templateData = null)
    {
        var regions = CreateDefaultRegions()
            .AddRange(CreateBlockRegions());

        foreach (var cage in Cages)
        {
            var cageCells = new List<SudokuCell>();
            foreach (var (row, col) in cage.CellCoordinates)
            {
                if (row >= 0 && row < Size && col >= 0 && col < Size)
                {
                    cageCells.Add(Cells[row][col]);
                }
            }
            if (cageCells.Count > 0)
            {
                regions = regions.Add(new SudokuRegion(
                    id: $"cage_{cage.Id}",
                    type: RegionType.Cage,
                    name: cage.Sum.ToString(),
                    cells: cageCells
                ));
            }
        }

        return regions;
    }

    public static KillerBoard Empty(int size = 9)
    {
        var cells = Enumerable.Range(0, size)
            .Select(i => Enumerable.Range(0, size)
                .Select(j => new SudokuCell(row: i, col: j))
                .ToList())
            .ToList();
        var board = new KillerBoard(size: size, cells: cells);
        return new KillerBoard(size: size, cells: cells, regions: board.CreateRegions());
    }

    public override Dictionary<string, object> ToJson()
    {
        return new Dictionary<string, object>
        {
            ["size"] = Size,
            ["cells"] = Cells.Select(row => row.Select(cell => cell.ToJson()).ToList()).ToList(),
            ["regions"] = Regions.Select(region => region.ToJson()).ToList(),
            ["cages"] = Cages.Select(cage => cage.ToJson()).ToList()
        };
    }

    /// <summary>
    /// 获取指定单元格所属的笼子
    /// </summary>
    public KillerCage? GetCageForCell(int row, int col)
    {
        // 使用缓存优化
        var cacheKey = $"{row},{col}";

        // 检查缓存是否需要重建
        var currentHash = Cages.Aggregate(0, (hash, c) => HashCode.Combine(hash, c.Id.GetHashCode()));
        if (_cageLookupCache == null || _cageLookupCacheHash != currentHash)
        {
            BuildCageLookupCache();
            _cageLookupCacheHash = currentHash;
        }

        return _cageLookupCache?.TryGetValue(cacheKey, out var cage) == true ? cage : null;
    }

    /// <summary>
    /// 构建cage查找缓存
    /// </summary>
    private void BuildCageLookupCache()
    {
        _cageLookupCache = [];
        foreach (var cage in Cages)
        {
            foreach (var (Row, Col) in cage.CellCoordinates)
            {
                var key = $"{Row},{Col}";
                _cageLookupCache[key] = cage;
            }
        }
    }

    /// <summary>
    /// 获取棋盘状态哈希值，用于缓存优化
    /// </summary>
    public int StateHash
    {
        get
        {
            var hash = 0;
            for (var i = 0; i < Size; i++)
            {
                for (var j = 0; j < Size; j++)
                {
                    var cell = Cells[i][j];
                    if (cell.Value != null)
                    {
                        hash = hash * 31 + cell.Value.Value + i * 9 + j;
                    }
                    if (cell.IsSelected)
                    {
                        hash = hash * 31 + 1000 + i * 9 + j;
                    }
                    if (cell.IsHighlighted)
                    {
                        hash = hash * 31 + 2000 + i * 9 + j;
                    }
                    if (cell.IsFixed)
                    {
                        hash = hash * 31 + 3000 + i * 9 + j;
                    }
                    if (cell.IsError)
                    {
                        hash = hash * 31 + 4000 + i * 9 + j;
                    }
                    foreach (var candidate in cell.Candidates)
                    {
                        hash = hash * 31 + 5000 + candidate + i * 9 + j;
                    }
                }
            }
            return hash;
        }
    }

    /// <summary>
    /// 获取所有笼子的验证状态
    /// </summary>
    public Dictionary<string, bool> GetCagesValidationStatus()
    {
        var result = new Dictionary<string, bool>();
        foreach (var cage in Cages)
        {
            result[cage.Id] = cage.IsValid(this);
        }
        return result;
    }

    /// <summary>
    /// 检查所有笼子是否都有效
    /// </summary>
    public bool AreAllCagesValid
    {
        get
        {
            foreach (var cage in Cages)
            {
                if (!cage.IsValid(this)) return false;
            }
            return true;
        }
    }

    /// <summary>
    /// 重写选择指定单元格，修改高亮逻辑，删除后半条规则
    /// </summary>
    public override Board SelectCell(int row, int col)
    {
        var newCells = Cells
            .Select(r => r
                .Select(c => c.CopyWith(
                    isSelected: c.Row == row && c.Col == col,
                    isHighlighted: false))
                .ToList())
            .ToList();

        var selectedCell = newCells[row][col];
        var finalCells = newCells
            .Select(r => r
                .Select(c =>
                {
                    bool isHighlighted = false;
                    if (selectedCell.Value != null)
                    {
                        isHighlighted = c.Value != null &&
                                        c.Value == selectedCell.Value &&
                                        c.Row != row &&
                                        c.Col != col;
                    }
                    return c.CopyWith(isHighlighted: isHighlighted);
                })
                .ToList())
            .ToList();

        var newRegions = Regions.Select(region =>
        {
            var newRegionCells = region.Cells
                .Select(c => finalCells[c.Row][c.Col])
                .ToList();
            return new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            );
        }).ToList();

        return CreateInstance(finalCells, newRegions);
    }
}
