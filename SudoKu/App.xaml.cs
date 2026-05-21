namespace SudoKu;

using SudoKu.Exceptions;
using SudoKu.Services;
using SudoKu.Services.Storage.Database;

/// <summary>
/// MAUI 应用程序主类，负责应用程序生命周期管理和资源初始化。
/// </summary>
public partial class App : Application
{
    /// <summary>
    /// 初始化应用程序实例。
    /// </summary>
    public App()
    {
        InitializeComponent();
    }

    /// <summary>
    /// 创建应用程序主窗口，并异步初始化数据库。
    /// </summary>
    /// <param name="activationState">激活状态。</param>
    /// <returns>应用程序主窗口实例。</returns>
    protected override Window CreateWindow(IActivationState? activationState)
    {
        _ = InitializeDatabaseAsync();

        return new Window(new AppShell());
    }

    /// <summary>
    /// 异步初始化数据库。
    /// </summary>
    private static async Task InitializeDatabaseAsync()
    {
        try
        {
            await SudokuDatabase.InitializeAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"数据库初始化错误: {ex}");
        }
    }

    /// <summary>
    /// 处理全局异常，提供用户友好的错误消息。
    /// </summary>
    /// <param name="exception">发生的异常。</param>
    /// <param name="handler">错误处理器实例。</param>
    /// <returns>用户友好的错误消息。</returns>
    public static string HandleGlobalException(Exception exception, IErrorHandler? handler = null)
    {
        handler ??= MauiProgram.Services?.GetService<IErrorHandler>();

        if (handler != null)
        {
            handler.LogError(exception, "GlobalException");
            var message = handler.HandleException(exception);
            NavigateToErrorPage(message);
            return message;
        }

        if (exception is GameGenerationCancelledException)
        {
            NavigateToErrorPage("游戏生成已取消");
            return "游戏生成已取消";
        }
        if (exception is GameGenerationTimeoutException)
        {
            NavigateToErrorPage("游戏生成超时，请重试");
            return "游戏生成超时，请重试";
        }
        if (exception is PuzzleGenerationException)
        {
            NavigateToErrorPage($"游戏生成失败: {exception.Message}");
            return $"游戏生成失败: {exception.Message}";
        }

        NavigateToErrorPage($"发生未知错误: {exception?.Message ?? "未知错误"}");
        return $"发生未知错误: {exception?.Message ?? "未知错误"}";
    }

    private static void NavigateToErrorPage(string message)
    {
        try
        {
            var encodedMessage = Uri.EscapeDataString(message);
            Shell.Current?.GoToAsync($"error?message={encodedMessage}");
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"导航到错误页面失败: {ex.Message}");
        }
    }
}
