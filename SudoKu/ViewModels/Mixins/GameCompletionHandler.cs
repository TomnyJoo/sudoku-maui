namespace SudoKu.ViewModels.Mixins;

using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services;

public class GameCompletionHandler
{
    private readonly Func<GameState<Board>?> _getState;
    private readonly Action<GameState<Board>> _setState;
    private readonly StatisticsStorageService _statisticsService;
    private readonly AudioService _audioService;

    public GameCompletionHandler(
        Func<GameState<Board>?> getState,
        Action<GameState<Board>> setState,
        StatisticsStorageService statisticsService,
        AudioService audioService)
    {
        _getState = getState;
        _setState = setState;
        _statisticsService = statisticsService;
        _audioService = audioService;
    }

    public async Task HandleCompletionAsync(Func<Task> onNavigateToCompletion)
    {
        var state = _getState();
        if (state == null) return;

        await _statisticsService.RecordGameAsync(
            state.GameType,
            state.Difficulty,
            state.ElapsedTime,
            state.Mistakes,
            state.HintsUsed,
            true);

        await GameStorageService.DeleteGameAsync(state.GameType, state.Difficulty);

        var isNewRecord = await _statisticsService.IsNewBestScoreAsync(
            state.GameType,
            state.Difficulty,
            state.ElapsedTime,
            state.Mistakes);

        await _audioService.PlayCompleteSoundAsync();
        await onNavigateToCompletion();
    }
}
