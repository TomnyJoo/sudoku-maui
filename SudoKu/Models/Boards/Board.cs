using System.Collections.Immutable;
using SudoKu.Models.Commands;

namespace SudoKu.Models.Boards;

/// <summary>
/// 数独棋盘抽象基类，封装棋盘状态和操作，提供统一的接口，支持不同类型的数独游戏（标准、锯齿、对角线等）
/// </summary>
public abstract record Board
{
    private List<SudokuRegion>[][] _cellRegions = null!;

    /// <summary>
    /// 构造棋盘模型
    /// </summary>
    protected Board(int size, IReadOnlyList<IReadOnlyList<SudokuCell>> cells, IReadOnlyList<SudokuRegion>? regions = null)
    {
        // 验证棋盘尺寸
        if (size <= 0)
        {
            throw new ArgumentException($"棋盘尺寸必须大于0: {size}");
        }

        // 验证单元格矩阵
        if (cells.Count != size)
        {
            throw new ArgumentException($"棋盘行数必须等于尺寸: {cells.Count} != {size}");
        }

        for (var i = 0; i < cells.Count; i++)
        {
            if (cells[i].Count != size)
            {
                throw new ArgumentException($"第{i}行列数必须等于尺寸: {cells[i].Count} != {size}");
            }

            for (var j = 0; j < cells[i].Count; j++)
            {
                var cell = cells[i][j];
                if (cell.Row != i || cell.Col != j)
                {
                    throw new ArgumentException($"单元格坐标不匹配: ({i},{j}) != ({cell.Row},{cell.Col})");
                }
            }
        }

        Size = size;
        Cells = [.. cells.Select(row => row.ToImmutableList())];
        Regions = regions?.ToImmutableList() ?? [];
        BuildCellRegionIndex();
    }

    /// <summary>
    /// 从JSON创建单元格矩阵
    /// </summary>
    protected static ImmutableList<ImmutableList<SudokuCell>> CellsFromJson(List<object> cellsJson)
    {
        return [.. cellsJson.Select(row =>
        {
            var rowList = (List<object>)row;
            var cells = rowList
                .Select(cellJson => SudokuCell.FromJson((Dictionary<string, object>)cellJson))
                .ToImmutableList();
            return cells;
        })];
    }

    /// <summary>
    /// 从JSON创建区域列表
    /// </summary>
    protected static ImmutableList<SudokuRegion> RegionsFromJson(List<object>? regionsJson)
    {
        if (regionsJson != null && regionsJson.Count > 0)
        {
            return [.. regionsJson.Select(regionJson => SudokuRegion.FromJson((Dictionary<string, object>)regionJson))];
        }
        return [];
    }

    /// <summary>
    /// 创建空的单元格矩阵
    /// </summary>
    protected static ImmutableList<ImmutableList<SudokuCell>> CreateEmptyCells(int size)
    {
        return [.. Enumerable.Range(0, size)
            .Select(i => Enumerable.Range(0, size)
                .Select(j => new SudokuCell(row: i, col: j))
                .ToImmutableList())];
    }

    /// <summary>
    /// 棋盘尺寸（通常为9）
    /// </summary>
    public int Size { get; }

    /// <summary>
    /// 棋盘单元格矩阵（行优先）
    /// </summary>
    public ImmutableList<ImmutableList<SudokuCell>> Cells { get; }

    /// <summary>
    /// 区域集合（用于区域验证）
    /// </summary>
    public ImmutableList<SudokuRegion> Regions { get; }

    /// <summary>
    /// 获取游戏类型标识符（子类可覆盖）
    /// </summary>
    public virtual string GameType => "";

    /// <summary>
    /// 获取指定位置的单元格
    /// </summary>
    public SudokuCell GetCell(int row, int col)
    {
        if (row < 0 || row >= Size || col < 0 || col >= Size)
        {
            throw new ArgumentOutOfRangeException($"坐标超出范围: row={row}, col={col}, size={Size}");
        }
        return Cells[row][col];
    }

