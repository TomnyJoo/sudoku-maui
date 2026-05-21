namespace SudoKu.Controls;

using System.Linq;
using SudoKu.Models;
using Font = Microsoft.Maui.Graphics.Font;

/// <summary>
/// 杀手数独笼子叠加层控件，使用 GraphicsView 绘制笼子背景色和数字之和标注。
/// 
/// 绘制顺序：笼子背景色 → 逐边虚线边框 → 和值标注
/// 注意：不绘制标准网格线（由底层SudokuCellView负责）。
/// </summary>
public partial class KillerCageOverlay : GraphicsView
{
    /// <summary>标识 Regions 绑定属性。</summary>
    public static readonly BindableProperty RegionsProperty =
        BindableProperty.Create(nameof(Regions), typeof(List<SudokuRegion>), typeof(KillerCageOverlay), null,
            propertyChanged: OnRegionsChanged);

    /// <summary>标识 BoardSize 绑定属性。</summary>
    public static readonly BindableProperty BoardSizeProperty =
        BindableProperty.Create(nameof(BoardSize), typeof(int), typeof(KillerCageOverlay), 9);

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

    /// <summary>标识 IsVisible 绑定属性。</summary>
    public static new readonly BindableProperty IsVisibleProperty =
        BindableProperty.Create(nameof(IsVisible), typeof(bool), typeof(KillerCageOverlay), true,
            propertyChanged: OnIsVisibleChanged);

    /// <summary>
    /// 初始化杀手笼子覆盖层的新实例。
    /// </summary>
    public KillerCageOverlay()
    {
        Drawable = new KillerCageDrawable(this);
        InputTransparent = true; // 叠加层不拦截触摸事件，让点击穿透到单元格
    }

    /// <summary>
    /// 可见性变化时重绘。
    /// </summary>
    private static void OnIsVisibleChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is KillerCageOverlay overlay)
            overlay.Invalidate();
    }

    /// <summary>
    /// 区域列表变化时重绘。
    /// </summary>
    private static void OnRegionsChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is KillerCageOverlay overlay)
            overlay.Invalidate();
    }
}

/// <summary>
/// 杀手数独笼子绘制器 - 完整参照Flutter实现。
/// 绘制顺序：笼子背景色 → 逐边虚线边框 → 和值标注
/// 注意：不绘制标准网格线（由底层SudokuCellView负责）。
/// </summary>
/// <remarks>
/// 初始化杀手笼子绘制器。
/// </remarks>
internal class KillerCageDrawable(KillerCageOverlay overlay) : IDrawable
{
    private readonly KillerCageOverlay _overlay = overlay;

