using System.Diagnostics;
using System.Text.Json;

namespace SudoKu.Helpers;

public enum LogLevel
{
    Debug,
    Info,
    Warning,
    Error
}

public static class AppLogger
{
    public static void Debug(string message, object? data = null)
    {
        Log(LogLevel.Debug, message, data);
    }

    public static void Info(string message, object? data = null)
    {
        Log(LogLevel.Info, message, data);
    }

    public static void Warning(string message, object? data = null)
    {
        Log(LogLevel.Warning, message, data);
    }

    public static void Error(string message, Exception? exception = null)
    {
        var data = exception != null ? new { Exception = exception.Message, StackTrace = exception.StackTrace } : null;
        Log(LogLevel.Error, message, data);
    }

    private static void Log(LogLevel level, string message, object? data)
    {
        var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
        var logMessage = $"[{timestamp}] [{level}] {message}";

        if (data != null)
        {
            try
            {
                var dataJson = JsonSerializer.Serialize(data);
                logMessage += $" | Data: {dataJson}";
            }
            catch
            {
                logMessage += $" | Data: {data}";
            }
        }

        System.Diagnostics.Debug.WriteLine(logMessage);
    }
}
