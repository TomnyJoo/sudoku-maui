namespace SudoKu.Controls.Renderers;

using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

public class SamuraiBoardRenderer : StandardBoardRenderer
{
    public override GameType SupportedGameType => GameType.Samurai;

    public static readonly (int row, int col)[] SubGridOffsets =
    [
        (0, 0), (0, 12), (12, 0), (12, 12), (6, 6)
    ];

    public static (int row, int col) GetSubGridOffset(int subGridIndex)
    {
        if (subGridIndex >= 0 && subGridIndex < SubGridOffsets.Length)
            return SubGridOffsets[subGridIndex];
        return (0, 0);
    }

    public bool IsCellInCurrentSubGrid(int row, int col, int currentSubGridIndex)
    {
        // 边界检查
        if (currentSubGridIndex < 0 || currentSubGridIndex >= SubGridOffsets.Length)
            return false;
            
        var (offsetRow, offsetCol) = SubGridOffsets[currentSubGridIndex];
        return row >= offsetRow && row < offsetRow + 9 &&
               col >= offsetCol && col < offsetCol + 9;
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

    public override void SetupViewProperties(SudokuBoardView boardView, Board board)
    {
        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;
        
        if (boardView.IsOverviewMode)
        {
            // 概览模式：显示完整的21x21棋盘
            boardView.SetSamuraiOffset(0, 0);
            boardView.SetGridLineOverlayProperties(GameType.Samurai, board.Size, isDark);
        }
        else
        {
            // 子盘模式：只显示当前子盘的9x9
            var index = boardView.CurrentSubGridIndex;
            if (index < 0 || index >= SubGridOffsets.Length)
                index = 0;
            
            var (offsetR, offsetC) = SubGridOffsets[index];
            boardView.SetSamuraiOffset(offsetR, offsetC);
            
            // 设置网格线为标准9x9
            boardView.SetGridLineOverlayProperties(GameType.Standard, 9, isDark);
        }
        
        // 隐藏杀手数独覆盖层（武士数独不使用）
        boardView.SetKillerOverlaysVisible(false);
    }

    public override int GetDisplaySize(SudokuBoardView boardView, Board board)
    {
        return boardView.IsOverviewMode ? board.Size : 9;
    }

    public override void UpdateGridSize(Grid grid, int boardSize)
    {
        // 武士数独的网格大小由 BuildBoard 根据模式决定，这里不做任何操作
    }

    public override void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        // 清空网格定义和子元素
        boardGrid.Children.Clear();
        boardGrid.RowDefinitions.Clear();
        boardGrid.ColumnDefinitions.Clear();
        
        if (boardView.IsOverviewMode)
        {
            BuildSamuraiOverview(boardView, board, boardGrid, isDarkMode);
        }
        else
        {
            BuildSamuraiSubGrid(boardView, board, boardGrid, isDarkMode);
        }
    }

    private void BuildSamuraiOverview(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        var size = board.Size;
        _cellViews = new SudokuCellView?[size, size];

        for (int i = 0; i < size; i++)
        {
            boardGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });
            boardGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
        }

        for (int idx = 0; idx < SubGridOffsets.Length; idx++)
        {
            var (offsetR, offsetC) = SubGridOffsets[idx];
            for (int r = 0; r < 9; r++)
            {
                for (int c = 0; c < 9; c++)
                {
                    int boardR = offsetR + r;
                    int boardC = offsetC + c;

                    var cell = board.Cells[boardR][boardC];
                    var cellView = new SudokuCellView
                    {
                        Row = boardR,
                        Col = boardC,
                        CellValue = cell.Value,
                        IsFixed = cell.IsFixed,
                        IsError = cell.IsError,
                        IsSelected = cell.IsSelected,
                        IsHighlighted = cell.IsHighlighted,
                        Candidates = [.. cell.Candidates],
                        ColorIndex = cell.ColorIndex,
                        HighlightMistakesEnabled = boardView.HighlightMistakesEnabled,
                    };
                    // 概览模式下单元格不应拦截触摸，点击由父层的 TapGestureRecognizer 统一处理以实现子盘切换
                    cellView.InputTransparent = true;
                    _cellViews[boardR, boardC] = cellView;
                    boardGrid.Add(cellView, boardC, boardR);
                    // 概览模式下不绑定单元格点击事件，由棋盘的 TapGestureRecognizer 统一处理
                    // 这样可以实现点击子盘区域切换到对应子盘，而不是选择单元格
                }
            }
        }
    }

    private void BuildSamuraiSubGrid(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        var index = boardView.CurrentSubGridIndex;
        if (index < 0 || index >= SubGridOffsets.Length)
            index = 0;

        var (offsetR, offsetC) = SubGridOffsets[index];
        _cellViews = new SudokuCellView?[9, 9];

        const int subSize = 9;
        const int blockSize = 3;

        for (int i = 0; i < subSize; i++)
        {
            boardGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });
            boardGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
        }

        var cornerColors = new Color[,]
        {
            { isDarkMode ? Color.FromArgb("#33EF4444") : Color.FromArgb("#33EF4444"), isDarkMode ? Color.FromArgb("#333B82F6") : Color.FromArgb("#333B82F6") },
            { isDarkMode ? Color.FromArgb("#3322C55E") : Color.FromArgb("#3322C55E"), isDarkMode ? Color.FromArgb("#33F59E0B") : Color.FromArgb("#33F59E0B") }
        };

        for (int r = 0; r < subSize; r++)
        {
            for (int c = 0; c < subSize; c++)
            {
                int absR = offsetR + r;
                int absC = offsetC + c;

                var cell = board.Cells[absR][absC];
                var cellView = new SudokuCellView
                {
                    Row = absR,
                    Col = absC,
                    CellValue = cell.Value,
                    IsFixed = cell.IsFixed,
                    IsError = cell.IsError,
                    IsSelected = cell.IsSelected,
                    IsHighlighted = cell.IsHighlighted,
                    Candidates = [.. cell.Candidates],
                    ColorIndex = cell.ColorIndex,
                    HighlightMistakesEnabled = boardView.HighlightMistakesEnabled,
                };

                int blockRow = r / blockSize;
                int blockCol = c / blockSize;
                if (blockRow != 1 && blockCol != 1)
                {
                    int colorRow = blockRow == 0 ? 0 : 1;
                    int colorCol = blockCol == 0 ? 0 : 1;
                    cellView.RegionBackgroundColor = cornerColors[colorRow, colorCol];
                }

                _cellViews[r, c] = cellView;
                boardGrid.Add(cellView, c, r);
                cellView.CellTapped += (s, e) => StandardBoardRenderer.OnCellTapped(boardView, absR, absC);
            }
        }
    }

    public override bool HandleSpecialTap(SudokuBoardView boardView, int row, int col, Board board)
    {
        if (boardView.IsOverviewMode)
        {
            for (int idx = 0; idx < SubGridOffsets.Length; idx++)
            {
                var (offsetR, offsetC) = SubGridOffsets[idx];
                if (row >= offsetR && row < offsetR + 9 && col >= offsetC && col < offsetC + 9)
                {
                    boardView.CurrentSubGridIndex = idx;
                    boardView.IsOverviewMode = false;
                    return true;
                }
            }
            return false;
        }

        return false;
    }
}
