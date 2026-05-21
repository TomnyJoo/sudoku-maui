using System.Windows.Input;
using Microsoft.Maui.Controls.Shapes;

namespace SudoKu.Controls;

/// <summary>
/// 功能键盘视图 - 使用MAUI原生控件实现3x3网格布局
/// </summary>
public partial class FunctionPadView : ContentView
{
    private readonly Grid _grid;
    private readonly Border[] _buttons = new Border[9];
    private readonly Image[] _icons = new Image[9];

    #region 可绑定属性

    public static readonly BindableProperty UndoCommandProperty;
    public static readonly BindableProperty RedoCommandProperty;
    public static readonly BindableProperty HintCommandProperty;
    public static readonly BindableProperty EraseCommandProperty;
    public static readonly BindableProperty ToggleMarkModeCommandProperty;
    public static readonly BindableProperty AutoMarkModeCommandProperty;
    public static readonly BindableProperty ShowSolutionCommandProperty;
    public static readonly BindableProperty ResetGameCommandProperty;
    public static readonly BindableProperty NewGameCommandProperty;

    public static readonly BindableProperty CanUndoProperty;
    public static readonly BindableProperty CanRedoProperty;
    public static readonly BindableProperty IsMarkModeProperty;
    public static readonly BindableProperty IsAutoMarkModeProperty;
    public static readonly BindableProperty IsShowingSolutionProperty;

    #endregion

    #region 属性

    public ICommand? UndoCommand { get => (ICommand?)GetValue(UndoCommandProperty); set => SetValue(UndoCommandProperty, value); }
    public ICommand? RedoCommand { get => (ICommand?)GetValue(RedoCommandProperty); set => SetValue(RedoCommandProperty, value); }
    public ICommand? HintCommand { get => (ICommand?)GetValue(HintCommandProperty); set => SetValue(HintCommandProperty, value); }
    public ICommand? EraseCommand { get => (ICommand?)GetValue(EraseCommandProperty); set => SetValue(EraseCommandProperty, value); }
    public ICommand? ToggleMarkModeCommand { get => (ICommand?)GetValue(ToggleMarkModeCommandProperty); set => SetValue(ToggleMarkModeCommandProperty, value); }
    public ICommand? AutoMarkModeCommand { get => (ICommand?)GetValue(AutoMarkModeCommandProperty); set => SetValue(AutoMarkModeCommandProperty, value); }
    public ICommand? ShowSolutionCommand { get => (ICommand?)GetValue(ShowSolutionCommandProperty); set => SetValue(ShowSolutionCommandProperty, value); }
    public ICommand? ResetGameCommand { get => (ICommand?)GetValue(ResetGameCommandProperty); set => SetValue(ResetGameCommandProperty, value); }
    public ICommand? NewGameCommand { get => (ICommand?)GetValue(NewGameCommandProperty); set => SetValue(NewGameCommandProperty, value); }
    public bool CanUndo { get => (bool)GetValue(CanUndoProperty); set => SetValue(CanUndoProperty, value); }
    public bool CanRedo { get => (bool)GetValue(CanRedoProperty); set => SetValue(CanRedoProperty, value); }
    public bool IsMarkMode { get => (bool)GetValue(IsMarkModeProperty); set => SetValue(IsMarkModeProperty, value); }
    public bool IsAutoMarkMode { get => (bool)GetValue(IsAutoMarkModeProperty); set => SetValue(IsAutoMarkModeProperty, value); }
    public bool IsShowingSolution { get => (bool)GetValue(IsShowingSolutionProperty); set => SetValue(IsShowingSolutionProperty, value); }

    #endregion

    // 按钮图标文件名（使用.png扩展名）
    private static readonly string[] ButtonIcons =
    [
        "undo.png", "redo.png", "lightbulb_outline.png",   // 撤销、重做、提示
        "edit.png", "auto_fix_high.png", "clear.png",       // 笔记、自动笔记、清除
        "visibility.png", "refresh.png", "add.png"           // 答案、重置、新游戏
    ];

