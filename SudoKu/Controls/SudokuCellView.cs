namespace SudoKu.Controls;

using Microsoft.Maui.Controls.Shapes;

/// <summary>
/// 数独单元格视图控件，显示单元格的值、候选数和状态。
/// 文字位置计算使用正确的baseline偏移，确保与Flutter视觉效果一致。
/// </summary>
public partial class SudokuCellView : ContentView
{
    private readonly Border _cellBorder;
    private readonly Grid _contentGrid;
    private readonly Label _valueLabel;
    private readonly Grid _candidatesGrid;

    #region 可绑定属性

    /// <summary>标识 CellValue 绑定属性。</summary>
    public static readonly BindableProperty CellValueProperty =
        BindableProperty.Create(nameof(CellValue), typeof(int?), typeof(SudokuCellView), null,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 IsFixed 绑定属性。</summary>
    public static readonly BindableProperty IsFixedProperty =
        BindableProperty.Create(nameof(IsFixed), typeof(bool), typeof(SudokuCellView), false,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 IsError 绑定属性。</summary>
    public static readonly BindableProperty IsErrorProperty =
        BindableProperty.Create(nameof(IsError), typeof(bool), typeof(SudokuCellView), false,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 IsSelected 绑定属性。</summary>
    public static readonly BindableProperty IsSelectedProperty =
        BindableProperty.Create(nameof(IsSelected), typeof(bool), typeof(SudokuCellView), false,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 IsHighlighted 绑定属性。</summary>
    public static readonly BindableProperty IsHighlightedProperty =
        BindableProperty.Create(nameof(IsHighlighted), typeof(bool), typeof(SudokuCellView), false,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 Candidates 绑定属性。</summary>
    public static readonly BindableProperty CandidatesProperty =
        BindableProperty.Create(nameof(Candidates), typeof(HashSet<int>), typeof(SudokuCellView), null,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 ColorIndex 绑定属性。</summary>
    public static readonly BindableProperty ColorIndexProperty =
        BindableProperty.Create(nameof(ColorIndex), typeof(int?), typeof(SudokuCellView), null,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 RegionBackgroundColor 绑定属性。</summary>
    public static readonly BindableProperty RegionBackgroundColorProperty =
        BindableProperty.Create(nameof(RegionBackgroundColor), typeof(Color), typeof(SudokuCellView), Colors.White,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 HighlightMistakesEnabled 绑定属性。</summary>
    public static readonly BindableProperty HighlightMistakesEnabledProperty =
        BindableProperty.Create(nameof(HighlightMistakesEnabled), typeof(bool), typeof(SudokuCellView), true,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 IsShowingSolution 绑定属性。</summary>
    public static readonly BindableProperty IsShowingSolutionProperty =
        BindableProperty.Create(nameof(IsShowingSolution), typeof(bool), typeof(SudokuCellView), false,
            propertyChanged: OnCellStateChanged);

    /// <summary>标识 SolutionValue 绑定属性。</summary>
    public static readonly BindableProperty SolutionValueProperty =
        BindableProperty.Create(nameof(SolutionValue), typeof(int?), typeof(SudokuCellView), null,
            propertyChanged: OnCellStateChanged);

    #endregion

    #region 属性

    /// <summary>单元格点击事件。</summary>
    public event EventHandler? CellTapped;

    /// <summary>获取或设置单元格行索引。</summary>
    public int Row { get; set; }

    /// <summary>获取或设置单元格列索引。</summary>
    public int Col { get; set; }

    /// <summary>获取或设置单元格值。</summary>
    public int? CellValue
    {
        get => (int?)GetValue(CellValueProperty);
        set => SetValue(CellValueProperty, value);
    }

    /// <summary>获取或设置是否为固定值。</summary>
    public bool IsFixed
    {
        get => (bool)GetValue(IsFixedProperty);
        set => SetValue(IsFixedProperty, value);
    }

    /// <summary>获取或设置是否为错误状态。</summary>
    public bool IsError
    {
        get => (bool)GetValue(IsErrorProperty);
        set => SetValue(IsErrorProperty, value);
    }

    /// <summary>获取或设置是否被选中。</summary>
    public bool IsSelected
    {
        get => (bool)GetValue(IsSelectedProperty);
        set => SetValue(IsSelectedProperty, value);
    }

    /// <summary>获取或设置是否高亮。</summary>
    public bool IsHighlighted
    {
        get => (bool)GetValue(IsHighlightedProperty);
        set => SetValue(IsHighlightedProperty, value);
    }

    /// <summary>获取或设置候选数集合。</summary>
    public HashSet<int>? Candidates
    {
        get => (HashSet<int>?)GetValue(CandidatesProperty);
        set => SetValue(CandidatesProperty, value);
    }

    /// <summary>获取或设置颜色索引。</summary>
    public int? ColorIndex
    {
        get => (int?)GetValue(ColorIndexProperty);
        set => SetValue(ColorIndexProperty, value);
    }

    /// <summary>获取或设置区域背景色。</summary>
    public Color RegionBackgroundColor
    {
        get => (Color)GetValue(RegionBackgroundColorProperty);
        set => SetValue(RegionBackgroundColorProperty, value);
    }

    /// <summary>获取或设置是否启用错误高亮。</summary>
    public bool HighlightMistakesEnabled
    {
        get => (bool)GetValue(HighlightMistakesEnabledProperty);
        set => SetValue(HighlightMistakesEnabledProperty, value);
    }

    /// <summary>获取或设置是否显示答案。</summary>
    public bool IsShowingSolution
    {
        get => (bool)GetValue(IsShowingSolutionProperty);
        set => SetValue(IsShowingSolutionProperty, value);
    }

    /// <summary>获取或设置答案值。</summary>
    public int? SolutionValue
    {
        get => (int?)GetValue(SolutionValueProperty);
        set => SetValue(SolutionValueProperty, value);
    }

    /// <summary>网格线颜色（细线）。</summary>
    public Color GridLineColor { get; set; } = Color.FromArgb("#CBD5E1");

    /// <summary>网格线颜色（粗线/宫格线）。</summary>
    public Color GridLineBoldColor { get; set; } = Color.FromArgb("#475569");

    /// <summary>是否为粗线边框。</summary>
    public bool IsBoldBorder { get; set; }

    #endregion

    /// <summary>
    /// 初始化数独单元格视图的新实例。
    /// </summary>
    public SudokuCellView()
    {
        HorizontalOptions = LayoutOptions.Fill;
        VerticalOptions = LayoutOptions.Fill;
        Padding = 0;
        Margin = 0;

        // 使用Grid作为容器，让值和候选数都居中显示
        _contentGrid = new Grid
        {
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
        };

        // 值Label - 居中显示
        _valueLabel = new Label
        {
            FontSize = 22,
            FontAutoScalingEnabled = true,
            HorizontalOptions = LayoutOptions.Center,
            VerticalOptions = LayoutOptions.Center,
            HorizontalTextAlignment = TextAlignment.Center,
            VerticalTextAlignment = TextAlignment.Center,
        };
        _contentGrid.Add(_valueLabel);

        // 候选数Grid - 3x3布局
        _candidatesGrid = new Grid
        {
            RowSpacing = 0,
            ColumnSpacing = 0,
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            Padding = new Thickness(2),
        };

        for (int r = 0; r < 3; r++)
        {
            _candidatesGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });
            _candidatesGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
        }
        _contentGrid.Add(_candidatesGrid);

        _cellBorder = new Border
        {
            StrokeShape = new Rectangle(),
            StrokeThickness = 0,
            Stroke = Colors.Transparent,
            BackgroundColor = Colors.Transparent,
            Content = _contentGrid,
            Padding = 0,
        };

        var tapGesture = new TapGestureRecognizer();
        tapGesture.Tapped += (s, e) => CellTapped?.Invoke(this, EventArgs.Empty);
        _cellBorder.GestureRecognizers.Add(tapGesture);

        Content = _cellBorder;
    }

    /// <summary>
    /// 单元格状态变化时更新显示。
    /// </summary>
    private static void OnCellStateChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is SudokuCellView cellView)
        {
            cellView.UpdateDisplay();
            if (cellView.IsSelected && oldValue is bool wasSelected && !wasSelected)
                cellView.AnimateSelection();
        }
    }

    /// <summary>
    /// 选中动画效果。
    /// </summary>
    private void AnimateSelection()
    {
        var scaleAnimation = new Animation(d => _cellBorder.Scale = d, 0.95, 1.0);
        scaleAnimation.Commit(_cellBorder, "SelectionScale", length: 150, easing: Easing.CubicOut);
    }

    /// <summary>
    /// 更新单元格显示。
    /// </summary>
    private void UpdateDisplay()
    {
        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;

        // 背景色优先级：选中 > 高亮 > 区域背景色 > 透明
        Color? bgColor;
        if (IsSelected)
        {
            bgColor = Color.FromArgb("#FFF3C4");
        }
        else if (IsHighlighted)
        {
            bgColor = isDark ? Color.FromArgb("#33FFFFFF") : Color.FromArgb("#BBDEFB");
        }
        else if (RegionBackgroundColor != Colors.White && RegionBackgroundColor != Colors.Transparent)
        {
            bgColor = RegionBackgroundColor;
        }
        else
        {
            bgColor = null; // 无值时透明
        }

        _cellBorder.BackgroundColor = bgColor ?? Colors.Transparent;

        // 值/候选数显示（考虑显示答案）
        var displayValue = IsShowingSolution ? SolutionValue : CellValue;
        var hasValue = displayValue.HasValue;
        var hasCandidates = !IsShowingSolution && Candidates is not null && Candidates.Count > 0;

        _valueLabel.IsVisible = hasValue;
        _candidatesGrid.IsVisible = !hasValue && hasCandidates;

        if (hasValue)
        {
            UpdateValueDisplay(isDark, displayValue);
        }
        else if (hasCandidates)
        {
            UpdateCandidatesDisplay(isDark);
        }
    }

    /// <summary>
    /// 更新单元格值的显示。
    /// </summary>
    private void UpdateValueDisplay(bool isDark, int? value)
    {
        _valueLabel.Text = value!.Value.ToString();
        _valueLabel.FontAttributes = IsFixed ? FontAttributes.Bold : FontAttributes.None;

        // 颜色设置 
        if (IsFixed)
        {
            _valueLabel.TextColor = isDark ? Color.FromArgb("#E2E8F0") : Color.FromArgb("#1E293B");
        }
        else if (IsError && HighlightMistakesEnabled)
        {
            _valueLabel.TextColor = Color.FromArgb("#EF4444");
        }
        else
        {
            _valueLabel.TextColor = isDark ? Color.FromArgb("#93C5FD") : Color.FromArgb("#2563EB");
        }
    }

    /// <summary>
    /// 更新候选数的显示。
    /// </summary>
    private void UpdateCandidatesDisplay(bool isDark)
    {
        _candidatesGrid.Children.Clear();
        if (Candidates is null) return;

        var candidateColor = isDark ? Color.FromArgb("#94A3B8") : Color.FromArgb("#64748B");

        for (int num = 1; num <= 9; num++)
        {
            var row = (num - 1) / 3;
            var col = (num - 1) % 3;

            var label = new Label
            {
                Text = Candidates.Contains(num) ? num.ToString() : string.Empty,
                FontSize = 10, 
                FontAutoScalingEnabled = true,
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
                HorizontalTextAlignment = TextAlignment.Center,
                VerticalTextAlignment = TextAlignment.Center,
                TextColor = candidateColor,
            };
            _candidatesGrid.Add(label, col, row);
        }
    }
}
