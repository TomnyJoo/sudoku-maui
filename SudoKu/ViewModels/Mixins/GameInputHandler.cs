namespace SudoKu.ViewModels.Mixins;

using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Models.Commands;

public class GameInputHandler<B> where B : Board
{
    private readonly Func<GameState<B>?> _getState;
    private readonly Action<GameState<B>> _setState;
    private readonly Func<bool> _getIsPlaying;

    public GameInputHandler(
        Func<GameState<B>?> getState,
        Action<GameState<B>> setState,
        Func<bool> getIsPlaying)
    {
        _getState = getState;
        _setState = setState;
        _getIsPlaying = getIsPlaying;
    }

    public void SelectCell(int row, int col)
    {
        var state = _getState();
        if (state == null || !_getIsPlaying()) return;

        var cell = state.Board.GetCell(row, col);
        if (cell.IsFixed)
        {
            var newBoard = (B)state.Board.SelectCell(row, col);
            _setState(state.UpdateBoard(newBoard));
            return;
        }

        if (cell.IsSelected)
        {
            var newBoard = (B)state.Board.SelectCell(-1, -1);
            _setState(state.UpdateBoard(newBoard));
            return;
        }

        var selectedBoard = (B)state.Board.SelectCell(row, col);
        _setState(state.UpdateBoard(selectedBoard));
    }

    public void SetCellValue(int row, int col, int? value)
    {
        var state = _getState();
        if (state == null || !_getIsPlaying()) return;

        var cell = state.Board.GetCell(row, col);
        if (cell.IsFixed) return;

        if (state.IsMarkMode)
        {
            var newCell = cell.ToggleCandidate(value ?? 0);
            var newBoard = (B)state.Board.SetCell(row, col, newCell);
            _setState(state.UpdateBoard(newBoard));
        }
        else
        {
            var newBoard = (B)state.Board.SetCellValue(row, col, value ?? 0);
            var isError = !state.Board.IsValidMove(row, col, value ?? 0);
            if (isError)
            {
                newBoard = (B)newBoard.SetCellError(row, col, true);
            }
            var newState = state.UpdateBoard(newBoard);
            if (isError)
            {
                newState = newState.IncrementMistakes();
            }
            _setState(newState);
        }
    }

    public void ToggleCandidate(int row, int col, int candidate)
    {
        SetCellValue(row, col, candidate);
    }

    public void ClearCell(int row, int col)
    {
        var state = _getState();
        if (state == null) return;

        var cell = state.Board.GetCell(row, col);
        if (cell.IsFixed) return;

        if (cell.Value != null)
        {
            var newBoard = (B)state.Board.ClearCell(row, col);
            newBoard = (B)newBoard.SetCellError(row, col, false);
            _setState(state.UpdateBoard(newBoard));
        }
        else if (cell.Candidates.Count > 0)
        {
            var newCell = cell.ClearCandidates();
            var newBoard = (B)state.Board.SetCell(row, col, newCell);
            _setState(state.UpdateBoard(newBoard));
        }
    }

    public void ClearAllErrors()
    {
        var state = _getState();
        if (state == null) return;

        B newBoard = state.Board;
        for (int r = 0; r < state.Board.Size; r++)
        {
            for (int c = 0; c < state.Board.Size; c++)
            {
                var cell = state.Board.GetCell(r, c);
                if (cell.IsError)
                {
                    newBoard = (B)newBoard.SetCellError(r, c, false);
                }
            }
        }
        _setState(state.UpdateBoard(newBoard));
    }
}
