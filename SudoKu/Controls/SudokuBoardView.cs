namespace SudoKu.Controls;

using System.Windows.Input;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Layouts;
using SudoKu.Controls.Renderers;
using SudoKu.Models;
using SudoKu.Models.Boards;

/// <summary>
/// 数独棋盘视图控件
/// 使用 Grid 布局渲染数独棋盘的所有单元格
/// 支持多种游戏类型和选中的单元格交互
/// 采用渲染器模式，每种游戏类型使用特定的渲染器
/// </summary>
public partial class SudokuBoardView : ContentView
{
    protected readonly Grid _boardGrid = null!;
    protected readonly GridLineOverlay _gridLineOverlay;
    protected readonly KillerCageOverlay? _killerCageOverlay;
    protected readonly KillerCageBackgroundOverlay? _killerCageBackgroundOverlay;
    private readonly AbsoluteLayout _overlayLayout;
    private readonly TapGestureRecognizer _boardTapGesture;

    private int _currentBoardSize = 9;
    private IBoardRenderer _renderer = null!;
    
    // 武士数独偏移量，用于子盘模式下的点击处理
    private int _samuraiOffsetRow = 0;
    private int _samuraiOffsetCol = 0;
    
    /// <summary>
    /// 设置武士数独子盘偏移量
    /// </summary>
    public void SetSamuraiOffset(int row, int col)
    {
        _samuraiOffsetRow = row;
        _samuraiOffsetCol = col;
    }
    
    /// <summary>
    /// 设置网格线覆盖层属性
    /// </summary>
    public void SetGridLineOverlayProperties(GameType gameType, int boardSize, bool isDarkTheme)
    {
        _gridLineOverlay.GameType = gameType;
        _gridLineOverlay.BoardSize = boardSize;
        _gridLineOverlay.IsDarkTheme = isDarkTheme;
    }
    
    /// <summary>
    /// 设置杀手数独覆盖层可见性
    /// </summary>
    public void SetKillerOverlaysVisible(bool visible)
    {
        _killerCageOverlay?.IsVisible = visible;
        _killerCageBackgroundOverlay?.IsVisible = visible;
    }

