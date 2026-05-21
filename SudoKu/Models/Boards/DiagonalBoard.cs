
using System.Collections.Immutable;

namespace SudoKu.Models.Boards;

/// <summary>
/// 对角线数独棋盘
/// </summary>
public sealed record DiagonalBoard : Board
{
    public DiagonalBoard(
        int size,
        IReadOnlyList<IReadOnlyList<SudokuCell>> cells,
        IReadOnlyList<SudokuRegion>? regions = null)
        : base(size: size, cells: cells, regions: regions)
    {
    }

    public override string GameType => "diagonal";

    /// <summary>
    /// 从JSON创建对角线数独棋盘
    /// </summary>
    public static DiagonalBoard FromJson(Dictionary<string, object> json)
    {
        var size = (int)json["size"];
        var cellsJson = (List<object>)json["cells"];
        var cells = CellsFromJson(cellsJson);

        var regionsJson = json.TryGetValue("regions", out var r) ? r as List<object> : null;
        var regions = RegionsFromJson(regionsJson);

        var board = new DiagonalBoard(size: size, cells: cells, regions: regions);
        // 如果没有区域信息，生成区域
        if (regions.Count == 0)
        {
            var generatedRegions = board.CreateRegions();
            return new DiagonalBoard(size: size, cells: cells, regions: generatedRegions);
        }

        return board;
    }

    public override Board CreateInstance(
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells,
        IReadOnlyList<SudokuRegion>? regions = null)
    {
        // 如果 regions 为 null 或空列表，使用 newCells 重新生成区域
        if (regions == null || regions.Count == 0)
        {
            var tempBoard = new DiagonalBoard(Size, newCells, []);
            regions = tempBoard.CreateRegions();
        }
        return new DiagonalBoard(
            size: Size,
            cells: newCells,
            regions: regions);
    }

    public override ImmutableList<SudokuRegion> CreateRegions(Dictionary<string, object>? templateData = null)
    {
        return CreateDefaultRegions()
            .AddRange(CreateBlockRegions())
            .Add(CreateMainDiagonalRegion())
            .Add(CreateAntiDiagonalRegion());
    }

    /// <summary>
    /// 创建主对角线区域
    /// </summary>
    private SudokuRegion CreateMainDiagonalRegion()
    {
        var diagonalCells = new List<SudokuCell>();
        for (int i = 0; i < Size; i++)
        {
            diagonalCells.Add(Cells[i][i]);
        }
        return new SudokuRegion(
            id: "diagonal_main",
            type: RegionType.Diagonal,
            name: "Main Diagonal",
            cells: diagonalCells
        );
    }

    /// <summary>
    /// 创建反对角线区域
    /// </summary>
    private SudokuRegion CreateAntiDiagonalRegion()
    {
        var diagonalCells = new List<SudokuCell>();
        for (int i = 0; i < Size; i++)
        {
            diagonalCells.Add(Cells[i][Size - 1 - i]);
        }
        return new SudokuRegion(
            id: "diagonal_anti",
            type: RegionType.Diagonal,
            name: "Anti Diagonal",
            cells: diagonalCells
        );
    }

    /// <summary>
    /// 创建空的对角线数独棋盘
    /// </summary>
    public static DiagonalBoard Empty(int size = 9)
    {
        var cells = CreateEmptyCells(size);
        var board = new DiagonalBoard(size: size, cells: cells);
        // 生成区域
        var regions = board.CreateRegions();
        return new DiagonalBoard(size: size, cells: cells, regions: regions);
    }
}
