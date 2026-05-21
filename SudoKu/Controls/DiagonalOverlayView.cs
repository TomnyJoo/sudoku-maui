namespace SudoKu.Controls;

/// <summary>
/// 对角线数独叠加层控件，使用 GraphicsView 绘制两条对角线虚线, 支持切换显示/隐藏。
/// 虚线参数：
/// - dashLength = 6.0
/// - gapLength = 4.0
/// </summary>
public partial class DiagonalOverlayView : GraphicsView
{
    /// <summary>标识 BoardSize 绑定属性。</summary>
    public static readonly BindableProperty BoardSizeProperty =
        BindableProperty.Create(nameof(BoardSize), typeof(int), typeof(DiagonalOverlayView), 9);

    /// <summary>标识 ShowDiagonalLines 绑定属性，控制对角线是否显示。</summary>
    public static readonly BindableProperty ShowDiagonalLinesProperty =
        BindableProperty.Create(nameof(ShowDiagonalLines), typeof(bool), typeof(DiagonalOverlayView), true,
            propertyChanged: (b, o, n) => ((DiagonalOverlayView)b).Invalidate());

    /// <summary>获取或设置棋盘尺寸。</summary>
    public int BoardSize
    {
        get => (int)GetValue(BoardSizeProperty);
        set => SetValue(BoardSizeProperty, value);
    }

    /// <summary>获取或设置是否显示对角线。</summary>
    public bool ShowDiagonalLines
    {
        get => (bool)GetValue(ShowDiagonalLinesProperty);
        set => SetValue(ShowDiagonalLinesProperty, value);
    }

    /// <summary>
    /// 初始化对角线叠加层的新实例。
    /// </summary>
    public DiagonalOverlayView()
    {
        Drawable = new DiagonalLineDrawable(this);
        InputTransparent = true; // 叠加层不拦截触摸事件
    }
}

/// <summary>
/// 对角线绘制器，负责在 GraphicsView 上绘制两条对角线虚线。
/// </summary>
internal class DiagonalLineDrawable(DiagonalOverlayView view) : IDrawable
{
    private readonly DiagonalOverlayView _view = view;

    /// <summary>
    /// 在画布上绘制两条对角线虚线（主对角线和副对角线）。
    /// </summary>
    public void Draw(ICanvas canvas, RectF dirtyRect)
    {
        if (canvas is null || !_view.ShowDiagonalLines) return;

        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;

        // 使用粗线颜色，但带透明度
        var lineColor = isDark
            ? Color.FromArgb("#A0AEC0").WithAlpha(0.5f)
            : Color.FromArgb("#475569").WithAlpha(0.5f);

        // Flutter: strokeWidth = 1.5
        canvas.StrokeColor = lineColor;
        canvas.StrokeSize = 1.5f;

        // 绘制主对角线虚线（左上到右下）
        DrawDashedLine(canvas, 0, 0, dirtyRect.Width, dirtyRect.Height);

        // 绘制副对角线虚线（右上到左下）
        DrawDashedLine(canvas, dirtyRect.Width, 0, 0, dirtyRect.Height);
    }

    /// <summary>
    /// 绘制虚线 -  dashLength=6.0, gapLength=4.0
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
}
