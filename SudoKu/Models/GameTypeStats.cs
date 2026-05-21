namespace SudoKu.Models;

public sealed record GameTypeStats
{
    public required GameType Type { get; init; }
    public int GamesPlayed { get; init; }
    public int GamesWon { get; init; }
    public double WinRate { get; init; }
    public int BestTime { get; init; }
    public double AvgCompletionTime { get; init; }
    public Dictionary<Difficulty, BestScore> BestScores { get; init; } = new();
}
