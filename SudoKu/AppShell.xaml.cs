namespace SudoKu;

using SudoKu.Views;
using SudoKu.ViewModels;

/// <summary>
/// 应用程序 Shell 主页面，管理底部导航栏和页面路由注册。
/// </summary>
public partial class AppShell : Shell
{
    /// <summary>
    /// 初始化 Shell 实例，注册所有页面路由。
    /// </summary>
    public AppShell()
    {
        InitializeComponent();
        RegisterRoutes();
    }

    /// <summary>
    /// 注册所有非 TabBar 页面的路由。
    /// </summary>
    private static void RegisterRoutes()
    {
        Routing.RegisterRoute(nameof(Views.GamePage), typeof(Views.GamePage));
        Routing.RegisterRoute(nameof(Views.CompletionPage), typeof(Views.CompletionPage));
        Routing.RegisterRoute(nameof(Views.CustomGamePage), typeof(Views.CustomGamePage));
    }

    protected override void OnHandlerChanged()
    {
        base.OnHandlerChanged();

        // 为 TabBar 页面设置 BindingContext
        if (Handler?.MauiContext?.Services != null)
        {
            var services = Handler.MauiContext.Services;
            if (CurrentPage is HomePage homePage)
            {
                homePage.BindingContext = services.GetRequiredService<HomeViewModel>();
            }
            else if (CurrentPage is StatisticsPage statsPage)
            {
                statsPage.BindingContext = services.GetRequiredService<StatisticsViewModel>();
            }
            else if (CurrentPage is SettingsPage settingsPage)
            {
                settingsPage.BindingContext = services.GetRequiredService<SettingsViewModel>();
            }
            else if (CurrentPage is RulesPage rulesPage)
            {
                rulesPage.BindingContext = services.GetRequiredService<RulesViewModel>();
            }
        }
    }
}
