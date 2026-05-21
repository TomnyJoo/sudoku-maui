namespace SudoKu.Controls;

using SudoKu.Models;
using Font = Microsoft.Maui.Graphics.Font;

/// <summary>
/// 区域边框视图控件，使用 GraphicsView 绘制数独区域的边界线。
/// 适用于锯齿数独、窗口数独等需要特殊区域边界的游戏类型。
/// 支持区域编号显示和区域高亮功能。
/// </summary>
public partial class RegionBorderView : GraphicsView
{
    /// <summary>标识 Regions 绑定属性。</summary>
    public static readonly BindableProperty RegionsProperty =
        BindableProperty.Create(nameof(Regions), typeof(List<SudokuRegion>), typeof(RegionBorderView), null,
            propertyChanged: OnRegionsChanged);

    /// <summary>标识 BoardSize 绑定属性。</summary>
    public static readonly BindableProperty BoardSizeProperty =
        BindableProperty.Create(nameof(BoardSize), typeof(int), typeof(RegionBorderView), 9);

    /// <summary>标识 RegionType 绑定属性，用于筛选需要绘制的区域类型。</summary>
    public static readonly BindableProperty RegionTypeFilterProperty =
        BindableProperty.Create(nameof(RegionTypeFilter), typeof(RegionType?), typeof(RegionBorderView), null);

    /// <summary>标识是否显示区域编号。</summary>
    public static readonly BindableProperty ShowRegionNumbersProperty =
        BindableProperty.Create(nameof(ShowRegionNumbers), typeof(bool), typeof(RegionBorderView), true,
            propertyChanged: OnRegionsChanged);

    /// <summary>标识高亮区域索引。</summary>
    public static readonly BindableProperty HighlightedRegionIndexProperty =
        BindableProperty.Create(nameof(HighlightedRegionIndex), typeof(int?), typeof(RegionBorderView), null,
            propertyChanged: OnRegionsChanged);

    /// <summary>获取或设置区域列表。</summary>
    public List<SudokuRegion>? Regions
    {
        get => (List<SudokuRegion>?)GetValue(RegionsProperty);
        set => SetValue(RegionsProperty, value);
    }

    /// <summary>获取或设置棋盘尺寸。</summary>
    public int BoardSize
    {
        get => (int)GetValue(BoardSizeProperty);
        set => SetValue(BoardSizeProperty, value);
    }

    /// <summary>获取或设置区域类型筛选器。</summary>
    public RegionType? RegionTypeFilter
    {
        get => (RegionType?)GetValue(RegionTypeFilterProperty);
        set => SetValue(RegionTypeFilterProperty, value);
    }

    /// <summary>获取或设置是否显示区域编号。</summary>
    public bool ShowRegionNumbers
    {
        get => (bool)GetValue(ShowRegionNumbersProperty);
        set => SetValue(ShowRegionNumbersProperty, value);
    }

    /// <summary>获取或设置高亮区域索引。</summary>
    public int? HighlightedRegionIndex
    {
        get => (int?)GetValue(HighlightedRegionIndexProperty);
        set => SetValue(HighlightedRegionIndexProperty, value);
    }

    /// <summary>
    /// 初始化区域边框视图的新实例。
    /// </summary>
    public RegionBorderView()
    {
        Drawable = new RegionBorderDrawable(this);
        InputTransparent = true; // 叠加层不拦截触摸事件，让点击穿透到单元格
    }

    /// <summary>
    /// 区域列表变化时重绘。
    /// </summary>
    private static void OnRegionsChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is RegionBorderView view)
        {
            view.Invalidate();
        }
    }

    /// <summary>
    /// 高亮指定索引的区域。
    /// </summary>
    public void HighlightRegion(int? regionIndex)
    {
        HighlightedRegionIndex = regionIndex;
        Invalidate();
    }
}

/// <summary>
/// 区域边框绘制器，负责在 GraphicsView 上绘制区域边界线。 通过检测相邻单元格是否属于同一区域来决定是否绘制粗边界线。
/// </summary>
internal class RegionBorderDrawable(RegionBorderView view) : IDrawable
{
    private readonly RegionBorderView _view = view;

