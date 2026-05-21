namespace SudoKu.ViewModels.Mixins;

using Microsoft.Maui.Controls;

public class GameTimerHandler
{
    private readonly Func<int> _getElapsedTime;
    private readonly Action<int> _updateElapsedTime;
    private IDispatcherTimer? _timer;
    private const int TimerIntervalMs = 1000;

    public GameTimerHandler(
        Func<int> getElapsedTime,
        Action<int> updateElapsedTime)
    {
        _getElapsedTime = getElapsedTime;
        _updateElapsedTime = updateElapsedTime;
    }

    public void StartTimer(Action onTick)
    {
        StopTimer();
        _timer = Application.Current?.Dispatcher.CreateTimer();
        if (_timer == null) return;

        _timer.Interval = TimeSpan.FromMilliseconds(TimerIntervalMs);
        _timer.IsRepeating = true;
        _timer.Tick += (_, _) => {
            var newTime = _getElapsedTime() + 1;
            _updateElapsedTime(newTime);
            onTick?.Invoke();
        };
        _timer.Start();
    }

    public void StopTimer()
    {
        if (_timer != null)
        {
            _timer.Stop();
            _timer = null;
        }
    }

    public bool IsRunning => _timer?.IsRunning ?? false;

    public void Dispose()
    {
        StopTimer();
    }
}
