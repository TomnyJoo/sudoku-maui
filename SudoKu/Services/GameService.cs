using SudoKu.Exceptions;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Resources;
using SudoKu.Services.Generation;
using SudoKu.Services.Interfaces;

namespace SudoKu.Services;

/// <summary>
/// 游戏服务实现类，管理游戏的核心操作流程。
/// 协调谜题生成器、存储服务和求解器完成游戏创建、输入处理和验证。
/// </summary>
/// <remarks>
/// 初始化游戏服务的新实例。
/// </remarks>
/// <param name="generator">谜题生成器，通过依赖注入提供。</param>
/// <param name="storageService">游戏存储服务，通过依赖注入提供。</param>
/// <param name="solver">谜题求解器，通过依赖注入提供。</param>
/// <param name="settingsService">设置服务，通过依赖注入提供。</param>
public class GameService(PuzzleGenerator generator, GameStorageService storageService, IPuzzleSolver solver, SettingsService settingsService) : IGameService<Board>
{
    private readonly PuzzleGenerator _generator = generator;
    private readonly GameStorageService _storageService = storageService;
    private readonly IPuzzleSolver _solver = solver;
    private readonly SettingsService _settingsService = settingsService;

    public PuzzleGenerator Generator => _generator;
    public GameStorageService StorageService => _storageService;
    public IPuzzleSolver Solver => _solver;
    public SettingsService SettingsService => _settingsService;

    /// <inheritdoc/>
    public async Task<GameState<Board>> CreateNewGameAsync(
        GameType type, Difficulty difficulty, CancellationToken token = default,
        IProgress<GenerationStage>? progress = null)
    {
        var result = await _generator.GenerateAsync(type, difficulty, progress, token);

        if (result.IsCancelled)
        {
            throw new GameGenerationCancelledException();
        }

        if (result.Puzzle is null || result.Solution is null)
        {
            var gameTypeName = GameTypeConfigFactory.GetConfig(type).LocalizedName;
            var difficultyName = difficulty switch
            {
                Difficulty.Beginner => AppResources.Beginner,
                Difficulty.Easy => AppResources.Easy,
                Difficulty.Medium => AppResources.Medium,
                Difficulty.Hard => AppResources.Hard,
                Difficulty.Expert => AppResources.Expert,
                Difficulty.Master => AppResources.Master,
                Difficulty.Custom => AppResources.CustomGame,
                _ => difficulty.ToString()
            };
            throw new InvalidOperationException(string.Format(AppResources.Gen_FailedMessage, gameTypeName, difficultyName));
        }

        var puzzleWithCandidates = result.Puzzle;

        var gameState = new GameState<Board>
        {
            Board = puzzleWithCandidates,
            InitialBoard = result.Puzzle.DeepCopy(),
            Solution = result.Solution,
            Difficulty = difficulty,
            GameType = type,
            Status = GameStatus.Playing,
            StartTime = DateTime.Now,
            History = [puzzleWithCandidates],
            HistoryIndex = 0,
            NumberCounts = puzzleWithCandidates.CalculateNumberCounts()
        };

        await _storageService.SaveGameAsync(gameState);

        return gameState;
    }

    /// <inheritdoc/>
    public async Task<GameState<Board>?> LoadGameAsync(GameType type, Difficulty difficulty)
    {
        return await _storageService.LoadGameAsync(type, difficulty);
    }

    /// <inheritdoc/>
    public async Task SaveGameAsync(GameState<Board> state)
    {
        await _storageService.SaveGameAsync(state);
    }

    /// <inheritdoc/>
    public async Task<bool> HasSavedGameAsync(GameType type, Difficulty difficulty)
    {
        return await GameStorageService.HasSavedGameAsync(type, difficulty);
    }

    /// <inheritdoc/>
    public GameState<Board> ProcessInput(GameState<Board> state, int row, int col, int value)
    {
        if (state.Board is null)
            return state;

        var cell = state.Board.GetCell(row, col);
        if (cell is null || cell.IsFixed)
            return state;

        var newBoard = state.Board.SetCellValue(row, col, value);

        var isError = !state.Board.IsValidMove(row, col, value);
        if (isError)
        {
            newBoard = newBoard.SetCellError(row, col, true);
        }

        if (state.IsAutoMarkMode)
        {
            newBoard = _solver.CalculateCandidates(newBoard, _settingsService.IsAdvancedStrategyEnabled);
        }

        var newState = state.UpdateBoard(newBoard);

        if (isError)
        {
            newState = newState.IncrementMistakes();
        }

        if (newBoard.IsComplete() && ValidateBoard(newBoard))
        {
            newState = newState.MarkCompleted();
        }
        else if (state.Status == GameStatus.NotStarted)
        {
            newState = newState with { Status = GameStatus.Playing };
        }

        return newState;
    }

