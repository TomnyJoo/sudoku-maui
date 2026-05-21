# Controls 架构重构实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 重构 SudoKu\Controls 目录架构，解决职责混乱、代码重复、缺乏配置化的问题，使其满足配置式、模块化的要求。

**架构：** 引入游戏配置接口（IGameConfig）统一管理游戏特定配置；创建渲染器基类（BaseBoardRenderer）提取公共逻辑；将游戏专用逻辑从 SudokuBoardView 移动到对应的渲染器和配置类中。

**技术栈：** .NET MAUI、C#、依赖注入、工厂模式、模板方法模式

---

## 文件结构

**新建文件：**
- `SudoKu/Controls/Config/IGameConfig.cs` - 游戏配置接口，定义颜色、偏移量等配置
- `SudoKu/Controls/Config/BaseGameConfig.cs` - 游戏配置基类，提供默认实现
- `SudoKu/Controls/Config/StandardGameConfig.cs` - 标准数独配置
- `SudoKu/Controls/Config/SamuraiGameConfig.cs` - 武士数独配置
- `SudoKu/Controls/Config/JigsawGameConfig.cs` - 锯齿数独配置
- `SudoKu/Controls/Config/DiagonalGameConfig.cs` - 对角线数独配置
- `SudoKu/Controls/Config/KillerGameConfig.cs` - 杀手数独配置
- `SudoKu/Controls/Config/WindowGameConfig.cs` - 窗口数独配置
- `SudoKu/Controls/Config/GameConfigFactory.cs` - 配置工厂
- `SudoKu/Controls/Renderers/BaseBoardRenderer.cs` - 渲染器基类

**修改文件：**
- `SudoKu/Controls/SudokuBoardView.cs` - 移除游戏专用逻辑，重新组织属性
- `SudoKu/Controls/Renderers/StandardBoardRenderer.cs` - 继承基类
- `SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs` - 继承基类，添加武士数独专用逻辑
- `SudoKu/Controls/Renderers/JigsawBoardRenderer.cs` - 继承基类，添加锯齿数独专用逻辑
- `SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs` - 继承基类
- `SudoKu/Controls/Renderers/KillerBoardRenderer.cs` - 继承基类
- `SudoKu/Controls/Renderers/WindowBoardRenderer.cs` - 继承基类

---

## 任务 1：创建游戏配置接口和基类

**文件：**
- 创建：`SudoKu/Controls/Config/IGameConfig.cs`
- 创建：`SudoKu/Controls/Config/BaseGameConfig.cs`

- [ ] **步骤 1：创建 IGameConfig 接口**

```csharp
namespace SudoKu.Controls.Config;

using Microsoft.Maui.Graphics;
using SudoKu.Models;

/// <summary>
/// 游戏配置接口，定义游戏特定的配置项
/// </summary>
public interface IGameConfig
{
    /// <summary>游戏类型</summary>
    GameType GameType { get; }
    
    /// <summary>获取区域颜色</summary>
    Color GetRegionColor(int regionIndex, bool isDarkMode);
    
    /// <summary>获取选中单元格背景色</summary>
    Color GetSelectedCellBackgroundColor(bool isDarkMode);
    
    /// <summary>获取高亮单元格背景色</summary>
    Color GetHighlightedCellBackgroundColor(bool isDarkMode);
    
    /// <summary>获取单元格背景色</summary>
    Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board, bool isDarkMode);
}
```

- [ ] **步骤 2：创建 BaseGameConfig 基类**

