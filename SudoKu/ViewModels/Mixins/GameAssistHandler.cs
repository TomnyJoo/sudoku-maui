namespace SudoKu.ViewModels.Mixins;

using SudoKu.Models;
using SudoKu.Models.Boards;

public class GameAssistHandler<B> where B : Board
{
    private readonly Func<GameState<B>?> _getState;
    private readonly Action<GameState<B>> _setState;
    private readonly Func<bool> _getIsPlaying;
    private readonly Action<string> _setHintMessage;
    private readonly Func<B?> _getSolverBoard;

    public GameAssistHandler(
        Func<GameState<B>?> getState,
        Action<GameState<B>> setState,
        Func<bool> getIsPlaying,
        Action<string> setHintMessage,
        Func<B?> getSolverBoard)
    {
        _getState = getState;
        _setState = setState;
        _getIsPlaying = getIsPlaying;
        _setHintMessage = setHintMessage;
        _getSolverBoard = getSolverBoard;
    }

    public void ProvideHint()
    {
        var state = _getState();
        if (state == null || state.Solution == null || !_getIsPlaying())
        {
            _setHintMessage("hintNotAvailable");
            return;
        }

        SudokuCell? targetCell = null;
        var selectedCell = state.GetSelectedCell();
        if (selectedCell is { IsEmpty: true, IsEditable: true })
        {
            targetCell = selectedCell;
        }

        if (targetCell == null)
        {
            for (int r = 0; r < state.Board.Size; r++)
            {
                for (int c = 0; c < state.Board.Size; c++)
                {
                    var cell = state.Board.GetCell(r, c);
                    if (cell.IsEmpty && cell.IsEditable)
                    {
                        targetCell = cell;
                        break;
                    }
                }
                if (targetCell != null) break;
            }
        }

        if (targetCell == null)
        {
            _setHintMessage("noHintAvailable");
            return;
        }

        var solutionValue = state.Solution.GetCell(targetCell.Row, targetCell.Col)?.Value;
        if (solutionValue == null)
        {
            _setHintMessage("hintError");
            return;
        }

        var newBoard = (B)state.Board.SetCellValue(targetCell.Row, targetCell.Col, solutionValue.Value);
        var newState = state.UpdateBoard(newBoard);
        newState = newState with { HintsUsed = state.HintsUsed + 1 };

        if (newBoard.IsComplete() && _getSolverBoard()?.IsValid() == true)
        {
            newState = newState.MarkCompleted();
        }

        _setState(newState);
        _setHintMessage("hintProvided");
    }
}
