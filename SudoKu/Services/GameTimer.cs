namespace SudoKu.Services;

public sealed class GameTimer
{
    private readonly Action _onTick;
    private readonly Action _onComplete;
    private IDispatcherTimer? _timer;
    private int _elapsedTime;
    private bool _isRunning;
    private bool _isCompleted;

    public GameTimer(Action onTick, Action onComplete)
    {
        _onTick = onTick;
        _onComplete = onComplete;
    }

    public int ElapsedTime => _elapsedTime;

    public bool IsRunning => _isRunning;

    public bool IsPaused => !_isRunning && _elapsedTime > 0;

    public bool IsCompleted => _isCompleted;

    public void Start(IDispatcher dispatcher)
    {
        if (_isRunning || _isCompleted) return;

        _isRunning = true;
        _timer = dispatcher.CreateTimer();
        _timer.Interval = TimeSpan.FromSeconds(1);
        _timer.Tick += Timer_Tick;
        _timer.Start();
    }

    private void Timer_Tick(object? sender, EventArgs e)
    {
        _elapsedTime++;
        _onTick();
    }

    public void Pause()
    {
        _timer?.Stop();
        _timer = null;
        _isRunning = false;
    }

    public void Resume(IDispatcher dispatcher) => Start(dispatcher);

    public void Stop()
    {
        _timer?.Stop();
        _timer = null;
        _isRunning = false;
    }

    public void Reset()
    {
        Stop();
        _elapsedTime = 0;
        _isCompleted = false;
    }

    public void SetElapsedTime(int seconds)
    {
        Stop();
        _elapsedTime = seconds;
        _isCompleted = false;
    }

    public void Complete()
    {
        Stop();
        _isCompleted = true;
        _onComplete();
    }

    public void Dispose()
    {
        _timer?.Stop();
        _timer = null;
    }
}
