namespace SudoKu.Views;

using System.Diagnostics;
using Microsoft.Maui.Graphics;
using SudoKu.ViewModels;

/// <summary>
/// 游戏完成页面，展示游戏成绩和操作选项。
/// </summary>
public partial class CompletionPage : ContentPage, IQueryAttributable
{
    private Dictionary<string, object>? _pendingParameters;

    /// <summary>
    /// 初始化完成页面的新实例。
    /// </summary>
    public CompletionPage()
    {
        InitializeComponent();
    }

    /// <summary>
    /// 接收 Shell 导航查询参数。
    /// </summary>
    /// <param name="query">查询参数字典。</param>
    public void ApplyQueryAttributes(IDictionary<string, object> query)
    {
        _pendingParameters = new Dictionary<string, object>(query);
    }

    /// <summary>
    /// 页面导航到时初始化完成数据。
    /// </summary>
    protected override async void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);

        if (BindingContext == null && App.Current?.Handler?.MauiContext?.Services != null)
        {
            BindingContext = App.Current.Handler.MauiContext.Services.GetRequiredService<CompletionViewModel>();
        }

        if (BindingContext is CompletionViewModel vm)
        {
            await vm.InitializeAsync(_pendingParameters);
        }
        _pendingParameters = null;
    }

    /// <summary>
    /// 新纪录弹窗遮罩点击事件。
    /// </summary>
    private void OnNewRecordOverlayTapped(object? sender, TappedEventArgs e)
    {
        // 不做任何操作，防止点击遮罩关闭弹窗
    }

    /// <summary>
    /// 新纪录弹窗确认按钮点击事件。
    /// </summary>
    private void OnNewRecordOkClicked(object? sender, EventArgs e)
    {
        if (BindingContext is CompletionViewModel vm)
        {
            vm.DismissNewRecord();
        }
    }
}
