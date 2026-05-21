using System.Collections.Immutable;
using SudoKu.Helpers;

namespace SudoKu.Models.Boards;

/// <summary>
/// 武士数独常量
/// </summary>
public static class SamuraiConstants
{
    public const int BoardSize = 21;
    public const int SubGridSize = 9;
    public const int SubGridCount = 5;

    // 子数独的起始位置
    // 参照 Flutter 的 SamuraiConstants.subGridOffsets 实现
    // 武士数独棋盘为 21x21 结构：
    // - 行范围：0-20（21行）
    // - 列范围：0-20（21列）
    public static readonly IReadOnlyList<(int StartRow, int StartCol)> SubGridOffsets = new List<(int, int)>
    {
        (0, 0),   // 左上角: 0-8行, 0-8列
        (0, 12),  // 右上角: 0-8行, 12-20列
        (12, 0),  // 左下角: 12-20行, 0-8列
        (12, 12), // 右下角: 12-20行, 12-20列
        (6, 6),   // 中心:   6-14行, 6-14列
    };

    // 子数独名称（使用 key 标识符，实际显示通过国际化处理）
    public static readonly IReadOnlyList<string> SubGridNames =
    [
        "topLeft",
        "topRight",
        "bottomLeft",
        "bottomRight",
        "center",
    ];

    // 重叠区域的位置（21x21棋盘）
    // 中心子网格与四个角子网格各重叠3x3区域
    public static readonly IReadOnlyList<(int StartRow, int StartCol, int EndRow, int EndCol)> OverlapRegions = new List<(int, int, int, int)>
    {
        (6, 6, 8, 8),     // 左上与中心重叠: 行6-8, 列6-8
        (6, 12, 8, 14),   // 右上与中心重叠: 行6-8, 列12-14
        (12, 6, 14, 8),   // 左下与中心重叠: 行12-14, 列6-8
        (12, 12, 14, 14), // 右下与中心重叠: 行12-14, 列12-14
    };

    // 难度级别对应的提示数
    public static readonly IReadOnlyDictionary<string, int> DifficultyClues = new Dictionary<string, int>
    {
        ["beginner"] = 45,
        ["easy"] = 40,
        ["medium"] = 35,
        ["hard"] = 30,
        ["expert"] = 25,
        ["master"] = 17,
    };
}

/// <summary>
/// 武士数独棋盘
/// </summary>
public sealed record SamuraiBoard : Board
{
    // 缓存空单元格和已填单元格列表，避免每次遍历 441 个单元格
    private IReadOnlyList<SudokuCell>? _emptyCellsCache;
    private IReadOnlyList<SudokuCell>? _filledCellsCache;
    private bool _cacheDirty = true;

    public SamuraiBoard(
        IReadOnlyList<IReadOnlyList<SudokuCell>> cells,
        IReadOnlyList<SudokuRegion>? regions = null)
        : base(size: SamuraiConstants.BoardSize, cells: cells, regions: regions ?? CreateRegionsStatic(cells))
    {
    }

    public override string GameType => "samurai";

    /// <summary>
    /// 从JSON创建武士数独棋盘
    /// </summary>
    public static SamuraiBoard FromJson(Dictionary<string, object> json)
    {
        var cellsJson = (List<object>)json["cells"];
        var cells = cellsJson.Select(row =>
        {
            var rowList = (List<object>)row;
            return rowList
                .Select(cellJson => SudokuCell.FromJson((Dictionary<string, object>)cellJson))
                .ToList();
        }).ToList();

        var regionsJson = json.TryGetValue("regions", out var r) ? r as List<object> : null;
        if (regionsJson != null && regionsJson.Count > 0)
        {
            var regions = regionsJson
                .Select(regionJson => SudokuRegion.FromJson((Dictionary<string, object>)regionJson))
                .ToList();
            return new SamuraiBoard(cells: cells, regions: regions);
        }
        return new SamuraiBoard(cells: cells); // 自动生成 regions
    }

    public override Board CreateInstance(
        IReadOnlyList<IReadOnlyList<SudokuCell>> newCells,
        IReadOnlyList<SudokuRegion>? regions = null)
    {
        // 如果 regions 为空，需要重新生成区域
        var actualRegions = regions ?? CreateRegions();
        return new SamuraiBoard(cells: newCells, regions: actualRegions);
    }

    public override int GetMaxNumber() => 9;

    public override ImmutableList<SudokuRegion> CreateRegions(Dictionary<string, object>? templateData = null)
        => CreateRegionsStatic(Cells);

