namespace SudoKu.Views;

using Microsoft.Maui.Controls.Shapes;
using SudoKu.Models;
using SudoKu.ViewModels;

/// <summary>
/// 首页，展示游戏类型选择、难度选择和操作按钮。
/// 完全参照 Flutter 项目的 HomeScreen 实现，包含：
/// - PageView 两页式布局（游戏类型选择页、难度选择页）
/// - 毛玻璃卡片效果（_GlassCard）
/// - 交错入场动画（_buildStaggeredCard）
/// - 响应式网格布局
/// </summary>
public partial class HomePage : ContentPage
{
    private static readonly (Color Primary, Color Light, string Icon)[] GameTypeStyles =
    [
        (Color.FromArgb("#6366F1"), Color.FromArgb("#818CF8"), "▣"), // Standard
        (Color.FromArgb("#A855F7"), Color.FromArgb("#C084FC"), "╱"), // Diagonal
        (Color.FromArgb("#3B82F6"), Color.FromArgb("#60A5FA"), "□"), // Window
        (Color.FromArgb("#06B6D4"), Color.FromArgb("#22D3EE"), "◇"), // Jigsaw
        (Color.FromArgb("#EF4444"), Color.FromArgb("#F87171"), "■"), // Killer
        (Color.FromArgb("#F97316"), Color.FromArgb("#FB923C"), "★"), // Samurai
    ];

    private static readonly (Color Primary, Color Light, string Stars)[] DifficultyStyles =
    [
        (Color.FromArgb("#22C55E"), Color.FromArgb("#4ADE80"), "★"),
        (Color.FromArgb("#10B981"), Color.FromArgb("#34D399"), "★★"),
        (Color.FromArgb("#EAB308"), Color.FromArgb("#FACC15"), "★★★"),
        (Color.FromArgb("#F97316"), Color.FromArgb("#FB923C"), "★★★★"),
        (Color.FromArgb("#EF4444"), Color.FromArgb("#F87171"), "★★★★★"),
        (Color.FromArgb("#A855F7"), Color.FromArgb("#C084FC"), "★★★★★★"),
    ];

    // 布局常量
    private const int GameTypeColumns = 2;
    private const int GameTypeRows = 3;
    private const double DefaultSpacing = 10;

    private double _lastWidth;
    private double _lastHeight;

    /// <summary>
    /// 初始化首页的新实例。
    /// </summary>
    public HomePage()
    {
        InitializeComponent();
    }

    /// <summary>
    /// 页面出现时初始化 - 参照 Flutter: initState
    /// </summary>
    protected override void OnAppearing()
    {
        base.OnAppearing();

        if (BindingContext is HomeViewModel vm)
        {
            // 重置状态
            vm.IsGenerating = false;
            vm.CurrentPage = 0;
            vm.IsDifficultyPage = false;

            // 构建游戏类型网格
            BuildGameTypeGrid();

            // 触发交错入场动画 - 参照 Flutter: _staggerController.forward()
            AnimateCardsEntry();
        }
    }

    /// <summary>
    /// 页面尺寸变化时重新构建响应式网格 - 参照 Flutter: LayoutBuilder
    /// </summary>
    protected override void OnSizeAllocated(double width, double height)
    {
        base.OnSizeAllocated(width, height);

        if (width <= 0 || height <= 0) return;

        if (BindingContext is HomeViewModel vm)
        {
            vm.PageWidth = width;
            vm.PageHeight = height;
        }

        // 仅在尺寸实际变化时重建网格，避免频繁重建
        if (Math.Abs(width - _lastWidth) > 1 || Math.Abs(height - _lastHeight) > 1)
        {
            _lastWidth = width;
            _lastHeight = height;

            BuildGameTypeGrid();
            BuildDifficultyGrid();
        }
    }

    /// <summary>
    /// 属性变化处理 - 监听 SelectedGameType 变化以更新难度页面图标
    /// </summary>
    protected override void OnPropertyChanged(string? propertyName = null)
    {
        base.OnPropertyChanged(propertyName);

        if (propertyName == nameof(BindingContext) && BindingContext is HomeViewModel vm)
        {
            vm.PropertyChanged += OnViewModelPropertyChanged;
        }
    }

    /// <summary>
    /// ViewModel 属性变化处理
    /// </summary>
    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (sender is not HomeViewModel vm) return;