    #region 可绑定属性
    public static readonly BindableProperty BoardProperty =
        BindableProperty.Create(nameof(Board), typeof(Board), typeof(SudokuBoardView), null,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty GameTypeProperty =
        BindableProperty.Create(nameof(GameType), typeof(GameType), typeof(SudokuBoardView), GameType.Standard,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty SelectedCellCommandProperty =
        BindableProperty.Create(nameof(SelectedCellCommand), typeof(ICommand), typeof(SudokuBoardView), null);

    public static readonly BindableProperty SelectedCellProperty =
        BindableProperty.Create(nameof(SelectedCell), typeof(SudokuCell), typeof(SudokuBoardView), null,
            propertyChanged: OnSelectedCellChanged);

    public static readonly BindableProperty CurrentSubGridIndexProperty =
        BindableProperty.Create(nameof(CurrentSubGridIndex), typeof(int), typeof(SudokuBoardView), 0,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty IsOverviewModeProperty =
        BindableProperty.Create(nameof(IsOverviewMode), typeof(bool), typeof(SudokuBoardView), false,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty ShowDiagonalLinesProperty =
        BindableProperty.Create(nameof(ShowDiagonalLines), typeof(bool), typeof(SudokuBoardView), true,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty ShowRegionNumbersProperty =
        BindableProperty.Create(nameof(ShowRegionNumbers), typeof(bool), typeof(SudokuBoardView), true,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty ShowCageSumsProperty =
        BindableProperty.Create(nameof(ShowCageSums), typeof(bool), typeof(SudokuBoardView), true,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty ShowCagesProperty =
        BindableProperty.Create(nameof(ShowCages), typeof(bool), typeof(SudokuBoardView), true,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty HighlightMistakesEnabledProperty =
        BindableProperty.Create(nameof(HighlightMistakesEnabled), typeof(bool), typeof(SudokuBoardView), true,
            propertyChanged: OnBoardChanged);

    public static readonly BindableProperty IsShowingSolutionProperty =
        BindableProperty.Create(nameof(IsShowingSolution), typeof(bool), typeof(SudokuBoardView), false,
            propertyChanged: OnSolutionChanged);

    public static readonly BindableProperty SolutionBoardProperty =
        BindableProperty.Create(nameof(SolutionBoard), typeof(Board), typeof(SudokuBoardView), null);
    #endregion

    #region 属性
    /// <summary>
    /// 是否正在显示答案
    /// </summary>
    public bool IsShowingSolution
    {
        get => (bool)GetValue(IsShowingSolutionProperty);
        set => SetValue(IsShowingSolutionProperty, value);
    }

    /// <summary>
    ///  答案面板
    /// </summary>
    public Board? SolutionBoard
    {
        get => (Board?)GetValue(SolutionBoardProperty);
        set => SetValue(SolutionBoardProperty, value);
    }

    /// <summary>
    /// 是否概览模式（武士数独）
    /// </summary>
    public bool IsOverviewMode
    {
        get => (bool)GetValue(IsOverviewModeProperty);
        set => SetValue(IsOverviewModeProperty, value);
    }

    public Board? Board
    {
        get => (Board?)GetValue(BoardProperty);
        set => SetValue(BoardProperty, value);
    }

    public GameType GameType
    {
        get => (GameType)GetValue(GameTypeProperty);
        set => SetValue(GameTypeProperty, value);
    }

    public ICommand? SelectedCellCommand
    {
        get => (ICommand?)GetValue(SelectedCellCommandProperty);
        set => SetValue(SelectedCellCommandProperty, value);
    }

    public SudokuCell? SelectedCell
    {
        get => (SudokuCell?)GetValue(SelectedCellProperty);
        set => SetValue(SelectedCellProperty, value);
    }

    public int CurrentSubGridIndex
    {
        get => (int)GetValue(CurrentSubGridIndexProperty);
        set => SetValue(CurrentSubGridIndexProperty, value);
    }

    public bool ShowDiagonalLines
    {
        get => (bool)GetValue(ShowDiagonalLinesProperty);
        set => SetValue(ShowDiagonalLinesProperty, value);
    }

    public bool ShowRegionNumbers
    {
        get => (bool)GetValue(ShowRegionNumbersProperty);
        set => SetValue(ShowRegionNumbersProperty, value);
    }

    public bool ShowCageSums
    {
        get => (bool)GetValue(ShowCageSumsProperty);
        set => SetValue(ShowCageSumsProperty, value);
    }

    public bool ShowCages
    {
        get => (bool)GetValue(ShowCagesProperty);
        set => SetValue(ShowCagesProperty, value);
    }

    public bool HighlightMistakesEnabled
    {
        get => (bool)GetValue(HighlightMistakesEnabledProperty);
        set => SetValue(HighlightMistakesEnabledProperty, value);
    }
    #endregion

    public SudokuBoardView()
    {
        HorizontalOptions = LayoutOptions.Fill;
        VerticalOptions = LayoutOptions.Fill;

        _renderer = BoardRendererFactory.GetRenderer(GameType);

        _boardGrid = new Grid
        {
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            RowSpacing = 0,
            ColumnSpacing = 0,
            BackgroundColor = Colors.Transparent
        };


        _gridLineOverlay = new GridLineOverlay();
        _killerCageOverlay = new KillerCageOverlay();

        _overlayLayout = new AbsoluteLayout
        {
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            BackgroundColor = Colors.Transparent
        };


        _boardTapGesture = new TapGestureRecognizer();
        _boardTapGesture.Tapped += OnBoardTapped;
        _overlayLayout.GestureRecognizers.Add(_boardTapGesture);


        AbsoluteLayout.SetLayoutBounds(_boardGrid, new Rect(0, 0, 1, 1));
        AbsoluteLayout.SetLayoutFlags(_boardGrid, AbsoluteLayoutFlags.All);
        _overlayLayout.Children.Add(_boardGrid);


        _killerCageBackgroundOverlay = new KillerCageBackgroundOverlay();
        AbsoluteLayout.SetLayoutBounds(_killerCageBackgroundOverlay, new Rect(0, 0, 1, 1));
        AbsoluteLayout.SetLayoutFlags(_killerCageBackgroundOverlay, AbsoluteLayoutFlags.All);
        _overlayLayout.Children.Add(_killerCageBackgroundOverlay);


        AbsoluteLayout.SetLayoutBounds(_gridLineOverlay, new Rect(0, 0, 1, 1));
        AbsoluteLayout.SetLayoutFlags(_gridLineOverlay, AbsoluteLayoutFlags.All);
        _overlayLayout.Children.Add(_gridLineOverlay);


        AbsoluteLayout.SetLayoutBounds(_killerCageOverlay, new Rect(0, 0, 1, 1));
        AbsoluteLayout.SetLayoutFlags(_killerCageOverlay, AbsoluteLayoutFlags.All);
        _overlayLayout.Children.Add(_killerCageOverlay);

        Content = _overlayLayout;

        BackgroundColor = (Color)Application.Current!.Resources["BoardBackgroundColor"];
        Padding = 2;
    }

    private void OnBoardTapped(object? sender, TappedEventArgs e)
    {
        if (Board is null) return;

        var tapPosition = e.GetPosition(_overlayLayout);
        if (tapPosition is null) return;

        var position = tapPosition.Value;
        var bounds = _overlayLayout.Bounds;


        double cellWidth = bounds.Width / _currentBoardSize;
        double cellHeight = bounds.Height / _currentBoardSize;


        int col = (int)(position.X / cellWidth);
        int row = (int)(position.Y / cellHeight);


        if (row < 0 || row >= _currentBoardSize || col < 0 || col >= _currentBoardSize)
            return;

        // 武士数独特殊处理
        if (GameType == GameType.Samurai)
        {
            if (IsOverviewMode)
            {
                // 概览模式，使用渲染器处理点击切换子盘
                if (_renderer.HandleSpecialTap(this, row, col, Board))
                    return;
            }
            else
            {
                // 子盘模式，需要加上偏移量
                row += _samuraiOffsetRow;
                col += _samuraiOffsetCol;
            }
        }

        if (row < 0 || row >= Board.Size || col < 0 || col >= Board.Size)
            return;

        var cmd = SelectedCellCommand;
        var actualCell = Board?.GetCell(row, col);
        if (cmd?.CanExecute(actualCell) == true && actualCell != null)
        {
            cmd.Execute(actualCell);
        }
    }

    private static void OnBoardChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is SudokuBoardView view)
        {

            if (oldValue is Board oldBoard && newValue is Board newBoard &&
                oldBoard.Size == newBoard.Size && oldBoard.GameType == newBoard.GameType)
            {
                view.UpdateChangedCells(oldBoard, newBoard);
            }
            else
            {

                view._renderer = BoardRendererFactory.GetRenderer(view.GameType);
                view._renderer.UpdateGridSize(view._boardGrid, view.Board?.Size ?? 9);
                view.BuildBoard();
            }
        }
    }

    private static void OnSelectedCellChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is SudokuBoardView view && view.Board != null)
        {
            view.UpdateAllCells();
        }
    }

    private void UpdateChangedCells(Board oldBoard, Board newBoard)
    {
        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;
        
        if (oldBoard.Size != newBoard.Size)
        {
            BuildBoard();
            return;
        }

        _renderer.UpdateChangedCells(this, oldBoard, newBoard, isDark);
    }

    private static void OnSolutionChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is SudokuBoardView view && view.Board != null)
        {
            view._renderer.UpdateAllCellsForSolution(view, view.Board);
        }
    }

    private void UpdateAllCells()
    {
        if (Board == null) return;
        
        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;
        _renderer.UpdateAllCells(this, Board, isDark);
    }

    private void BuildBoard()
    {
        _boardGrid.Children.Clear();
        _boardGrid.RowDefinitions.Clear();
        _boardGrid.ColumnDefinitions.Clear();

        if (Board is null) return;

        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;

        // 让渲染器设置视图属性（特别是武士数独需要特殊处理）
        _renderer.SetupViewProperties(this, Board);

        // 对于非武士数独，设置通用的网格线属性
        if (GameType != GameType.Samurai)
        {
            _gridLineOverlay.GameType = GameType;
            _gridLineOverlay.BoardSize = Board.Size;
            _gridLineOverlay.IsDarkTheme = isDark;
        }


        var cageRegions = Board.Regions.Where(r => r.Type == RegionType.Cage).ToList();
        _killerCageBackgroundOverlay!.Regions = cageRegions;
        _killerCageBackgroundOverlay.BoardSize = Board.Size;
        _killerCageBackgroundOverlay.IsVisible = GameType == GameType.Killer;



        _killerCageOverlay!.Regions = cageRegions;
        _killerCageOverlay.BoardSize = Board.Size;
        _killerCageOverlay.IsVisible = GameType == GameType.Killer && ShowCages;


        if (GameType == GameType.Killer && ShowCages)
        {
            _killerCageOverlay.Invalidate();
        }

        _currentBoardSize = _renderer.GetDisplaySize(this, Board);
        _renderer.UpdateGridSize(_boardGrid, Board.Size);
        _renderer.BuildBoard(this, Board, _boardGrid, isDark);
    }
}

