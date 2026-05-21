namespace SudoKu.Controls;

using SudoKu.Models;

/// <summary>
/// 杀手数独笼子背景覆盖层 - 只绘制笼子背景色，放在网格线之下
/// </summary>
public partial class KillerCageBackgroundOverlay : GraphicsView
{
    public static readonly BindableProperty RegionsProperty =
        BindableProperty.Create(nameof(Regions), typeof(List<SudokuRegion>), typeof(KillerCageBackgroundOverlay), null,
            propertyChanged: (b, o, n) => ((KillerCageBackgroundOverlay)b).Invalidate());

    public static readonly BindableProperty BoardSizeProperty =
        BindableProperty.Create(nameof(BoardSize), typeof(int), typeof(KillerCageBackgroundOverlay), 9);

    public List<SudokuRegion>? Regions
    {
        get => (List<SudokuRegion>?)GetValue(RegionsProperty);
        set => SetValue(RegionsProperty, value);
    }

    public int BoardSize
    {
        get => (int)GetValue(BoardSizeProperty);
        set => SetValue(BoardSizeProperty, value);
    }

    public KillerCageBackgroundOverlay()
    {
        Drawable = new KillerCageBackgroundDrawable(this);
        InputTransparent = true;
    }
}

internal class KillerCageBackgroundDrawable(KillerCageBackgroundOverlay overlay) : IDrawable
{
    private readonly KillerCageBackgroundOverlay _overlay = overlay;

    private static readonly Color[] LightCageColors =
    [
        Color.FromArgb("#FFF3E0"), Color.FromArgb("#E8F5E8"),
        Color.FromArgb("#E3F2FD"), Color.FromArgb("#F3E5F5"),
        Color.FromArgb("#E0F2F1"), Color.FromArgb("#FFF8E1"),
        Color.FromArgb("#E8EAF6"), Color.FromArgb("#FBE9E7"),
        Color.FromArgb("#F9FAFB"),
    ];

    private static readonly Color[] DarkCageColors =
    [
        Color.FromArgb("#4A3535"), Color.FromArgb("#2D4A2D"),
        Color.FromArgb("#2D2D4A"), Color.FromArgb("#4A3540"),
        Color.FromArgb("#40354A"), Color.FromArgb("#2D4A4A"),
        Color.FromArgb("#4A4035"), Color.FromArgb("#2D354A"),
        Color.FromArgb("#4A3535"),
    ];

    public void Draw(ICanvas canvas, RectF dirtyRect)
    {
        var regions = _overlay.Regions;
        var boardSize = _overlay.BoardSize;
        if (regions == null || boardSize <= 0) return;

        float cellWidth = dirtyRect.Width / boardSize;
        float cellHeight = dirtyRect.Height / boardSize;
        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;
        var cageColors = isDark ? DarkCageColors : LightCageColors;

        var cageRegions = regions.Where(r => r.Type == RegionType.Cage).ToList();
        if (cageRegions.Count == 0) return;

        var cageColorMap = BuildCageColorMap(cageRegions);

        foreach (var cage in cageRegions)
        {
            if (cage.Cells.Count == 0) continue;
            var colorIndex = cageColorMap.GetValueOrDefault(cage.Id, 0);
            canvas.FillColor = cageColors[colorIndex % cageColors.Length].WithAlpha(0.55f);
            foreach (var cell in cage.Cells)
            {
                canvas.FillRectangle(cell.Col * cellWidth, cell.Row * cellHeight, cellWidth, cellHeight);
            }
        }
    }

    private static Dictionary<string, int> BuildCageColorMap(List<SudokuRegion> cageRegions)
    {
        var colorMap = new Dictionary<string, int>();
        var sorted = cageRegions.OrderByDescending(c => c.Cells.Count).ToList();
        var cellToCage = new Dictionary<(int r, int c), string>();
        foreach (var cage in sorted)
            foreach (var cell in cage.Cells)
                cellToCage[(cell.Row, cell.Col)] = cage.Id;

        foreach (var cage in sorted)
        {
            var adjacentColors = new HashSet<int>();
            foreach (var cell in cage.Cells)
            {
                var neighbors = new (int r, int c)[] { (cell.Row-1, cell.Col), (cell.Row+1, cell.Col), (cell.Row, cell.Col-1), (cell.Row, cell.Col+1) };
                foreach (var (nr, nc) in neighbors)
                    if (cellToCage.TryGetValue((nr, nc), out var id) && id != cage.Id && colorMap.TryGetValue(id, out var c))
                        adjacentColors.Add(c);
            }
            int idx = 0;
            while (adjacentColors.Contains(idx) && idx < 8) idx++;
            colorMap[cage.Id] = idx;
        }
        return colorMap;
    }
}
