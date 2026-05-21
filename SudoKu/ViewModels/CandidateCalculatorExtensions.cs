using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving;

namespace SudoKu.ViewModels;

public static class CandidateCalculatorExtensions
{
    public static Dictionary<string, HashSet<int>> ComputeSamuraiCandidates(
        this CandidateCalculator calculator,
        int[] visibleSubBoards,
        bool useAdvancedStrategies = true)
    {
        var allCandidates = calculator.ComputeAllCandidates(useAdvancedStrategies);

        var result = new Dictionary<string, HashSet<int>>();

        foreach (var subBoardIndex in visibleSubBoards)
        {
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subBoardIndex];
            for (int row = startRow; row < startRow + 9; row++)
            {
                for (int col = startCol; col < startCol + 9; col++)
                {
                    var key = $"{row},{col}";
                    if (allCandidates.TryGetValue(key, out var candidates))
                    {
                        result[key] = candidates;
                    }
                }
            }
        }

        return result;
    }
}