```csharp
namespace SudoKu.Controls.Config;

using Microsoft.Maui.Graphics;
using SudoKu.Models;
using SudoKu.Models.Boards;

/// <summary>
/// 游戏配置基类，提供默认实现
/// </summary>
public abstract class BaseGameConfig : IGameConfig
{
    public abstract GameType GameType { get; }
    
    protected static readonly Color[] RegionColorsLight =
    [
        Color.FromArgb("#FFFFFF"),
        Color.FromArgb("#F5F5F5"),
    ];

    protected static readonly Color[] RegionColorsDark =
    [
        Color.FromArgb("#2D2D2D"),
        Color.FromArgb("#383838"),
    ];
    
    public virtual Color GetRegionColor(int regionIndex, bool isDarkMode)
    {
        var colors = isDarkMode ? RegionColorsDark : RegionColorsLight;
        return colors[regionIndex % colors.Length];
    }
    
    public virtual Color GetSelectedCellBackgroundColor(bool isDarkMode)
    {
        return Color.FromArgb("#40C4FF");
    }
    
    public virtual Color GetHighlightedCellBackgroundColor(bool isDarkMode)
    {
        return isDarkMode ? Color.FromArgb("#33FFFFFF") : Color.FromArgb("#E0F7FA");
    }
    
    public virtual Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board, bool isDarkMode)
    {
        if (cell.IsSelected)
            return GetSelectedCellBackgroundColor(isDarkMode);

        if (selectedCell != null)
        {
            if (cell.Row == selectedCell.Row && cell.Col == selectedCell.Col)
                return GetSelectedCellBackgroundColor(isDarkMode);

            if (cell.Row == selectedCell.Row || cell.Col == selectedCell.Col)
                return GetHighlightedCellBackgroundColor(isDarkMode);

            int blockSize = board.Size == 9 ? 3 : 2;
            if (cell.Row / blockSize == selectedCell.Row / blockSize &&
                cell.Col / blockSize == selectedCell.Col / blockSize)
                return GetHighlightedCellBackgroundColor(isDarkMode);
        }

        return Colors.Transparent;
    }
}
```

- [ ] **步骤 3：构建验证接口和基类**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 4：Commit**

```bash
git add SudoKu/Controls/Config/IGameConfig.cs SudoKu/Controls/Config/BaseGameConfig.cs
git commit -m "feat(config): add game config interface and base class"
```

---

## 任务 2：创建具体游戏配置类

**文件：**
- 创建：`SudoKu/Controls/Config/StandardGameConfig.cs`
- 创建：`SudoKu/Controls/Config/SamuraiGameConfig.cs`
- 创建：`SudoKu/Controls/Config/JigsawGameConfig.cs`
- 创建：`SudoKu/Controls/Config/DiagonalGameConfig.cs`
- 创建：`SudoKu/Controls/Config/KillerGameConfig.cs`
- 创建：`SudoKu/Controls/Config/WindowGameConfig.cs`

- [ ] **步骤 1：创建 StandardGameConfig**

```csharp
namespace SudoKu.Controls.Config;

using SudoKu.Models;

/// <summary>
/// 标准数独配置
/// </summary>
public class StandardGameConfig : BaseGameConfig
{
    public override GameType GameType => GameType.Standard;
}
```

- [ ] **步骤 2：创建 SamuraiGameConfig**

```csharp
namespace SudoKu.Controls.Config;

using Microsoft.Maui.Graphics;
using SudoKu.Models;
using SudoKu.Models.Boards;

/// <summary>
/// 武士数独配置
/// </summary>
public class SamuraiGameConfig : BaseGameConfig
{
    public override GameType GameType => GameType.Samurai;
    
    /// <summary>武士数独五个子盘在21x21棋盘中的偏移</summary>
    public static readonly (int row, int col)[] SubGridOffsets =
    [
        (0, 0), (0, 12), (12, 0), (12, 12), (6, 6)
    ];
    
    public override Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board, bool isDarkMode)
    {
        if (cell.IsSelected)
            return GetSelectedCellBackgroundColor(isDarkMode);

        if (selectedCell != null)
        {
            if (cell.Row == selectedCell.Row && cell.Col == selectedCell.Col)
                return GetSelectedCellBackgroundColor(isDarkMode);

            if (cell.Row == selectedCell.Row || cell.Col == selectedCell.Col)
                return GetHighlightedCellBackgroundColor(isDarkMode);

            if (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex)
                return GetHighlightedCellBackgroundColor(isDarkMode);
        }

        return Colors.Transparent;
    }
    
    public (int row, int col) GetSubGridOffset(int subGridIndex)
    {
        if (subGridIndex >= 0 && subGridIndex < SubGridOffsets.Length)
            return SubGridOffsets[subGridIndex];
        return (0, 0);
    }
}
```

- [ ] **步骤 3：创建 JigsawGameConfig**

