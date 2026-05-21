namespace SudoKu.ViewModels;

using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services;

/// <summary>
/// 游戏完成页面 ViewModel，展示游戏成绩和操作选项。
/// 参照 Flutter FinishScreen 实现，包含当前 vs 最佳统计对比和新纪录弹窗。
/// </summary>
public partial class CompletionViewModel : BaseViewModel
{
    private readonly StatisticsStorageService _statisticsService;
    private GameType _gameType;
    private Difficulty _difficulty;
    private int _elapsedTime;
    private int _mistakes;
    private int _hintsUsed;
    private double _accuracy;
    private bool _isNewRecord;
    private int _bestTime;
    private int _bestMistakes;
    private string _elapsedTimeDisplay = "00:00";
    private string _bestTimeDisplay = "--:--";
    private string _bestMistakesDisplay = "--";
    private string _mistakesIcon = "\u26A0"; // ⚠

    /// <summary>
    /// 初始化完成页面 ViewModel 的新实例。
    /// </summary>
    /// <param name="statisticsService">统计服务实例。</param>
    public CompletionViewModel(StatisticsStorageService statisticsService)
    {
        _statisticsService = statisticsService;
        Title = "恭喜完成";
    }

    /// <summary>获取游戏类型。</summary>
    public GameType GameType => _gameType;

    /// <summary>获取游戏类型的显示名称。</summary>
    public string GameTypeDisplayName => GameTypeConfigFactory.GetDisplayName(_gameType);

    /// <summary>获取难度等级。</summary>
    public Difficulty Difficulty => _difficulty;

    /// <summary>获取难度等级的显示名称。</summary>
    public string DifficultyDisplayName => _difficulty.GetDisplayName();

    /// <summary>获取已用时间（秒）。</summary>
    public int ElapsedTime => _elapsedTime;

    /// <summary>获取错误次数。</summary>
    public int Mistakes => _mistakes;

    /// <summary>获取使用的提示次数。</summary>
    public int HintsUsed => _hintsUsed;

    /// <summary>获取准确率（0.0到1.0）。</summary>
    public double Accuracy => _accuracy;

    /// <summary>
    /// 获取或设置是否为新纪录。
    /// </summary>
    public bool IsNewRecord
    {
        get => _isNewRecord;
        set => SetProperty(ref _isNewRecord, value);
    }

    /// <summary>获取最佳时间（秒）。</summary>
    public int BestTime => _bestTime;

    /// <summary>获取已用时间的显示字符串。</summary>
    public string ElapsedTimeDisplay
    {
        get => _elapsedTimeDisplay;
        private set => SetProperty(ref _elapsedTimeDisplay, value);
    }

    /// <summary>获取最佳时间的显示字符串。</summary>
    public string BestTimeDisplay
    {
        get => _bestTimeDisplay;
        private set => SetProperty(ref _bestTimeDisplay, value);
    }

    /// <summary>获取最佳错误次数的显示字符串。</summary>
    public string BestMistakesDisplay
    {
        get => _bestMistakesDisplay;
        private set => SetProperty(ref _bestMistakesDisplay, value);
    }

    /// <summary>获取错误次数图标（0错误显示✓，否则显示⚠）。</summary>
    public string MistakesIcon
    {
        get => _mistakesIcon;
        private set => SetProperty(ref _mistakesIcon, value);
    }

    /// <summary>
    /// 异步初始化完成页面数据。
    /// </summary>
    /// <param name="parameter">导航参数，包含 GameState 和 IsNewRecord。</param>
    /// <returns>初始化完成的任务。</returns>
    public override async Task InitializeAsync(object? parameter = null)
    {
        if (parameter is Dictionary<string, object> paramsDict)
        {
            if (paramsDict.TryGetValue("GameState", out var gs) && gs is GameState<Board> state)
            {
                _gameType = state.GameType;
                _difficulty = state.Difficulty;
                _elapsedTime = state.ElapsedTime;
                _mistakes = state.Mistakes;
                _hintsUsed = state.HintsUsed;
                _accuracy = state.Accuracy;
                ElapsedTimeDisplay = FormatTime(_elapsedTime);
                Title = GameTypeConfigFactory.GetDisplayName(_gameType) + " - 完成";
            }

            if (paramsDict.TryGetValue("IsNewRecord", out var nr) && nr is bool newRecord)
            {
                IsNewRecord = newRecord;
            }
        }

        // 设置错误图标
        MistakesIcon = _mistakes == 0 ? "\u2705" : "\u26A0";

        // 加载最佳成绩
        var bestScore = await _statisticsService.GetBestScoreAsync(_gameType, _difficulty);
        if (bestScore is not null)
        {
            _bestTime = bestScore.Time;
            _bestMistakes = bestScore.Mistakes;
            BestTimeDisplay = FormatTime(_bestTime);
            BestMistakesDisplay = _bestMistakes.ToString();
        }
        else
        {
            BestTimeDisplay = "--:--";
            BestMistakesDisplay = "--";
        }
    }

    /// <summary>
    /// 关闭新纪录弹窗。
    /// </summary>
    public void DismissNewRecord()
    {
        IsNewRecord = false;
    }

    /// <summary>
    /// 再玩一次命令，导航回游戏页面开始新游戏。
    /// </summary>
    [RelayCommand]
    private async Task PlayAgainAsync()
    {
        await NavigationService.GoToAsync(nameof(Views.GamePage), new Dictionary<string, object>
        {
            { "GameType", _gameType },
            { "Difficulty", _difficulty },
            { "IsNewGame", true }
        });
    }

    /// <summary>
    /// 返回主菜单命令。
    /// </summary>
    [RelayCommand]
    private async Task BackToMenuAsync()
    {
        await NavigationService.GoToRootAsync();
    }

    /// <summary>
    /// 将秒数格式化为时间显示字符串。
    /// </summary>
    /// <param name="seconds">秒数。</param>
    /// <returns>格式化的时间字符串。</returns>
    private static string FormatTime(int seconds)
    {
        if (seconds < 0) seconds = 0;
        var ts = TimeSpan.FromSeconds(seconds);
        if (ts.TotalHours >= 1)
        {
            return ts.ToString(@"hh\:mm\:ss");
        }
        return ts.ToString(@"mm\:ss");
    }
}