        if (e.PropertyName == nameof(HomeViewModel.IsDifficultyPage))
        {
            if (vm.IsDifficultyPage)
            {
                // 切换到难度页面时构建难度网格
                BuildDifficultyGrid();
                UpdateDifficultyIcon(vm.SelectedGameType);
            }
        }
        else if (e.PropertyName == nameof(HomeViewModel.SelectedGameType))
        {
            UpdateDifficultyIcon(vm.SelectedGameType);
        }
    }

    /// <summary>
    /// 更新难度页面图标 - 根据选中的游戏类型显示对应图标
    /// </summary>
    private void UpdateDifficultyIcon(GameType? gameType)
    {
        if (gameType == null) return;

        var colorIdx = GetGameTypeColorIndex(gameType.Value);
        var (primaryColor, lightColor, icon) = GameTypeStyles[colorIdx];

        DifficultyIconBorder.BackgroundColor = primaryColor.WithAlpha(0.15f);
        DifficultyIconLabel.Text = icon;
        DifficultyIconLabel.TextColor = lightColor;
    }

    /// <summary>
    /// 获取游戏类型的颜色索引 - 参照 Flutter 的 GameType.values 顺序
    /// </summary>
    private static int GetGameTypeColorIndex(GameType type)
    {
        return type switch
        {
            GameType.Standard => 0,
            GameType.Diagonal => 1,
            GameType.Window => 2,
            GameType.Jigsaw => 3,
            GameType.Killer => 4,
            GameType.Samurai => 5,
            _ => 0
        };
    }

    #region 游戏类型网格 - 参照 Flutter: _buildGameTypePage

    /// <summary>
    /// 构建响应式游戏类型网格 - 参照 Flutter: GridView.count with dynamic childAspectRatio
    /// </summary>
    private void BuildGameTypeGrid()
    {
        if (BindingContext is not HomeViewModel vm) return;
        if (vm.GameTypeItems.Count == 0) return;

        var grid = GameTypeGrid;
        grid.RowDefinitions.Clear();
        grid.ColumnDefinitions.Clear();
        grid.Children.Clear();

        // 获取可用空间
        var availableWidth = grid.Width > 0 ? grid.Width : Width - 40; // 20 padding each side
        var availableHeight = grid.Height > 0 ? grid.Height : Height - 200;

        if (availableWidth <= 0 || availableHeight <= 0) return;

        // 计算卡片尺寸 - 参照 Flutter 逻辑
        var spacing = DefaultSpacing;

        // 动态调整间距 - 参照 Flutter: spacing = constraints.maxHeight < 300 ? 6.0 : (constraints.maxHeight < 500 ? 8.0 : 10.0)
        if (availableHeight < 300) spacing = 6;
        else if (availableHeight < 500) spacing = 8;
        _ = spacing * (GameTypeRows - 1);
        _ = spacing * (GameTypeColumns - 1);

        // 设置 Grid 行列定义 - 使用 Star 实现均分
        for (int r = 0; r < GameTypeRows; r++)
            grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        for (int c = 0; c < GameTypeColumns; c++)
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        grid.RowSpacing = spacing;
        grid.ColumnSpacing = spacing;

        // 构建卡片
        for (int i = 0; i < vm.GameTypeItems.Count && i < GameTypeRows * GameTypeColumns; i++)
        {
            var item = vm.GameTypeItems[i];
            var row = i / GameTypeColumns;
            var col = i % GameTypeColumns;
            var colorIdx = GetGameTypeColorIndex(item.Type);
            var (primaryColor, lightColor, icon) = GameTypeStyles[colorIdx];

            var card = CreateGameTypeCard(item, primaryColor, lightColor, icon);
            grid.Add(card, col, row);
        }
    }

    /// <summary>
    /// 创建游戏类型卡片
    /// </summary>
    private Border CreateGameTypeCard(GameTypeDisplay item, Color primaryColor, Color lightColor, string icon)
    {
        // 毛玻璃卡片效果
        var card = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(16) },
            BackgroundColor = GetGlassBackgroundColor(),
            Stroke = GetGlassBorderColor(),
            StrokeThickness = 1,
            Shadow = new Shadow
            {
                Brush = Colors.Black,
                Offset = new Point(0, 4),
                Radius = 10,
                Opacity = 0.08f,
            },
            Padding = new Thickness(10),
        };

        // 点击手势 - 参照 Flutter: GestureDetector onTap
        var tap = new TapGestureRecognizer();
        tap.Tapped += (_, _) =>
        {
            if (BindingContext is HomeViewModel vm)
                vm.SelectGameTypeCommand.Execute(item.Type);
        };
        card.GestureRecognizers.Add(tap);

        // 内容布局 - 参照 Flutter: Column with icon, name, description
        var content = new VerticalStackLayout
        {
            Spacing = 8,
            HorizontalOptions = LayoutOptions.Center,
            VerticalOptions = LayoutOptions.Center,
        };

        // 图标容器
        var iconBorder = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(10) },
            BackgroundColor = primaryColor.WithAlpha(Application.Current?.RequestedTheme == AppTheme.Dark ? 0.12f : 0.10f),
            WidthRequest = 36,
            HeightRequest = 36,
            HorizontalOptions = LayoutOptions.Center,
            Content = new Label
            {
                Text = icon,
                FontSize = 20,
                TextColor = lightColor,
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
            }
        };
        content.Add(iconBorder);

        // 游戏类型名称 - 参照 Flutter: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))
        content.Add(new Label
        {
            Text = item.DisplayName,
            FontSize = 13,
            FontAttributes = FontAttributes.Bold,
            TextColor = Application.Current?.RequestedTheme == AppTheme.Dark
                ? Colors.White
                : Color.FromArgb("#1E1B4B"),
            HorizontalOptions = LayoutOptions.Center,
            HorizontalTextAlignment = TextAlignment.Center,
            LineBreakMode = LineBreakMode.TailTruncation,
            MaxLines = 1,
        });

        // 描述 - 参照 Flutter: Text(subtitles[type], style: TextStyle(fontSize: 10, color: ...))
        content.Add(new Label
        {
            Text = item.Description,
            FontSize = 10,
            TextColor = Application.Current?.RequestedTheme == AppTheme.Dark
                ? Color.FromArgb("#50FFFFFF")
                : Color.FromArgb("#64748B"),
            HorizontalOptions = LayoutOptions.Center,
            HorizontalTextAlignment = TextAlignment.Center,
            LineBreakMode = LineBreakMode.WordWrap,
            MaxLines = 2,
        });

        card.Content = content;
        return card;
    }

    #endregion

    #region 难度列表 - 参照 Flutter: _buildDifficultyPage

    /// <summary>
    /// 构建响应式难度列表 - 参照 Flutter: Column + Expanded for each item
    /// </summary>
    private void BuildDifficultyGrid()
    {
        if (BindingContext is not HomeViewModel vm) return;
        if (vm.DifficultyItems.Count == 0) return;

        var grid = DifficultyGrid;
        grid.RowDefinitions.Clear();
        grid.ColumnDefinitions.Clear();
        grid.Children.Clear();

        var count = vm.DifficultyItems.Count;
        var availableHeight = grid.Height > 0 ? grid.Height : Height - 300;

        if (availableHeight <= 0) return;

        // 动态间距 - 参照 Flutter: spacing = availableHeight < 300 ? 4.0 : (availableHeight < 450 ? 6.0 : 10.0)
        var spacing = availableHeight < 300 ? 4 : (availableHeight < 450 ? 6 : 10);
        grid.RowSpacing = spacing;

        // 每个难度项均分可用高度 - 参照 Flutter: Expanded(child: _buildDifficultyItem(...))
        for (int i = 0; i < count; i++)
            grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        // 构建难度项
        for (int i = 0; i < count; i++)
        {
            var item = vm.DifficultyItems[i];
            var (primaryColor, lightColor, stars) = DifficultyStyles[i];

            var card = CreateDifficultyCard(item, primaryColor, lightColor, stars, i + 1);
            grid.Add(card, 0, i);
        }
    }

    /// <summary>
    /// 创建难度卡片 - 参照 Flutter: _GlassCard + _buildDifficultyItem
    /// </summary>
    private Border CreateDifficultyCard(DifficultyDisplay item, Color primaryColor, Color lightColor, string stars, int index)
    {
        // 毛玻璃卡片
        var card = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(16) },
            BackgroundColor = GetGlassBackgroundColor(),
            Stroke = GetGlassBorderColor(),
            StrokeThickness = 1,
            Shadow = new Shadow
            {
                Brush = Colors.Black,
                Offset = new Point(0, 4),
                Radius = 10,
                Opacity = 0.08f,
            },
        };

        // 点击手势
        var tap = new TapGestureRecognizer();
        tap.Tapped += (_, _) =>
        {
            if (BindingContext is HomeViewModel vm)
                vm.SelectDifficultyCommand.Execute(item.Level);
        };
        card.GestureRecognizers.Add(tap);

        // 内容行 - 参照 Flutter: Row with number container + name/stars
        var content = new Grid
        {
            ColumnDefinitions =
            {
                new ColumnDefinition { Width = GridLength.Auto },
                new ColumnDefinition { Width = new GridLength(12) }, // spacing
                new ColumnDefinition { Width = GridLength.Star },
            },
            Padding = new Thickness(16, 8),
            VerticalOptions = LayoutOptions.Center,
        };

        // 序号容器 - 参照 Flutter: Container with primaryColor.withAlpha(25)
        var numBorder = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(10) },
            BackgroundColor = primaryColor.WithAlpha(Application.Current?.RequestedTheme == AppTheme.Dark ? 0.12f : 0.10f),
            WidthRequest = 36,
            VerticalOptions = LayoutOptions.Center,
            Content = new Label
            {
                Text = index.ToString(),
                FontSize = 14,
                FontAttributes = FontAttributes.Bold,
                TextColor = lightColor,
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
            }
        };
        content.Add(numBorder, 0, 0);

        // 名称和星级 - 参照 Flutter: Column with label and stars
        var infoLayout = new VerticalStackLayout
        {
            VerticalOptions = LayoutOptions.Center,
            Spacing = 2,
        };

        // 难度名称
        infoLayout.Add(new Label
        {
            Text = item.DisplayName,
            FontSize = 14,
            FontAttributes = FontAttributes.Bold,
            TextColor = Application.Current?.RequestedTheme == AppTheme.Dark
                ? Colors.White
                : Color.FromArgb("#1E1B4B"),
            LineBreakMode = LineBreakMode.TailTruncation,
        });

        // 星级
        infoLayout.Add(new Label
        {
            Text = stars,
            FontSize = 10,
            TextColor = Application.Current?.RequestedTheme == AppTheme.Dark
                ? Color.FromArgb("#64EAB308")
                : Color.FromArgb("#B4EAB308"),
        });

        content.Add(infoLayout, 2, 0);

        card.Content = content;
        return card;
    }

    #endregion

    #region 毛玻璃效果辅助方法

    /// <summary>
    /// 获取毛玻璃背景色 - 参照 Flutter: Colors.white.withAlpha(isDarkMode ? 8 : 70)
    /// </summary>
    private static Color GetGlassBackgroundColor()
    {
        return Application.Current?.RequestedTheme == AppTheme.Dark
            ? Color.FromArgb("#14FFFFFF")  // Dark: 8% white
            : Color.FromArgb("#46FFFFFF"); // Light: 27% white
    }

    /// <summary>
    /// 获取毛玻璃边框色 - 参照 Flutter: Colors.white.withAlpha(isDarkMode ? 10 : 120)
    /// </summary>
    private static Color GetGlassBorderColor()
    {
        return Application.Current?.RequestedTheme == AppTheme.Dark
            ? Color.FromArgb("#0AFFFFFF")  // Dark: 4% white
            : Color.FromArgb("#78FFFFFF"); // Light: 47% white
    }

    #endregion

    #region 动画 - 参照 Flutter: _buildStaggeredCard

    /// <summary>
    /// 卡片交错入场动画 - 参照 Flutter: _staggerController with delay
    /// </summary>
    private async void AnimateCardsEntry()
    {
        // 等待布局完成
        await Task.Delay(100);

        var grid = GameTypeGrid;
        if (grid.Children.Count == 0) return;

        int index = 0;
        foreach (var child in grid.Children)
        {
            if (child is Border card)
            {
                // 初始状态 - 参照 Flutter: Opacity(0), TranslateY(20), Scale(0.95)
                card.Opacity = 0;
                card.TranslationY = 20;
                card.Scale = 0.95;

                // 计算延迟 - 参照 Flutter: delay = index * 0.08 (80ms)
                var delay = index * 80;
                _ = HomePage.AnimateSingleCard(card, delay);
                index++;
            }
        }
    }

    /// <summary>
    /// 单个卡片动画 - 参照 Flutter: Curves.easeOut
    /// </summary>
    private static async Task AnimateSingleCard(Border card, int delayMs)
    {
        await Task.Delay(delayMs);

        // 并行执行多个动画
        var fadeTask = card.FadeToAsync(1, 300, Easing.CubicOut);
        var translateTask = card.TranslateToAsync(0, 0, 300, Easing.CubicOut);
        var scaleTask = card.ScaleToAsync(1.0, 300, Easing.CubicOut);

        await Task.WhenAll(fadeTask, translateTask, scaleTask);
    }

    #endregion
}
