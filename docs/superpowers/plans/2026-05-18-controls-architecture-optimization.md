# Controls 架构优化实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 优化 SudoKu\Controls 目录架构，解决职责混乱、代码重复问题，基于项目已有的 GameTypeConfig 和渲染器模式进行扩展。

**架构：** 扩展现有 GameTypeConfig 添加 UI 配置属性；扩展 IBoardRenderer 接口添加 BuildBoard 方法；将游戏专用逻辑从 SudokuBoardView 移动到对应的渲染器中；统一颜色管理。

**技术栈：** .NET MAUI、C#、工厂模式、模板方法模式

---

## 文件结构

**修改文件：**
- `SudoKu/Models/GameType.cs` - 扩展 GameTypeConfig 添加 UI 配置属性
- `SudoKu/Controls/Renderers/IBoardRenderer.cs` - 扩展接口添加 BuildBoard 方法
- `SudoKu/Controls/Renderers/StandardBoardRenderer.cs` - 实现 BuildBoard 默认逻辑
- `SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs` - 实现武士数独专用 BuildBoard 逻辑
- `SudoKu/Controls/Renderers/JigsawBoardRenderer.cs` - 统一颜色定义
- `SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs` - 统一颜色定义
- `SudoKu/Controls/Renderers/KillerBoardRenderer.cs` - 统一颜色定义
- `SudoKu/Controls/Renderers/WindowBoardRenderer.cs` - 统一颜色定义
- `SudoKu/Controls/SudokuBoardView.cs` - 移除游戏专用逻辑，删除重复定义

---

## 任务 1：扩展 GameTypeConfig 添加 UI 配置属性

**文件：**
- 修改：`SudoKu/Models/GameType.cs:33-90`

- [ ] **步骤 1：在 GameTypeConfig 类中添加 UI 配置属性**

在 `SudoKu/Models/GameType.cs` 文件的 `GameTypeConfig` 类中，在 `ShowCustomGame` 属性后添加以下属性：

```csharp
    /// <summary>获取是否在首页显示"自定义游戏"按钮。</summary>
    public bool ShowCustomGame { get; init; }

    /// <summary>获取主题颜色（用于 UI 显示）。</summary>
    public Color? ThemeColor { get; init; }

    /// <summary>获取浅色模式下的区域颜色数组。</summary>
    public Color[]? RegionColorsLight { get; init; }

    /// <summary>获取深色模式下的区域颜色数组。</summary>
    public Color[]? RegionColorsDark { get; init; }

    /// <summary>获取本地化的显示名称。</summary>
    public string LocalizedName => AppResources.ResourceManager.GetString(NameKey)
        ?? Type.ToString();
```

- [ ] **步骤 2：在 GameTypeConfigFactory 中为各游戏类型添加 UI 配置**

在 `SudoKu/Models/GameType.cs` 文件的 `GameTypeConfigFactory` 静态构造函数中，为各游戏类型添加 UI 配置。

修改 Standard 配置（约第 68-81 行）：

```csharp
        _configs[GameType.Standard] = new GameTypeConfig
        {
            Type = GameType.Standard,
            NameKey = "GameType_Standard",
            BoardSize = 9,
            SupportedRegionTypes = { RegionType.Block, RegionType.Row, RegionType.Column },
            SupportsCustomRules = false,
            SupportsDifficulty = true,
            IconPath = "standard.png",
            DescriptionKey = "GameType_Standard_Desc",
            ShowCustomGame = true,
            ThemeColor = Color.FromArgb("#4CAF50"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            }
        };
```

修改 Jigsaw 配置（约第 83-96 行）：