    /// <inheritdoc/>
    public GameState<Board> ProcessHint(GameState<Board> state)
    {
        if (state.Board is null || state.Solution is null)
            return state;

        SudokuCell? targetCell = null;
        var selectedCell = state.GetSelectedCell();
        if (selectedCell is { IsEmpty: true, IsEditable: true })
        {
            targetCell = selectedCell;
        }

        if (targetCell is null)
        {
            for (int r = 0; r < state.Board.Size; r++)
            {
                for (int c = 0; c < state.Board.Size; c++)
                {
                    var cell = state.Board.Cells[r][c];
                    if (cell.IsEmpty && cell.IsEditable)
                    {
                        targetCell = cell;
                        break;
                    }
                }
                if (targetCell is not null)
                    break;
            }
        }

        if (targetCell is null)
            return state;

        var solutionValue = state.Solution.GetCell(targetCell.Row, targetCell.Col)?.Value;
        if (solutionValue is null)
            return state;

        var newBoard = state.Board.SetCellValue(targetCell.Row, targetCell.Col, solutionValue.Value);

        if (state.IsAutoMarkMode)
        {
            newBoard = _solver.CalculateCandidates(newBoard, _settingsService.IsAdvancedStrategyEnabled);
        }

        var newState = state.UpdateBoard(newBoard);
        newState = newState with { HintsUsed = state.HintsUsed + 1 };

        if (newBoard.IsComplete() && ValidateBoard(newBoard))
        {
            newState = newState.MarkCompleted();
        }

        return newState;
    }

    /// <inheritdoc/>
    public GameState<Board> ProcessErase(GameState<Board> state)
    {
        if (state.Board is null)
            return state;

        var selectedCell = state.GetSelectedCell();
        if (selectedCell is null || selectedCell.IsFixed)
            return state;

        Board newBoard;

        if (state.IsMarkMode)
        {
            var cell = state.Board.GetCell(selectedCell.Row, selectedCell.Col);
            var newCell = cell.ClearCandidates();
            newBoard = state.Board.SetCell(selectedCell.Row, selectedCell.Col, newCell);
        }
        else
        {
            newBoard = state.Board.ClearCell(selectedCell.Row, selectedCell.Col);
            newBoard = newBoard.SetCellError(selectedCell.Row, selectedCell.Col, false);

            if (state.IsAutoMarkMode)
            {
                newBoard = _solver.CalculateCandidates(newBoard, _settingsService.IsAdvancedStrategyEnabled);
            }
        }

        return state.UpdateBoard(newBoard);
    }

    /// <inheritdoc/>
    public bool ValidateBoard(Board board)
    {
        return board.IsValid();
    }

    /// <inheritdoc/>
    public GameState<Board> ProcessUndo(GameState<Board> state)
    {
        if (state.History is null || state.History.Count == 0 || state.HistoryIndex <= 0)
            return state;

        var newIndex = state.HistoryIndex - 1;
        var previousBoard = state.History[newIndex];
        return state with
        {
            Board = previousBoard,
            HistoryIndex = newIndex,
            Mistakes = Math.Max(0, state.Mistakes)
        };
    }

    /// <inheritdoc/>
    public GameState<Board> ProcessRedo(GameState<Board> state)
    {
        if (state.History is null || state.History.Count == 0
            || state.HistoryIndex >= state.History.Count - 1)
            return state;

        var newIndex = state.HistoryIndex + 1;
        var nextBoard = state.History[newIndex];
        return state with
        {
            Board = nextBoard,
            HistoryIndex = newIndex
        };
    }

    /// <inheritdoc/>
    public GameState<Board> ProcessReset(GameState<Board> state)
    {
        if (state.InitialBoard is null)
            return state;

        var resetBoard = state.InitialBoard.DeepCopy();

        return state with
        {
            Board = resetBoard,
            History = [resetBoard],
            HistoryIndex = 0,
            Mistakes = 0,
            HintsUsed = 0,
            Status = GameStatus.NotStarted,
            StartTime = DateTime.Now
        };
    }

    /// <inheritdoc/>
    public bool IsGameCompleted(GameState<Board> state)
    {
        if (state.Board is null)
            return false;

        return state.Board.IsComplete() && ValidateBoard(state.Board);
    }

    /// <inheritdoc/>
    public Board CalculateCandidates(Board board, bool useAdvancedStrategies = false)
    {
        return _solver.CalculateCandidates(board, useAdvancedStrategies);
    }
}
