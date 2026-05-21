namespace SudoKu.Controls.Renderers;

using System.Linq;
using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

public class StandardBoardRenderer : IBoardRenderer
{
    public virtual GameType SupportedGameType => GameType.Standard;

    protected SudokuCellView?[,]? _cellViews;

    public virtual void UpdateGridSize(Grid grid, int boardSize)
    {
        grid.RowDefinitions.Clear();
        grid.ColumnDefinitions.Clear();

        for (int i = 0; i < boardSize; i++)
        {
            grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        }
    }

    public virtual int GetDisplaySize(SudokuBoardView boardView, Board board)
    {
        return board.Size;
    }

    public virtual void SetupViewProperties(SudokuBoardView boardView, Board board)
    {
        // 默认实现为空
    }

    public virtual Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board)
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

    public virtual bool ShouldHighlightCell(SudokuCell cell, SudokuCell? selectedCell)
    {
        if (selectedCell == null) return false;

        if (selectedCell.Value > 0 && cell.Value == selectedCell.Value)
            return true;

        return cell.Row == selectedCell.Row ||
               cell.Col == selectedCell.Col ||
               (cell.Row / 3 == selectedCell.Row / 3 && cell.Col / 3 == selectedCell.Col / 3);
    }

    public virtual Color GetRegionColor(int regionIndex, bool isDarkMode)
    {
        var config = GameTypeConfigFactory.GetConfig(SupportedGameType);
        var colors = isDarkMode ? config.RegionColorsDark : config.RegionColorsLight;
        
        if (colors == null || colors.Length == 0)
        {
            return isDarkMode 
                ? Color.FromArgb("#2D2D2D") 
                : Color.FromArgb("#FFFFFF");
        }
        
        return colors[regionIndex % colors.Length];
    }

    public virtual void SetupOverlays(SudokuBoardView boardView, Board board, Grid boardGrid, AbsoluteLayout overlayLayout)
    {
    }

    public virtual SudokuCellView CreateCellView(SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
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

    public virtual void UpdateCellView(SudokuCellView cellView, SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
    {
        var cell = board.Cells[row][col];
        cellView.CellValue = cell.Value;
        cellView.IsFixed = cell.IsFixed;
        cellView.IsError = cell.IsError;
        cellView.IsSelected = cell.IsSelected;
        cellView.IsHighlighted = cell.IsHighlighted;
        cellView.Candidates = [.. cell.Candidates];
        cellView.ColorIndex = cell.ColorIndex;
        cellView.HighlightMistakesEnabled = boardView.HighlightMistakesEnabled;
    }

    public virtual void ConfigureSpecialCells(SudokuCellView cellView, Board board, int row, int col, bool isDarkMode)
    {
    }

    public virtual bool RequiresOverlay(View overlay) => false;

    public virtual void UpdateOverlayVisibility(Board board, AbsoluteLayout overlayLayout, bool showCages)
    {
    }

    public virtual void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        var size = board.Size;
        _cellViews = new SudokuCellView?[size, size];

        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                var cellView = CreateCellView(boardView, board, r, c, isDarkMode);
                if (cellView != null)
                {
                    if (boardView.IsShowingSolution && boardView.SolutionBoard != null)
                    {
                        cellView.SolutionValue = boardView.SolutionBoard.Cells[r][c].Value;
                    }
                    cellView.IsShowingSolution = boardView.IsShowingSolution;
                    _cellViews[r, c] = cellView;
                    boardGrid.Add(cellView, c, r);
                    cellView.CellTapped += (s, e) => StandardBoardRenderer.OnCellTapped(boardView, cellView.Row, cellView.Col);
                }
            }
        }
    }

    public virtual bool HandleSpecialTap(SudokuBoardView boardView, int row, int col, Board board)
    {
        return false;
    }

    public virtual void UpdateAllCells(SudokuBoardView boardView, Board board, bool isDarkMode)
    {
        if (_cellViews == null) return;

        // __cellViews 的实际维度可能与 board.Size 不一致，访问 _cellViews[r,c] 时越界
        int viewRows = _cellViews.GetLength(0);
        int viewCols = _cellViews.GetLength(1);
        int maxRow = Math.Min(viewRows, board.Size);
        int maxCol = Math.Min(viewCols, board.Size);

        for (int r = 0; r < viewRows; r++)
        {
            for (int c = 0; c < viewCols; c++)
            {
                if (!(_cellViews[r, c] is SudokuCellView cellView))
                    continue;

                var absR = cellView.Row;
                var absC = cellView.Col;

                // 防护：仅在绝对坐标在当前 board 范围内才尝试更新，避免索引越界
                if (absR < 0 || absR >= board.Size || absC < 0 || absC >= board.Size)
                    continue;

                UpdateCellView(cellView, boardView, board, absR, absC, isDarkMode);
            }
        }
    }

    public virtual void UpdateAllCellsForSolution(SudokuBoardView boardView, Board board)
    {
        if (_cellViews == null || boardView.SolutionBoard == null) return;

        int viewRows = _cellViews.GetLength(0);
        int viewCols = _cellViews.GetLength(1);

        for (int r = 0; r < viewRows; r++)
        {
            for (int c = 0; c < viewCols; c++)
            {
                if (_cellViews[r, c] is SudokuCellView cellView)
                {
                    var absR = cellView.Row;
                    var absC = cellView.Col;
                    if (absR >= 0 && absR < board.Size && absC >= 0 && absC < board.Size)
                    {
                        if (boardView.IsShowingSolution)
                        {
                            cellView.SolutionValue = boardView.SolutionBoard.Cells[absR][absC].Value;
                        }
                        cellView.IsShowingSolution = boardView.IsShowingSolution;
                    }
                }
            }
        }
    }

    public virtual void UpdateChangedCells(SudokuBoardView boardView, Board oldBoard, Board newBoard, bool isDarkMode)
    {
        if (_cellViews == null) return;

        int viewRows = _cellViews.GetLength(0);
        int viewCols = _cellViews.GetLength(1);

        for (int r = 0; r < viewRows; r++)
        {
            for (int c = 0; c < viewCols; c++)
            {
                if (!(_cellViews[r, c] is SudokuCellView cellView))
                    continue;

                var absR = cellView.Row;
                var absC = cellView.Col;

                if (absR < 0 || absR >= newBoard.Size || absC < 0 || absC >= newBoard.Size)
                    continue;

                var oldCell = oldBoard.Cells[absR][absC];
                var newCell = newBoard.Cells[absR][absC];

                if (oldCell.Value != newCell.Value ||
                    oldCell.IsFixed != newCell.IsFixed ||
                    oldCell.Candidates?.SequenceEqual(newCell.Candidates ?? Enumerable.Empty<int>()) == false ||
                    oldCell.IsError != newCell.IsError)
                {
                    UpdateCellView(cellView, boardView, newBoard, absR, absC, isDarkMode);
                }
            }
        }
    }

    protected static void OnCellTapped(SudokuBoardView boardView, int row, int col)
    {
        var cmd = boardView.SelectedCellCommand;
        if (boardView.Board == null || cmd == null) return;
        SudokuCell? actualCell;
        try
        {
            actualCell = boardView.Board.GetCell(row, col);
        }
        catch
        {
            // 如果坐标不在当前棋盘范围内，则不处理点击
            return;
        }

        if (actualCell == null) return;
        if (cmd.CanExecute(actualCell))
        {
            cmd.Execute(actualCell);
        }
    }
}