```csharp
namespace SudoKu.Controls.Config;

using Microsoft.Maui.Graphics;
using SudoKu.Models;
using SudoKu.Models.Boards;

/// <summary>
/// 锯齿数独配置
/// </summary>
public class JigsawGameConfig : BaseGameConfig
{
    public override GameType GameType => GameType.Jigsaw;
    
    private static readonly Color[] RegionColorsLight =
    [
        Color.FromArgb("#FFF3E0"),
        Color.FromArgb("#E8F5E8"),
        Color.FromArgb("#E3F2FD"),
        Color.FromArgb("#F3E5F5"),
        Color.FromArgb("#E0F2F1"),
        Color.FromArgb("#FFF8E1"),
        Color.FromArgb("#E8EAF6"),
        Color.FromArgb("#FBE9E7"),
        Color.FromArgb("#F9FAFB"),
    ];

    private static readonly Color[] RegionColorsDark =
    [
        Color.FromArgb("#4A3535"),
        Color.FromArgb("#2D4A2D"),
        Color.FromArgb("#2D2D4A"),
        Color.FromArgb("#4A3540"),
        Color.FromArgb("#40354A"),
        Color.FromArgb("#4A4035"),
        Color.FromArgb("#2D354A"),
        Color.FromArgb("#4A3535"),
    ];
    
    public override Color GetRegionColor(int regionIndex, bool isDarkMode)
    {
        var colors = isDarkMode ? RegionColorsDark : RegionColorsLight;
        return colors[regionIndex % colors.Length];
    }
    
    public override Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board, bool isDarkMode)
    {
        if (cell.IsSelected)
            return GetSelectedCellBackgroundColor(isDarkMode);

        if (selectedCell != null)
        {
            if (cell.Row == selectedCell.Row && cell.Col == selectedCell.Col)
                return GetSelectedCellBackgroundColor(isDarkMode);

            if (cell.Row == selectedCell.Row || cell.Col == selectedCell.Col)
                return GetHighlightedCellBackgroundColor(isDarkMode);

            if (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex)
                return GetHighlightedCellBackgroundColor(isDarkMode);
        }

        return Colors.Transparent;
    }
}
```

- [ ] **步骤 4：创建 DiagonalGameConfig**

```csharp
namespace SudoKu.Controls.Config;

using Microsoft.Maui.Graphics;
using SudoKu.Models;

/// <summary>
/// 对角线数独配置
/// </summary>
public class DiagonalGameConfig : BaseGameConfig
{
    public override GameType GameType => GameType.Diagonal;
    
    /// <summary>获取对角线颜色</summary>
    public Color GetDiagonalColor(bool isPrimary, bool isDarkMode)
    {
        return isDarkMode
            ? Color.FromArgb("#4A4035")
            : Color.FromArgb("#FFF8E1");
    }
}
```

- [ ] **步骤 5：创建 KillerGameConfig**

```csharp
namespace SudoKu.Controls.Config;

using Microsoft.Maui.Graphics;
using SudoKu.Models;
using SudoKu.Models.Boards;

/// <summary>
/// 杀手数独配置
/// </summary>
public class KillerGameConfig : BaseGameConfig
{
    public override GameType GameType => GameType.Killer;
    
    private static readonly Color CageBackgroundLight = Color.FromArgb("#FFFDE7");
    private static readonly Color CageBackgroundDark = Color.FromArgb("#4A4530");
    
    public Color GetCageBackgroundColor(bool isDarkMode)
    {
        return isDarkMode ? CageBackgroundDark : CageBackgroundLight;
    }
    
    public override Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board, bool isDarkMode)
    {
        if (cell.IsSelected)
            return GetSelectedCellBackgroundColor(isDarkMode);

        if (selectedCell != null)
        {
            if (cell.Row == selectedCell.Row && cell.Col == selectedCell.Col)
                return GetSelectedCellBackgroundColor(isDarkMode);

            if (cell.Row == selectedCell.Row || cell.Col == selectedCell.Col)
                return GetHighlightedCellBackgroundColor(isDarkMode);

            int blockSize = board.Size == 9 ? 3 : 2;
            if (cell.Row / blockSize == selectedCell.Row / blockSize &&
                cell.Col / blockSize == selectedCell.Col / blockSize)
                return GetHighlightedCellBackgroundColor(isDarkMode);

            if (cell.ColorIndex.HasValue && cell.ColorIndex == selectedCell.ColorIndex)
                return Color.FromArgb("#FFF9C4");
        }

        return Colors.Transparent;
    }
}
```

