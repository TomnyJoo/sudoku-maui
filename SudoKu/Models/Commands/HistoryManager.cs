namespace SudoKu.Models.Commands;

using System.Collections.Immutable;
using SudoKu.Models.Boards;

public sealed class HistoryManager(Board initialBoard, ImmutableList<IBoardCommand>? commands = null, int currentIndex = -1)
{
    public const int DefaultMaxSize = 50;

    public Board InitialBoard { get; } = initialBoard;
    public ImmutableList<IBoardCommand> Commands { get; } = commands ?? [];
    public int CurrentIndex { get; } = currentIndex;

    public int MaxSize { get; set; } = DefaultMaxSize;

    public bool CanUndo => CurrentIndex >= 0;
    public bool CanRedo => CurrentIndex < Commands.Count - 1;

    public int Length => CurrentIndex + 1;

    public Board CurrentBoard
    {
        get
        {
            if (CurrentIndex < 0) return InitialBoard;
            return Replay(CurrentIndex);
        }
    }

    public HistoryManager AddCommand(IBoardCommand command)
    {
        var newCommands = Commands;
        newCommands = newCommands.RemoveRange(CurrentIndex + 1, newCommands.Count - CurrentIndex - 1);
        newCommands = newCommands.Add(command);
        var newIndex = newCommands.Count - 1;

        if (newCommands.Count > MaxSize)
        {
            var excessCount = newCommands.Count - MaxSize;
            var newInitialBoard = InitialBoard;

            for (int i = 0; i < excessCount; i++)
            {
                newInitialBoard = newCommands[i].Execute(newInitialBoard);
            }

            var trimmedCommands = newCommands.RemoveRange(0, excessCount);
            var trimmedIndex = newIndex - excessCount;

            return new HistoryManager(newInitialBoard, trimmedCommands, trimmedIndex);
        }

        return new HistoryManager(InitialBoard, newCommands, newIndex);
    }

    public (HistoryManager, Board?) Undo()
    {
        if (!CanUndo) return (this, null);
        var newIndex = CurrentIndex - 1;
        return (
            new HistoryManager(InitialBoard, Commands, newIndex),
            newIndex < 0 ? InitialBoard : Replay(newIndex)
        );
    }

    public (HistoryManager, Board?) Redo()
    {
        if (!CanRedo) return (this, null);
        var newIndex = CurrentIndex + 1;
        return (
            new HistoryManager(InitialBoard, Commands, newIndex),
            Replay(newIndex)
        );
    }

    private Board Replay(int upToIndex)
    {
        var board = InitialBoard;
        for (int i = 0; i <= upToIndex; i++)
        {
            board = Commands[i].Execute(board);
        }
        return board;
    }

    public HistoryManager Clear() => new(InitialBoard);
}
