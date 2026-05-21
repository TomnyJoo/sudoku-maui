using System.Collections.Immutable;

namespace SudoKu.Models.Boards;

/// <summary>
/// 窗口区域定义类
/// </summary>
public sealed record WindowRegion
{
    public WindowRegion(
        string id,
        string name,
        int startRow,
        int startCol,
        int endRow,
        int endCol)
    {
        Id = id;
        Name = name;
        StartRow = startRow;
        StartCol = startCol;
        EndRow = endRow;
        EndCol = endCol;
    }

    public string Id { get; }
    public string Name { get; }
    public int StartRow { get; }
    public int StartCol { get; }
    public int EndRow { get; }
    public int EndCol { get; }

    public int Width => EndCol - StartCol + 1;
    public int Height => EndRow - StartRow + 1;
}

/// <summary>
/// 窗口数独常量
/// </summary>
public static class WindowConstants
{
    public static readonly IReadOnlyList<WindowRegion> WindowRegions =
    [
        new(
            id: "window_top_left",
            name: "Window Top Left",
            startRow: 1,
            startCol: 1,
            endRow: 3,
            endCol: 3
        ),
        new(
            id: "window_top_right",
            name: "Window Top Right",
            startRow: 1,
            startCol: 5,
            endRow: 3,
            endCol: 7
        ),
        new(
            id: "window_bottom_left",
            name: "Window Bottom Left",
            startRow: 5,
            startCol: 1,
            endRow: 7,
            endCol: 3
        ),
        new WindowRegion(
            id: "window_bottom_right",
            name: "Window Bottom Right",
            startRow: 5,
            startCol: 5,
            endRow: 7,
            endCol: 7
        )
    ];

    /// <summary>
    /// 检查单元格是否在窗口区域内
    /// </summary>
    public static bool IsCellInWindowRegion(int row, int col)
    {
        foreach (var region in WindowRegions)
        {
            if (row >= region.StartRow && row <= region.EndRow && 
                col >= region.StartCol && col <= region.EndCol)
            {
                return true;
            }
        }
        return false;
    }
}

/// <summary>
/// 窗口数独棋盘，在标准数独基础上增加了4个窗口区域（Window）
/// </summary>
public sealed record WindowBoard : Board
{
    public WindowBoard(
        int size,
        IReadOnlyList<IReadOnlyList<SudokuCell>> cells,
        IReadOnlyList<SudokuRegion>? regions = null)
        : base(size: size, cells: cells, regions: regions)
    {
    }

    public override string GameType => "window";

    /// <summary>
    /// 从JSON创建窗口数独棋盘
    /// </summary>
    public static WindowBoard FromJson(Dictionary<string, object> json)
    {
        var size = (int)json["size"];
        var cellsJson = (List<object>)json["cells"];
        var cells = CellsFromJson(cellsJson);

        var regionsJson = json.TryGetValue("regions", out var r) ? r as List<object> : null;
        var regions = RegionsFromJson(regionsJson);
        if (regions.Count == 0)
        {
            var tempBoard = new WindowBoard(size: size, cells: cells);
            regions = tempBoard.CreateRegions();
        }

        return new WindowBoard(size: size, cells: cells, regions: regions);
    }

    public override Board CreateInstance(
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells,
        IReadOnlyList<SudokuRegion>? regions = null)
    {
        // 【关键修复】如果 regions 为 null 或空列表，需要重新生成区域（包含行、列、宫格和窗口）
        // 使用 newCells 创建临时 Board 来生成区域，确保区域单元格引用正确
        if (regions == null || regions.Count == 0)
        {
            var tempBoard = new WindowBoard(Size, newCells, []);
            regions = tempBoard.CreateRegions();
        }
        
        // 【关键修复】确保 regions 中的单元格引用与 newCells 一致
        // 防止区域中的单元格引用过期或指向错误的对象
        var updatedRegions = UpdateRegionCellReferences(regions, newCells);
        
        return new WindowBoard(
            size: Size,
            cells: newCells,
            regions: updatedRegions);
    }

    /// <summary>
    /// 更新区域中的单元格引用，使其指向 newCells 中的对应对象
    /// </summary>
    private static List<SudokuRegion> UpdateRegionCellReferences(
        IReadOnlyList<SudokuRegion> regions,
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells)
    {
        var updatedRegions = new List<SudokuRegion>();
        foreach (var region in regions)
        {
            var newRegionCells = region.Cells
                .Select(cell => newCells[cell.Row][cell.Col])
                .ToList();
            updatedRegions.Add(new SudokuRegion(
                id: region.Id,
                type: region.Type,
                name: region.Name,
                cells: newRegionCells
            ));
        }
        return updatedRegions;
    }

    public override ImmutableList<SudokuRegion> CreateRegions(Dictionary<string, object>? templateData = null)
    {
        return CreateDefaultRegions()
            .AddRange(CreateBlockRegions())
            .AddRange([.. CreateWindowRegions()]);
    }

    /// <summary>
    /// 创建窗口区域
    /// </summary>
    private List<SudokuRegion> CreateWindowRegions()
    {
        var windows = new List<SudokuRegion>();

        // 窗口区域直接使用定义的索引，不需要转换
        foreach (var windowRegion in WindowConstants.WindowRegions)
        {
            var windowCells = new List<SudokuCell>();
            for (int row = windowRegion.StartRow; row <= windowRegion.EndRow; row++)
            {
                for (int col = windowRegion.StartCol; col <= windowRegion.EndCol; col++)
                {
                    windowCells.Add(Cells[row][col]);
                }
            }
            windows.Add(new SudokuRegion(
                id: windowRegion.Id,
                type: RegionType.Window,
                name: windowRegion.Name,
                cells: windowCells
            ));
        }

        return windows;
    }

    /// <summary>
    /// 创建空的窗口数独棋盘
    /// </summary>
    public static WindowBoard Empty(int size = 9)
    {
        var cells = CreateEmptyCells(size);
        var board = new WindowBoard(size: size, cells: cells);
        var regions = board.CreateRegions();
        return new WindowBoard(size: size, cells: cells, regions: regions);
    }

    public override Dictionary<string, object> ToJson()
    {
        return new Dictionary<string, object>
        {
            ["size"] = Size,
            ["cells"] = Cells.Select(row => row.Select(cell => cell.ToJson()).ToList()).ToList(),
            ["regions"] = Regions.Select(region => region.ToJson()).ToList()
        };
    }

    /// <summary>
    /// 检查指定位置是否在窗口区域内
    /// </summary>
    public static bool IsInWindowRegion(int row, int col)
    {
        foreach (var windowRegion in WindowConstants.WindowRegions)
        {
            if (row >= windowRegion.StartRow && row <= windowRegion.EndRow &&
                col >= windowRegion.StartCol && col <= windowRegion.EndCol)
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 获取指定位置所属的窗口区域ID
    /// </summary>
    public static string? GetWindowRegionId(int row, int col)
    {
        foreach (var windowRegion in WindowConstants.WindowRegions)
        {
            if (row >= windowRegion.StartRow && row <= windowRegion.EndRow &&
                col >= windowRegion.StartCol && col <= windowRegion.EndCol)
            {
                return windowRegion.Id;
            }
        }
        return null;
    }
}