```csharp
        _configs[GameType.Jigsaw] = new GameTypeConfig
        {
            Type = GameType.Jigsaw,
            NameKey = "GameType_Jigsaw",
            BoardSize = 9,
            SupportedRegionTypes = { RegionType.Jigsaw, RegionType.Row, RegionType.Column },
            SupportsCustomRules = true,
            SupportsDifficulty = true,
            IconPath = "jigsaw.png",
            DescriptionKey = "GameType_Jigsaw_Desc",
            ShowCustomGame = true,
            ThemeColor = Color.FromArgb("#FF9800"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFF3E0"),
                Color.FromArgb("#E8F5E8"),
                Color.FromArgb("#E3F2FD"),
                Color.FromArgb("#F3E5F5"),
                Color.FromArgb("#E0F2F1"),
                Color.FromArgb("#FFF8E1"),
                Color.FromArgb("#E8EAF6"),
                Color.FromArgb("#FBE9E7"),
                Color.FromArgb("#F9FAFB"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#4A3535"),
                Color.FromArgb("#2D4A2D"),
                Color.FromArgb("#2D2D4A"),
                Color.FromArgb("#4A3540"),
                Color.FromArgb("#40354A"),
                Color.FromArgb("#2D4A4A"),
                Color.FromArgb("#4A4035"),
                Color.FromArgb("#2D354A"),
                Color.FromArgb("#4A3535"),
            }
        };
```

修改 Diagonal 配置（约第 98-111 行）：

```csharp
        _configs[GameType.Diagonal] = new GameTypeConfig
        {
            Type = GameType.Diagonal,
            NameKey = "GameType_Diagonal",
            BoardSize = 9,
            SupportedRegionTypes = { RegionType.Block, RegionType.Row, RegionType.Column, RegionType.Diagonal },
            SupportsCustomRules = false,
            SupportsDifficulty = true,
            IconPath = "diagonal.png",
            DescriptionKey = "GameType_Diagonal_Desc",
            ShowCustomGame = true,
            ThemeColor = Color.FromArgb("#2196F3"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            }
        };
```

修改 Window 配置（约第 113-126 行）：

```csharp
        _configs[GameType.Window] = new GameTypeConfig
        {
            Type = GameType.Window,
            NameKey = "GameType_Window",
            BoardSize = 9,
            SupportedRegionTypes = { RegionType.Block, RegionType.Row, RegionType.Column, RegionType.Window },
            SupportsCustomRules = false,
            SupportsDifficulty = true,
            IconPath = "window.png",
            DescriptionKey = "GameType_Window_Desc",
            ShowCustomGame = true,
            ThemeColor = Color.FromArgb("#9C27B0"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            }
        };
```

修改 Killer 配置（约第 128-141 行）：

```csharp
        _configs[GameType.Killer] = new GameTypeConfig
        {
            Type = GameType.Killer,
            NameKey = "GameType_Killer",
            BoardSize = 9,
            SupportedRegionTypes = { RegionType.Block, RegionType.Cage },
            SupportsCustomRules = true,
            SupportsDifficulty = true,
            IconPath = "killer.png",
            DescriptionKey = "GameType_Killer_Desc",
            ShowCustomGame = true,
            ThemeColor = Color.FromArgb("#F44336"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            }
        };
```

修改 Samurai 配置（约第 143-156 行）：

```csharp
        _configs[GameType.Samurai] = new GameTypeConfig
        {
            Type = GameType.Samurai,
            NameKey = "GameType_Samurai",
            BoardSize = 21,
            SupportedRegionTypes = { RegionType.Block, RegionType.Row, RegionType.Column },
            SupportsCustomRules = false,
            SupportsDifficulty = true,
            IconPath = "samurai.png",
            DescriptionKey = "GameType_Samurai_Desc",
            ShowCustomGame = true,
            ThemeColor = Color.FromArgb("#00BCD4"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            }
        };
```

修改 Custom 配置（约第 158-171 行）：

