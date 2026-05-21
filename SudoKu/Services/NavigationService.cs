namespace SudoKu.Services;

/// <summary>
/// 导航服务实现类，封装 MAUI Shell 导航功能。
/// 提供类型安全的页面导航方法。
/// </summary>
public class NavigationService
{
    /// <summary>
    /// 初始化导航服务的新实例。
    /// </summary>
    public NavigationService()
    {
    }

    /// <summary>
    /// 异步导航到指定路由页面。
    /// </summary>
    /// <param name="route">目标页面路由。</param>
    /// <param name="parameters">导航参数字典，可为 null。</param>
    public static async Task GoToAsync(string route, Dictionary<string, object>? parameters = null)
    {
        if (parameters is not null && parameters.Count > 0)
        {
            var queryParameters = new Dictionary<string, object>(parameters);
            await Shell.Current.GoToAsync(route, queryParameters);
        }
        else
        {
            await Shell.Current.GoToAsync(route);
        }
    }

    /// <summary>
    /// 异步返回上一页。
    /// </summary>
    public static async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    /// <summary>
    /// 异步弹出导航栈到根页面。
    /// </summary>
    public static async Task GoToRootAsync()
    {
        try
        {
            // 如果导航栈有多页，先弹出所有页面回到 ShellContent
            if (Shell.Current.Navigation.NavigationStack.Count > 1)
            {
                await Shell.Current.Navigation.PopToRootAsync();
            }
        }
        catch
        {
            // 如果弹出失败，尝试绝对路由导航
            try
            {
                await Shell.Current.GoToAsync("//Home");
            }
            catch
            {
                // 最终回退：忽略
            }
        }
    }
}