- [ ] **步骤 6：创建 WindowGameConfig**

```csharp
namespace SudoKu.Controls.Config;

using SudoKu.Models;

/// <summary>
/// 窗口数独配置
/// </summary>
public class WindowGameConfig : BaseGameConfig
{
    public override GameType GameType => GameType.Window;
}
```

- [ ] **步骤 7：构建验证所有配置类**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 8：Commit**

```bash
git add SudoKu/Controls/Config/
git commit -m "feat(config): add game-specific config classes"
```

---

## 任务 3：创建配置工厂

**文件：**
- 创建：`SudoKu/Controls/Config/GameConfigFactory.cs`

- [ ] **步骤 1：创建 GameConfigFactory**

```csharp
namespace SudoKu.Controls.Config;

using SudoKu.Models;

/// <summary>
/// 游戏配置工厂，根据游戏类型创建对应的配置实例
/// </summary>
public static class GameConfigFactory
{
    private static readonly Dictionary<GameType, IGameConfig> _configs = new()
    {
        { GameType.Standard, new StandardGameConfig() },
        { GameType.Diagonal, new DiagonalGameConfig() },
        { GameType.Jigsaw, new JigsawGameConfig() },
        { GameType.Killer, new KillerGameConfig() },
        { GameType.Samurai, new SamuraiGameConfig() },
        { GameType.Window, new WindowGameConfig() }
    };

    private static readonly IGameConfig _defaultConfig = new StandardGameConfig();

    /// <summary>
    /// 根据游戏类型获取配置
    /// </summary>
    public static IGameConfig GetConfig(GameType gameType)
    {
        return _configs.GetValueOrDefault(gameType, _defaultConfig);
    }

    /// <summary>
    /// 注册自定义配置
    /// </summary>
    public static void RegisterConfig(GameType gameType, IGameConfig config)
    {
        _configs[gameType] = config;
    }
}
```

- [ ] **步骤 2：构建验证工厂**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 3：Commit**

```bash
git add SudoKu/Controls/Config/GameConfigFactory.cs
git commit -m "feat(config): add game config factory"
```

---

## 任务 4：创建渲染器基类

**文件：**
- 创建：`SudoKu/Controls/Renderers/BaseBoardRenderer.cs`

- [ ] **步骤 1：创建 BaseBoardRenderer**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Controls.Config;
using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

/// <summary>
/// 渲染器基类，提供默认实现
/// </summary>
public abstract class BaseBoardRenderer : IBoardRenderer
{
    public abstract GameType SupportedGameType { get; }
    
    protected IGameConfig Config { get; }
    
    protected BaseBoardRenderer()
    {
        Config = GameConfigFactory.GetConfig(SupportedGameType);
    }
    
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

    public virtual Color GetCellBackgroundColor(SudokuCell cell, SudokuCell? selectedCell, int row, int col, Board board)
    {
        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;
        return Config.GetCellBackgroundColor(cell, selectedCell, row, col, board, isDark);
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
        return Config.GetRegionColor(regionIndex, isDarkMode);
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
}
```

- [ ] **步骤 2：构建验证基类**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 3：Commit**

```bash
git add SudoKu/Controls/Renderers/BaseBoardRenderer.cs
git commit -m "feat(renderer): add base board renderer"
```

---

## 任务 5：重构 StandardBoardRenderer

**文件：**
- 修改：`SudoKu/Controls/Renderers/StandardBoardRenderer.cs`

- [ ] **步骤 1：重构 StandardBoardRenderer 继承基类**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Models;

/// <summary>
/// 标准数独渲染器
/// </summary>
public class StandardBoardRenderer : BaseBoardRenderer
{
    public override GameType SupportedGameType => GameType.Standard;
}
```

- [ ] **步骤 2：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 3：Commit**

```bash
git add SudoKu/Controls/Renderers/StandardBoardRenderer.cs
git commit -m "refactor(renderer): simplify StandardBoardRenderer to use base class"
```

---

## 任务 6：重构 SamuraiBoardRenderer

**文件：**
- 修改：`SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs`

- [ ] **步骤 1：重构 SamuraiBoardRenderer 继承基类并添加专用逻辑**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Controls.Config;
using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;

/// <summary>
/// 武士数独渲染器
/// </summary>
public class SamuraiBoardRenderer : BaseBoardRenderer
{
    public override GameType SupportedGameType => GameType.Samurai;
    
