namespace SudoKu.Views;

using SudoKu.Helpers;
using SudoKu.ViewModels;

/// <summary>
/// 自定义游戏页面，允许用户编辑棋盘并创建自定义谜题。
/// 参照Flutter CustomGameScreen实现，支持横屏和竖屏布局切换。
/// </summary>
public partial class CustomGamePage : ContentPage
{
    /// <summary>
    /// 初始化自定义游戏页面的新实例。
    /// </summary>
    public CustomGamePage()
    {
        InitializeComponent();
        // 订阅尺寸变化事件以切换布局
        SizeChanged += OnPageSizeChanged;
    }

    /// <summary>
    /// 页面尺寸变化时切换横竖屏布局。
    /// 参照Flutter _buildGameLayout方法。
    /// </summary>
    private void OnPageSizeChanged(object? sender, EventArgs e)
    {
        // 横屏：宽度 >= 高度
        bool isHorizontal = Width >= Height;

        if (HorizontalLayout != null && VerticalLayout != null)
        {
            HorizontalLayout.IsVisible = isHorizontal;
            VerticalLayout.IsVisible = !isHorizontal;
        }
    }

    /// <summary>
    /// 页面导航到时初始化棋盘数据。
    /// </summary>
    protected override async void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);

        // 初始化ViewModel
        if (BindingContext == null && App.Current?.Handler?.MauiContext?.Services != null)
        {
            BindingContext = App.Current.Handler.MauiContext.Services.GetRequiredService<CustomGameViewModel>();
        }

        // 调用ViewModel初始化
        if (BindingContext is CustomGameViewModel vm)
        {
            await vm.InitializeAsync();
        }

        // 初始布局设置
        OnPageSizeChanged(this, EventArgs.Empty);
    }

    /// <summary>
    /// 页面离开时的清理工作。
    /// </summary>
    protected override async void OnNavigatedFrom(NavigatedFromEventArgs args)
    {
        base.OnNavigatedFrom(args);

        // 取消尺寸变化订阅
        SizeChanged -= OnPageSizeChanged;

        // 清理ViewModel
        if (BindingContext is CustomGameViewModel vm)
        {
            await vm.CleanupAsync();
        }
    }
}
