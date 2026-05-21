using Microsoft.Maui.Layouts;
using SudoKu.Controls;
using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.ViewModels;

namespace SudoKu.Views;

/// <summary>
/// 统一游戏屏幕页面。
/// 通过构造函数参数接收游戏类型配置，支持所有6种游戏类型。
/// 使用AbsoluteLayout实现精确的Stack+Positioned布局。
/// </summary>
public partial class GamePage : ContentPage, IQueryAttributable
{
    private readonly GameViewModel? _viewModel;
    private SudokuBoardView? _boardView;
    private KillerCageOverlay? _cageOverlay;
    private RegionBorderView? _regionBorderView;
    private DiagonalOverlayView? _diagonalOverlay;
    private KeyboardAreaView? _keyboardView;
    private IDictionary<string, object>? _pendingParameters;

    // ========== 布局状态  ==========
    private double _lastLayoutWidth;
    private double _lastLayoutHeight;
    private bool _isLayoutPending;

    /// <summary>
    /// 初始化游戏页面的新实例。
    /// </summary>
    public GamePage()
    {
        InitializeComponent();
        BindingContext = App.Current?.Handler?.MauiContext?.Services.GetRequiredService<GameViewModel>();
        _viewModel = BindingContext as GameViewModel;
        _viewModel!.PropertyChanged += OnViewModelPropertyChanged;

        // 使用SizeChanged事件确保布局在尺寸真正可用时计算
        DynamicArea.SizeChanged += OnDynamicAreaSizeChanged;
    }

    /// <summary>
    /// 应用导航查询参数。
    /// </summary>
    /// <param name="query">导航参数字典。</param>
    public void ApplyQueryAttributes(IDictionary<string, object> query)
    {
        _pendingParameters = new Dictionary<string, object>(query);
    }

