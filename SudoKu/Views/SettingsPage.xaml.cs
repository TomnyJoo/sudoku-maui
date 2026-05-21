namespace SudoKu.Views;

using SudoKu.ViewModels;

/// <summary>
/// 设置页面，提供应用程序和游戏设置的配置界面。
/// </summary>
public partial class SettingsPage : ContentPage
{
    /// <summary>
    /// 初始化设置页面的新实例。
    /// </summary>
    public SettingsPage()
    {
        InitializeComponent();
    }

    /// <summary>
    /// 页面导航到时重新加载设置。
    /// </summary>
    protected override async void OnNavigatedTo(NavigatedToEventArgs args)
    {
        base.OnNavigatedTo(args);

        if (BindingContext == null && App.Current?.Handler?.MauiContext?.Services != null)
        {
            BindingContext = App.Current.Handler.MauiContext.Services.GetRequiredService<SettingsViewModel>();
        }

        if (BindingContext is SettingsViewModel vm)
        {
            await vm.InitializeAsync();
        }
    }

    /// <summary>
    /// 页面离开时的处理。
    /// </summary>
    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        // 可以在这里添加清理逻辑
    }
}
