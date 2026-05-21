namespace SudoKu.Views;

using SudoKu.ViewModels;

/// <summary>
/// 统计页面，展示游戏统计数据和各游戏类型的详细统计。
/// </summary>
public partial class StatisticsPage : ContentPage
{
    /// <summary>
    /// 初始化统计页面的新实例。
    /// </summary>
    public StatisticsPage()
    {
        InitializeComponent();
    }

    /// <summary>
    /// 页面导航到时加载统计数据。
    /// </summary>
    protected override async void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);

        if (BindingContext == null && App.Current?.Handler?.MauiContext?.Services != null)
        {
            BindingContext = App.Current.Handler.MauiContext.Services.GetRequiredService<StatisticsViewModel>();
        }

        if (BindingContext is StatisticsViewModel vm)
        {
            await vm.InitializeAsync();
        }
    }
}