```csharp
        _configs[GameType.Custom] = new GameTypeConfig
        {
            Type = GameType.Custom,
            NameKey = "GameType_Custom",
            BoardSize = 9,
            SupportedRegionTypes = { RegionType.Block, RegionType.Row, RegionType.Column, RegionType.Custom },
            SupportsCustomRules = true,
            SupportsDifficulty = false,
            IconPath = "custom.png",
            DescriptionKey = "GameType_Custom_Desc",
            ShowCustomGame = false,
            ThemeColor = Color.FromArgb("#607D8B"),
            RegionColorsLight = new Color[]
            {
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            },
            RegionColorsDark = new Color[]
            {
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            }
        };
```

- [ ] **步骤 3：添加必要的 using 语句**

在 `SudoKu/Models/GameType.cs` 文件顶部，确保有以下 using 语句：

```csharp
using Microsoft.Maui.Graphics;
```

- [ ] **步骤 4：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 5：Commit**

```bash
git add SudoKu/Models/GameType.cs
git commit -m "feat(config): extend GameTypeConfig with UI configuration properties"
```

---

## 任务 2：扩展 IBoardRenderer 接口

**文件：**
- 修改：`SudoKu/Controls/Renderers/IBoardRenderer.cs`

- [ ] **步骤 1：在 IBoardRenderer 接口中添加新方法**

在 `SudoKu/Controls/Renderers/IBoardRenderer.cs` 文件中，在 `UpdateOverlayVisibility` 方法后添加以下方法：

```csharp
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
```

- [ ] **步骤 2：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建失败，因为所有渲染器都需要实现新方法

- [ ] **步骤 3：Commit**

```bash
git add SudoKu/Controls/Renderers/IBoardRenderer.cs
git commit -m "feat(renderer): extend IBoardRenderer with BuildBoard and HandleSpecialTap methods"
```

---

## 任务 3：在 StandardBoardRenderer 中实现新方法

**文件：**
- 修改：`SudoKu/Controls/Renderers/StandardBoardRenderer.cs`

- [ ] **步骤 1：添加 BuildBoard 方法的默认实现**

在 `SudoKu/Controls/Renderers/StandardBoardRenderer.cs` 文件末尾，在 `UpdateOverlayVisibility` 方法后添加：

```csharp
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
                    cellView.CellTapped += (s, e) => OnCellTapped(boardView, cellView.Row, cellView.Col);
                }
            }
        }
    }

    public virtual bool HandleSpecialTap(SudokuBoardView boardView, int row, int col, Board board)
    {
        return false;
    }

    private void OnCellTapped(SudokuBoardView boardView, int row, int col)
    {
        var cmd = boardView.SelectedCellCommand;
        var actualCell = boardView.Board?.GetCell(row, col);
        if (cmd?.CanExecute(actualCell) == true && actualCell != null)
        {
            cmd.Execute(actualCell);
        }
    }
```

- [ ] **步骤 2：添加 _cellViews 字段**

在 `StandardBoardRenderer` 类的开头，添加字段：

```csharp
public class StandardBoardRenderer : IBoardRenderer
{
    public virtual GameType SupportedGameType => GameType.Standard;

    protected SudokuCellView?[,]? _cellViews;

    private static readonly Color[] RegionColorsLight =
```

- [ ] **步骤 3：修改 CreateCellView 方法使用 _cellViews**

修改 `CreateCellView` 方法，将创建的 cellView 存储到 _cellViews：

```csharp
    public virtual SudokuCellView CreateCellView(SudokuBoardView boardView, Board board, int row, int col, bool isDarkMode)
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
        
        if (_cellViews != null)
        {
            _cellViews[row, col] = cellView;
        }
        
        return cellView;
    }
```

- [ ] **步骤 4：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 5：Commit**

```bash
git add SudoKu/Controls/Renderers/StandardBoardRenderer.cs
git commit -m "feat(renderer): implement BuildBoard and HandleSpecialTap in StandardBoardRenderer"
```

---

## 任务 4：在 SamuraiBoardRenderer 中实现武士专用逻辑

**文件：**
- 修改：`SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs`

- [ ] **步骤 1：添加必要的字段和常量**

在 `SamuraiBoardRenderer` 类中，确保有以下字段：