    /// <summary>
    /// 页面导航完成后初始化游戏。
    /// </summary>
    protected override async void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);
        
        if (_viewModel != null)
        {
            await _viewModel.HandleNavigatedToAsync(_pendingParameters);
            _pendingParameters = null;
        }

        if (_viewModel != null && !_viewModel.IsGenerating)
        {
            if (_boardView == null || _keyboardView == null)
            {
                CreateBoardAndKeyboard();
            }
            
            // 延迟布局计算，确保视图已加载且尺寸可用
            _isLayoutPending = true;
            await Task.Delay(100);
            await Dispatcher.DispatchAsync(() => LayoutDynamicArea(true));
        }
    }

    /// <summary>
    /// 页面即将离开时保存游戏状态。
    /// </summary>
    protected override void OnNavigatedFrom(NavigatedFromEventArgs args)
    {
        base.OnNavigatedFrom(args);
        _viewModel?.HandleNavigatedFrom();
    }

    /// <summary>
    /// 动态区域尺寸变化时重新计算布局。
    /// </summary>
    private void OnDynamicAreaSizeChanged(object? sender, EventArgs e)
    {
        if (_isLayoutPending || (_boardView != null && _keyboardView != null))
        {
            LayoutDynamicArea(false);
        }
    }

    /// <summary>
    /// 页面尺寸分配时重新计算布局。
    /// </summary>
    protected override void OnSizeAllocated(double width, double height)
    {
        base.OnSizeAllocated(width, height);
        // 只在尺寸显著变化时重新布局
        if (width > 0 && height > 0 &&
            (Math.Abs(width - _lastLayoutWidth) > 5 || Math.Abs(height - _lastLayoutHeight) > 5))
        {
            _isLayoutPending = true;
            LayoutDynamicArea(false);
        }
    }

    /// <summary>
    /// ViewModel属性变化时更新视图。
    /// </summary>
    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(GameViewModel.Board))
        {
            UpdateBoardView();
            // 棋盘变化后重新布局
            _isLayoutPending = true;
            Dispatcher.DispatchAsync(() => LayoutDynamicArea(true));
        }
        else if (e.PropertyName == nameof(GameViewModel.IsGenerating))
        {
            // 当正在生成时隐藏棋盘和键盘；生成结束后显示并确保创建视图
            if (_viewModel == null) return;
            var isGen = _viewModel.IsGenerating;
            // 在UI线程执行可见性与交互切换，确保视觉上完全不可见并且不接收输入
            Dispatcher.Dispatch(() =>
            {
                BoardContainer.IsVisible = !isGen;
                KeyboardContainer.IsVisible = !isGen;
                BoardContainer.InputTransparent = isGen;
                KeyboardContainer.InputTransparent = isGen;
                BoardContainer.IsEnabled = !isGen;
                KeyboardContainer.IsEnabled = !isGen;
                BoardContainer.Opacity = isGen ? 0 : 1;
                KeyboardContainer.Opacity = isGen ? 0 : 1;
            });

            if (!isGen)
            {
                // 生成完成，确保创建并布局棋盘/键盘
                Dispatcher.DispatchAsync(() =>
                {
                    if (_boardView == null || _keyboardView == null)
                    {
                        CreateBoardAndKeyboard();
                        _isLayoutPending = true;
                        _ = Task.Delay(50).ContinueWith(_ => Dispatcher.DispatchAsync(() => LayoutDynamicArea(true)));
                    }
                });
            }
        }
    }

    /// <summary>
    /// 创建棋盘和键盘视图。
    /// </summary>
    private void CreateBoardAndKeyboard()
    {
        if (_boardView == null)
        {
            // UnifiedBoardWidget
            _boardView = new SudokuBoardView();
            _boardView.SetBinding(SudokuBoardView.SelectedCellCommandProperty,
                new Binding(nameof(GameViewModel.SelectCellCommand), source: _viewModel));
            _boardView.SetBinding(SudokuBoardView.BoardProperty,
                new Binding(nameof(GameViewModel.Board), source: _viewModel));
            _boardView.SetBinding(SudokuBoardView.GameTypeProperty,
                new Binding(nameof(GameViewModel.GameType), source: _viewModel));
            _boardView.SetBinding(SudokuBoardView.IsShowingSolutionProperty,
                new Binding(nameof(GameViewModel.IsShowingSolution), source: _viewModel));
            _boardView.SetBinding(SudokuBoardView.SolutionBoardProperty,
                new Binding(nameof(GameViewModel.SolutionBoard), source: _viewModel));
            _boardView.SetBinding(SudokuBoardView.SelectedCellProperty,
                new Binding(nameof(GameViewModel.SelectedCell), source: _viewModel));
            BoardContainer.Children.Add(_boardView);

            // Killer笼子覆盖层
            _cageOverlay = new KillerCageOverlay();
            BoardContainer.Children.Add(_cageOverlay);

            // Jigsaw区域边框视图
            _regionBorderView = new RegionBorderView { RegionTypeFilter = RegionType.Jigsaw };
            BoardContainer.Children.Add(_regionBorderView);

            // Diagonal对角线覆盖层
            _diagonalOverlay = new DiagonalOverlayView();
            BoardContainer.Children.Add(_diagonalOverlay);
        }

        if (_keyboardView == null)
        {
            var numberPad = new NumberPadView();
            numberPad.SetBinding(NumberPadView.InputNumberCommandProperty,
                new Binding(nameof(GameViewModel.InputNumberCommand), source: _viewModel));
            numberPad.SetBinding(NumberPadView.NumberCountsProperty,
                new Binding(nameof(GameViewModel.NumberCounts), source: _viewModel));
            numberPad.SetBinding(NumberPadView.MaxCountProperty,
                new Binding(nameof(GameViewModel.MaxNumberCount), source: _viewModel));

            var functionPad = new FunctionPadView();
            functionPad.SetBinding(FunctionPadView.UndoCommandProperty,
                new Binding(nameof(GameViewModel.UndoCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.RedoCommandProperty,
                new Binding(nameof(GameViewModel.RedoCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.HintCommandProperty,
                new Binding(nameof(GameViewModel.HintCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.EraseCommandProperty,
                new Binding(nameof(GameViewModel.EraseCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.ToggleMarkModeCommandProperty,
                new Binding(nameof(GameViewModel.ToggleMarkModeCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.AutoMarkModeCommandProperty,
                new Binding(nameof(GameViewModel.ToggleAutoMarkModeCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.ShowSolutionCommandProperty,
                new Binding(nameof(GameViewModel.ShowSolutionCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.ResetGameCommandProperty,
                new Binding(nameof(GameViewModel.ResetGameCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.NewGameCommandProperty,
                new Binding(nameof(GameViewModel.NewGameCommand), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.CanUndoProperty,
                new Binding(nameof(GameViewModel.CanUndo), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.CanRedoProperty,
                new Binding(nameof(GameViewModel.CanRedo), source: _viewModel));
            functionPad.SetBinding(FunctionPadView.IsMarkModeProperty,
                new Binding(nameof(GameViewModel.IsMarkMode), source: _viewModel, mode: BindingMode.TwoWay));
            functionPad.SetBinding(FunctionPadView.IsAutoMarkModeProperty,
                new Binding(nameof(GameViewModel.IsAutoMarkMode), source: _viewModel, mode: BindingMode.TwoWay));
            functionPad.SetBinding(FunctionPadView.IsShowingSolutionProperty,
                new Binding(nameof(GameViewModel.IsShowingSolution), source: _viewModel, mode: BindingMode.TwoWay));

            _keyboardView = new KeyboardAreaView
            {
                NumberPad = numberPad,
                FunctionPad = functionPad
            };
            KeyboardContainer.Children.Add(_keyboardView);
        }

        UpdateBoardView();
    }

    /// <summary>
    /// 更新棋盘视图数据绑定。
    /// </summary>
    private void UpdateBoardView()
    {
        if (_boardView == null || _viewModel?.Board == null) return;

        // Board 和 GameType 已通过绑定更新，这里只需更新覆盖层和子网格属性
        _boardView.SetBinding(SudokuBoardView.CurrentSubGridIndexProperty,
            new Binding(nameof(GameViewModel.CurrentSubGridIndex), source: _viewModel, mode: BindingMode.TwoWay));
        _boardView.SetBinding(SudokuBoardView.IsOverviewModeProperty,
            new Binding(nameof(GameViewModel.IsOverviewMode), source: _viewModel, mode: BindingMode.TwoWay));

        var gameType = _viewModel.CurrentState?.GameType ?? GameType.Standard;

        // Killer笼子覆盖层
        if (_cageOverlay != null)
        {
            _cageOverlay.IsVisible = gameType == GameType.Killer;
            if (gameType == GameType.Killer)
            {
                _cageOverlay.Regions = [.. _viewModel.Board.Regions];
                _cageOverlay.BoardSize = _viewModel.Board.Size;
            }
        }

        // Jigsaw区域边界视图
        if (_regionBorderView != null)
        {
            _regionBorderView.IsVisible = gameType == GameType.Jigsaw;
            if (gameType == GameType.Jigsaw)
            {
                _regionBorderView.Regions = [.. _viewModel.Board.Regions];
                _regionBorderView.BoardSize = _viewModel.Board.Size;
                _regionBorderView.SetBinding(RegionBorderView.ShowRegionNumbersProperty,
                    new Binding(nameof(GameViewModel.ShowRegionNumbers), source: _viewModel, mode: BindingMode.OneWay));
            }
        }

        // Diagonal对角线覆盖层
        if (_diagonalOverlay != null)
        {
            _diagonalOverlay.IsVisible = gameType == GameType.Diagonal;
            if (gameType == GameType.Diagonal)
            {
                _diagonalOverlay.BoardSize = _viewModel.Board.Size;
                _diagonalOverlay.SetBinding(DiagonalOverlayView.ShowDiagonalLinesProperty,
                    new Binding(nameof(GameViewModel.ShowDiagonalLines), source: _viewModel, mode: BindingMode.OneWay));
            }
        }
    }

    /// <summary>
    /// 动态布局计算
    /// </summary>
    /// <param name="forceRecalc">是否强制重新计算。</param>
    private void LayoutDynamicArea(bool forceRecalc)
    {
        double availableWidth = DynamicArea.Width;
        double availableHeight = DynamicArea.Height;

        if (availableWidth <= 0 || availableHeight <= 0)
        {
            _isLayoutPending = true;
            return;
        }

        // 防止过于频繁的布局计算
        if (!forceRecalc &&
            Math.Abs(availableWidth - _lastLayoutWidth) < 2 &&
            Math.Abs(availableHeight - _lastLayoutHeight) < 2)
        {
            return;
        }

        _lastLayoutWidth = availableWidth;
        _lastLayoutHeight = availableHeight;
        _isLayoutPending = false;

        if (_boardView == null || _keyboardView == null) return;

        bool isHorizontal = availableWidth >= availableHeight;

        GameLayout layout;
        if (_viewModel?.IsSamuraiGame == true && _viewModel.IsOverviewMode)
        {
            layout = LayoutCalculator.CalculateSamuraiLayout(availableWidth, availableHeight, true);
        }
        else
        {
            layout = LayoutCalculator.CalculateStandardLayout(availableWidth, availableHeight, isHorizontal);
        }

        AbsoluteLayout.SetLayoutBounds(BoardContainer, new Rect(layout.BoardX, layout.BoardY, layout.BoardSize, layout.BoardSize));
        AbsoluteLayout.SetLayoutFlags(BoardContainer, AbsoluteLayoutFlags.None);

        AbsoluteLayout.SetLayoutBounds(KeyboardContainer, new Rect(layout.KeypadX, layout.KeypadY, layout.KeypadWidth, layout.KeypadHeight));
        AbsoluteLayout.SetLayoutFlags(KeyboardContainer, AbsoluteLayoutFlags.None);

        // 设置尺寸
        _boardView.WidthRequest = layout.BoardSize;
        _boardView.HeightRequest = layout.BoardSize;
        if (_cageOverlay != null) { _cageOverlay.WidthRequest = layout.BoardSize; _cageOverlay.HeightRequest = layout.BoardSize; }
        if (_regionBorderView != null) { _regionBorderView.WidthRequest = layout.BoardSize; _regionBorderView.HeightRequest = layout.BoardSize; }
        if (_diagonalOverlay != null) { _diagonalOverlay.WidthRequest = layout.BoardSize; _diagonalOverlay.HeightRequest = layout.BoardSize; }

        _keyboardView.WidthRequest = layout.KeypadWidth;
        _keyboardView.HeightRequest = layout.KeypadHeight;

        //  横屏时数字键盘在上、功能键盘在下；竖屏时数字键盘在左、功能键盘在右
        _keyboardView.SetLayoutOrientation(isHorizontal);
    }

    /// <summary>
    /// 页面消失时保存游戏状态。
    /// </summary>
    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        // 游戏状态由ViewModel自动管理
    }

    /// <summary>
    /// 页面销毁时清理资源。
    /// </summary>
    protected override void OnHandlerChanged()
    {
        base.OnHandlerChanged();
        _viewModel?.PropertyChanged -= OnViewModelPropertyChanged;
    }
}
