namespace SudoKu.Controls;

using Microsoft.Maui.Graphics;
using SudoKu.Models;

/// <summary>
/// 网格线覆盖层控件，使用 GraphicsView 统一绘制棋盘网格线。
/// </summary>
public partial class GridLineOverlay : GraphicsView
{
    /// <summary>标识 GameType 绑定属性。</summary>
    public static readonly BindableProperty GameTypeProperty =
        BindableProperty.Create(nameof(GameType), typeof(GameType), typeof(GridLineOverlay), GameType.Standard,
            propertyChanged: (b, o, n) => ((GridLineOverlay)b).Invalidate());

    /// <summary>标识 BoardSize 绑定属性。</summary>
    public static readonly BindableProperty BoardSizeProperty =
        BindableProperty.Create(nameof(BoardSize), typeof(int), typeof(GridLineOverlay), 9,
            propertyChanged: (b, o, n) => ((GridLineOverlay)b).Invalidate());

    /// <summary>标识是否为深色主题。</summary>
    public static readonly BindableProperty IsDarkThemeProperty =
        BindableProperty.Create(nameof(IsDarkTheme), typeof(bool), typeof(GridLineOverlay), false,
            propertyChanged: (b, o, n) => ((GridLineOverlay)b).Invalidate());

    /// <summary>武士数独五个子盘在21x21棋盘中的偏移。参考Flutter SamuraiConstants.subGridOffsets。</summary>
    private static readonly (int row, int col)[] SamuraiSubGridOffsets =
    [
        (0, 0), (0, 12), (12, 0), (12, 12), (6, 6)
    ];

    /// <summary>获取或设置游戏类型。</summary>
    public GameType GameType
    {
        get => (GameType)GetValue(GameTypeProperty);
        set => SetValue(GameTypeProperty, value);
    }

    /// <summary>获取或设置棋盘尺寸。</summary>
    public int BoardSize
    {
        get => (int)GetValue(BoardSizeProperty);
        set => SetValue(BoardSizeProperty, value);
    }

    /// <summary>获取或设置是否为深色主题。</summary>
    public bool IsDarkTheme
    {
        get => (bool)GetValue(IsDarkThemeProperty);
        set => SetValue(IsDarkThemeProperty, value);
    }

    /// <summary>
    /// 初始化网格线覆盖层的新实例。
    /// </summary>
    public GridLineOverlay()
    {
        HorizontalOptions = LayoutOptions.Fill;
        VerticalOptions = LayoutOptions.Fill;
        Drawable = new GridLineDrawable(this);
        InputTransparent = true; // 叠加层不拦截触摸事件，让点击穿透到单元格
    }

    /// <summary>
    /// 网格线绘制器，负责在 GraphicsView 上绘制网格线。
    /// </summary>
    private class GridLineDrawable(GridLineOverlay overlay) : IDrawable
    {
        private readonly GridLineOverlay _overlay = overlay;

        /// <summary>
        /// 在画布上绘制网格线。
        /// </summary>
        public void Draw(ICanvas canvas, RectF bounds)
        {
            var size = _overlay.BoardSize;
            if (size <= 0) return;

            var gameType = _overlay.GameType;
            var isJigsaw = gameType == GameType.Jigsaw;
            var isWindow = gameType == GameType.Window;
            var isSamurai = gameType == GameType.Samurai && size == 21;
            var isDark = _overlay.IsDarkTheme;

            // 细线颜色和粗细
            var thinColor = isDark
                ? Color.FromArgb("#4A5568")
                : Color.FromArgb("#CBD5E1");
            const float thinWidth = 1.0f;

            // 粗线颜色和粗细
            var boldColor = isDark
                ? Color.FromArgb("#A0AEC0")
                : Color.FromArgb("#475569");
            float boldWidth = isWindow ? 2.5f : 3.0f;

            // 武士数独子盘边框颜色（五个子盘用不同颜色区分）
            var subGridColors = new[]
            {
                isDark ? Color.FromArgb("#F87171") : Color.FromArgb("#EF4444"), // 红色
                isDark ? Color.FromArgb("#FBBF24") : Color.FromArgb("#F59E0B"), // 橙色
                isDark ? Color.FromArgb("#34D399") : Color.FromArgb("#10B981"), // 绿色
                isDark ? Color.FromArgb("#60A5FA") : Color.FromArgb("#3B82F6"), // 蓝色
                isDark ? Color.FromArgb("#A78BFA") : Color.FromArgb("#8B5CF6"),  // 紫色
            };

            var cellWidth = bounds.Width / size;
            var cellHeight = bounds.Height / size;

            // 武士数独总览模式：只为子盘区域绘制网格线
            if (isSamurai)
            {
                // 绘制每个子盘的网格线
                for (int idx = 0; idx < SamuraiSubGridOffsets.Length; idx++)
                {
                    var (startRow, startCol) = SamuraiSubGridOffsets[idx];
                    var subColor = subGridColors[idx];

                    // 绘制子盘内部细线
                    for (int i = 1; i < 9; i++)
                    {
                        // 水平线
                        float y = (startRow + i) * cellHeight;
                        float x1 = startCol * cellWidth;
                        float x2 = (startCol + 9) * cellWidth;
                        bool isBold = i % 3 == 0;

                        canvas.StrokeColor = isBold ? subColor : thinColor;
                        canvas.StrokeSize = isBold ? boldWidth : thinWidth;
                        canvas.DrawLine(x1, y, x2, y);

                        // 垂直线
                        float x = (startCol + i) * cellWidth;
                        float y1 = startRow * cellHeight;
                        float y2 = (startRow + 9) * cellHeight;

                        canvas.StrokeColor = isBold ? subColor : thinColor;
                        canvas.StrokeSize = isBold ? boldWidth : thinWidth;
                        canvas.DrawLine(x, y1, x, y2);
                    }

                    // 绘制子盘外边框（用对应颜色，粗细与宫格线一致）
                    var borderRect = new RectF(
                        startCol * cellWidth,
                        startRow * cellHeight,
                        9 * cellWidth,
                        9 * cellHeight);
                    canvas.StrokeColor = subColor;
                    canvas.StrokeSize = boldWidth;
                    canvas.DrawRectangle(borderRect);
                }
                return;
            }

            // 锯齿数独不绘制宫格粗线
            bool useBlockThickLines = !isJigsaw;

            // 计算宫格大小：9x9棋盘为3
            var blockSize = size == 9 ? 3 : 2;

            // 普通模式：绘制整个棋盘的网格线
            // 绘制竖线
            for (int i = 0; i <= size; i++)
            {
                float x = i * cellWidth;
                bool isBold = useBlockThickLines && (i % blockSize == 0);

                canvas.StrokeColor = isBold ? boldColor : thinColor;
                canvas.StrokeSize = isBold ? boldWidth : thinWidth;
                canvas.DrawLine(x, 0, x, bounds.Height);
            }

            // 绘制横线
            for (int i = 0; i <= size; i++)
            {
                float y = i * cellHeight;
                bool isBold = useBlockThickLines && (i % blockSize == 0);

                canvas.StrokeColor = isBold ? boldColor : thinColor;
                canvas.StrokeSize = isBold ? boldWidth : thinWidth;
                canvas.DrawLine(0, y, bounds.Width, y);
            }
        }
    }
}
