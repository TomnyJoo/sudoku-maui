namespace SudoKu.Controls;

using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

/// <summary>
/// 键盘区域视图 - 组合数字键盘和功能键盘，支持横竖屏布局切换
/// 纯布局容器，不处理任何数据绑定，子控件直接绑定到 ViewModel
/// </summary>
public partial class KeyboardAreaView : ContentView
{
    private Grid? _layoutGrid;
    private NumberPadView? _numberPad;
    private FunctionPadView? _functionPad;
    private bool? _currentOrientation;
    private bool _isHandlerAttached;

    public static readonly BindableProperty NumberPadProperty = BindableProperty.Create(
        nameof(NumberPad), typeof(NumberPadView), typeof(KeyboardAreaView), null,
        propertyChanged: (bindable, oldValue, newValue) => 
        {
            if (bindable is KeyboardAreaView view && newValue is NumberPadView pad)
            {
                view._numberPad = pad;
            }
        });

    public static readonly BindableProperty FunctionPadProperty = BindableProperty.Create(
        nameof(FunctionPad), typeof(FunctionPadView), typeof(KeyboardAreaView), null,
        propertyChanged: (bindable, oldValue, newValue) => 
        {
            if (bindable is KeyboardAreaView view && newValue is FunctionPadView pad)
            {
                view._functionPad = pad;
            }
        });

    public NumberPadView? NumberPad
    {
        get => (NumberPadView?)GetValue(NumberPadProperty);
        set => SetValue(NumberPadProperty, value);
    }

    public FunctionPadView? FunctionPad
    {
        get => (FunctionPadView?)GetValue(FunctionPadProperty);
        set => SetValue(FunctionPadProperty, value);
    }

    public KeyboardAreaView()
    {
        _layoutGrid = new Grid
        {
            ColumnSpacing = 4,
            RowSpacing = 4,
            HorizontalOptions = LayoutOptions.Fill,
            VerticalOptions = LayoutOptions.Fill,
            BackgroundColor = Colors.Transparent
        };

        Content = _layoutGrid;
    }

    protected override void OnHandlerChanged()
    {
        base.OnHandlerChanged();

        if (Handler != null && !_isHandlerAttached)
        {
            _isHandlerAttached = true;
            if (_layoutGrid != null && _numberPad != null && _functionPad != null)
            {
                SetLayoutOrientation(false);
            }
        }
    }

    public void SetLayoutOrientation(bool vertical)
    {
        if (_layoutGrid == null || _numberPad == null || _functionPad == null)
        {
            System.Diagnostics.Debug.WriteLine("KeyboardAreaView.SetLayoutOrientation: _layoutGrid or child controls are null");
            return;
        }

        if (_currentOrientation == vertical)
        {
            return;
        }

        _currentOrientation = vertical;

        try
        {
            if (vertical)
            {
                _layoutGrid.RowDefinitions = new RowDefinitionCollection
                {
                    new RowDefinition { Height = new GridLength(1, GridUnitType.Star) },
                    new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }
                };
                _layoutGrid.ColumnDefinitions = new ColumnDefinitionCollection
                {
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
                };

                _layoutGrid.Children.Clear();
                _layoutGrid.Add(_numberPad, 0, 0);
                _layoutGrid.Add(_functionPad, 0, 1);
            }
            else
            {
                _layoutGrid.RowDefinitions = new RowDefinitionCollection
                {
                    new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }
                };
                _layoutGrid.ColumnDefinitions = new ColumnDefinitionCollection
                {
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
                };

                _layoutGrid.Children.Clear();
                _layoutGrid.Add(_numberPad, 0, 0);
                _layoutGrid.Add(_functionPad, 1, 0);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"KeyboardAreaView.SetLayoutOrientation failed: {ex.Message}, Type: {ex.GetType().Name}");
            _currentOrientation = null;
        }
    }
}