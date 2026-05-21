namespace SudoKu.Helpers;

#region 标准数独常量
/// <summary>
/// 标准数独相关常量
/// </summary>
public static class StandardConstants
{
    /// <summary>棋盘大小</summary>
    public const int BoardSize = 9;
    
    /// <summary>宫格大小</summary>
    public const int BoxSize = 3;
    
    /// <summary>总单元格数</summary>
    public const int CellCount = 81;
    
    /// <summary>最小填数数量（保证唯一解）</summary>
    public const int MinFilledCells = 17;
    
    /// <summary>完整位掩码 (1-9)</summary>
    public const uint FullMask = 0x1FF;
}
#endregion

#region 通用常量
/// <summary>
/// 数独通用常量
/// </summary>
public static class SudokuConstants
{
    /// <summary>最大数字</summary>
    public const int MaxNumber = 9;
    
    /// <summary>最小数字</summary>
    public const int MinNumber = 1;
    
    /// <summary>空单元格值</summary>
    public const int EmptyCellValue = 0;
}
#endregion

/// <summary>
/// 全局常量定义类，集中管理项目中使用的常量值。
/// </summary>
public static class Constants
{
    /// <summary>标准数独棋盘尺寸。</summary>
    public const int StandardBoardSize = StandardConstants.BoardSize;

    /// <summary>标准数独宫格尺寸。</summary>
    public const int StandardBlockSize = StandardConstants.BoxSize;

    /// <summary>武士数独棋盘尺寸。</summary>
    public const int SamuraiBoardSize = SudoKu.Models.Boards.SamuraiConstants.BoardSize;

    /// <summary>最大历史记录数量。</summary>
    public const int MaxHistorySize = 50;

    /// <summary>默认难度等级。</summary>
    public const string DefaultDifficulty = "Medium";

    /// <summary>默认语言设置。</summary>
    public const string DefaultLanguage = "zh-CN";

    /// <summary>数据库文件名。</summary>
    public const string DatabaseFileName = "sudokucollection.db";

    /// <summary>设置文件名前缀。</summary>
    public const string SettingsPrefix = "sudokucollection_settings_";

    /// <summary>自动保存间隔（秒）。</summary>
    public const int AutoSaveIntervalSeconds = 30;

    /// <summary>计时器更新间隔（毫秒）。</summary>
    public const int TimerUpdateIntervalMs = 1000;

    /// <summary>最大提示次数。</summary>
    public const int MaxHints = 3;

    /// <summary>最大错误次数（达到后游戏结束）。</summary>
    public const int MaxMistakes = 3;

    /// <summary>单元格动画持续时间（毫秒）。</summary>
    public const int CellAnimationDurationMs = 150;

    /// <summary>页面切换动画持续时间（毫秒）。</summary>
    public const int PageTransitionDurationMs = 250;

    /// <summary>最小棋盘尺寸。</summary>
    public const int MinBoardSize = 4;

    /// <summary>最大棋盘尺寸。</summary>
    public const int MaxBoardSize = 25;

    /// <summary>候选数显示的最大数量（超过则省略显示）。</summary>
    public const int MaxCandidatesDisplay = 9;

    #region 窗口数独常量

    /// <summary>窗口数独窗口大小（3x3）。</summary>
    public const int WindowSize = 3;

    /// <summary>窗口区域定义：四个窗口的起始位置 (startRow, startCol)。</summary>
    /// <remarks>
    /// 四个窗口位置：
    /// - 左上: (1, 1) → 范围 [1,3] x [1,3]
    /// - 右上: (1, 5) → 范围 [1,3] x [5,7]
    /// - 左下: (5, 1) → 范围 [5,7] x [1,3]
    /// - 右下: (5, 5) → 范围 [5,7] x [5,7]
    /// </remarks>
    public static readonly (int StartRow, int StartCol)[] WindowPositions =
    {
        (1, 1),  // 左上窗口
        (1, 5),  // 右上窗口
        (5, 1),  // 左下窗口
        (5, 5),  // 右下窗口
    };

    #endregion

    #region UI 间距常量

    /// <summary>间距 - 超小 (2.0)</summary>
    public const double SpacingExtraSmall = 2.0;

    /// <summary>间距 - 小 (4.0)</summary>
    public const double SpacingSmall = 4.0;

    /// <summary>间距 - 中 (8.0)</summary>
    public const double SpacingMedium = 8.0;

    /// <summary>间距 - 标准 (12.0)</summary>
    public const double SpacingStandard = 12.0;

    /// <summary>间距 - 大 (16.0)</summary>
    public const double SpacingLarge = 16.0;

    /// <summary>间距 - 超大 (20.0)</summary>
    public const double SpacingExtraLarge = 20.0;

    /// <summary>间距 - 巨大 (24.0)</summary>
    public const double SpacingHuge = 24.0;

    /// <summary>间距 - 最大 (32.0)</summary>
    public const double SpacingMaximum = 32.0;

    #endregion

    #region 布局常量

    /// <summary>最小单元格尺寸。</summary>
    public const double MinCellSize = 32.0;

    /// <summary>最小键盘按钮尺寸。</summary>
    public const double MinKeypadCellSize = 35.0;

    /// <summary>键盘内边距。</summary>
    public const double KeyboardPadding = 2.0;

    /// <summary>键盘按钮间距。</summary>
    public const double KeyboardButtonSpacing = 4.0;

    /// <summary>键盘底部边距。</summary>
    public const double KeypadBottomMargin = 8.0;

    /// <summary>棋盘与键盘间距。</summary>
    public const double BoardKeypadSpacing = 8.0;

    #endregion

    #region 武士数独常量（兼容旧代码）

    /// <summary>武士数独子网格尺寸。</summary>
    public const int SamuraiSubGridSize = SudoKu.Models.Boards.SamuraiConstants.SubGridSize;

    /// <summary>武士数独子网格数量。</summary>
    public const int SamuraiSubGridCount = SudoKu.Models.Boards.SamuraiConstants.SubGridCount;

    /// <summary>武士数独子网格偏移位置。</summary>
    public static readonly (int Row, int Col)[] SamuraiSubGridOffsets = SudoKu.Models.Boards.SamuraiConstants.SubGridOffsets.Select(o => (Row: o.StartRow, Col: o.StartCol)).ToArray();

    #endregion

    #region 动画时长常量

    /// <summary>单元格动画持续时间（毫秒）。</summary>
    public const int AnimationDurationCell = 150;

    /// <summary>页面切换动画持续时间（毫秒）。</summary>
    public const int AnimationDurationPage = 250;

    /// <summary>按钮按压动画持续时间（毫秒）。</summary>
    public const int AnimationDurationButton = 100;

    /// <summary>对话框动画持续时间（毫秒）。</summary>
    public const int AnimationDurationDialog = 200;

    #endregion

    #region 颜色透明度常量

    /// <summary>阴影透明度 - 浅色。</summary>
    public const float ShadowLightAlpha = 0.1f;

    /// <summary>阴影透明度 - 深色。</summary>
    public const float ShadowDarkAlpha = 0.3f;

    /// <summary>渐变透明度。</summary>
    public const float GradientAlpha = 0.15f;

    /// <summary>选中高亮透明度。</summary>
    public const float HighlightAlpha = 0.3f;

    #endregion
}
