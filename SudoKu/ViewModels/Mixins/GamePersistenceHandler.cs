namespace SudoKu.ViewModels.Mixins;

using SudoKu.Models;
using SudoKu.Models.Boards;

public class GamePersistenceHandler<B>(
    Func<GameState<B>?> getState,
    Action<GameState<B>> setState,
    Action<string> handleError,
    Func<Task> saveGameAsync,
    Func<Task<GameState<B>?>> loadGameAsync,
    Func<Task<bool>> hasSavedGameAsync) where B : Board
{
    private readonly Func<GameState<B>?> _getState = getState;
    private readonly Action<GameState<B>> _setState = setState;
    private readonly Action<string> _handleError = handleError;
    private readonly Func<Task> _saveGameAsync = saveGameAsync;
    private readonly Func<Task<GameState<B>?>> _loadGameAsync = loadGameAsync;
    private readonly Func<Task<bool>> _hasSavedGameAsync = hasSavedGameAsync;

    public async Task SaveGameAsync()
    {
        var state = _getState();
        if (state == null || state.IsCompleted || state?.StartTime == null) return;

        try
        {
            await _saveGameAsync();
        }
        catch (Exception ex)
        {
            _handleError($"保存游戏失败: {ex.Message}");
        }
    }

    public async Task LoadGameAsync()
    {
        try
        {
            var savedState = await _loadGameAsync();
            if (savedState != null && !savedState.IsCompleted && savedState?.StartTime != null)
            {
                _setState(savedState);
            }
        }
        catch (Exception ex)
        {
            _handleError($"加载游戏失败: {ex.Message}");
        }
    }

    public async Task<bool> HasSavedGameAsync()
    {
        return await _hasSavedGameAsync();
    }
}
