namespace SudoKu.Controls.Renderers;

using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

public class DiagonalBoardRenderer : StandardBoardRenderer
{
    public override GameType SupportedGameType => GameType.Diagonal;

    public override Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board)
    {
        if (selectedCell != null)
        {
            if (cell.IsSelected)
                return Color.FromArgb("#40C4FF");

            if (cell.Row == selectedCell.Row && cell.Col == selectedCell.Col)
                return Color.FromArgb("#40C4FF");

            if (cell.Row == selectedCell.Row || cell.Col == selectedCell.Col)
                return Color.FromArgb("#E0F7FA");

            int blockSize = board.Size == 9 ? 3 : 2;
            if (cell.Row / blockSize == selectedCell.Row / blockSize &&
                cell.Col / blockSize == selectedCell.Col / blockSize)
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
               (cell.Row / 3 == selectedCell.Row / 3 && cell.Col / 3 == selectedCell.Col / 3);
    }

    public Color GetDiagonalColor(bool isPrimary, bool isDarkMode)
    {
        return isDarkMode
            ? Color.FromArgb("#4A4035")
            : Color.FromArgb("#FFF8E1");
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
        int size = board.Size;
        if (row == col || row + col == size - 1)
        {
            cellView.RegionBackgroundColor = isDarkMode
                ? Color.FromArgb("#1A3A4A").WithAlpha(0.5f)
                : Color.FromArgb("#B2EBF2").WithAlpha(0.45f);
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
