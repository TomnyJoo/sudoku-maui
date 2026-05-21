using System.Collections.Immutable;

namespace SudoKu.Models.Boards;

/// <summary>
/// 标准数独棋盘
/// </summary>
public sealed record StandardBoard : Board
{
    public StandardBoard(
        int size,
        IReadOnlyList<IReadOnlyList<SudokuCell>> cells,
        IReadOnlyList<SudokuRegion>? regions = null)
        : base(size: size, cells: cells, regions: regions)
    {
    }

    public override string GameType => "standard";

    /// <summary>
    /// 从JSON创建标准数独棋盘
    /// </summary>
    public static StandardBoard FromJson(Dictionary<string, object> json)
    {
        var size = (int)json["size"];
        var cellsJson = (List<object>)json["cells"];
        var cells = CellsFromJson(cellsJson);

        var regionsJson = json.TryGetValue("regions", out var r) ? r as List<object> : null;
        var regions = RegionsFromJson(regionsJson);
        if (regions.Count == 0)
        {
            var tempBoard = new StandardBoard(size: size, cells: cells);
            regions = tempBoard.CreateRegions();
        }

        return new StandardBoard(size: size, cells: cells, regions: regions);
    }

    public override Board CreateInstance(
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells,
        IReadOnlyList<SudokuRegion>? regions = null)
    {
        // 【关键修复】如果 regions 为 null 或空列表，需要使用 newCells 重新生成区域
        // 确保区域单元格引用正确的 cells 对象
        if (regions == null || regions.Count == 0)
        {
            var tempBoard = new StandardBoard(Size, newCells, []);
            regions = tempBoard.CreateRegions();
        }
        return new StandardBoard(size: Size, cells: newCells, regions: regions);
    }

    public override ImmutableList<SudokuRegion> CreateRegions(Dictionary<string, object>? templateData = null)
    {
        return CreateDefaultRegions().AddRange(CreateBlockRegions());
    }

    /// <summary>
    /// 创建空的标准数独棋盘
    /// </summary>
    public static StandardBoard Empty(int size = 9)
    {
        var cells = CreateEmptyCells(size);
        var board = new StandardBoard(size: size, cells: cells);
        var regions = board.CreateRegions();
        return new StandardBoard(size: size, cells: cells, regions: regions);
    }
}
