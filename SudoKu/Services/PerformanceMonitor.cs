using System.Diagnostics;

namespace SudoKu.Services;

public static class PerformanceMonitor
{
    private static readonly Dictionary<string, Stopwatch> _traces = new();
    private static readonly Dictionary<string, List<double>> _metrics = new();
    private static readonly object _lock = new();

    public static bool IsEnabled { get; set; } = false;

    public static void StartTrace(string name)
    {
        if (!IsEnabled) return;

        lock (_lock)
        {
            var sw = Stopwatch.StartNew();
            _traces[name] = sw;
        }
    }

    public static long EndTrace(string name)
    {
        if (!IsEnabled) return 0;

        lock (_lock)
        {
            if (_traces.TryGetValue(name, out var sw))
            {
                sw.Stop();
                _traces.Remove(name);
                var elapsed = sw.ElapsedMilliseconds;
                LogMetric(name, elapsed);
                return elapsed;
            }
        }
        return 0;
    }

    public static void LogMetric(string name, double value)
    {
        if (!IsEnabled) return;

        lock (_lock)
        {
            if (!_metrics.ContainsKey(name))
                _metrics[name] = new List<double>();

            _metrics[name].Add(value);
        }
    }

    public static (double avg, double min, double max) GetMetricStats(string name)
    {
        lock (_lock)
        {
            if (_metrics.TryGetValue(name, out var values) && values.Count > 0)
            {
                return (values.Average(), values.Min(), values.Max());
            }
        }
        return (0, 0, 0);
    }

    public static void Clear()
    {
        lock (_lock)
        {
            _traces.Clear();
            _metrics.Clear();
        }
    }

    public static T Measure<T>(string operation, Func<T> func)
    {
        if (!IsEnabled)
            return func();

        StartTrace(operation);
        try
        {
            return func();
        }
        finally
        {
            EndTrace(operation);
        }
    }

    public static void Measure(string operation, Action action)
    {
        if (!IsEnabled)
        {
            action();
            return;
        }

        StartTrace(operation);
        try
        {
            action();
        }
        finally
        {
            EndTrace(operation);
        }
    }
}
