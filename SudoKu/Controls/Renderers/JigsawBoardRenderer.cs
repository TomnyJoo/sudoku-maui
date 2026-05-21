namespace SudoKu.Controls.Renderers;

using Microsoft.Maui.Graphics;
using SudoKu.Models;
using SudoKu.Models.Boards;

public class JigsawBoardRenderer : StandardBoardRenderer
{
    public override GameType SupportedGameType => GameType.Jigsaw;

    public override Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board)
    {
        if (cell.IsSelected)
            return Color.FromArgb("#40C4FF");

        if (selectedCell != null)
        {
            if (cell.Row == selectedCell.Row && cell.Col == selectedCell.Col)
                return Color.FromArgb("#40C4FF");

            if (cell.Row == selectedCell.Row || cell.Col == selectedCell.Col)
                return Color.FromArgb("#E0F7FA");

            if (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex)
                return Color.FromArgb("#E0F7FA");
        }

        return Colors.Transparent;
    }

    public override bool ShouldHighlightCell(SudokuCell cell, SudokuCell? selectedCell)
    {
        if (selectedCell == null) return false;

        if (selectedCell.Value > 0 && cell.Value == selectedCell.Value)
            return true;

        return cell.Row == selectedCell.Row ||
               cell.Col == selectedCell.Col ||
               (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex);
    }

    public override SudokuCellView CreateCellView(SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
    {
        var cell = board.Cells[row][col];
        var cellView = new SudokuCellView
        {
            Row = row,
            Col = col,
            CellValue = cell.Value,
            IsFixed = cell.IsFixed,
            IsError = cell.IsError,
            IsSelected = cell.IsSelected,
            IsHighlighted = cell.IsHighlighted,
            Candidates = [.. cell.Candidates],
            ColorIndex = cell.ColorIndex,
            HighlightMistakesEnabled = boardView.HighlightMistakesEnabled,
        };
        ConfigureSpecialCells(cellView, board, row, col, isDarkMode);
        return cellView;
    }

    public override void UpdateCellView(SudokuCellView cellView, SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
    {
        base.UpdateCellView(cellView, boardView, board, row, col, isDarkMode);
        ConfigureSpecialCells(cellView, board, row, col, isDarkMode);
    }

    public override void ConfigureSpecialCells(SudokuCellView cellView, Board board, int row, int col, bool isDarkMode)
    {
        if (board.Regions.Count > 0)
        {
            var jigsawRegions = board.Regions.Where(r => r.Type == RegionType.Jigsaw).ToList();
            for (int idx = 0; idx < jigsawRegions.Count; idx++)
            {
                if (jigsawRegions[idx].Cells.Any(c => c.Row == row && c.Col == col))
                {
                    cellView.RegionBackgroundColor = GetRegionColor(idx, isDarkMode).WithAlpha(0.45f);
                    break;
                }
            }
        }
    }

    public override void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        base.BuildBoard(boardView, board, boardGrid, isDarkMode);
        
        var size = board.Size;
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (_cellViews?[r, c] is SudokuCellView cellView)
                {
                    ConfigureSpecialCells(cellView, board, r, c, isDarkMode);
                }
            }
        }
    }
}
