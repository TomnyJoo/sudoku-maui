namespace SudoKu.Services;

using SudoKu.Models;
using SudoKu.Models.Boards;

public sealed class SessionStatistics
{
    public SessionStatistics(
        Board board,
        int mistakes,
        int totalMoves,
        bool isCompleted,
        int elapsedTime,
        string difficulty = "medium")
    {
        Board = board;
        Mistakes = mistakes;
        TotalMoves = totalMoves;
        IsCompleted = isCompleted;
        ElapsedTime = elapsedTime;
        Difficulty = difficulty;
    }

    public Board Board { get; }
    public int Mistakes { get; }
    public int TotalMoves { get; }
    public bool IsCompleted { get; }
    public int ElapsedTime { get; }
    public string Difficulty { get; }

    public double Accuracy => TotalMoves > 0 ? (double)(TotalMoves - Mistakes) / TotalMoves : 1.0;

    public double CompletionPercentage
    {
        get
        {
            var totalCells = Board.Size * Board.Size;
            if (totalCells == 0) return 0.0;
            var filledCells = Board.GetFilledCells().Count;
            return (double)filledCells / totalCells;
        }
    }

    public double Efficiency => TotalMoves > 0 ? (double)ElapsedTime / TotalMoves : 0.0;

    public int EstimatedCompletionTime
    {
        get
        {
            if (CompletionPercentage <= 0) return 0;
            var estimatedTotalTime = ElapsedTime / CompletionPercentage;
            return (int)(estimatedTotalTime - ElapsedTime);
        }
    }

    public SessionStatistics UpdateBoard(Board newBoard) =>
        new(newBoard, Mistakes, TotalMoves, IsCompleted, ElapsedTime, Difficulty);

    public SessionStatistics UpdateMistakes(int newMistakes) =>
        new(Board, newMistakes, TotalMoves, IsCompleted, ElapsedTime, Difficulty);

    public SessionStatistics UpdateTotalMoves(int newTotalMoves) =>
        new(Board, Mistakes, newTotalMoves, IsCompleted, ElapsedTime, Difficulty);

    public SessionStatistics UpdateCompletionStatus(bool completed) =>
        new(Board, Mistakes, TotalMoves, completed, ElapsedTime, Difficulty);

    public SessionStatistics UpdateElapsedTime(int newElapsedTime) =>
        new(Board, Mistakes, TotalMoves, IsCompleted, newElapsedTime, Difficulty);

    public SessionStatistics UpdateDifficulty(string newDifficulty) =>
        new(Board, Mistakes, TotalMoves, IsCompleted, ElapsedTime, newDifficulty);

    public bool IsNearlyCompleted() => CompletionPercentage >= 0.9;

    public bool IsHavingDifficulty() => Mistakes > TotalMoves * 0.3;

    public string GetStatusDescription()
    {
        if (IsCompleted)
        {
            return "游戏已完成";
        }
        else if (IsNearlyCompleted())
        {
            return "即将完成";
        }
        else if (IsHavingDifficulty())
        {
            return "遇到困难";
        }
        else
        {
            return "游戏进行中";
        }
    }
}