```csharp
public class SamuraiBoardRenderer : StandardBoardRenderer
{
    public override GameType SupportedGameType => GameType.Samurai;

    public static readonly (int row, int col)[] SubGridOffsets =
    [
        (0, 0), (0, 12), (12, 0), (12, 12), (6, 6)
    ];

    private int _currentSubGridIndex = 0;
    private bool _isOverviewMode = false;

    private static readonly Color[] RegionColorsLight =
```

- [ ] **步骤 2：重写 BuildBoard 方法**

在 `SamuraiBoardRenderer` 类中，重写 `BuildBoard` 方法：

```csharp
    public override void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
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
                    _cellViews[boardR, boardC] = cellView;
                    boardGrid.Add(cellView, boardC, boardR);
                    cellView.CellTapped += (s, e) => OnCellTapped(boardView, boardR, boardC);
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
                cellView.CellTapped += (s, e) => OnCellTapped(boardView, absR, absC);
            }
        }
    }
```

- [ ] **步骤 3：重写 HandleSpecialTap 方法**

在 `SamuraiBoardRenderer` 类中，重写 `HandleSpecialTap` 方法：

```csharp
    public override bool HandleSpecialTap(SudokuBoardView boardView, int row, int col, Board board)
    {
        if (!boardView.IsOverviewMode)
            return false;

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
```

- [ ] **步骤 4：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 5：Commit**

```bash
git add SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs
git commit -m "feat(renderer): implement Samurai-specific BuildBoard and HandleSpecialTap"
```

---

## 任务 5：在其他渲染器中实现新方法

**文件：**
- 修改：`SudoKu/Controls/Renderers/JigsawBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/KillerBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/WindowBoardRenderer.cs`

- [ ] **步骤 1：在 JigsawBoardRenderer 中添加默认实现**

在 `JigsawBoardRenderer.cs` 文件末尾添加：

```csharp
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
```

- [ ] **步骤 2：在 DiagonalBoardRenderer 中添加默认实现**

在 `DiagonalBoardRenderer.cs` 文件末尾添加：

```csharp
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
```

- [ ] **步骤 3：在 KillerBoardRenderer 中添加默认实现**

在 `KillerBoardRenderer.cs` 文件末尾添加：

```csharp
    public override bool RequiresOverlay(View overlay) => true;

    public override void BuildBoard(SudokuBoardView boardView, Board board, Grid boardGrid, bool isDarkMode)
    {
        base.BuildBoard(boardView, board, boardGrid, isDarkMode);
    }
```

- [ ] **步骤 4：在 WindowBoardRenderer 中添加默认实现**

在 `WindowBoardRenderer.cs` 文件末尾添加：

```csharp
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
```

- [ ] **步骤 5：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 6：Commit**

```bash
git add SudoKu/Controls/Renderers/JigsawBoardRenderer.cs SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs SudoKu/Controls/Renderers/KillerBoardRenderer.cs SudoKu/Controls/Renderers/WindowBoardRenderer.cs
git commit -m "feat(renderer): implement BuildBoard in all renderers"
```

---

## 任务 6：重构 SudokuBoardView 使用渲染器的 BuildBoard 方法

**文件：**
- 修改：`SudoKu/Controls/SudokuBoardView.cs`

- [ ] **步骤 1：删除重复的颜色定义**

删除 `SudokuBoardView.cs` 中的以下代码（约第 55-72 行）：

```csharp
    private static readonly Color[] JigsawRegionColorsLight =
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

    private static readonly Color[] JigsawRegionColorsDark =
    [
        Color.FromArgb("#4A3535"),
        Color.FromArgb("#2D4A2D"),
        Color.FromArgb("#2D2D4A"),
        Color.FromArgb("#4A3540"),
        Color.FromArgb("#40354A"),
        Color.FromArgb("#2D4A4A"),
        Color.FromArgb("#4A4035"),
        Color.FromArgb("#2D354A"),
        Color.FromArgb("#4A3535"),
    ];
```