    /// <summary>
    /// 在画布上绘制区域边界线。
    /// </summary>
    public void Draw(ICanvas canvas, RectF dirtyRect)
    {
        if (canvas is null) return;

        var regions = _view.Regions;
        var boardSize = _view.BoardSize;
        var regionTypeFilter = _view.RegionTypeFilter;

        if (regions == null || boardSize <= 0) return;

        // 根据筛选器获取需要绘制的区域
        var filteredRegions = regionTypeFilter.HasValue
            ? regions.Where(r => r.Type == regionTypeFilter.Value).ToList()
            : [.. regions];

        if (filteredRegions.Count == 0) return;

        // 构建单元格到区域ID的映射
        var cellToRegionId = new string[boardSize, boardSize];
        for (int r = 0; r < boardSize; r++)
            for (int c = 0; c < boardSize; c++)
                cellToRegionId[r, c] = string.Empty;

        foreach (var region in filteredRegions)
        {
            foreach (var cell in region.Cells)
            {
                if (cell.Row >= 0 && cell.Row < boardSize && cell.Col >= 0 && cell.Col < boardSize)
                {
                    cellToRegionId[cell.Row, cell.Col] = region.Id;
                }
            }
        }

        float cellWidth = dirtyRect.Width / boardSize;
        float cellHeight = dirtyRect.Height / boardSize;

        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;

        // === 1. 绘制区域边界线 ===
        canvas.StrokeColor = isDark ? Color.FromArgb("#6B7280") : Color.FromArgb("#374151");
        canvas.StrokeSize = 1.5f;

        // 构建区域单元格缓存
        var regionCellsCache = GetRegionCellsCache(filteredRegions, cellToRegionId, boardSize);

        foreach (var region in filteredRegions)
        {
            var regionCells = regionCellsCache.GetValueOrDefault(region.Id, new List<(int, int)>());
            if (regionCells.Count == 0) continue;

            foreach (var (row, col) in regionCells)
            {
                float x = col * cellWidth;
                float y = row * cellHeight;

                // 检查四个方向的邻居
                var directions = new (int dr, int dc)[]
                {
                    (-1, 0), (1, 0), (0, -1), (0, 1)
                };

                foreach (var (dr, dc) in directions)
                {
                    int newRow = row + dr;
                    int newCol = col + dc;

                    if (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize)
                    {
                        var neighborRegionId = cellToRegionId[newRow, newCol];
                        if (neighborRegionId != region.Id)
                        {
                            DrawBoundaryBetweenCells(canvas, x, y, cellWidth, cellHeight, dr, dc);
                        }
                    }
                    else
                    {
                        // 边界单元格，绘制外边框
                        DrawBoundaryBetweenCells(canvas, x, y, cellWidth, cellHeight, dr, dc);
                    }
                }
            }
        }

        // === 2. 绘制区域高亮 ===
        var highlightedIndex = _view.HighlightedRegionIndex;
        if (highlightedIndex.HasValue && highlightedIndex.Value >= 0 && highlightedIndex.Value < filteredRegions.Count)
        {
            var highlightedRegion = filteredRegions[highlightedIndex.Value];
            canvas.FillColor = isDark
                ? Color.FromArgb("#FFFFFF").WithAlpha(0.2f)
                : Color.FromArgb("#4A6FA5").WithAlpha(0.3f);

            foreach (var cell in highlightedRegion.Cells)
            {
                if (cell.Row >= 0 && cell.Row < boardSize && cell.Col >= 0 && cell.Col < boardSize)
                {
                    float x = cell.Col * cellWidth;
                    float y = cell.Row * cellHeight;
                    canvas.FillRectangle(x, y, cellWidth, cellHeight);
                }
            }
        }

        // === 3. 绘制区域编号 ===
        if (_view.ShowRegionNumbers)
        {
            var regionMinCellCache = GetRegionMinCellCache(filteredRegions, cellToRegionId, boardSize);

            for (int i = 0; i < filteredRegions.Count; i++)
            {
                var region = filteredRegions[i];
                if (!regionMinCellCache.TryGetValue(region.Id, out var minCell))
                    continue;

                float x = minCell.col * cellWidth;
                float y = minCell.row * cellHeight;
                float minCellSize = Math.Min(cellWidth, cellHeight);

                float circleRadius = minCellSize * 0.18f;

                float centerX = x + minCellSize * 0.2f;
                float centerY = y + minCellSize * 0.2f;

                // 绘制背景圆圈
                canvas.FillColor = isDark
                    ? Color.FromArgb("#666666").WithAlpha(0.5f)
                    : Color.FromArgb("#FFFFFF").WithAlpha(0.5f);
                canvas.FillCircle(centerX, centerY, circleRadius);

                // 绘制圆圈边框
                canvas.StrokeColor = isDark ? Color.FromArgb("#666666") : Color.FromArgb("#CCCCCC");
                canvas.StrokeSize = 0.5f;
                canvas.DrawCircle(centerX, centerY, circleRadius);

                // 绘制编号文字
                // MAUI DrawString的Y坐标是从baseline开始，需要向下偏移
                string numberText = (i + 1).ToString();
                float fontSize = minCellSize * 0.2f;
                canvas.Font = new Font("OpenSansBold", (int)fontSize);
                var textSize = canvas.GetStringSize(numberText, new Font("OpenSansBold", (int)fontSize), fontSize);
                canvas.FillColor = isDark ? Color.FromArgb("#FFFFFF") : Color.FromArgb("#333333");

                // 调整Y坐标：水平居中，垂直baseline偏移
                float textX = centerX - textSize.Width / 2;
                float baselineOffset = textSize.Height * 0.6f; // 与杀手数独一致
                float textY = centerY - textSize.Height / 2 + baselineOffset;
                canvas.DrawString(numberText, textX, textY, HorizontalAlignment.Left);
            }
        }
    }