    private bool _isInitialized;
    private bool _isHandlerAttached;

    /// <summary>
    /// 静态构造函数 - 在类首次加载时执行，添加异常处理
    /// </summary>
    static FunctionPadView()
    {
        try
        {
            UndoCommandProperty = BindableProperty.Create(
                nameof(UndoCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            RedoCommandProperty = BindableProperty.Create(
                nameof(RedoCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            HintCommandProperty = BindableProperty.Create(
                nameof(HintCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            EraseCommandProperty = BindableProperty.Create(
                nameof(EraseCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            ToggleMarkModeCommandProperty = BindableProperty.Create(
                nameof(ToggleMarkModeCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            AutoMarkModeCommandProperty = BindableProperty.Create(
                nameof(AutoMarkModeCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            ShowSolutionCommandProperty = BindableProperty.Create(
                nameof(ShowSolutionCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            ResetGameCommandProperty = BindableProperty.Create(
                nameof(ResetGameCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            NewGameCommandProperty = BindableProperty.Create(
                nameof(NewGameCommand), 
                typeof(ICommand), 
                typeof(FunctionPadView), 
                null);

            CanUndoProperty = BindableProperty.Create(
                nameof(CanUndo), 
                typeof(bool), 
                typeof(FunctionPadView), 
                false);

            CanRedoProperty = BindableProperty.Create(
                nameof(CanRedo), 
                typeof(bool), 
                typeof(FunctionPadView), 
                false);

            IsMarkModeProperty = BindableProperty.Create(
                nameof(IsMarkMode), 
                typeof(bool), 
                typeof(FunctionPadView), 
                false);

            IsAutoMarkModeProperty = BindableProperty.Create(
                nameof(IsAutoMarkMode), 
                typeof(bool), 
                typeof(FunctionPadView), 
                false);

            IsShowingSolutionProperty = BindableProperty.Create(
                nameof(IsShowingSolution), 
                typeof(bool), 
                typeof(FunctionPadView), 
                false);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"FunctionPadView static constructor failed: {ex.Message}");
            throw;
        }
    }

    public FunctionPadView()
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

        for (int i = 0; i < 9; i++)
        {
            int row = i / 3;
            int col = i % 3;
            var button = CreateFunctionButton(ButtonIcons[i], i);
            _buttons[i] = button;
            _grid.Add(button, col, row);
        }

        Content = _grid;
        BackgroundColor = Colors.Transparent;
        _isInitialized = true;
    }

    protected override void OnHandlerChanged()
    {
        base.OnHandlerChanged();
        
        if (Handler != null && !_isHandlerAttached)
        {
            _isHandlerAttached = true;
            InitializeVisualState();
        }
    }

    private void InitializeVisualState()
    {
        try
        {
            _buttons[0].Opacity = CanUndo ? 1.0 : 0.4;
            _buttons[1].Opacity = CanRedo ? 1.0 : 0.4;
            UpdateMarkModeButton();
            UpdateAutoMarkModeButton();
            UpdateShowSolutionButton();
            UpdateButtonStatesForSolutionMode();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"FunctionPadView.InitializeVisualState failed: {ex.Message}");
        }
    }

    private Border CreateFunctionButton(string icon, int index)
    {
        var button = new Border
        {
            StrokeShape = new RoundRectangle { CornerRadius = new CornerRadius(10) },
            Padding = 0,
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1").WithAlpha(0.2f), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8").WithAlpha(0.2f), 1.0f),
                }
            },
            Shadow = new Shadow { Brush = Colors.Black, Offset = new Point(0.0, 2.0), Radius = 4, Opacity = 0.2f },
        };

        var iconImage = new Image
        {
            Source = icon,
            WidthRequest = 20,
            HeightRequest = 20,
            HorizontalOptions = LayoutOptions.Center,
            VerticalOptions = LayoutOptions.Center,
        };

        var tintBehavior = new CommunityToolkit.Maui.Behaviors.IconTintColorBehavior
        {
            TintColor = Colors.Blue,
        };
        iconImage.Behaviors.Add(tintBehavior);

        _icons[index] = iconImage;
        button.Content = iconImage;

        var tap = new TapGestureRecognizer();
        tap.Tapped += (_, _) => OnButtonTapped(index);
        button.GestureRecognizers.Add(tap);

        return button;
    }

    private void OnButtonTapped(int index)
    {
        if (index < 0 || index >= _buttons.Length || !_buttons[index].IsEnabled)
            return;

        var command = index switch
        {
            0 => UndoCommand,
            1 => RedoCommand,
            2 => HintCommand,
            3 => ToggleMarkModeCommand,
            4 => AutoMarkModeCommand,
            5 => EraseCommand,
            6 => ShowSolutionCommand,
            7 => ResetGameCommand,
            8 => NewGameCommand,
            _ => null
        };
        if (command?.CanExecute(null) == true)
            command.Execute(null);
    }

    protected override void OnPropertyChanged(string? propertyName = null)
    {
        base.OnPropertyChanged(propertyName);
        if (!_isInitialized) return;

        if (propertyName == nameof(CanUndo))
            _buttons[0].Opacity = CanUndo ? 1.0 : 0.4;
        else if (propertyName == nameof(CanRedo))
            _buttons[1].Opacity = CanRedo ? 1.0 : 0.4;
        else if (propertyName == nameof(IsMarkMode))
            UpdateMarkModeButton();
        else if (propertyName == nameof(IsAutoMarkMode))
            UpdateAutoMarkModeButton();
        else if (propertyName == nameof(IsShowingSolution))
        {
            UpdateShowSolutionButton();
            UpdateButtonStatesForSolutionMode();
        }
    }

    private void UpdateShowSolutionButton()
    {
        var button = _buttons[6];
        if (IsShowingSolution)
        {
            button.Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1"), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8"), 1.0f),
                }
            };
        }
        else
        {
            button.Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1").WithAlpha(0.2f), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8").WithAlpha(0.2f), 1.0f),
                }
            };
        }
    }

    private void UpdateButtonStatesForSolutionMode()
    {
        if (IsShowingSolution)
        {
            for (int i = 0; i < _buttons.Length; i++)
            {
                if (i == 6 || i == 7 || i == 8)
                {
                    _buttons[i].Opacity = 1.0;
                    _buttons[i].IsEnabled = true;
                }
                else
                {
                    _buttons[i].Opacity = 0.4;
                    _buttons[i].IsEnabled = false;
                }
            }
        }
        else
        {
            for (int i = 0; i < _buttons.Length; i++)
            {
                _buttons[i].Opacity = 1.0;
                _buttons[i].IsEnabled = true;
            }
            _buttons[0].Opacity = CanUndo ? 1.0 : 0.4;
            _buttons[1].Opacity = CanRedo ? 1.0 : 0.4;
        }
    }

    private void UpdateMarkModeButton()
    {
        var button = _buttons[3];
        if (IsMarkMode)
        {
            button.Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1"), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8"), 1.0f),
                }
            };
        }
        else
        {
            button.Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1").WithAlpha(0.2f), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8").WithAlpha(0.2f), 1.0f),
                }
            };
        }
    }

    private void UpdateAutoMarkModeButton()
    {
        var button = _buttons[4];
        if (IsAutoMarkMode)
        {
            button.Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1"), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8"), 1.0f),
                }
            };
        }
        else
        {
            button.Background = new LinearGradientBrush
            {
                EndPoint = new Point(1.0, 0.0),
                GradientStops =
                {
                    new GradientStop(Color.FromArgb("#6366F1").WithAlpha(0.2f), 0.0f),
                    new GradientStop(Color.FromArgb("#818CF8").WithAlpha(0.2f), 1.0f),
                }
            };
        }
    }

    public static void UpdateCommands() { }
}