- [ ] **步骤 2：删除重复的 SamuraiSubGridOffsets 定义**

删除 `SudokuBoardView.cs` 中的以下代码（约第 36-40 行）：

```csharp
    private static readonly (int row, int col)[] SamuraiSubGridOffsets =
    [
        (0, 0), (0, 12), (12, 0), (12, 12), (6, 6)
    ];
```

- [ ] **步骤 3：修改 BuildBoard 方法调用渲染器**

修改 `BuildBoard` 方法（约第 476-515 行），将游戏专用逻辑移到渲染器：

```csharp
    private void BuildBoard()
    {
        _boardGrid.Children.Clear();
        _boardGrid.RowDefinitions.Clear();
        _boardGrid.ColumnDefinitions.Clear();

        if (Board is null) return;

        var isDark = Application.Current?.RequestedTheme == AppTheme.Dark;

        _gridLineOverlay.GameType = GameType;
        _gridLineOverlay.BoardSize = Board.Size;
        _gridLineOverlay.IsDarkTheme = isDark;

        var cageRegions = Board.Regions.Where(r => r.Type == RegionType.Cage).ToList();
        _killerCageBackgroundOverlay!.Regions = cageRegions;
        _killerCageBackgroundOverlay.BoardSize = Board.Size;
        _killerCageBackgroundOverlay.IsVisible = GameType == GameType.Killer;

        _killerCageOverlay!.Regions = cageRegions;
        _killerCageOverlay.BoardSize = Board.Size;
        _killerCageOverlay.IsVisible = GameType == GameType.Killer && ShowCages;

        if (GameType == GameType.Killer && ShowCages)
        {
            _killerCageOverlay.Invalidate();
        }

        _samuraiOffsetRow = 0;
        _samuraiOffsetCol = 0;
        _currentBoardSize = Board.Size;

        _renderer.UpdateGridSize(_boardGrid, Board.Size);
        _renderer.BuildBoard(this, Board, _boardGrid, isDark);
    }
```

- [ ] **步骤 4：删除武士专用方法**

删除 `SudokuBoardView.cs` 中的以下方法（约第 600-699 行）：
- `BuildSamuraiSubGrid()`
- `BuildSamuraiOverview()`
- `HandleSamuraiOverviewTap()`

- [ ] **步骤 5：修改 OnBoardTapped 方法使用渲染器**

修改 `OnBoardTapped` 方法（约第 268-305 行）：

```csharp
    private void OnBoardTapped(object? sender, TappedEventArgs e)
    {
        if (Board is null) return;

        var tapPosition = e.GetPosition(_overlayLayout);
        if (tapPosition is null) return;

        var position = tapPosition.Value;
        var bounds = _overlayLayout.Bounds;

        double cellWidth = bounds.Width / _currentBoardSize;
        double cellHeight = bounds.Height / _currentBoardSize;

        int col = (int)(position.X / cellWidth);
        int row = (int)(position.Y / cellHeight);

        if (row < 0 || row >= _currentBoardSize || col < 0 || col >= _currentBoardSize)
            return;

        if (GameType == GameType.Samurai)
        {
            if (IsOverviewMode)
            {
                if (_renderer.HandleSpecialTap(this, row, col, Board))
                    return;
            }
            else
            {
                row += _samuraiOffsetRow;
                col += _samuraiOffsetCol;
            }
        }

        if (row < 0 || row >= Board.Size || col < 0 || col >= Board.Size)
            return;

        var cmd = SelectedCellCommand;
        var actualCell = Board?.GetCell(row, col);
        if (cmd?.CanExecute(actualCell) == true && actualCell != null)
        {
            cmd.Execute(actualCell);
        }
    }
```

- [ ] **步骤 6：删除 OnCellTapped 方法**

删除 `SudokuBoardView.cs` 中的 `OnCellTapped` 方法（约第 516-524 行），因为现在由渲染器处理。

- [ ] **步骤 7：删除 IsCellInWindowRegion 方法**

