namespace SudoKu.Controls;

using System.Collections.Generic;
using System.Windows.Input;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Shapes;
using Microsoft.Maui.Graphics;

/// <summary>
/// 数字键盘视图，使用半透明渐变背景 + 圆角矩形，3x3网格布局。
/// </summary>
public partial class NumberPadView : ContentView
{
    private readonly Grid _grid;
    private readonly Border[] _numberButtons = new Border[9];
    private readonly Label[] _numberLabels = new Label[9];
    private readonly Border[] _countBadges = new Border[9];
    private readonly Label[] _countLabels = new Label[9];

    #region 可绑定属性

    public static readonly BindableProperty InputNumberCommandProperty;
    public static readonly BindableProperty NumberCountsProperty;
    public static readonly BindableProperty MaxCountProperty;

    #endregion

    #region 属性

    public ICommand? InputNumberCommand
    {
        get => (ICommand?)GetValue(InputNumberCommandProperty);
        set => SetValue(InputNumberCommandProperty, value);
    }

    public Dictionary<int, int>? NumberCounts
    {
        get => (Dictionary<int, int>?)GetValue(NumberCountsProperty);
        set => SetValue(NumberCountsProperty, value);
    }

    public int MaxCount
    {
        get => (int)GetValue(MaxCountProperty);
        set => SetValue(MaxCountProperty, value);
    }

    #endregion

    private static readonly (Color Primary, Color Secondary) ButtonColors =
        (Color.FromArgb("#6366F1"), Color.FromArgb("#818CF8"));

    /// <summary>
    /// 静态构造函数 - 在类首次加载时执行，添加异常处理
    /// </summary>
    static NumberPadView()
    {
        try
        {
            InputNumberCommandProperty = BindableProperty.Create(
                nameof(InputNumberCommand), 
                typeof(ICommand), 
                typeof(NumberPadView), 
                null);
            
            NumberCountsProperty = BindableProperty.Create(
                nameof(NumberCounts), 
                typeof(Dictionary<int, int>), 
                typeof(NumberPadView), 
                null,
                propertyChanged: OnNumberCountsChanged);
            
            MaxCountProperty = BindableProperty.Create(
                nameof(MaxCount), 
                typeof(int), 
                typeof(NumberPadView), 
                9);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"NumberPadView static constructor failed: {ex.Message}");
            throw;
        }
    }

    public NumberPadView()
    {
        _grid = new Grid
        {
            RowSpacing = 4,
            ColumnSpacing = 4,
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            BackgroundColor = Colors.Transparent,
            Padding = new Thickness(2),
        };

        for (int i = 0; i < 3; i++)
        {
            _grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
            _grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        }

        for (int num = 1; num <= 9; num++)
        {
            int row = (num - 1) / 3;
            int col = (num - 1) % 3;

            var button = CreateNumberButton(num);
            _numberButtons[num - 1] = button;
            _grid.Add(button, col, row);
        }

        Content = _grid;
        BackgroundColor = Colors.Transparent;
    }

    /// <summary>
    /// 创建数字按钮 - Flutter风格：半透明渐变 + 圆角 + 数字居中 + 右上角计数徽章
    /// </summary>
    private Border CreateNumberButton(int num)
    {
        var button = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(10) },
            Padding = 0,
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            Background = new LinearGradientBrush
            {
                EndPoint = new Point(1, 0),
                GradientStops =
                {
                    new GradientStop(ButtonColors.Primary.WithAlpha(0.2f), 0.0f),
                    new GradientStop(ButtonColors.Secondary.WithAlpha(0.2f), 1.0f),
                }
            },
            Shadow = new Shadow
            {
                Brush = Colors.Black,
                Offset = new Point(0, 2),
                Radius = 4,
                Opacity = 0.2f,
            },
        };

        var contentGrid = new Grid
        {
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
        };

        var numberLabel = new Label
        {
            Text = num.ToString(),
            FontSize = 22,
            FontAttributes = FontAttributes.Bold,
            TextColor = ButtonColors.Primary,
            HorizontalOptions = LayoutOptions.Center,
            VerticalOptions = LayoutOptions.Center,
        };
        _numberLabels[num - 1] = numberLabel;
        contentGrid.Add(numberLabel);

        var badge = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(4) },
            BackgroundColor = Color.FromArgb("#EF4444"),
            Padding = new Thickness(4, 1),
            HorizontalOptions = LayoutOptions.End,
            VerticalOptions = LayoutOptions.Start,
            Margin = new Thickness(0, 2, 2, 0),
            IsVisible = false,
            Stroke = Color.FromArgb("#99FFFFFF"),
            StrokeThickness = 1,
        };

        var countLabel = new Label
        {
            FontSize = 10,
            FontAttributes = FontAttributes.Bold,
            TextColor = Colors.White,
            HorizontalOptions = LayoutOptions.Center,
            VerticalOptions = LayoutOptions.Center,
        };
        _countLabels[num - 1] = countLabel;
        badge.Content = countLabel;
        _countBadges[num - 1] = badge;

        contentGrid.Add(badge);

        button.Content = contentGrid;

        var tap = new TapGestureRecognizer();
        int capturedNum = num;
        tap.Tapped += (_, _) =>
        {
            if (InputNumberCommand?.CanExecute(capturedNum) == true)
                InputNumberCommand.Execute(capturedNum);
        };
        button.GestureRecognizers.Add(tap);

        return button;
    }

    private static void OnNumberCountsChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is NumberPadView view && newValue is Dictionary<int, int> counts)
            view.UpdateButtonStates(counts);
    }

    private void UpdateButtonStates(Dictionary<int, int> counts)
    {
        for (int num = 1; num <= 9; num++)
        {
            int count = counts.TryGetValue(num, out var c) ? c : 0;
            var badge = _countBadges[num - 1];
            var countLabel = _countLabels[num - 1];

            if (count > 0)
            {
                badge.IsVisible = true;
                countLabel.Text = count.ToString();
            }
            else
            {
                badge.IsVisible = false;
            }
        }
    }
}
