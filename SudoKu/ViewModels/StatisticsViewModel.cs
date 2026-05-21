namespace SudoKu.ViewModels;

using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.Input;
using SudoKu.Models;
using SudoKu.Resources;
using SudoKu.Services;

/// <summary>
/// 统计页面 ViewModel，展示游戏统计数据和各游戏类型的详细统计。
/// </summary>
public partial class StatisticsViewModel : BaseViewModel
{
    private readonly StatisticsStorageService _statisticsService;

    private int _totalGamesPlayed;
    private int _totalGamesWon;
    private double _winRate;
    private int _currentStreak;
    private int _bestStreak;
    private string _totalPlayTimeDisplay = "00:00:00";

    /// <summary>
    /// 初始化统计 ViewModel 的新实例。
    /// </summary>
    /// <param name="statisticsService">统计服务实例。</param>
    public StatisticsViewModel(StatisticsStorageService statisticsService)
    {
        _statisticsService = statisticsService;
        Title = "统计";
    }

    /// <summary>获取或设置总游戏次数。</summary>
    public int TotalGamesPlayed
    {
        get => _totalGamesPlayed;
        private set => SetProperty(ref _totalGamesPlayed, value);
    }

    /// <summary>获取或设置总胜利次数。</summary>
    public int TotalGamesWon
    {
        get => _totalGamesWon;
        private set => SetProperty(ref _totalGamesWon, value);
    }

    /// <summary>获取或设置胜率（0.0到1.0）。</summary>
    public double WinRate
    {
        get => _winRate;
        private set => SetProperty(ref _winRate, value);
    }

    /// <summary>获取或设置当前连胜次数。</summary>
    public int CurrentStreak
    {
        get => _currentStreak;
        private set => SetProperty(ref _currentStreak, value);
    }

    /// <summary>获取或设置最佳连胜次数。</summary>
    public int BestStreak
    {
        get => _bestStreak;
        private set => SetProperty(ref _bestStreak, value);
    }

    /// <summary>获取或设置总游戏时间的显示字符串。</summary>
    public string TotalPlayTimeDisplay
    {
        get => _totalPlayTimeDisplay;
        private set => SetProperty(ref _totalPlayTimeDisplay, value);
    }

    /// <summary>获取各游戏类型的统计列表。</summary>
    public ObservableCollection<GameTypeStatsDisplay> GameTypeStatsList { get; } = [];

    /// <summary>
    /// 异步初始化统计数据。
    /// </summary>
    /// <param name="parameter">导航参数，未使用。</param>
    /// <returns>初始化完成的任务。</returns>
    public override async Task InitializeAsync(object? parameter = null)
    {
        await RefreshAsync();
    }

    /// <summary>
    /// 刷新统计数据命令，重新从服务加载最新统计。
    /// </summary>
    [RelayCommand]
    private async Task RefreshAsync()
    {
        IsBusy = true;
        try
        {
            var stats = await _statisticsService.GetStatisticsAsync();
            UpdateStatistics(stats);
        }
        finally
        {
            IsBusy = false;
        }
    }

    /// <summary>
    /// 清除统计数据命令。
    /// </summary>
    [RelayCommand]
    private async Task ClearStatisticsAsync()
    {
        await _statisticsService.ClearStatisticsAsync();
        await RefreshAsync();
    }

    /// <summary>
    /// 更新统计数据显示。
    /// </summary>
    /// <param name="stats">游戏统计信息。</param>
    private void UpdateStatistics(GameStatistics stats)
    {
        TotalGamesPlayed = stats.TotalGamesPlayed;
        TotalGamesWon = stats.TotalGamesWon;
        WinRate = stats.WinRate;
        CurrentStreak = stats.CurrentStreak;
        BestStreak = stats.BestStreak;
        TotalPlayTimeDisplay = FormatPlayTime(stats.TotalPlayTime);

        GameTypeStatsList.Clear();
        foreach (var kvp in stats.GameTypeStats)
        {
            var typeStats = kvp.Value;
            GameTypeStatsList.Add(new GameTypeStatsDisplay
            {
                GameType = typeStats.Type,
                DisplayName = GameTypeConfigFactory.GetDisplayName(typeStats.Type),
                GamesPlayed = typeStats.GamesPlayed,
                GamesWon = typeStats.GamesWon,
                WinRate = typeStats.WinRate,
                BestTime = typeStats.BestTime,
                BestTimeDisplay = typeStats.BestTime > 0 ? FormatTime(typeStats.BestTime) : "--:--",
                AvgCompletionTime = typeStats.AvgCompletionTime,
                AvgCompletionTimeDisplay = typeStats.AvgCompletionTime > 0
                    ? FormatTime((int)typeStats.AvgCompletionTime)
                    : "--:--"
            });
        }
    }

    /// <summary>
    /// 将秒数格式化为时间显示字符串。
    /// </summary>
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

    /// <summary>
    /// 将总秒数格式化为游戏时间显示字符串。
    /// </summary>
    private static string FormatPlayTime(long totalSeconds)
    {
        if (totalSeconds < 0) totalSeconds = 0;
        var ts = TimeSpan.FromSeconds(totalSeconds);
        if (ts.TotalDays >= 1)
        {
            return $"{(int)ts.TotalDays}天 {ts:hh\\:mm\\:ss}";
        }
        return ts.ToString(@"hh\:mm\:ss");
    }
}

/// <summary>
/// 游戏类型统计显示模型，用于UI层展示各游戏类型的统计数据。
/// </summary>
public class GameTypeStatsDisplay
{
    /// <summary>获取或设置游戏类型。</summary>
    public GameType GameType { get; set; }

    /// <summary>获取或设置显示名称。</summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>获取或设置游戏次数。</summary>
    public int GamesPlayed { get; set; }

    /// <summary>获取或设置胜利次数。</summary>
    public int GamesWon { get; set; }

    /// <summary>获取或设置胜率。</summary>
    public double WinRate { get; set; }

    /// <summary>获取或设置最佳时间（秒）。</summary>
    public int BestTime { get; set; }

    /// <summary>获取或设置最佳时间显示字符串。</summary>
    public string BestTimeDisplay { get; set; } = "--:--";

    /// <summary>获取或设置平均完成时间（秒）。</summary>
    public double AvgCompletionTime { get; set; }

    /// <summary>获取或设置平均完成时间显示字符串。</summary>
    public string AvgCompletionTimeDisplay { get; set; } = "--:--";

    /// <summary>获取格式化的游戏次数文本。</summary>
    public string GamesPlayedDisplay => string.Format(AppResources.StatsGamesPlayedFormat, GamesPlayed);

    /// <summary>获取格式化的胜利次数文本。</summary>
    public string GamesWonDisplay => string.Format(AppResources.StatsGamesWonFormat, GamesWon);
}
