using CommunityToolkit.Maui;
using SudoKu.Helpers;
using SudoKu.Resources;
using SudoKu.Services;
using SudoKu.Services.Generation;

namespace SudoKu
{
    public static class MauiProgram
    {
        public static IServiceProvider? Services { get; private set; }

        static MauiProgram()
        {
            AppDomain.CurrentDomain.UnhandledException += OnUnhandledException;
            TaskScheduler.UnobservedTaskException += OnUnobservedTaskException;
        }

        public static MauiApp CreateMauiApp()
        {
            var builder = MauiApp.CreateBuilder();
            builder
                .UseMauiApp<App>()
                .UseMauiCommunityToolkit()
                .ConfigureFonts(fonts =>
                {
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                    fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                });

            RegisterServices(builder.Services);

            var app = builder.Build();
            Services = app.Services;

            InitializeApplicationAsync(app);

            return app;
        }

        private static void RegisterServices(IServiceCollection services)
        {
            services.AddSingleton<IErrorHandler, ErrorHandler>();

            services.AddSingleton<TemplateManager>();
            services.AddSingleton<PuzzleGenerator>();

            services.AddSingleton<Services.Storage.Database.SudokuDatabase>();
            services.AddSingleton<Services.SettingsService>();
            services.AddSingleton<Services.GameStorageService>();
            services.AddSingleton<Services.StatisticsStorageService>();
            services.AddSingleton<Services.AudioService>();

            services.AddSingleton<Services.Interfaces.IGameService<Models.Boards.Board>, Services.GameService>();
            services.AddSingleton<Services.GameService>();

            RegisterSolvingServices(services);

            services.AddSingleton<ViewModels.HomeViewModel>();
            services.AddSingleton<ViewModels.GameViewModel>();
            services.AddSingleton<ViewModels.CompletionViewModel>();
            services.AddScoped<ViewModels.CustomGameViewModel>();
            services.AddScoped<ViewModels.SettingsViewModel>();
            services.AddScoped<ViewModels.StatisticsViewModel>();
            services.AddScoped<ViewModels.RulesViewModel>();

            services.AddTransient<Views.HomePage>();
            services.AddTransient<Views.GamePage>();
            services.AddTransient<Views.CompletionPage>();
            services.AddTransient<Views.CustomGamePage>();
            services.AddTransient<Views.SettingsPage>();
            services.AddTransient<Views.StatisticsPage>();
            services.AddTransient<Views.RulesPage>();
        }

        private static void RegisterSolvingServices(IServiceCollection services)
        {
            services.AddSingleton<Services.Interfaces.IPuzzleSolver, Services.Solving.PuzzleSolver>();
        }

        private static async void InitializeApplicationAsync(MauiApp app)
        {
            try
            {
#if DEBUG
                DebugLogger.EnableDebugLogging = true;
                DebugLogger.EnablePerformanceLogging = true;
                PerformanceMonitor.IsEnabled = true;
                AppLogger.Info("调试模式已启用 - 性能监控和调试日志已开启");
#endif

                var settings = app.Services.GetRequiredService<Services.SettingsService>();
                AppResources.Culture = new System.Globalization.CultureInfo(settings.Language);

                var success = await AppInitializer.InitializeAsync(app.Services);
                if (!success)
                {
                    AppLogger.Warning("应用初始化存在问题，但将继续运行");
                }
            }
            catch (Exception ex)
            {
                AppLogger.Error("应用初始化异常", ex);
            }
        }

        private static void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            if (e.ExceptionObject is Exception ex)
            {
                AppLogger.Error("未处理的应用异常", ex);
            }
        }

        private static void OnUnobservedTaskException(object? sender, UnobservedTaskExceptionEventArgs e)
        {
            e.SetObserved();
            AppLogger.Error("未观察到的任务异常", e.Exception);
        }
    }
}