    protected new SamuraiGameConfig SamuraiConfig => (SamuraiGameConfig)Config;
    
    public (int row, int col) GetSubGridOffset(int subGridIndex)
    {
        return SamuraiConfig.GetSubGridOffset(subGridIndex);
    }
    
    public bool IsCellInCurrentSubGrid(int row, int col, int currentSubGridIndex)
    {
        var (offsetRow, offsetCol) = SamuraiConfig.GetSubGridOffset(currentSubGridIndex);
        return row >= offsetRow && row < offsetRow + 9 &&
               col >= offsetCol && col < offsetCol + 9;
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
    
    public override bool RequiresOverlay(View overlay) => true;
}
```

- [ ] **步骤 2：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 3：Commit**

```bash
git add SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs
git commit -m "refactor(renderer): simplify SamuraiBoardRenderer to use base class and config"
```

---

## 任务 7：重构 JigsawBoardRenderer

**文件：**
- 修改：`SudoKu/Controls/Renderers/JigsawBoardRenderer.cs`

- [ ] **步骤 1：重构 JigsawBoardRenderer 继承基类并添加专用逻辑**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Controls.Config;
using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Graphics;

/// <summary>
/// 锯齿数独渲染器
/// </summary>
public class JigsawBoardRenderer : BaseBoardRenderer
{
    public override GameType SupportedGameType => GameType.Jigsaw;
    
    protected new JigsawGameConfig JigsawConfig => (JigsawGameConfig)Config;
    
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
        var cellView = base.CreateCellView(boardView, board, row, col, isDarkMode);
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
                    cellView.RegionBackgroundColor = JigsawConfig.GetRegionColor(idx, isDarkMode).WithAlpha(0.45f);
                    break;
                }
            }
        }
    }
}
```

- [ ] **步骤 2：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 3：Commit**

```bash
git add SudoKu/Controls/Renderers/JigsawBoardRenderer.cs
git commit -m "refactor(renderer): simplify JigsawBoardRenderer to use base class and config"
```

---

## 任务 8：重构其他渲染器

**文件：**
- 修改：`SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/KillerBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/WindowBoardRenderer.cs`

- [ ] **步骤 1：重构 DiagonalBoardRenderer**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Controls.Config;
using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Graphics;

/// <summary>
/// 对角线数独渲染器
/// </summary>
public class DiagonalBoardRenderer : BaseBoardRenderer
{
    public override GameType SupportedGameType => GameType.Diagonal;
    
    protected new DiagonalGameConfig DiagonalConfig => (DiagonalGameConfig)Config;
    
