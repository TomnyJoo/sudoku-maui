namespace SudoKu.ViewModels.Mixins;

using System.Collections.Immutable;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services;
using SudoKu.Services.Solving;

public class GameAutoMarkHandler
{
    private readonly Func<GameState<Board>?> _getState;
    private readonly Action<GameState<Board>> _setState;
    private readonly SettingsService _settingsService;
    private CancellationTokenSource? _debounceCts;

    public GameAutoMarkHandler(
        Func<GameState<Board>?> getState,
        Action<GameState<Board>> setState,
        SettingsService settingsService)
    {
        _getState = getState;
        _setState = setState;
        _settingsService = settingsService;
    }

    public async Task AutoMarkCandidatesAsync(int[]? visibleSubBoards = null)
    {
        CancelDebounce();
        _debounceCts = new CancellationTokenSource();
        var token = _debounceCts.Token;

        try
        {
            await Task.Delay(100, token);
            if (token.IsCancellationRequested) return;

            var state = _getState();
            if (state?.Board == null) return;

            var calculator = new CandidateCalculator(state.Board);
            var useAdvanced = _settingsService.IsAdvancedStrategyEnabled;

            Dictionary<string, HashSet<int>> candidates;

            if (state.Board is SamuraiBoard && visibleSubBoards != null)
            {
                candidates = calculator.ComputeSamuraiCandidates(visibleSubBoards, useAdvanced);
            }
            else
            {
                candidates = calculator.ComputeAllCandidates(useAdvanced);
            }

            var newBoard = state.Board;

            if (state.Board is SamuraiBoard && visibleSubBoards != null)
            {
                foreach (var subBoardIndex in visibleSubBoards)
                {
                    var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subBoardIndex];
                    for (int row = startRow; row < startRow + 9; row++)
                    {
                        for (int col = startCol; col < startCol + 9; col++)
                        {
                            var key = $"{row},{col}";
                            if (candidates.TryGetValue(key, out var cellCandidates))
                            {
                                newBoard = newBoard.SetCellCandidates(row, col, cellCandidates.ToImmutableHashSet());
                            }
                        }
                    }
                }
            }
            else
            {
                foreach (var (key, cellCandidates) in candidates)
                {
                    var parts = key.Split(',');
                    if (parts.Length == 2 &&
                        int.TryParse(parts[0], out var row) &&
                        int.TryParse(parts[1], out var col))
                    {
                        newBoard = newBoard.SetCellCandidates(row, col, cellCandidates.ToImmutableHashSet());
                    }
                }
            }

            _setState(state with { Board = newBoard });
        }
        catch (OperationCanceledException) { }
        finally { _debounceCts = null; }
    }

    public void CancelDebounce()
    {
        _debounceCts?.Cancel();
        _debounceCts?.Dispose();
        _debounceCts = null;
    }

    public void Dispose()
    {
        CancelDebounce();
    }
}
