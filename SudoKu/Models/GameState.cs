namespace SudoKu.Models;

using SudoKu.Models.Boards;
using SudoKu.Models.Commands;

public record class GameState<B> where B : Board
{
    public const int MaxHistorySize = 50;

    public B Board { get; init; } = null!;
    public B InitialBoard { get; init; } = null!;
    public B Solution { get; init; } = null!;
    
    public Difficulty Difficulty { get; init; } = Difficulty.Medium;
    public int ElapsedTime { get; init; }
    public int Mistakes { get; init; }
    public bool IsCompleted { get; init; }
    public List<B> History { get; init; } = [];
    public int HistoryIndex { get; init; }
    public HistoryManager? HistoryManager { get; init; }
    public Dictionary<int, int> NumberCounts { get; init; } = [];
    public DateTime StartTime { get; init; } = DateTime.Now;
    public DateTime? CompletionTime { get; init; }
    public bool IsShowingSolution { get; init; }
    public B? SavedBoard { get; init; }
    public bool IsMarkMode { get; init; }
    public bool IsAutoMarkMode { get; init; }
    public int HintsUsed { get; init; }
    public GameType GameType { get; init; }
    public GameStatus Status { get; init; } = GameStatus.NotStarted;
    public SudokuCell? SelectedCell { get; init; }

    public double Accuracy
    {
        get
        {
            var totalActions = Mistakes + (Board?.GetFilledCells().Count ?? 0) - (InitialBoard?.GetFilledCells().Count ?? 0);
            if (totalActions <= 0) return 1.0;
            return Math.Max(0.0, 1.0 - (double)Mistakes / totalActions);
        }
    }

    public double CompletionPercentage
    {
        get
        {
            if (Board is null) return 0.0;
            var totalCells = Board.Size * Board.Size;
            var filledCells = Board.GetFilledCells().Count;
            return (double)filledCells / totalCells;
        }
    }

    public bool CanUndo => HistoryManager?.CanUndo ?? HistoryIndex > 0;
    public bool CanRedo => HistoryManager?.CanRedo ?? HistoryIndex < History.Count - 1;

    public GameState<B> CopyWith(
        B? board = null,
        B? initialBoard = null,
        B? solution = null,
        Difficulty? difficulty = null,
        int? elapsedTime = null,
        int? mistakes = null,
        bool? isCompleted = null,
        List<B>? history = null,
        int? historyIndex = null,
        HistoryManager? historyManager = null,
        Dictionary<int, int>? numberCounts = null,
        DateTime? startTime = null,
        DateTime? completionTime = null,
        bool? isShowingSolution = null,
        B? savedBoard = null,
        bool? isMarkMode = null,
        bool? isAutoMarkMode = null,
        int? hintsUsed = null,
        GameType? gameType = null,
        GameStatus? status = null,
        SudokuCell? selectedCell = null)
    {
        var newBoard = board ?? Board ?? default!;
        var newInitialBoard = initialBoard ?? InitialBoard ?? default!;
        var newSolution = solution ?? Solution ?? default!;
        var newSavedBoard = savedBoard ?? SavedBoard;
        return new GameState<B>
        {
            Board = newBoard,
            InitialBoard = newInitialBoard,
            Solution = newSolution,
            Difficulty = difficulty ?? Difficulty,
            ElapsedTime = elapsedTime ?? ElapsedTime,
            Mistakes = mistakes ?? Mistakes,
            IsCompleted = isCompleted ?? IsCompleted,
            History = history ?? [.. History],
            HistoryIndex = historyIndex ?? HistoryIndex,
            HistoryManager = historyManager ?? HistoryManager,
            NumberCounts = numberCounts ?? new Dictionary<int, int>(NumberCounts),
            StartTime = startTime ?? StartTime,
            CompletionTime = completionTime ?? CompletionTime,
            IsShowingSolution = isShowingSolution ?? IsShowingSolution,
            SavedBoard = newSavedBoard,
            IsMarkMode = isMarkMode ?? IsMarkMode,
            IsAutoMarkMode = isAutoMarkMode ?? IsAutoMarkMode,
            HintsUsed = hintsUsed ?? HintsUsed,
            GameType = gameType ?? GameType,
            Status = status ?? Status,
            SelectedCell = selectedCell ?? SelectedCell
        };
    }

