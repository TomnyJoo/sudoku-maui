namespace SudoKu.Models;

public sealed record GameInfo
{
    public required int Id { get; init; }
    public required GameType GameType { get; init; }
    public required string PuzzleJson { get; init; }
    public required string SolutionJson { get; init; }
    public required DateTime CreatedAt { get; init; }
    public required string Name { get; init; }
}
