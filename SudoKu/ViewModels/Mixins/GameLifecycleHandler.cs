namespace SudoKu.ViewModels.Mixins;

using SudoKu.Models;
using SudoKu.Models.Boards;

public class GameLifecycleHandler<B> where B : Board
{
    private readonly Func<GameState<B>?> _getState;
    private readonly Action<GameState<B>> _setState;
    private readonly Func<bool> _getIsShowingSolution;

    public GameLifecycleHandler(
        Func<GameState<B>?> getState,
        Action<GameState<B>> setState,
        Func<bool> getIsShowingSolution)
    {
        _getState = getState;
        _setState = setState;
        _getIsShowingSolution = getIsShowingSolution;
    }

    public void ToggleMarkMode()
    {
        var state = _getState();
        if (state == null) return;
        _setState(state with { IsMarkMode = !state.IsMarkMode });
    }

    public void ToggleAutoMarkMode()
    {
        var state = _getState();
        if (state == null) return;
        _setState(state with { IsAutoMarkMode = !state.IsAutoMarkMode });
    }

    public void ToggleShowSolution()
    {
        var state = _getState();
        if (state == null || state.Solution == null) return;

        if (_getIsShowingSolution())
        {
            if (state.SavedBoard != null)
            {
                _setState(state with { IsShowingSolution = false, SavedBoard = null });
            }
            else
            {
                _setState(state with { IsShowingSolution = false });
            }
        }
        else
        {
            _setState(state with { IsShowingSolution = true, SavedBoard = state.Board });
        }
    }

    public void Undo()
    {
        var state = _getState();
        if (state == null || _getIsShowingSolution()) return;
        if (state.History == null || state.History.Count == 0 || state.HistoryIndex <= 0) return;

        var newIndex = state.HistoryIndex - 1;
        var previousBoard = state.History[newIndex];
        _setState(state with { Board = previousBoard, HistoryIndex = newIndex });
    }

    public void Redo()
    {
        var state = _getState();
        if (state == null || _getIsShowingSolution()) return;
        if (state.History == null || state.History.Count == 0 || state.HistoryIndex >= state.History.Count - 1) return;

        var newIndex = state.HistoryIndex + 1;
        var nextBoard = state.History[newIndex];
        _setState(state with { Board = nextBoard, HistoryIndex = newIndex });
    }

    public bool CanUndo()
    {
        var state = _getState();
        return state?.History != null && state.History.Count > 0 && state.HistoryIndex > 0;
    }

    public bool CanRedo()
    {
        var state = _getState();
        return state?.History != null && state.History.Count > 0 && state.HistoryIndex < state.History.Count - 1;
    }
}
