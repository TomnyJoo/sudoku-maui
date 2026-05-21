namespace SudoKu.Controls.Renderers;

using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

public class WindowBoardRenderer : StandardBoardRenderer
{
    public override GameType SupportedGameType => GameType.Window;

    public (int row, int col) GetWindowOffset(int windowIndex)
    {
        var regions = WindowConstants.WindowRegions;
        if (windowIndex >= 0 && windowIndex < regions.Count)
            return (regions[windowIndex].StartRow, regions[windowIndex].StartCol);
        return (0, 0);
    }

    public bool IsInWindowRegion(int row, int col)
    {
        return WindowBoard.IsInWindowRegion(row, col);
    }

    public int GetWindowIndex(int row, int col)
    {
        var regions = WindowConstants.WindowRegions;
        for (int i = 0; i < regions.Count; i++)
        {
            var region = regions[i];
            if (row >= region.StartRow && row <= region.EndRow &&
                col >= region.StartCol && col <= region.EndCol)
                return i;
        }
        return -1;
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
        }

        if (IsInWindowRegion(row, col))
            return Color.FromArgb("#F5F5F5");

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
        if (IsInWindowRegion(row, col))
        {
            cellView.RegionBackgroundColor = isDarkMode
                ? Color.FromArgb("#1A237E").WithAlpha(0.15f)
                : Color.FromArgb("#E3F2FD");
        }
    }

    public override bool RequiresOverlay(View overlay) => true;

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