删除 `SudokuBoardView.cs` 中的 `IsCellInWindowRegion` 方法（约第 526-530 行），因为现在由渲染器处理。

- [ ] **步骤 8：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 9：Commit**

```bash
git add SudoKu/Controls/SudokuBoardView.cs
git commit -m "refactor(board): move game-specific logic to renderers, remove duplicates"
```

---

## 任务 7：统一渲染器中的颜色定义

**文件：**
- 修改：`SudoKu/Controls/Renderers/StandardBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/JigsawBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/DiagonalBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/KillerBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/WindowBoardRenderer.cs`
- 修改：`SudoKu/Controls/Renderers/SamuraiBoardRenderer.cs`

- [ ] **步骤 1：修改 StandardBoardRenderer 使用 GameTypeConfig**

修改 `StandardBoardRenderer.cs` 中的 `GetRegionColor` 方法：

```csharp
    public virtual Color GetRegionColor(int regionIndex, bool isDarkMode)
    {
        var config = GameTypeConfigFactory.GetConfig(SupportedGameType);
        var colors = isDarkMode 
            ? (config.RegionColorsDark ?? RegionColorsDark)
            : (config.RegionColorsLight ?? RegionColorsLight);
        return colors[regionIndex % colors.Length];
    }
```

- [ ] **步骤 2：修改 JigsawBoardRenderer 使用 GameTypeConfig**

修改 `JigsawBoardRenderer.cs` 中的 `GetRegionColor` 方法：

```csharp
    public override Color GetRegionColor(int regionIndex, bool isDarkMode)
    {
        var config = GameTypeConfigFactory.GetConfig(GameType.Jigsaw);
        var colors = isDarkMode 
            ? (config.RegionColorsDark ?? RegionColorsDark)
            : (config.RegionColorsLight ?? RegionColorsLight);
        return colors[regionIndex % colors.Length];
    }
```

删除 `JigsawBoardRenderer.cs` 中的重复颜色定义（第 17-34 行）。

- [ ] **步骤 3：修改其他渲染器使用 GameTypeConfig**

对 DiagonalBoardRenderer、KillerBoardRenderer、WindowBoardRenderer、SamuraiBoardRenderer 执行相同的修改。

- [ ] **步骤 4：构建验证**

运行：`dotnet build -f net10.0-windows10.0.19041.0 --nologo`
预期：构建成功，无错误

- [ ] **步骤 5：Commit**

```bash
git add SudoKu/Controls/Renderers/
git commit -m "refactor(renderer): use GameTypeConfig for region colors"
```

---

## 任务 8：完整测试

- [ ] **步骤 1：运行所有测试**

运行：`dotnet test --nologo`
预期：所有测试通过

- [ ] **步骤 2：手动测试各游戏类型**

启动应用程序，测试以下功能：
1. 标准数独：选择单元格、输入数字、高亮显示
2. 锯齿数独：区域颜色显示正确
3. 对角线数独：对角线背景色显示正确
4. 窗口数独：窗口区域背景色显示正确
5. 杀手数独：笼子显示正确
6. 武士数独：概览模式切换、子网格选择

- [ ] **步骤 3：最终 Commit**

```bash
git add .
git commit -m "test: verify all game types work correctly after refactoring"
```

---

## 总结

本计划通过以下优化解决了 Controls 目录的架构问题：

1. **扩展 GameTypeConfig**：添加 UI 配置属性，统一管理颜色等配置
2. **扩展 IBoardRenderer**：添加 BuildBoard 和 HandleSpecialTap 方法
3. **重构 SamuraiBoardRenderer**：将武士专用逻辑从 SudokuBoardView 移到渲染器
4. **清理 SudokuBoardView**：删除重复定义和游戏专用逻辑
5. **统一颜色管理**：所有渲染器使用 GameTypeConfig 中的颜色配置

这些改进使架构更加模块化、配置化，便于扩展新的游戏类型。