    /// <summary>
    /// 在画布上绘制笼子边框和和值标注。
    /// 背景色已移至 KillerCageBackgroundOverlay 绘制。
    /// </summary>
    public void Draw(ICanvas canvas, RectF dirtyRect)
    {
        if (canvas is null) return;

        var regions = _overlay.Regions;
        var boardSize = _overlay.BoardSize;
        if (regions == null || boardSize <= 0) return;

        float cellWidth = dirtyRect.Width / boardSize;
        float cellHeight = dirtyRect.Height / boardSize;

        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;

        var borderColor = isDark ? Color.FromArgb("#EF5350") : Color.FromArgb("#D32F2F");

        // 获取所有笼子区域
        var cageRegions = regions.Where(r => r.Type == RegionType.Cage).ToList();
        if (cageRegions.Count == 0) return;

        // 构建单元格到笼子的映射（用于判断相邻关系）
        var cellToCage = new Dictionary<(int r, int c), SudokuRegion>();
        foreach (var cage in cageRegions)
        {
            foreach (var cell in cage.Cells)
                cellToCage[(cell.Row, cell.Col)] = cage;
        }

        // === 1. 绘制笼子虚线边框 ===
        canvas.StrokeColor = borderColor;
        canvas.StrokeSize = 1.8f;

        foreach (var cage in cageRegions)
        {
            if (cage.Cells.Count == 0) continue;

            foreach (var cell in cage.Cells)
            {
                float x = cell.Col * cellWidth;
                float y = cell.Row * cellHeight;

                // 上边：如果上方单元格不在同一笼子，绘制虚线
                if (!cellToCage.ContainsKey((cell.Row - 1, cell.Col)) ||
                    cellToCage[(cell.Row - 1, cell.Col)].Id != cage.Id)
                {
                    DrawDashedLine(canvas, x, y, x + cellWidth, y);
                }

                // 下边
                if (!cellToCage.ContainsKey((cell.Row + 1, cell.Col)) ||
                    cellToCage[(cell.Row + 1, cell.Col)].Id != cage.Id)
                {
                    DrawDashedLine(canvas, x, y + cellHeight, x + cellWidth, y + cellHeight);
                }

                // 左边
                if (!cellToCage.ContainsKey((cell.Row, cell.Col - 1)) ||
                    cellToCage[(cell.Row, cell.Col - 1)].Id != cage.Id)
                {
                    DrawDashedLine(canvas, x, y, x, y + cellHeight);
                }

                // 右边
                if (!cellToCage.ContainsKey((cell.Row, cell.Col + 1)) ||
                    cellToCage[(cell.Row, cell.Col + 1)].Id != cage.Id)
                {
                    DrawDashedLine(canvas, x + cellWidth, y, x + cellWidth, y + cellHeight);
                }
            }
        }

        // === 2. 绘制和值标注
        var sumColor = isDark ? Color.FromArgb("#FFCCBC") : Color.FromArgb("#5D4037");
        var bgColor = isDark ? Color.FromArgb("#1E1E1E").WithAlpha(0.95f) : Color.FromArgb("#FFFFFF").WithAlpha(0.95f);
        const float sumFontSize = 11.0f;
        canvas.Font = new Font("OpenSansBold", (int)sumFontSize);

        foreach (var cage in cageRegions)
        {
            if (cage.Cells.Count == 0) continue;

            // 笼子名称存储的是和值
            string? sumText = cage.Name;
            if (string.IsNullOrEmpty(sumText)) continue;

            // 尝试解析为数字验证
            if (!int.TryParse(sumText, out _)) continue;

            (int Row, int Col) = FindBestSumPosition(cage);

            float cellX = Col * cellWidth;
            float cellY = Row * cellHeight;

            // 测量文字宽度
            var textSize = canvas.GetStringSize(sumText, new Font("OpenSansBold", (int)sumFontSize), sumFontSize);

            const float padding = 2.0f;
            float bgX = cellX + 2;
            float bgY = cellY + 2;
            float bgW = textSize.Width + padding * 2;
            float bgH = textSize.Height + padding;

            // 绘制背景圆角矩形
            canvas.FillColor = bgColor;
            canvas.FillRoundedRectangle(bgX, bgY, bgW, bgH, 3f);

            // 绘制和值文字
            // MAUI DrawString的Y坐标是从文字baseline开始，需要调整
            // 经验值：向下偏移约0.6个字符高度使视觉位置与Flutter一致
            canvas.FillColor = sumColor;
            float baselineOffset = textSize.Height * 0.6f; // 调整baseline偏移
            float textY = bgY + padding + baselineOffset;
            canvas.DrawString(sumText, bgX + padding, textY, HorizontalAlignment.Left);
        }
    }

    /// <summary>
    /// 绘制虚线 - dashLength=6.0, gapLength=4.0
    /// </summary>
    private static void DrawDashedLine(ICanvas canvas, float x1, float y1, float x2, float y2)
    {
        const float dashLength = 6.0f;
        const float gapLength = 4.0f;

        float totalLength = MathF.Sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
        if (totalLength <= 0) return;

        float dx = (x2 - x1) / totalLength;
        float dy = (y2 - y1) / totalLength;

        int dashCount = (int)(totalLength / (dashLength + gapLength));

        for (int i = 0; i < dashCount; i++)
        {
            float dashStart = i * (dashLength + gapLength);
            float dashEnd = dashStart + dashLength;

            canvas.DrawLine(
                x1 + dx * dashStart, y1 + dy * dashStart,
                x1 + dx * dashEnd, y1 + dy * dashEnd);
        }
    }

    /// <summary>
    /// 智能和值定位
    /// 优先级：有值的单元格 > 无候选数的单元格 > 候选数最少的单元格
    /// </summary>
    private static (int Row, int Col) FindBestSumPosition(SudokuRegion cage)
    {
        // Priority 1: 有值的单元格
        foreach (var cell in cage.Cells)
        {
            if (cell.Value.HasValue && cell.Value.Value != 0)
                return (cell.Row, cell.Col);
        }

        // Priority 2: 无候选数的单元格
        foreach (var cell in cage.Cells)
        {
            if (cell.Candidates == null || cell.Candidates.Count == 0)
                return (cell.Row, cell.Col);
        }

        // Priority 3: 候选数最少的单元格
        SudokuCell best = cage.Cells[0];
        int minCount = int.MaxValue;
        foreach (var cell in cage.Cells)
        {
            int count = cell.Candidates?.Count ?? 0;
            if (count < minCount)
            {
                minCount = count;
                best = cell;
            }
        }
        return (best.Row, best.Col);
    }
}