    public GameState<B> AddCommand(IBoardCommand command)
    {
        var newHistoryManager = (HistoryManager ?? new HistoryManager(InitialBoard)).AddCommand(command);
        var newBoard = (B)newHistoryManager.CurrentBoard;
        var newNumberCounts = newBoard.CalculateNumberCounts();

        return CopyWith(
            board: newBoard,
            historyManager: newHistoryManager,
            numberCounts: newNumberCounts);
    }

    public GameState<B> UpdateBoard(B newBoard)
    {
        var newHistory = new List<B>(History);
        if (HistoryIndex < History.Count - 1)
        {
            newHistory = [.. newHistory.Take(HistoryIndex + 1)];
        }
        newHistory.Add(newBoard);

        if (newHistory.Count > MaxHistorySize)
        {
            newHistory = [.. newHistory.Skip(newHistory.Count - MaxHistorySize)];
        }

        var newNumberCounts = newBoard.CalculateNumberCounts();

        return CopyWith(
            board: newBoard,
            history: newHistory,
            historyIndex: newHistory.Count - 1,
            numberCounts: newNumberCounts);
    }

    public GameState<B> Undo()
    {
        if (HistoryManager != null)
        {
            var (newManager, board) = HistoryManager.Undo();
            if (board == null) return this;
            return CopyWith(
                board: (B)board,
                historyManager: newManager);
        }

        if (!CanUndo) return this;
        var previousBoard = History[HistoryIndex - 1];
        return CopyWith(
            board: previousBoard,
            historyIndex: HistoryIndex - 1);
    }

    public GameState<B> Redo()
    {
        if (HistoryManager != null)
        {
            var (newManager, board) = HistoryManager.Redo();
            if (board == null) return this;
            return CopyWith(
                board: (B)board,
                historyManager: newManager);
        }

        if (!CanRedo) return this;
        var nextBoard = History[HistoryIndex + 1];
        return CopyWith(
            board: nextBoard,
            historyIndex: HistoryIndex + 1);
    }

    public SudokuCell? GetSelectedCell()
    {
        if (Board == null) return null;
        for (int r = 0; r < Board.Size; r++)
        {
            for (int c = 0; c < Board.Size; c++)
            {
                var cell = Board.GetCell(r, c);
                if (cell.IsSelected)
                {
                    return cell;
                }
            }
        }
        return null;
    }

    public GameState<B> ResetGame()
    {
        if (InitialBoard == null) return this;

        var resetBoard = (B)InitialBoard.DeepCopy();
        var newHistoryManager = new HistoryManager(resetBoard);
        return CopyWith(
            board: resetBoard,
            history: [resetBoard],
            historyIndex: 0,
            historyManager: newHistoryManager,
            mistakes: 0,
            hintsUsed: 0,
            status: GameStatus.NotStarted,
            startTime: DateTime.Now);
    }

    public GameState<B> IncrementMistakes()
    {
        return CopyWith(mistakes: Mistakes + 1);
    }

    public GameState<B> MarkCompleted()
    {
        return CopyWith(
            isCompleted: true,
            status: GameStatus.Completed,
            completionTime: DateTime.Now);
    }

    public GameState<B> ToggleMarkMode()
    {
        return CopyWith(isMarkMode: !IsMarkMode);
    }

    public GameState<B> ToggleAutoMarkMode()
    {
        return CopyWith(isAutoMarkMode: !IsAutoMarkMode);
    }

    public GameState<B> ShowSolution()
    {
        return CopyWith(isShowingSolution: true);
    }

    public GameState<B> HideSolution()
    {
        return CopyWith(isShowingSolution: false);
    }

    public GameState<B> UpdateElapsedTime(int elapsedTime)
    {
        return CopyWith(elapsedTime: elapsedTime);
    }

    public GameState<B> SetMistakes(int mistakes)
    {
        return CopyWith(mistakes: mistakes);
    }

    public GameState<B> AddHintsUsed(int hints = 1)
    {
        return CopyWith(hintsUsed: HintsUsed + hints);
    }

    public GameState<B> SetIsCompleted(bool isCompleted)
    {
        return CopyWith(isCompleted: isCompleted);
    }

    public GameState<B> SetCompletionTime(DateTime completionTime)
    {
        return CopyWith(completionTime: completionTime);
    }

    public GameState<B> SetStatus(GameStatus status)
    {
        return CopyWith(status: status);
    }

    public GameState<B> SetSelectedCell(SudokuCell? cell)
    {
        return CopyWith(selectedCell: cell);
    }
}
