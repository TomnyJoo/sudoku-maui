namespace SudoKu.Models;

public sealed record GameStatistics
{
    public int TotalGamesPlayed { get; init; }
    public int TotalGamesWon { get; init; }
    public double WinRate { get; init; }
    public long TotalPlayTime { get; init; }
    public int TotalHintsUsed { get; init; }
    public int TotalErrors { get; init; }
    public int CurrentStreak { get; init; }
    public int BestStreak { get; init; }
    public Dictionary<GameType, GameTypeStats> GameTypeStats { get; init; } = new();
}
