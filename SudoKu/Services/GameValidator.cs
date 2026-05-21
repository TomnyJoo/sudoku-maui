namespace SudoKu.Services;

using SudoKu.Models;
using SudoKu.Models.Boards;

public class GameValidator
{
    public bool ValidateBoard(Board board)
    {
        foreach (var region in board.Regions)
        {
            if (!region.IsValid())
            {
                return false;
            }
        }
        return true;
    }

    public bool IsValidMove(Board board, int row, int col, int value)
    {
        if (value < 1 || value > board.Size)
        {
            return false;
        }

        var cell = board.GetCell(row, col);
        if (cell.IsFixed)
        {
            return false;
        }

        foreach (var region in board.Regions)
        {
            if (region.ContainsCoordinate(row, col))
            {
                foreach (var regionCell in region.Cells)
                {
                    if (regionCell.Row == row && regionCell.Col == col) continue;
                    if (regionCell.Value == value)
                    {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    public bool ValidatePuzzleSolution(Board puzzle, Board solution)
    {
        if (puzzle.Size != solution.Size)
        {
            return false;
        }

        for (int row = 0; row < puzzle.Size; row++)
        {
            for (int col = 0; col < puzzle.Size; col++)
            {
                var puzzleCell = puzzle.GetCell(row, col);
                var solutionCell = solution.GetCell(row, col);

                if (puzzleCell.Value != null && puzzleCell.Value != solutionCell.Value)
                {
                    return false;
                }
            }
        }

        return true;
    }

    public bool IsGameCompleted(Board board)
    {
        for (int row = 0; row < board.Size; row++)
        {
            for (int col = 0; col < board.Size; col++)
            {
                if (board.GetCell(row, col).Value == null)
                {
                    return false;
                }
            }
        }

        return ValidateBoard(board);
    }

    public bool HasDuplicates(Board board)
    {
        foreach (var region in board.Regions)
        {
            if (!region.IsValid())
            {
                return true;
            }
        }
        return false;
    }
}

public class KillerGameValidator : GameValidator
{
    public bool ValidateKillerCages(KillerBoard board)
    {
        foreach (var cage in board.Cages)
        {
            var cells = cage.CellCoordinates
                .Select(coord => board.GetCell(coord.Row, coord.Col))
                .ToList();

            var filledCells = cells.Where(c => c.Value != null).ToList();
            if (filledCells.Count != cells.Count)
            {
                return false;
            }

            var filledValues = filledCells.Select(c => c.Value!.Value).ToList();
            if (filledValues.Distinct().Count() != filledValues.Count)
            {
                return false;
            }

            var actualSum = filledCells.Sum(c => c.Value!.Value);

            if (actualSum != cage.Sum)
            {
                return false;
            }
        }
        return true;
    }
}
