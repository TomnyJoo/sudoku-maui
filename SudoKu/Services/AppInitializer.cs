using System.Diagnostics;
using SudoKu.Services.Generation;

namespace SudoKu.Services;

public enum InitializationStatus
{
    Uninitialized,
    Initializing,
    Completed,
    Failed
}

public static class AppInitializer
{
    private static bool _isInitialized;
    private static InitializationStatus _status = InitializationStatus.Uninitialized;
    private static double _progress = 0;

    public static InitializationStatus Status => _status;
    public static bool IsInitialized => _isInitialized;
    public static double Progress => _progress;

    public static async Task<bool> InitializeAsync(IServiceProvider services)
    {
        if (_isInitialized) return true;

        _status = InitializationStatus.Initializing;
        _progress = 0;
        var stopwatch = Stopwatch.StartNew();

        try
        {
            UpdateProgress(0.1, "初始化设置...");
            await InitializeSettingsAsync(services);

            UpdateProgress(0.3, "预加载资源...");
            await PreloadResourcesAsync();

            UpdateProgress(0.6, "预加载模板...");
            await PreloadTemplatesAsync(services);

            UpdateProgress(0.9, "验证服务...");
            ValidateServices(services);

            _status = InitializationStatus.Completed;
            _progress = 1.0;
            _isInitialized = true;
            stopwatch.Stop();
            Helpers.AppLogger.Info($"应用初始化完成，耗时 {stopwatch.ElapsedMilliseconds}ms");
            return true;
        }
        catch (Exception ex)
        {
            _status = InitializationStatus.Failed;
            _progress = 0;
            Helpers.AppLogger.Error("应用初始化失败", ex);
            return false;
        }
    }

    private static void UpdateProgress(double progress, string message)
    {
        _progress = progress;
        Helpers.AppLogger.Debug($"初始化进度: {progress * 100:F0}% - {message}");
    }

    private static async Task PreloadResourcesAsync()
    {
        await Task.Run(() => { });
        Helpers.AppLogger.Debug("资源预加载完成");
    }

    private static async Task InitializeSettingsAsync(IServiceProvider services)
    {
        var settings = services.GetRequiredService<SettingsService>();
        await settings.LoadAsync();
        Helpers.AppLogger.Debug("设置服务初始化完成");
    }

    private static async Task PreloadTemplatesAsync(IServiceProvider services)
    {
        var templateManager = services.GetRequiredService<TemplateManager>();
        await TemplateManager.PreloadAsync();
        Helpers.AppLogger.Debug("模板预加载完成");
    }

    private static void ValidateServices(IServiceProvider services)
    {
        _ = services.GetRequiredService<Interfaces.IGameService<Models.Boards.Board>>();
        _ = services.GetRequiredService<GameStorageService>();
        Helpers.AppLogger.Debug("服务验证完成");
    }
}
