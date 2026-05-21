namespace SudoKu.Controls.Renderers;

using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

public interface IBoardRenderer
{
    GameType SupportedGameType { get; }
    void UpdateGridSize(Grid grid, int boardSize);
    
    /// <summary>
    /// 获取当前显示的棋盘大小
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="board">棋盘数据</param>
    /// <returns>当前显示的棋盘大小</returns>
    int GetDisplaySize(SudokuBoardView boardView, Board board);
    
    /// <summary>
    /// 设置视图属性（如偏移量、覆盖层等）
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="board">棋盘数据</param>
    void SetupViewProperties(SudokuBoardView boardView, Board board);
    Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board);
    bool ShouldHighlightCell(SudokuCell cell, SudokuCell? selectedCell);
    Color GetRegionColor(int regionIndex, bool isDarkMode);
    void SetupOverlays(SudokuBoardView boardView, Board board, Grid boardGrid, AbsoluteLayout overlayLayout);
    SudokuCellView CreateCellView(SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode);
    void UpdateCellView(SudokuCellView cellView, SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode);
    void ConfigureSpecialCells(SudokuCellView cellView, Board board, int row, int col, bool isDarkMode);
    bool RequiresOverlay(View overlay);
    void UpdateOverlayVisibility(Board board, AbsoluteLayout overlayLayout, bool showCages);

    /// <summary>
    /// 构建棋盘视图
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="board">棋盘数据</param>
    /// <param name="boardGrid">网格容器</param>
    /// <param name="isDarkMode">是否深色模式</param>
    void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode);

    /// <summary>
    /// 处理特殊点击（如武士数独概览模式）
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="row">点击的行</param>
    /// <param name="col">点击的列</param>
    /// <param name="board">棋盘数据</param>
    /// <returns>是否已处理该点击</returns>
    bool HandleSpecialTap(SudokuBoardView boardView, int row, int col, Board board);

    /// <summary>
    /// 更新所有单元格视图
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="board">棋盘数据</param>
    /// <param name="isDarkMode">是否深色模式</param>
    void UpdateAllCells(SudokuBoardView boardView, Board board, bool isDarkMode);

    /// <summary>
    /// 更新答案显示
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="board">棋盘数据</param>
    void UpdateAllCellsForSolution(SudokuBoardView boardView, Board board);

    /// <summary>
    /// 更新变化的单元格
    /// </summary>
    /// <param name="boardView">棋盘视图</param>
    /// <param name="oldBoard">旧棋盘数据</param>
    /// <param name="newBoard">新棋盘数据</param>
    /// <param name="isDarkMode">是否深色模式</param>
    void UpdateChangedCells(SudokuBoardView boardView, Board oldBoard, Board newBoard, bool isDarkMode);
}
