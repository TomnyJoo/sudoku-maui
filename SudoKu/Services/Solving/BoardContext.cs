using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving;

/// <summary>
/// 棋盘上下文 - 用于策略分析
/// 参照 Flutter candidate_calculator.dart BoardContext
/// </summary>
public class BoardContext
{
    /// <summary>
    /// 构造棋盘上下文
    /// </summary>
    public BoardContext(Board board) : this(board, board.Regions)
    {
    }

    /// <summary>
    /// 构造棋盘上下文（指定区域）
    /// </summary>
    public BoardContext(Board board, IReadOnlyList<SudokuRegion> regions)
    {
        Board = board;
        Size = board.Size;
        TypeCounts = new Dictionary<RegionType, int>();

        // 初始化类型计数
        foreach (var type in Enum.GetValues<RegionType>())
        {
            TypeCounts[type] = 0;
        }

        // 统计各类型区域数量
        foreach (var region in regions)
        {
            TypeCounts[region.Type] = TypeCounts.GetValueOrDefault(region.Type) + 1;
        }

        // 计算区域单元格索引
        var n = Size;
        RegionCellIndices = new List<List<int>>();
        RegionTypes = new List<RegionType>();

        foreach (var region in regions)
        {
            var indices = new List<int>();
            foreach (var cell in region.Cells)
            {
                indices.Add(cell.Row * n + cell.Col);
            }
            RegionCellIndices.Add(indices);
            RegionTypes.Add(region.Type);
        }

        // 初始化候选集
        CandidateSets = new HashSet<int>[n, n];
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                CandidateSets[r, c] = new HashSet<int>();
            }
        }

        _cellToRegions = null;
    }

    /// <summary>
    /// 从棋盘创建上下文
    /// </summary>
    public static BoardContext FromBoard(Board board) =>
        new(board, board.Regions);

    /// <summary>棋盘引用</summary>
    public Board Board { get; set; }

    /// <summary>棋盘尺寸</summary>
    public int Size { get; }

    /// <summary>候选数集合 [row, col]</summary>
    public HashSet<int>[,] CandidateSets { get; }

    /// <summary>区域单元格索引列表</summary>
    public List<List<int>> RegionCellIndices { get; }

    /// <summary>区域类型列表</summary>
    public List<RegionType> RegionTypes { get; }

    /// <summary>单元格到区域的映射（延迟计算）</summary>
    private List<List<List<int>>>? _cellToRegions;

    /// <summary>各类型区域数量统计</summary>
    public Dictionary<RegionType, int> TypeCounts { get; }

    // 杀手数独专用数据
    private List<KillerCage>? _killerCages;
    private Dictionary<(int, int), KillerCage>? _cellToKillerCage;

    /// <summary>
    /// 获取单元格到区域的映射（延迟计算）
    /// </summary>
    public List<List<List<int>>> CellToRegions
    {
        get
        {
            _cellToRegions ??= ComputeCellToRegions();
            return _cellToRegions;
        }
    }

    /// <summary>
    /// 计算单元格到区域的映射
    /// </summary>
    private List<List<List<int>>> ComputeCellToRegions()
    {
        var n = Size;
        var result = new List<List<List<int>>>();

        for (int r = 0; r < n; r++)
        {
            var rowList = new List<List<int>>();
            for (int c = 0; c < n; c++)
            {
                rowList.Add(new List<int>());
            }
            result.Add(rowList);
        }

        for (int regIdx = 0; regIdx < RegionCellIndices.Count; regIdx++)
        {
            foreach (var idx in RegionCellIndices[regIdx])
            {
                var r = idx / n;
                var c = idx % n;
                result[r][c].Add(regIdx);
            }
        }

        return result;
    }

    /// <summary>是否有全局行约束</summary>
    public bool HasGlobalRows => TypeCounts[RegionType.Row] == Size;

    /// <summary>是否有全局列约束</summary>
    public bool HasGlobalColumns => TypeCounts[RegionType.Column] == Size;

    /// <summary>是否有全局宫约束</summary>
    public bool HasGlobalBlocks => TypeCounts[RegionType.Block] == Size;

    /// <summary>是否有全局行列约束</summary>
    public bool HasGlobalRowsAndColumns => HasGlobalRows && HasGlobalColumns;

    /// <summary>
    /// 获取区域单元格索引
    /// </summary>
    public List<int> GetRegionCells(int regionIdx) => RegionCellIndices[regionIdx];

    /// <summary>
    /// 获取区域类型
    /// </summary>
    public RegionType GetRegionType(int regionIdx) => RegionTypes[regionIdx];

    /// <summary>
    /// 通过区域索引获取区域对象
    /// </summary>
    public SudokuRegion GetRegion(int regionIdx) => Board.Regions[regionIdx];

    /// <summary>
    /// 获取包含指定单元格的所有区域
    /// </summary>
    public List<SudokuRegion> GetRegionsForCell(int row, int col)
    {
        var regionIndices = CellToRegions[row][col];
        return regionIndices.Select(idx => Board.Regions[idx]).ToList();
    }

    /// <summary>
    /// 直接获取指定位置的单元格
    /// </summary>
    public SudokuCell Cell(int row, int col) => Board.GetCell(row, col);

    /// <summary>
    /// 直接获取单元格值
    /// </summary>
    public int? CellValue(int row, int col) => Board.GetCell(row, col).Value;

    /// <summary>
    /// 获取候选数
    /// </summary>
    public HashSet<int> GetCandidates(int row, int col) => CandidateSets[row, col];

    /// <summary>
    /// 设置候选数
    /// </summary>
    public void SetCandidates(int row, int col, HashSet<int> candidates)
    {
        CandidateSets[row, col] = candidates;
    }

    /// <summary>
    /// 移除候选数
    /// </summary>
    public void RemoveCandidate(int row, int col, int number)
    {
        CandidateSets[row, col].Remove(number);
    }

    /// <summary>
    /// 批量移除候选数
    /// </summary>
    public void RemoveCandidates(int row, int col, IEnumerable<int> numbers)
    {
        foreach (var num in numbers)
        {
            CandidateSets[row, col].Remove(num);
        }
    }

    /// <summary>
    /// 添加候选数
    /// </summary>
    public void AddCandidate(int row, int col, int number)
    {
        CandidateSets[row, col].Add(number);
    }

    /// <summary>
    /// 批量添加候选数
    /// </summary>
    public void AddCandidates(int row, int col, IEnumerable<int> numbers)
    {
        foreach (var num in numbers)
        {
            CandidateSets[row, col].Add(num);
        }
    }

    /// <summary>
    /// 检查是否有指定候选数
    /// </summary>
    public bool HasCandidate(int row, int col, int number) =>
        CandidateSets[row, col].Contains(number);

    /// <summary>
    /// 获取候选数数量
    /// </summary>
    public int CandidateCount(int row, int col) => CandidateSets[row, col].Count;

    /// <summary>
    /// 检查是否为单候选数
    /// </summary>
    public bool IsSingleCandidate(int row, int col) =>
        CandidateSets[row, col].Count == 1;

    /// <summary>
    /// 获取单候选数
    /// </summary>
    public int? GetSingleCandidate(int row, int col)
    {
        var candidates = CandidateSets[row, col];
        return candidates.Count == 1 ? candidates.First() : null;
    }

    /// <summary>
    /// 设置杀手数独笼子信息
    /// </summary>
    public void SetKillerCages(List<KillerCage> cages)
    {
        _killerCages = cages;
        _cellToKillerCage = new Dictionary<(int, int), KillerCage>();

        foreach (var cage in cages)
        {
            foreach (var (r, c) in cage.CellCoordinates)
            {
                _cellToKillerCage[(r, c)] = cage;
            }
        }
    }

    /// <summary>杀手数独笼子列表</summary>
    public List<KillerCage>? KillerCages => _killerCages;

    /// <summary>
    /// 获取单元格所属的杀手笼子
    /// </summary>
    public KillerCage? GetCageForCell(int row, int col) =>
        _cellToKillerCage?.GetValueOrDefault((row, col));
}