    /// <summary>
    /// 静态方法创建区域
    /// </summary>
    private static ImmutableList<SudokuRegion> CreateRegionsStatic(IReadOnlyList<IReadOnlyList<SudokuCell>> cells)
    {
        var regions = new List<SudokuRegion>();
        for (int i = 0; i < 5; i++)
        {
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[i];
            regions.AddRange(CreateSubGridRegions(cells, startRow, startCol, i));
        }
        System.Diagnostics.Debug.Assert(regions.Count == 135, $"Expected 135 regions, got {regions.Count}");
        return regions.ToImmutableList();
    }

    private static List<SudokuRegion> CreateSubGridRegions(
        IReadOnlyList<IReadOnlyList<SudokuCell>> cells, int startRow, int startCol, int subGridIndex)
    {
        var regions = new List<SudokuRegion>();

        // 行区域（使用全局坐标）
        for (int row = 0; row < SamuraiConstants.SubGridSize; row++)
        {
            var rowCells = new List<SudokuCell>();
            for (int col = 0; col < SamuraiConstants.SubGridSize; col++)
            {
                rowCells.Add(cells[startRow + row][startCol + col]);
            }
            regions.Add(new SudokuRegion(
                id: $"subgrid_{subGridIndex}_row_{row}",
                type: RegionType.Row,
                name: $"SubGrid {subGridIndex} Row {row}",
                cells: rowCells
            ));
        }

        // 列区域
        for (int col = 0; col < SamuraiConstants.SubGridSize; col++)
        {
            var colCells = new List<SudokuCell>();
            for (int row = 0; row < SamuraiConstants.SubGridSize; row++)
            {
                colCells.Add(cells[startRow + row][startCol + col]);
            }
            regions.Add(new SudokuRegion(
                id: $"subgrid_{subGridIndex}_col_{col}",
                type: RegionType.Column,
                name: $"SubGrid {subGridIndex} Column {col}",
                cells: colCells
            ));
        }

        // 宫区域
        for (int blockRow = 0; blockRow < StandardConstants.BoxSize; blockRow++)
        {
            for (int blockCol = 0; blockCol < StandardConstants.BoxSize; blockCol++)
            {
                var blockCells = new List<SudokuCell>();
                for (int i = 0; i < StandardConstants.BoxSize; i++)
                {
                    for (int j = 0; j < StandardConstants.BoxSize; j++)
                    {
                        blockCells.Add(cells[startRow + blockRow * StandardConstants.BoxSize + i][startCol + blockCol * StandardConstants.BoxSize + j]);
                    }
                }
                regions.Add(new SudokuRegion(
                    id: $"subgrid_{subGridIndex}_block_{blockRow}_{blockCol}",
                    type: RegionType.Block,
                    name: $"SubGrid {subGridIndex} Block {blockRow}_{blockCol}",
                    cells: blockCells
                ));
            }
        }

        return regions;
    }

    /// <summary>
    /// 标记缓存为脏，在单元格变更后调用
    /// </summary>
    private void InvalidateCache()
    {
        _cacheDirty = true;
        _emptyCellsCache = null;
        _filledCellsCache = null;
    }

    /// <summary>
    /// 获取指定单元格所属的子网格列表
    /// </summary>
    public static List<int> GetSubGridsForCell(int row, int col)
    {
        var subGrids = new List<int>();
        for (int i = 0; i < 5; i++)
        {
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[i];
            if (row >= startRow && row < startRow + SamuraiConstants.SubGridSize &&
                col >= startCol && col < startCol + SamuraiConstants.SubGridSize)
            {
                subGrids.Add(i);
            }
        }
        return subGrids;
    }

    /// <summary>
    /// 检查单元格是否在重叠区域
    /// </summary>
    public static bool IsOverlapRegion(int row, int col) => SamuraiBoard.GetSubGridsForCell(row, col).Count > 1;

    /// <summary>
    /// 检查单元格是否在可玩区域内（任意子网格中）
    /// </summary>
    public static bool IsPlayableCell(int row, int col) => SamuraiBoard.GetSubGridsForCell(row, col).Count > 0;