    /// <summary>
    /// 设置单元格值
    /// </summary>
    public Board SetCellValue(int row, int col, int? value)
    {
        var cell = GetCell(row, col);
        if (!cell.IsEditable) return this;

        var newCell = cell.SetValue(value);
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 设置整个单元格（包括固定状态）
    /// </summary>
    public Board SetCell(int row, int col, SudokuCell newCell) =>
        UpdateCell(row, col, newCell);

    /// <summary>
    /// 设置单元格候选数字
    /// </summary>
    public Board SetCellCandidates(int row, int col, ImmutableHashSet<int> candidates)
    {
        var cell = GetCell(row, col);
        var newCell = cell.CopyWith(candidates: candidates);
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 添加单元格候选数字
    /// </summary>
    public Board AddCellCandidate(int row, int col, int number)
    {
        var cell = GetCell(row, col);
        var newCell = cell.AddCandidate(number);
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 移除单元格候选数字
    /// </summary>
    public Board RemoveCellCandidate(int row, int col, int number)
    {
        var cell = GetCell(row, col);
        var newCell = cell.RemoveCandidate(number);
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 切换单元格候选数字
    /// </summary>
    public Board ToggleCellCandidate(int row, int col, int number)
    {
        var cell = GetCell(row, col);
        var newCell = cell.ToggleCandidate(number);
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 清除单元格内容（保留固定状态）
    /// </summary>
    public Board ClearCell(int row, int col)
    {
        var cell = GetCell(row, col);
        if (!cell.IsEditable) return this;

        var newCell = cell.Clear();
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 选择单元格
    /// </summary>
    /// <param name="row">行坐标，传入 -1 表示取消选择</param>
    /// <param name="col">列坐标，传入 -1 表示取消选择</param>
    public virtual Board SelectCell(int row, int col)
    {
        // 如果传入 -1, -1，表示取消选择
        if (row < 0 || col < 0)
        {
            return ClearAllSelection();
        }

        // 先清除所有选择状态
        var clearedBoard = ClearAllSelection();

        // 设置新选择状态
        var cell = clearedBoard.GetCell(row, col);
        var newCell = cell.CopyWith(isSelected: true);

        // 设置高亮状态
        var highlightedBoard = clearedBoard.UpdateCell(row, col, newCell);
        return highlightedBoard.UpdateHighlights(row, col);
    }

    /// <summary>
    /// 清除所有选择状态
    /// </summary>
    public Board ClearSelection() => ClearAllSelection();

    /// <summary>
    /// 设置单元格错误状态
    /// </summary>
    public Board SetCellError(int row, int col, bool isError)
    {
        var cell = GetCell(row, col);
        var newCell = cell.CopyWith(isError: isError);
        return UpdateCell(row, col, newCell);
    }

    /// <summary>
    /// 获取指定行的所有单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetRow(int row) => [.. Cells[row]];

    /// <summary>
    /// 执行棋盘命令
    /// </summary>
    public Board ExecuteCommand(IBoardCommand command) => command.Execute(this);

    /// <summary>
    /// 获取指定列的所有单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetColumn(int col) =>
        [.. Enumerable.Range(0, Size).Select(i => Cells[i][col])];

    /// <summary>
    /// 获取指定区域的所有单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetRegion(string regionId)
    {
        var region = Regions.FirstOrDefault(r => r.Id == regionId);
        return region == null ? throw new ArgumentException($"区域不存在: {regionId}") : [.. region.Cells];
    }

    /// <summary>
    /// 获取所有空单元格
    /// </summary>
    public virtual IReadOnlyList<SudokuCell> GetEmptyCells()
    {
        var emptyCells = new List<SudokuCell>();
        foreach (var row in Cells)
        {
            foreach (var cell in row)
            {
                if (cell.IsEmpty)
                {
                    emptyCells.Add(cell);
                }
            }
        }
        return emptyCells;
    }

    /// <summary>
    /// 获取所有已填单元格
    /// </summary>
    public virtual IReadOnlyList<SudokuCell> GetFilledCells()
    {
        var filledCells = new List<SudokuCell>();
        foreach (var row in Cells)
        {
            foreach (var cell in row)
            {
                if (!cell.IsEmpty)
                {
                    filledCells.Add(cell);
                }
            }
        }
        return filledCells;
    }

    /// <summary>
    /// 检查棋盘是否完整（所有单元格已填）
    /// </summary>
    public virtual bool IsComplete() => GetEmptyCells().Count == 0;

    /// <summary>
    /// 计算数字使用次数统计，返回数字使用次数的映射
    /// </summary>
    public Dictionary<int, int> CalculateNumberCounts()
    {
        var counts = new Dictionary<int, int>();
        for (var i = 1; i <= Size; i++)
        {
            counts[i] = 0;
        }

        foreach (var row in Cells)
        {
            foreach (var cell in row)
            {
                if (cell.Value != null)
                {
                    counts[cell.Value.Value] = counts.GetValueOrDefault(cell.Value.Value) + 1;
                }
            }
        }

        return counts;
    }

    /// <summary>
    /// 清空棋盘（保留固定数字）
    /// </summary>
    public Board Reset()
    {
        var newCells = Cells
            .Select(row => row
                .Select(cell => cell.IsFixed ? cell : cell.Clear())
                .ToList())
            .ToList()
            .Select(row => row.AsReadOnly())
            .ToList();

        var newRegions = Regions.Select(region =>
        {
            var newRegionCells = region.Cells
                .Select(cell => newCells[cell.Row][cell.Col])
                .ToList();
            return new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            );
        }).ToList();

        return CreateInstance(newCells, newRegions);
    }

    /// <summary>
    /// 更新单元格
    /// </summary>
    protected Board UpdateCell(int row, int col, SudokuCell newCell)
    {
        var newCells = Cells.SetItem(row, Cells[row].SetItem(col, newCell));

        // 同步更新 regions 中的 cells
        var newRegions = Regions.Select(region =>
        {
            var newRegionCells = region.Cells.Select(cell =>
            {
                if (cell.Row == row && cell.Col == col)
                {
                    return newCell;
                }
                return cell;
            }).ToImmutableList();
            return new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            );
        }).ToImmutableList();

        return CreateInstance(newCells, newRegions);
    }

    /// <summary>
    /// 清除所有选择状态
    /// </summary>
    protected Board ClearAllSelection()
    {
        var newCells = Cells
            .Select(row => row
                .Select(cell => cell.CopyWith(isSelected: false, isHighlighted: false))
                .ToImmutableList())
            .ToImmutableList();

        var newRegions = Regions.Select(region =>
        {
            var newRegionCells = region.Cells
                .Select(cell => newCells[cell.Row][cell.Col])
                .ToImmutableList();
            return new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            );
        }).ToImmutableList();

        return CreateInstance(newCells, newRegions);
    }

    /// <summary>
    /// 更新高亮状态
    /// </summary>
    protected Board UpdateHighlights(int selectedRow, int selectedCol)
    {
        var newCells = Cells
            .Select(row => row
                .Select(cell => cell.CopyWith(
                    isHighlighted: ShouldHighlightCell(cell, selectedRow, selectedCol)))
                .ToImmutableList())
            .ToImmutableList();

        var newRegions = Regions.Select(region =>
        {
            var newRegionCells = region.Cells
                .Select(cell => newCells[cell.Row][cell.Col])
                .ToImmutableList();
            return new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            );
        }).ToImmutableList();

        return CreateInstance(newCells, newRegions);
    }

    /// <summary>
    /// 检查单元格是否应该高亮
    /// </summary>
    protected bool ShouldHighlightCell(SudokuCell cell, int selectedRow, int selectedCol)
    {
        var selectedCell = GetCell(selectedRow, selectedCol);

        // 如果选中的单元格有值，则高亮相同值的单元格
        if (selectedCell.Value != null)
        {
            return cell.Value != null &&
                   cell.Value == selectedCell.Value &&
                   cell.Row != selectedRow &&
                   cell.Col != selectedCol;
        }
        else
        {
            // 如果选中的单元格无值，则高亮相同行、同列或同区域的单元格
            // 同行或同列
            if (cell.Row == selectedRow || cell.Col == selectedCol)
            {
                return true;
            }

            // 同区域（如果区域集合存在）
            if (Regions.Count > 0)
            {
                // 查找包含选中单元格的区域
                var selectedCellRegions = Regions
                    .Where(region => region.ContainsCoordinate(selectedRow, selectedCol))
                    .ToList();

                // 查找包含当前单元格的区域
                var currentCellRegions = Regions
                    .Where(region => region.ContainsCoordinate(cell.Row, cell.Col))
                    .ToList();

                // 检查是否有共同的区域
                foreach (var selectedRegion in selectedCellRegions)
                {
                    foreach (var currentRegion in currentCellRegions)
                    {
                        if (selectedRegion.Id == currentRegion.Id)
                        {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }

    /// <summary>
    /// 获取用于调试的字符串表示（不依赖国际化）
    /// </summary>
    public string ToDebugString()
    {
        var filledCells = GetFilledCells().Count;
        var totalCells = Size * Size;
        var completionPercent = (filledCells / (double)totalCells * 100).ToString("F1");

        return $"Board(size: {Size}, cells: {filledCells}/{totalCells} ({completionPercent}%完成))";
    }

    /// <summary>
    /// 将棋盘转换为JSON格式
    /// </summary>
    public virtual Dictionary<string, object> ToJson()
    {
        return new Dictionary<string, object>
        {
            ["size"] = Size,
            ["cells"] = Cells.Select(row => row.Select(cell => cell.ToJson()).ToList()).ToList(),
            ["regions"] = Regions.Select(region => region.ToJson()).ToList()
        };
    }

    /// <summary>
    /// 创建棋盘的副本，支持选择性更新
    /// </summary>
    public Board CopyWith(IReadOnlyList<IReadOnlyList<SudokuCell>>? cells = null, IReadOnlyList<SudokuRegion>? regions = null)
    {
        var cellsCopy = cells ??
            Cells.Select(row => row.Select(cell => cell.CopyWith()).ToList())
                .ToList()
                .Select(row => row.AsReadOnly())
                .ToList();
        return CreateInstance(cellsCopy, regions ?? Regions);
    }

    /// <summary>
    /// 创建新棋盘实例（子类需要实现）
    /// </summary>
    public abstract Board CreateInstance(
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells,
        IReadOnlyList<SudokuRegion>? regions = null);

    /// <summary>
    /// 创建所有区域（包括通用区域和特殊区域）,子类必须实现此方法，确保区域创建的统一性
    /// </summary>
    public virtual ImmutableList<SudokuRegion> CreateRegions(Dictionary<string, object>? templateData = null) =>
        CreateDefaultRegions(); // 默认实现：创建通用区域（行、列）

    /// <summary>
    /// 创建默认的行和列区域
    /// </summary>
    protected ImmutableList<SudokuRegion> CreateDefaultRegions()
    {
        var regions = new List<SudokuRegion>();

        // 添加行区域
        for (int i = 0; i < Size; i++)
        {
            var rowCells = Enumerable.Range(0, Size).Select(j => Cells[i][j]).ToList();
            regions.Add(new SudokuRegion(
                id: $"row_{i}",
                type: RegionType.Row,
                name: $"Row {i}",
                cells: rowCells
            ));
        }

        // 添加列区域
        for (int j = 0; j < Size; j++)
        {
            var colCells = Enumerable.Range(0, Size).Select(i => Cells[i][j]).ToList();
            regions.Add(new SudokuRegion(
                id: $"col_{j}",
                type: RegionType.Column,
                name: $"Column {j}",
                cells: colCells
            ));
        }

        return [.. regions];
    }

    /// <summary>
    /// 创建宫格区域
    /// </summary>
    protected ImmutableList<SudokuRegion> CreateBlockRegions(
        int? blockSize = null,
        RegionType regionType = RegionType.Block,
        string regionPrefix = "block")
    {
        var actualBlockSize = blockSize ?? (int)Math.Sqrt(Size);
        var regions = new List<SudokuRegion>();

        for (int blockRow = 0; blockRow < actualBlockSize; blockRow++)
        {
            for (int blockCol = 0; blockCol < actualBlockSize; blockCol++)
            {
                var blockCells = new List<SudokuCell>();
                for (int i = 0; i < actualBlockSize; i++)
                {
                    for (int j = 0; j < actualBlockSize; j++)
                    {
                        var row = blockRow * actualBlockSize + i;
                        var col = blockCol * actualBlockSize + j;
                        if (row < Size && col < Size)
                        {
                            blockCells.Add(Cells[row][col]);
                        }
                    }
                }
                if (blockCells.Count > 0)
                {
                    regions.Add(new SudokuRegion(
                        id: $"{regionPrefix}_{blockRow}_{blockCol}",
                        type: regionType,
                        name: $"{char.ToUpper(regionPrefix[0])}{regionPrefix[1..]} {blockRow}_{blockCol}",
                        cells: blockCells
                    ));
                }
            }
        }

        return [.. regions];
    }

    /// <summary>
    /// 获取数独游戏中使用的最大数字,武士数独需要重写此方法返回9
    /// </summary>
    public virtual int GetMaxNumber() => Size;

    /// <summary>
    /// 深拷贝棋盘
    /// </summary>
    public Board DeepCopy()
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(Size);
        foreach (var row in Cells)
        {
            var newRow = new List<SudokuCell>(Size);
            foreach (var cell in row)
            {
                newRow.Add(cell with { });
            }
            newCells.Add(newRow);
        }
        return CreateInstance(newCells, Regions);
    }

    /// <summary>
    /// 深拷贝单元格
    /// </summary>
    public IReadOnlyList<IReadOnlyList<SudokuCell>> DeepCopyCells()
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(Size);
        foreach (var row in Cells)
        {
            var newRow = new List<SudokuCell>(Size);
            foreach (var cell in row)
            {
                newRow.Add(cell with { });
            }
            newCells.Add(newRow);
        }
        return newCells;
    }

    /// <summary>
    /// 获取区域所有单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetRegionCells(string regionId)
    {
        var region = Regions.FirstOrDefault(r => r.Id == regionId);
        return region?.Cells ?? [];
    }

    /// <summary>
    /// 获取区域空单元格
    /// </summary>
    public IReadOnlyList<SudokuCell> GetRegionEmptyCells(string regionId)
    {
        return [.. GetRegionCells(regionId).Where(c => c.IsEmpty)];
    }

    /// <summary>
    /// 清除所有候选数
    /// </summary>
    public Board ClearCellCandidates()
    {
        var newCells = Cells
            .Select(row => row
                .Select(cell => cell.CopyWith(candidates: []))
                .ToImmutableList())
            .ToImmutableList();
        return CreateInstance(newCells, Regions);
    }

    /// <summary>
    /// 检查棋盘是否有效
    /// </summary>
    public bool IsValid()
    {
        // 检查行、列、区域是否有重复数字
        for (int i = 0; i < Size; i++)
        {
            var rowValues = Cells[i].Where(c => c.Value.HasValue).Select(c => c.Value!.Value).ToList();
            if (rowValues.Count != rowValues.Distinct().Count()) return false;

            var colValues = Enumerable.Range(0, Size).Select(r => Cells[r][i].Value).Where(v => v.HasValue).Select(v => v!.Value).ToList();
            if (colValues.Count != colValues.Distinct().Count()) return false;
        }

        foreach (var region in Regions)
        {
            var regionValues = region.Cells.Where(c => c.Value.HasValue).Select(c => c.Value!.Value).ToList();
            if (regionValues.Count != regionValues.Distinct().Count()) return false;
        }

        return true;
    }

    /// <summary>
    /// 检查在指定位置放置指定数字是否有效
    /// </summary>
    /// <param name="row">行索引</param>
    /// <param name="col">列索引</param>
    /// <param name="value">要放置的数字</param>
    /// <returns>如果有效返回true，否则返回false</returns>
    public virtual bool IsValidMove(int row, int col, int value)
    {
        // 检查行是否已有该数字
        for (int c = 0; c < Size; c++)
        {
            if (c != col && Cells[row][c].Value == value)
                return false;
        }

        // 检查列是否已有该数字
        for (int r = 0; r < Size; r++)
        {
            if (r != row && Cells[r][col].Value == value)
                return false;
        }

        // 检查所在区域是否已有该数字
        foreach (var region in Regions)
        {
            if (region.Cells.Any(c => c.Row == row && c.Col == col))
            {
                foreach (var cell in region.Cells)
                {
                    if (cell.Row != row && cell.Col != col && cell.Value == value)
                        return false;
                }
                break;
            }
        }

        return true;
    }

    protected void BuildCellRegionIndex()
    {
        _cellRegions = new List<SudokuRegion>[Size][];
        for (int r = 0; r < Size; r++)
        {
            _cellRegions[r] = new List<SudokuRegion>[Size];
            for (int c = 0; c < Size; c++)
                _cellRegions[r][c] = [];
        }
        foreach (var region in Regions)
            foreach (var cell in region.Cells)
                _cellRegions[cell.Row][cell.Col].Add(region);
    }

    public IReadOnlyList<SudokuRegion> GetCellRegions(int row, int col)
    {
        if (_cellRegions == null) BuildCellRegionIndex();
        return _cellRegions![row][col];
    }
}