    public override SudokuCellView CreateCellView(SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
    {
        var cellView = base.CreateCellView(boardView, board, row, col, isDarkMode);
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
}
```

- [ ] **步骤 2：重构 KillerBoardRenderer**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Controls.Config;
using SudoKu.Models;
using SudoKu.Models.Boards;
using Microsoft.Maui.Graphics;

/// <summary>
/// 杀手数独渲染器
/// </summary>
public class KillerBoardRenderer : BaseBoardRenderer
{
    public override GameType SupportedGameType => GameType.Killer;
    
    protected new KillerGameConfig KillerConfig => (KillerGameConfig)Config;
    
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
    
    public override bool RequiresOverlay(View overlay) => true;
}
```

- [ ] **步骤 3：重构 WindowBoardRenderer**

```csharp
namespace SudoKu.Controls.Renderers;

using SudoKu.Models;

/// <summary>
/// 窗口数独渲染器
/// </summary>
public class WindowBoardRenderer : BaseBoardRenderer
{
    public override GameType SupportedGameType => GameType.Window;
}
```

- [ ] **步骤 4：构建验证所有渲染器**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 5：Commit**

```bash
git add SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs SudoKu/Controls/Renderers/KillerBoardRenderer.cs SudoKu/Controls/Renderers/WindowBoardRenderer.cs
git commit -m "refactor(renderer): simplify remaining renderers to use base class and config"
```

---

## 任务 9：重构 SudokuBoardView - 移除游戏专用逻辑

**文件：**
- 修改：`SudoKu/Controls/SudokuBoardView.cs`

- [ ] **步骤 1：移除武士数独专用常量和方法**

删除以下代码：
- `SamuraiSubGridOffsets` 常量（已移动到 `SamuraiGameConfig`）
- `JigsawRegionColorsLight/Dark` 常量（已移动到 `JigsawGameConfig`）
- `BuildSamuraiSubGrid` 方法（将在后续任务中重构）
- `BuildSamuraiOverview` 方法（将在后续任务中重构）
- `HandleSamuraiOverviewTap` 方法（将在后续任务中重构）
- `IsCellInWindowRegion` 方法（已移动到 `WindowConstants`）

- [ ] **步骤 2：重新组织属性分组**

将属性按照以下分组重新组织：

```csharp
#region 可绑定属性 - 公用属性

/// <summary>标识 Board 绑定属性。</summary>
public static readonly BindableProperty BoardProperty = ...;

/// <summary>标识 GameType 绑定属性。</summary>
public static readonly BindableProperty GameTypeProperty = ...;

/// <summary>标识 SelectedCellCommand 绑定属性。</summary>
public static readonly BindableProperty SelectedCellCommandProperty = ...;

/// <summary>标识 SelectedCell 绑定属性。</summary>
public static readonly BindableProperty SelectedCellProperty = ...;

/// <summary>标识 IsShowingSolution 绑定属性。</summary>
public static readonly BindableProperty IsShowingSolutionProperty = ...;

/// <summary>标识 SolutionBoard 绑定属性。</summary>
public static readonly BindableProperty SolutionBoardProperty = ...;

#endregion

#region 可绑定属性 - 显示配置

/// <summary>标识 HighlightMistakesEnabled 绑定属性。</summary>
public static readonly BindableProperty HighlightMistakesEnabledProperty = ...;

#endregion

#region 可绑定属性 - 武士数独专用

/// <summary>标识 CurrentSubGridIndex 绑定属性。</summary>
public static readonly BindableProperty CurrentSubGridIndexProperty = ...;

/// <summary>标识 IsOverviewMode 绑定属性。</summary>
public static readonly BindableProperty IsOverviewModeProperty = ...;

#endregion

#region 可绑定属性 - 对角线数独专用

/// <summary>标识 ShowDiagonalLines 绑定属性。</summary>
public static readonly BindableProperty ShowDiagonalLinesProperty = ...;

#endregion

#region 可绑定属性 - 锯齿数独专用

/// <summary>标识 ShowRegionNumbers 绑定属性。</summary>
public static readonly BindableProperty ShowRegionNumbersProperty = ...;

#endregion

#region 可绑定属性 - 杀手数独专用

/// <summary>标识 ShowCageSums 绑定属性。</summary>
public static readonly BindableProperty ShowCageSumsProperty = ...;

/// <summary>标识 ShowCages 绑定属性。</summary>
public static readonly BindableProperty ShowCagesProperty = ...;

#endregion
```

- [ ] **步骤 3：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建失败，因为 `BuildSamuraiSubGrid` 和 `BuildSamuraiOverview` 方法被删除但仍在被调用

- [ ] **步骤 4：暂时注释掉武士数独相关调用**

在 `BuildBoard` 方法中，暂时注释掉武士数独相关代码：

```csharp
// TODO: 重构武士数独构建逻辑
if (GameType == GameType.Samurai)
{
    // if (IsOverviewMode)
    //     BuildSamuraiOverview();
    // else
    //     BuildSamuraiSubGrid();
    // return;
    
    // 暂时使用标准构建逻辑
    _samuraiOffsetRow = 0;
    _samuraiOffsetCol = 0;
}
```

- [ ] **步骤 5：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 6：Commit**

```bash
git add SudoKu/Controls/SudokuBoardView.cs
git commit -m "refactor(board): remove game-specific logic from SudokuBoardView and reorganize properties"
```

---

## 任务 10：重构武士数独构建逻辑

**文件：**
- 修改：`SudoKu/Controls/SudokuBoardView.cs`
- 修改：`SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs`

- [ ] **步骤 1：在 SamuraiBoardRenderer 中添加构建方法**

```csharp
public void BuildSamuraiSubGrid(SudokuBoardView boardView, Board board, Grid boardGrid, int currentSubGridIndex, bool isDarkMode)
{
    var index = currentSubGridIndex;
    if (index < 0 || index >= SamuraiConfig.SubGridOffsets.Length)
        index = 0;

    var (offsetR, offsetC) = SamuraiConfig.GetSubGridOffset(index);
    
    boardGrid.Children.Clear();
    boardGrid.RowDefinitions.Clear();
    boardGrid.ColumnDefinitions.Clear();
    
    const int subSize = 9;
    
    for (int i = 0; i < subSize; i++)
    {
        boardGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });
        boardGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
    }
    
    var cornerColors = new Color[,]
    {
        { isDark ? Color.FromArgb("#33EF4444") : Color.FromArgb("#33EF4444"), isDark ? Color.FromArgb("#333B82F6") : Color.FromArgb("#333B82F6") },
        { isDark ? Color.FromArgb("#3322C55E") : Color.FromArgb("#3322C55E"), isDark ? Color.FromArgb("#33F59E0B") : Color.FromArgb("#33F59E0B") }
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

            int blockRow = r / 3;
            int blockCol = c / 3;
            if (blockRow != 1 && blockCol != 1)
            {
                int colorRow = blockRow == 0 ? 0 : 1;
                int colorCol = blockCol == 0 ? 0 : 1;
                cellView.RegionBackgroundColor = cornerColors[colorRow, colorCol];
            }

            boardGrid.Add(cellView, c, r);
        }
    }
}
```

- [ ] **步骤 2：在 SudokuBoardView 中调用渲染器方法**

恢复 `BuildBoard` 方法中的武士数独逻辑：

```csharp
if (GameType == GameType.Samurai)
{
    if (IsOverviewMode)
        BuildSamuraiOverview();
    else
    {
        var samuraiRenderer = _renderer as SamuraiBoardRenderer;
        samuraiRenderer?.BuildSamuraiSubGrid(this, Board, _boardGrid, CurrentSubGridIndex, isDark);
        _samuraiOffsetRow = SamuraiGameConfig.SubGridOffsets[CurrentSubGridIndex].row;
        _samuraiOffsetCol = SamuraiGameConfig.SubGridOffsets[CurrentSubGridIndex].col;
        _currentBoardSize = 9;
    }
    return;
}
```

- [ ] **步骤 3：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 4：Commit**

```bash
git add SudoKu/Controls/SudokuBoardView.cs SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs
git commit -m "refactor(samurai): move samurai build logic to SamuraiBoardRenderer"
```

---

## 任务 11：运行完整测试

**文件：**
- 无

- [ ] **步骤 1：运行完整构建**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 2：运行应用程序验证功能**

手动测试：
1. 启动应用程序
2. 测试标准数独游戏
3. 测试武士数独游戏（切换子网格、总览模式）
4. 测试锯齿数独游戏（区域颜色显示）
5. 测试对角线数独游戏（对角线显示）
6. 测试杀手数独游戏（笼子显示）
7. 测试窗口数独游戏

预期：所有游戏类型功能正常

- [ ] **步骤 3：最终 Commit**

```bash
git add .
git commit -m "refactor(controls): complete architecture refactoring

- Add game config interface and base class
- Add game-specific config classes
- Add game config factory
- Add base board renderer
- Refactor all renderers to use base class and config
- Remove game-specific logic from SudokuBoardView
- Reorganize properties by functionality
- Move samurai build logic to SamuraiBoardRenderer

This refactoring improves:
- Separation of concerns
- Code reusability
- Configurability
- Extensibility
"
```

---

## 执行交接

计划已完成并保存到 `docs/superpowers/plans/2026-05-18-refactor-controls-architecture.md`。两种执行方式：

**1. 子代理驱动（推荐）** - 每个任务调度一个新的子代理，任务间进行审查，快速迭代

**2. 内联执行** - 在当前会话中使用 executing-plans 执行任务，批量执行并设有检查点

**选哪种方式？**