    /// <summary>
    /// 绘制单元格边界线。
    /// </summary>
    private static void DrawBoundaryBetweenCells(ICanvas canvas, float x, float y, float cellWidth, float cellHeight, int dr, int dc)
    {
        // direction.$1 == -1: 上边
        if (dr == -1)
        {
            canvas.DrawLine(x, y, x + cellWidth, y);
        }
        // direction.$1 == 1: 下边
        else if (dr == 1)
        {
            canvas.DrawLine(x, y + cellHeight, x + cellWidth, y + cellHeight);
        }
        // direction.$2 == -1: 左边
        else if (dc == -1)
        {
            canvas.DrawLine(x, y, x, y + cellHeight);
        }
        // direction.$2 == 1: 右边
        else if (dc == 1)
        {
            canvas.DrawLine(x + cellWidth, y, x + cellWidth, y + cellHeight);
        }
    }

    /// <summary>
    /// 构建区域单元格缓存。
    /// </summary>
    private static Dictionary<string, List<(int row, int col)>> GetRegionCellsCache(
        List<SudokuRegion> _,
        string[,] cellToRegionId,
        int boardSize)
    {
        var cache = new Dictionary<string, List<(int, int)>>();

        for (int r = 0; r < boardSize; r++)
        {
            for (int c = 0; c < boardSize; c++)
            {
                var regionId = cellToRegionId[r, c];
                if (string.IsNullOrEmpty(regionId)) continue;

                if (!cache.ContainsKey(regionId))
                    cache[regionId] = [];

                cache[regionId].Add((r, c));
            }
        }

        return cache;
    }

    /// <summary>
    /// 获取每个区域的左上角单元格。
    /// </summary>
    private static Dictionary<string, (int row, int col)> GetRegionMinCellCache(
        List<SudokuRegion> _,
        string[,] cellToRegionId,
        int boardSize)
    {
        var regionCellsCache = GetRegionCellsCache(_, cellToRegionId, boardSize);
        var cache = new Dictionary<string, (int, int)>();

        foreach (var kvp in regionCellsCache)
        {
            var regionCells = kvp.Value;
            if (regionCells.Count == 0) continue;

            int minRow = boardSize, minCol = boardSize;
            foreach (var (row, col) in regionCells)
            {
                if (row < minRow || (row == minRow && col < minCol))
                {
                    minRow = row;
                    minCol = col;
                }
            }
            cache[kvp.Key] = (minRow, minCol);
        }

        return cache;
    }
}
