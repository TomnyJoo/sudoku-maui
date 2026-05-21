namespace SudoKu.Controls.Renderers;

using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

public class KillerBoardRenderer : StandardBoardRenderer
{
    public override GameType SupportedGameType => GameType.Killer;

    private static readonly Color CageBackgroundLight = Color.FromArgb("#FFFDE7");
    private static readonly Color CageBackgroundDark = Color.FromArgb("#4A4530");

    public Color GetCageBackgroundColor(bool isDarkMode)
    {
        return isDarkMode ? CageBackgroundDark : CageBackgroundLight;
    }

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

            int blockSize = board.Size == 9 ? 3 : 2;
            if (cell.Row / blockSize == selectedCell.Row / blockSize &&
                cell.Col / blockSize == selectedCell.Col / blockSize)
                return Color.FromArgb("#E0F7FA");

            if (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex)
                return Color.FromArgb("#FFF9C4");
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
               (cell.Row / 3 == selectedCell.Row / 3 && cell.Col / 3 == selectedCell.Col / 3) ||
               (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex);
    }

    public override SudokuCellView CreateCellView(SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
    {
        var cell = board.Cells[row][col];
        return new SudokuCellView
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
    }

    public override bool RequiresOverlay(View overlay) => true;

    public override void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        base.BuildBoard(boardView, board, boardGrid, isDarkMode);
    }
}