    /// <summary>
    /// 获取所有可玩区域内的空单元格
    /// </summary>
    public override IReadOnlyList<SudokuCell> GetEmptyCells()
    {
        if (!_cacheDirty && _emptyCellsCache != null)
        {
            return _emptyCellsCache;
        }

        var emptyCells = new List<SudokuCell>();
        for (int row = 0; row < SamuraiConstants.BoardSize; row++)
        {
            for (int col = 0; col < SamuraiConstants.BoardSize; col++)
            {
                if (IsPlayableCell(row, col))
                {
                    var cell = Cells[row][col];
                    if (cell.IsEmpty)
                    {
                        emptyCells.Add(cell);
                    }
                }
            }
        }
        _emptyCellsCache = emptyCells;
        _cacheDirty = false;
        return emptyCells;
    }

    /// <summary>
    /// 获取所有可玩区域内已填单元格
    /// </summary>
    public override IReadOnlyList<SudokuCell> GetFilledCells()
    {
        if (!_cacheDirty && _filledCellsCache != null)
        {
            return _filledCellsCache;
        }

        var filledCells = new List<SudokuCell>();
        for (int row = 0; row < SamuraiConstants.BoardSize; row++)
        {
            for (int col = 0; col < SamuraiConstants.BoardSize; col++)
            {
                if (IsPlayableCell(row, col))
                {
                    var cell = Cells[row][col];
                    if (!cell.IsEmpty)
                    {
                        filledCells.Add(cell);
                    }
                }
            }
        }
        _filledCellsCache = filledCells;
        _cacheDirty = false;
        return filledCells;
    }

    /// <summary>
    /// 检查棋盘是否完整（所有可玩单元格已填）
    /// </summary>
    public override bool IsComplete() => GetEmptyCells().Count == 0;

    /// <summary>
    /// 获取可玩单元格总数
    /// </summary>
    public static int PlayableCellCount
    {
        get
        {
            int count = 0;
            for (int row = 0; row < SamuraiConstants.BoardSize; row++)
            {
                for (int col = 0; col < SamuraiConstants.BoardSize; col++)
                {
                    if (IsPlayableCell(row, col))
                    {
                        count++;
                    }
                }
            }
            return count;
        }
    }

    /// <summary>
    /// 合并子棋盘到当前棋盘
    /// </summary>
    public SamuraiBoard MergeSubBoard(Board subBoard, int startRow, int startCol)
    {
        var newCells = Cells.Select(r => r.ToList()).ToList();
        for (int i = 0; i < SamuraiConstants.SubGridSize; i++)
        {
            for (int j = 0; j < SamuraiConstants.SubGridSize; j++)
            {
                var targetRow = startRow + i;
                var targetCol = startCol + j;
                if (targetRow >= 0 && targetRow < SamuraiConstants.BoardSize &&
                    targetCol >= 0 && targetCol < SamuraiConstants.BoardSize)
                {
                    var subCell = subBoard.GetCell(i, j);
                    if (subCell.Value != null)
                    {
                        newCells[targetRow][targetCol] = newCells[targetRow][targetCol].CopyWith(
                            value: subCell.Value,
                            isFixed: true
                        );
                    }
                }
            }
        }
        return new SamuraiBoard(cells: newCells, regions: Regions);
    }

    /// <summary>
    /// 获取指定索引的子网格
    /// </summary>
    public Board GetSubBoard(int index)
    {
        if (index < 0 || index >= 5)
        {
            throw new ArgumentException("Subgrid index must be between 0 and 4");
        }

        var (startRow, startCol) = SamuraiConstants.SubGridOffsets[index];
        var subGridCells = Enumerable.Range(0, SamuraiConstants.SubGridSize)
            .Select(i => Enumerable.Range(0, SamuraiConstants.SubGridSize)
                .Select(j =>
                {
                    var original = Cells[startRow + i][startCol + j];
                    // 创建新 SudokuCell，坐标映射到 0..8
                    return new SudokuCell(
                        row: i,
                        col: j,
                        value: original.Value,
                        isFixed: original.IsFixed,
                        candidates: original.Candidates,
                        isSelected: original.IsSelected,
                        isError: original.IsError
                    );
                })
                .ToList())
            .ToList();

        // 创建一个标准数独板作为子网格
        return new StandardBoard(size: SamuraiConstants.SubGridSize, cells: subGridCells);
    }

    /// <summary>
    /// 创建空的武士数独棋盘
    /// </summary>
    public static SamuraiBoard Empty()
    {
        var cells = Enumerable.Range(0, SamuraiConstants.BoardSize)
            .Select(i => Enumerable.Range(0, SamuraiConstants.BoardSize)
                .Select(j => new SudokuCell(row: i, col: j))
                .ToList())
            .ToList();
        return new SamuraiBoard(cells: cells);
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
}
