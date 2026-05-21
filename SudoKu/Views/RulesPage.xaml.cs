namespace SudoKu.Views;

using SudoKu.ViewModels;

/// <summary>
/// 规则页面，展示各游戏类型的规则说明。
/// </summary>
public partial class RulesPage : ContentPage
{
    /// <summary>
    /// 初始化规则页面的新实例。
    /// </summary>
    public RulesPage()
    {
        InitializeComponent();
    }

    /// <summary>
    /// 页面导航到时初始化规则数据。
    /// </summary>
    protected override async void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);

        if (BindingContext == null && App.Current?.Handler?.MauiContext?.Services != null)
        {
            BindingContext = App.Current.Handler.MauiContext.Services.GetRequiredService<RulesViewModel>();
        }

        if (BindingContext is RulesViewModel vm)
        {
            await vm.InitializeAsync();
        }
    }
}
