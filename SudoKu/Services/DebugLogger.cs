using System.Diagnostics;
using SudoKu.Helpers;

namespace SudoKu.Services;

public static class DebugLogger
{
    public static bool EnableDebugLogging { get; set; } = false;
    public static bool EnablePerformanceLogging { get; set; } = false;

    private static readonly string[] EnabledModules = new[]
    {
        "DiggingAlgorithm",
        "PuzzleGenerator",
        "DLXSolver"
    };

    public static bool IsModuleEnabled(string moduleName)
    {
        return EnableDebugLogging && EnabledModules.Contains(moduleName);
    }

    public static void Debug(string module, string message)
    {
        if (IsModuleEnabled(module))
        {
            AppLogger.Debug($"[{module}] {message}");
        }
    }

    public static void Debug(string module, string message, params object[] args)
    {
        if (IsModuleEnabled(module))
        {
            AppLogger.Debug($"[{module}] {string.Format(message, args)}");
        }
    }

    public static void Performance(string operation, Action action)
    {
        if (!EnablePerformanceLogging)
        {
            action();
            return;
        }

        var sw = Stopwatch.StartNew();
        action();
        sw.Stop();
        AppLogger.Debug($"[PERF] {operation}: {sw.ElapsedMilliseconds}ms");
    }

    public static T Performance<T>(string operation, Func<T> func)
    {
        if (!EnablePerformanceLogging)
            return func();

        var sw = Stopwatch.StartNew();
        try
        {
            return func();
        }
        finally
        {
            sw.Stop();
            AppLogger.Debug($"[PERF] {operation}: {sw.ElapsedMilliseconds}ms");
        }
    }
}
