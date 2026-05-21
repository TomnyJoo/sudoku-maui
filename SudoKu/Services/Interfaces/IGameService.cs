namespace SudoKu.Services.Interfaces;

using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Generation;

public interface IGameService<B> where B : Board
{
    PuzzleGenerator Generator { get; }
    GameStorageService StorageService { get; }
    IPuzzleSolver Solver { get; }
    SettingsService SettingsService { get; }

    Task<GameState<B>> CreateNewGameAsync(GameType type,
                                          Difficulty difficulty,
                                          CancellationToken token = default,                                          
                                          IProgress<GenerationStage>? progress = null);
    Task<GameState<B>?> LoadGameAsync(GameType type, Difficulty difficulty);
    Task SaveGameAsync(GameState<B> state);
    Task<bool> HasSavedGameAsync(GameType type, Difficulty difficulty);
    bool IsGameCompleted(GameState<B> state);
    bool ValidateBoard(B board);
    GameState<B> ProcessInput(GameState<B> state, int row, int col, int value);
    GameState<B> ProcessHint(GameState<B> state);
    GameState<B> ProcessErase(GameState<B> state);
    GameState<B> ProcessUndo(GameState<B> state);
    GameState<B> ProcessRedo(GameState<B> state);
    GameState<B> ProcessReset(GameState<B> state);
    B CalculateCandidates(B board, bool useAdvancedStrategies = false);
}
