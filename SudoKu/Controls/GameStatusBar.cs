namespace SudoKu.Controls;

using SudoKu.Models;

/// <summary>
/// 游戏状态栏控件，显示当前游戏的难度、时间、错误次数和最佳时间。
/// </summary>
public partial class GameStatusBar : ContentView
{
    /// <summary>
    /// 标识 Difficulty 绑定属性。
    /// </summary>
    public static readonly BindableProperty DifficultyProperty =
        BindableProperty.Create(nameof(Difficulty), typeof(Difficulty), typeof(GameStatusBar), Difficulty.Medium);

    /// <summary>
    /// 标识 ElapsedTime 绑定属性。
    /// </summary>
    public static readonly BindableProperty ElapsedTimeProperty =
        BindableProperty.Create(nameof(ElapsedTime), typeof(string), typeof(GameStatusBar), "00:00");

    /// <summary>
    /// 标识 Mistakes 绑定属性。
    /// </summary>
    public static readonly BindableProperty MistakesProperty =
        BindableProperty.Create(nameof(Mistakes), typeof(int), typeof(GameStatusBar), 0);

    /// <summary>
    /// 标识 BestTime 绑定属性。
    /// </summary>
    public static readonly BindableProperty BestTimeProperty =
        BindableProperty.Create(nameof(BestTime), typeof(string), typeof(GameStatusBar), "--:--");

    /// <summary>获取或设置难度等级。</summary>
    public Difficulty Difficulty
    {
        get => (Difficulty)GetValue(DifficultyProperty);
        set => SetValue(DifficultyProperty, value);
    }

    /// <summary>获取或设置已用时间显示字符串。</summary>
    public string ElapsedTime
    {
        get => (string)GetValue(ElapsedTimeProperty);
        set => SetValue(ElapsedTimeProperty, value);
    }

    /// <summary>获取或设置错误次数。</summary>
    public int Mistakes
    {
        get => (int)GetValue(MistakesProperty);
        set => SetValue(MistakesProperty, value);
    }

    /// <summary>获取或设置最佳时间显示字符串。</summary>
    public string BestTime
    {
        get => (string)GetValue(BestTimeProperty);
        set => SetValue(BestTimeProperty, value);
    }

    /// <summary>
    /// 初始化游戏状态栏的新实例。
    /// </summary>
    public GameStatusBar()
    {
        // 创建渐变背景
        var gradientBrush = new LinearGradientBrush
        {
            GradientStops = {
                new GradientStop { Color = Colors.Blue.WithAlpha(51), Offset = 0 },
                new GradientStop { Color = Colors.Blue.WithAlpha(26), Offset = 1 }
            },
            StartPoint = new Point(0, 0),
            EndPoint = new Point(1, 1)
        };

        var border = new Border
        {
            Padding = new Thickness(16, 8),
            StrokeThickness = 1,
            Stroke = Colors.Blue.WithAlpha(102),
            Background = gradientBrush
        };

        var grid = new Grid
        {
            ColumnSpacing = 24
        };

        // 创建统计项
        var statItems = new List<HorizontalStackLayout>
        {
            // 时间统计项
            GameStatusBar.CreateStatItem("⏱", ElapsedTime, Colors.Blue),

            // 错误统计项
            GameStatusBar.CreateStatItem("⚠", Mistakes.ToString(), Colors.Red),

            // 难度统计项
            GameStatusBar.CreateStatItem("⭐", Difficulty.ToString(), Colors.Orange),

            // 最佳时间统计项
            GameStatusBar.CreateStatItem("🏆", BestTime, Colors.Yellow)
        };

        // 添加统计项到网格
        for (int i = 0; i < statItems.Count; i++)
        {
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            grid.Add(statItems[i], i, 0);
        }

        border.Content = grid;
        Content = border;
    }

    /// <summary>
    /// 创建统计项。
    /// </summary>
    /// <param name="icon">图标。</param>
    /// <param name="value">值。</param>
    /// <param name="color">颜色。</param>
    /// <returns>统计项视图。</returns>
    private static HorizontalStackLayout CreateStatItem(string icon, string value, Color color)
    {
        var stack = new HorizontalStackLayout { Spacing = 8, VerticalOptions = LayoutOptions.Center };

        // 图标容器
        var iconBorder = new Border
        {
            WidthRequest = 32,
            HeightRequest = 32,
            BackgroundColor = color.WithAlpha(51),
            Content = new Label
            {
                Text = icon,
                FontSize = 16,
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center
            }
        };
        stack.Add(iconBorder);

        // 值标签
        var valueLabel = new Label
        {
            Text = value,
            FontSize = 14,
            FontAttributes = FontAttributes.Bold,
            VerticalOptions = LayoutOptions.Center
        };
        stack.Add(valueLabel);

        return stack;
    }
}
