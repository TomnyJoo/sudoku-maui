namespace SudoKu.Helpers;

using SudoKu.Models;

/// <summary>
/// 游戏布局计算器，参照 Flutter 的 LayoutCalculator 实现。
/// 提供独立的布局计算逻辑，可被多个页面复用。
/// </summary>
public static class LayoutCalculator
{
    /// <summary>
    /// 计算标准数独布局（横屏或竖屏）。
    /// </summary>
    /// <param name="availableWidth">可用宽度。</param>
    /// <param name="availableHeight">可用高度。</param>
    /// <param name="isHorizontal">是否为横屏布局。</param>
    /// <returns>布局结果。</returns>
    public static GameLayout CalculateStandardLayout(
        double availableWidth,
        double availableHeight,
        bool isHorizontal)
    {
        if (isHorizontal)
        {
            return CalculateHorizontalLayout(availableWidth, availableHeight);
        }
        else
        {
            return CalculateVerticalLayout(availableWidth, availableHeight);
        }
    }

    /// <summary>
    /// 计算横屏布局（棋盘在左，键盘在右）。
    /// </summary>
    private static GameLayout CalculateHorizontalLayout(double width, double height)
    {
        // 计算棋盘尺寸
        double boardSize = height;
        double keypadWidth = boardSize * 0.5;
        double keypadHeight = boardSize;

        // 检查宽度是否足够
        double totalWidthNeeded = boardSize + Constants.BoardKeypadSpacing + keypadWidth;
        if (totalWidthNeeded > width)
        {
            // 宽度不足，按比例缩小
            boardSize = (width - Constants.BoardKeypadSpacing) / 1.5;
            keypadWidth = boardSize * 0.5;
            keypadHeight = boardSize;
        }

        // 确保最小单元格尺寸
        double minBoardSize = Constants.MinCellSize * 9;
        if (boardSize < minBoardSize)
        {
            boardSize = minBoardSize;
            keypadWidth = boardSize * 0.5;
            keypadHeight = boardSize;
        }

        // 居中计算
        double totalContentWidth = boardSize + Constants.BoardKeypadSpacing + keypadWidth;
        double startX = (width - totalContentWidth) / 2;

        return new GameLayout(
            startX,
            (height - boardSize) / 2,
            boardSize,
            startX + boardSize + Constants.BoardKeypadSpacing,
            (height - keypadHeight) / 2,
            keypadWidth,
            keypadHeight,
            true
        );
    }

    /// <summary>
    /// 计算竖屏布局（棋盘在上，键盘在下）。
    /// </summary>
    private static GameLayout CalculateVerticalLayout(double width, double height)
    {
        // 计算棋盘尺寸
        double boardSize = width;
        double keypadWidth = boardSize;
        double keypadHeight = boardSize * 0.5;

        // 检查高度是否足够
        double totalHeightNeeded = boardSize + Constants.BoardKeypadSpacing + keypadHeight + Constants.KeypadBottomMargin;
        if (totalHeightNeeded > height)
        {
            // 高度不足，按比例缩小
            boardSize = (height - Constants.BoardKeypadSpacing - Constants.KeypadBottomMargin) / 1.5;
            keypadWidth = boardSize;
            keypadHeight = boardSize * 0.5;
        }

        // 确保最小单元格尺寸
        double minBoardSize = Constants.MinCellSize * 9;
        if (boardSize < minBoardSize)
        {
            boardSize = minBoardSize;
            keypadWidth = boardSize;
            keypadHeight = boardSize * 0.5;
        }

        // 居中计算
        double totalContentHeight = boardSize + Constants.BoardKeypadSpacing + keypadHeight + Constants.KeypadBottomMargin;
        double startY = (height - totalContentHeight) / 2;

        return new GameLayout(
            (width - boardSize) / 2,
            startY,
            boardSize,
            (width - keypadWidth) / 2,
            startY + boardSize + Constants.BoardKeypadSpacing,
            keypadWidth,
            keypadHeight,
            false
        );
    }

    /// <summary>
    /// 计算武士数独布局。
    /// </summary>
    public static GameLayout CalculateSamuraiLayout(
        double availableWidth,
        double availableHeight,
        bool isOverviewMode)
    {
        if (isOverviewMode)
        {
            // 总览模式：显示完整 21x21 棋盘
            return CalculateSamuraiOverviewLayout(availableWidth, availableHeight);
        }
        else
        {
            // 子网格模式：只显示单个 9x9 子盘
            return CalculateStandardLayout(availableWidth, availableHeight, availableWidth >= availableHeight);
        }
    }

    /// <summary>
    /// 计算武士数独总览布局。
    /// </summary>
    private static GameLayout CalculateSamuraiOverviewLayout(double width, double height)
    {
        // 21x21 棋盘，但有效区域是 21x21
        double boardSize = Math.Min(width, height);
        double cellSize = boardSize / Constants.SamuraiBoardSize;

        // 确保最小单元格尺寸
        double minCellSize = Constants.MinCellSize * 0.6; // 总览模式可以更小
        if (cellSize < minCellSize)
        {
            cellSize = minCellSize;
            boardSize = cellSize * Constants.SamuraiBoardSize;
        }

        return new GameLayout(
            (width - boardSize) / 2,
            (height - boardSize) / 2,
            boardSize,
            0,
            0,
            0,
            0,
            false
        );
    }

    /// <summary>
    /// 计算布局利用率。
    /// </summary>
    public static double CalculateUtilizationRatio(GameLayout layout, double availableWidth, double availableHeight)
    {
        double contentArea = layout.BoardSize * layout.BoardSize + layout.KeypadWidth * layout.KeypadHeight;
        double availableArea = availableWidth * availableHeight;
        return availableArea > 0 ? contentArea / availableArea : 0;
    }
}

/// <summary>
/// 游戏布局数据类，包含棋盘和键盘的位置和尺寸信息。
/// </summary>
public record GameLayout(
    double BoardX,
    double BoardY,
    double BoardSize,
    double KeypadX,
    double KeypadY,
    double KeypadWidth,
    double KeypadHeight,
    bool IsHorizontal
);
