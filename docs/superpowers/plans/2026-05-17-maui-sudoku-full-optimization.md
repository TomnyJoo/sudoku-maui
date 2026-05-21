# MAUI 数独项目全面优化实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 对照 Flutter 参考项目，全面修复 MAUI 数独项目的架构问题，提升代码质量、可维护性和稳定性。

**架构：** 采用分层架构 + 统一错误处理 + 依赖注入优化。将巨型类拆分为小而专注的组件，建立统一的日志和性能监控体系。

**技术栈：** .NET MAUI, CommunityToolkit.Mvvm, Microsoft.Extensions.DependencyInjection

---

## 文件结构

### 新建文件

| 文件 | 职责 |
|------|------|
| `Services/ErrorHandler.cs` | 统一异常处理和用户友好消息转换 |
| `Services/IErrorHandler.cs` | 错误处理器接口 |
| `Services/PerformanceMonitor.cs` | 性能监控工具 |
| `Services/DebugLogger.cs` | 调试日志控制 |
| `Controls/Renderers/IBoardRenderer.cs` | 渲染器接口 |
| `Controls/Renderers/StandardBoardRenderer.cs` | 标准数独渲染器 |
| `Controls/Renderers/DiagonalBoardRenderer.cs` | 对角线数独渲染器 |
| `Controls/Renderers/JigsawBoardRenderer.cs` | 锯齿数独渲染器 |
| `Controls/Renderers/KillerBoardRenderer.cs` | 杀手数独渲染器 |
| `Controls/Renderers/SamuraiBoardRenderer.cs` | 武士数独渲染器 |
| `Controls/Renderers/WindowBoardRenderer.cs` | 窗口数独渲染器 |
| `Controls/Renderers/BoardRendererFactory.cs` | 渲染器工厂 |
| `Controls/OverlayManager.cs` | 叠加层统一管理器 |
| `ViewModels/Mixins/GameTimerHandler.cs` | 计时器管理 Handler |
| `ViewModels/Mixins/GameCompletionHandler.cs` | 游戏完成处理 Handler |
| `ViewModels/Mixins/GamePropertyNotificationHandler.cs` | 属性通知 Handler |
| `ViewModels/Mixins/GameAutoMarkHandler.cs` | 自动标记候选数 Handler |

### 修改文件

| 文件 | 变更内容 |
|------|---------|
| `MauiProgram.cs` | 添加错误处理器注册、优化 DI 生命周期 |
| `App.xaml.cs` | 添加错误页面导航 |
| `AppInitializer.cs` | 添加资源预加载和状态反馈 |
| `SettingsService.cs` | 实现 MigrateToV1 迁移逻辑 |
| `GameViewModel.cs` | 拆分职责、减少代码量 |
| `SudokuBoardView.cs` | 使用渲染器模式重构 |
| `Services/AppLogger.cs` | 添加日志级别控制和性能追踪 |

---

## 任务 1：创建统一错误处理系统

**文件：**
- 创建：`Services/IErrorHandler.cs`
- 创建：`Services/ErrorHandler.cs`
- 修改：`MauiProgram.cs`
- 修改：`App.xaml.cs`

- [ ] **步骤 1：创建错误处理器接口**

```csharp
// Services/IErrorHandler.cs
namespace SudoKu.Services;

public interface IErrorHandler
{
    string HandleException(Exception exception);
    void LogError(Exception exception, string? context = null);
    void LogError(Exception exception, string? context, Exception innerException);
    bool IsGameLogicError(Exception exception);
    bool IsGameStorageError(Exception exception);
    bool IsGameGenerationError(Exception exception);
}
```

- [ ] **步骤 2：创建错误处理器实现**

```csharp
// Services/ErrorHandler.cs
using SudoKu.Helpers;

namespace SudoKu.Services;

public class ErrorHandler : IErrorHandler
{
    public static readonly ErrorHandler Instance = new();

    private ErrorHandler() { }

    public string HandleException(Exception exception)
    {
        return exception switch
        {
            GameGenerationException e => $"游戏生成失败: {e.Message}",
            GameGenerationCancelledException e => $"游戏生成已取消: {e.Message}",
            GameGenerationTimeoutException e => $"游戏生成超时: {e.Message}",
            GameGenerationNoSolutionException e => $"游戏生成无解: {e.Message}",
            GameLogicException e => $"游戏逻辑错误: {e.Message}",
            GameValidationException e => $"游戏验证错误: {e.Message}",
            GameStorageException e => $"游戏存储错误: {e.Message}",
            SudokuException e => e.Message,
            _ => $"发生未知错误: {exception}"
        };
    }

    public void LogError(Exception exception, string? context = null)
    {
        var message = context != null ? $"[{context}] {exception}" : exception.ToString();
        AppLogger.Error(message, exception);
    }

    public void LogError(Exception exception, string? context, Exception innerException)
    {
        var message = context != null ? $"[{context}] {exception}" : exception.ToString();
        AppLogger.Error(message, innerException);
    }

    public bool IsGameLogicError(Exception exception) =>
        exception is GameLogicException || exception is GameValidationException;

    public bool IsGameStorageError(Exception exception) =>
        exception is GameStorageException;

    public bool IsGameGenerationError(Exception exception) =>
        exception is GameGenerationException ||
        exception is GameGenerationCancelledException ||
        exception is GameGenerationTimeoutException ||
        exception is GameGenerationNoSolutionException;
}
```

- [ ] **步骤 3：在 DI 容器注册错误处理器**

修改 `MauiProgram.cs` 的 `RegisterServices` 方法：
```csharp
services.AddSingleton<IErrorHandler, ErrorHandler>();
```

- [ ] **步骤 4：添加错误页面导航**

在 `App.xaml.cs` 中添加错误页面导航逻辑：
```csharp
private void NavigateToErrorPage(string message)
{
    // 使用 NavigationService 或 Shell 导航到错误页面
    Shell.Current.GoToAsync($"error?message={Uri.EscapeDataString(message)}");
}
```

- [ ] **步骤 5：更新全局异常处理**

修改 `OnUnhandledException` 使用 ErrorHandler：
```csharp
private static void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
{
    if (e.ExceptionObject is Exception ex)
    {
        var handler = Services?.GetService<IErrorHandler>();
        var message = handler?.HandleException(ex) ?? ex.Message;
        AppLogger.Error($"未处理异常: {message}", ex);
    }
}
```

- [ ] **步骤 6：Commit**

```bash
git add Services/IErrorHandler.cs Services/ErrorHandler.cs MauiProgram.cs App.xaml.cs
git commit -m "feat: 添加统一错误处理系统"
```

---

## 任务 2：实现设置迁移逻辑

**文件：**
- 修改：`Services/SettingsService.cs`

- [ ] **步骤 1：实现 MigrateToV1 逻辑**

修改 `SettingsService.cs` 的 `MigrateToV1` 方法：

```csharp
private Task MigrateToV1()
{
    // 从旧的各游戏类型设置迁移到统一设置
    var prefs = Preferences.Default;

    // 迁移自动检查设置
    var oldAutoCheckKeys = new[] {
        "standard_auto_check", "diagonal_auto_check", "killer_auto_check",
        "jigsaw_auto_check", "window_auto_check"
    };
    foreach (var key in oldAutoCheckKeys)
    {
        if (prefs.ContainsKey(key))
        {
            _isAutoCheckErrorsEnabled = prefs.Get(key, false);
            break;
        }
    }

    // 迁移高亮错误设置
    var oldHighlightKeys = new[] {
        "standard_highlight_mistakes", "diagonal_highlight_mistakes", "killer_highlight_mistakes",
        "jigsaw_highlight_mistakes", "window_highlight_mistakes"
    };
    foreach (var key in oldHighlightKeys)
    {
        if (prefs.ContainsKey(key))
        {
            _isErrorHighlightEnabled = prefs.Get(key, true);
            break;
        }
    }

    // 迁移高级策略设置
    if (prefs.ContainsKey("game_use_advanced_strategy"))
    {
        _isAdvancedStrategyEnabled = prefs.Get("game_use_advanced_strategy", false);
    }

    AppLogger.Info("设置迁移到 V1 完成");
    return Task.CompletedTask;
}
```

- [ ] **步骤 2：添加迁移测试验证**

在 `SettingsService` 中添加测试方法：
```csharp
public bool TestMigrationV1()
{
    var prefs = Preferences.Default;
    // 验证迁移后的值是否正确
    return _isAutoCheckErrorsEnabled || _isErrorHighlightEnabled;
}
```

- [ ] **步骤 3：Commit**

```bash
git add Services/SettingsService.cs
git commit -m "feat: 实现设置迁移逻辑 MigrateToV1"
```

---

## 任务 3：重构 SudokuBoardView 为渲染器模式

**文件：**
- 创建：`Controls/Renderers/IBoardRenderer.cs`
- 创建：`Controls/Renderers/BoardRendererFactory.cs`
- 创建：`Controls/Renderers/StandardBoardRenderer.cs`
- 创建：`Controls/Renderers/DiagonalBoardRenderer.cs`
- 创建：`Controls/Renderers/JigsawBoardRenderer.cs`
- 创建：`Controls/Renderers/KillerBoardRenderer.cs`
- 创建：`Controls/Renderers/SamuraiBoardRenderer.cs`
- 创建：`Controls/Renderers/WindowBoardRenderer.cs`
- 创建：`Controls/OverlayManager.cs`
- 修改：`Controls/SudokuBoardView.cs`

- [ ] **步骤 1：创建渲染器接口**

```csharp
// Controls/Renderers/IBoardRenderer.cs
namespace SudoKu.Controls.Renderers;

using SudoKu.Models.Boards;
using Microsoft.Maui.Graphics;

public interface IBoardRenderer
{
    GameType SupportedGameType { get; }
    void Render(Board board, Canvas canvas, Rect bounds);
    void RenderCell(Board board, int row, int col, Canvas canvas, Rect cellRect);
    Color GetCellBackgroundColor(Board board, int row, int col);
    bool ShouldHighlightCell(Board board, int row, int col);
}
```

- [ ] **步骤 2：创建渲染器工厂**

```csharp
// Controls/Renderers/BoardRendererFactory.cs
namespace SudoKu.Controls.Renderers;

using SudoKu.Models;

public static class BoardRendererFactory
{
    private static readonly Dictionary<GameType, IBoardRenderer> _renderers = new()
    {
        { GameType.Standard, new StandardBoardRenderer() },
        { GameType.Diagonal, new DiagonalBoardRenderer() },
        { GameType.Jigsaw, new JigsawBoardRenderer() },
        { GameType.Killer, new KillerBoardRenderer() },
        { GameType.Samurai, new SamuraiBoardRenderer() },
        { GameType.Window, new WindowBoardRenderer() }
    };

    public static IBoardRenderer GetRenderer(GameType gameType)
    {
        return _renderers.GetValueOrDefault(gameType, _renderers[GameType.Standard]);
    }
}
```

- [ ] **步骤 3：创建 StandardBoardRenderer**

```csharp
// Controls/Renderers/StandardBoardRenderer.cs
namespace SudoKu.Controls.Renderers;

using SudoKu.Models.Boards;
using SudoKu.Models;
using Microsoft.Maui.Graphics;

public class StandardBoardRenderer : IBoardRenderer
{
    public GameType SupportedGameType => GameType.Standard;

    public void Render(Board board, Canvas canvas, Rect bounds)
    {
        // 实现标准数独棋盘渲染逻辑
    }

    public void RenderCell(Board board, int row, int col, Canvas canvas, Rect cellRect)
    {
        // 实现单元格渲染逻辑
    }

    public Color GetCellBackgroundColor(Board board, int row, int col)
    {
        var cell = board.GetCell(row, col);
        if (cell.IsSelected) return Color.FromArgb("#40C4FF");
        if (cell.IsHighlighted) return Color.FromArgb("#E0F7FA");
        return Colors.Transparent;
    }

    public bool ShouldHighlightCell(Board board, int row, int col)
    {
        var selected = board.Cells
            .SelectMany(r => r)
            .FirstOrDefault(c => c.IsSelected);
        if (selected == null) return false;

        var cell = board.GetCell(row, col);
        return cell.Row == selected.Row ||
               cell.Col == selected.Col ||
               (cell.Row / 3 == selected.Row / 3 && cell.Col / 3 == selected.Col / 3);
    }
}
```

- [ ] **步骤 4：创建其他游戏类型渲染器**

按照 `StandardBoardRenderer` 的模式，创建：
- `DiagonalBoardRenderer` - 额外渲染两条对角线
- `JigsawBoardRenderer` - 使用区域颜色矩阵
- `KillerBoardRenderer` - 渲染笼子和求和
- `SamuraiBoardRenderer` - 21x21 棋盘分块渲染
- `WindowBoardRenderer` - 4 个 3x3 窗口区域

- [ ] **步骤 5：创建 OverlayManager**

```csharp
// Controls/OverlayManager.cs
namespace SudoKu.Controls;

using Microsoft.Maui.Controls;

public class OverlayManager
{
    private readonly List<View> _overlays = new();
    private readonly AbsoluteLayout _container;

    public OverlayManager(AbsoluteLayout container)
    {
        _container = container;
    }

    public void AddOverlay(View overlay)
    {
        if (!_overlays.Contains(overlay))
        {
            _overlays.Add(overlay);
            _container.Add(overlay);
        }
    }

    public void RemoveOverlay(View overlay)
    {
        if (_overlays.Remove(overlay))
        {
            _container.Remove(overlay);
        }
    }

    public void ClearOverlays()
    {
        foreach (var overlay in _overlays.ToList())
        {
            _container.Remove(overlay);
        }
        _overlays.Clear();
    }

    public void SetOverlaysEnabled(bool enabled)
    {
        foreach (var overlay in _overlays)
        {
            overlay.IsVisible = enabled;
        }
    }
}
```

- [ ] **步骤 6：重构 SudokuBoardView**

将现有的 600+ 行代码重构为使用渲染器：

```csharp
// 修改后的 SudokuBoardView.cs 核心结构
public partial class SudokuBoardView : ContentView
{
    private IBoardRenderer _renderer;
    private readonly OverlayManager _overlayManager;

    public SudokuBoardView()
    {
        _renderer = BoardRendererFactory.GetRenderer(GameType);
        _overlayManager = new OverlayManager(_overlayLayout);
        InitializeComponent();
    }

    private static void OnBoardChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is SudokuBoardView view)
        {
            view._renderer = BoardRendererFactory.GetRenderer(view.GameType);
            view._overlayManager.ClearOverlays();
            view.SetupOverlays();
            view.InvalidateMeasure();
        }
    }

    private void SetupOverlays()
    {
        // 根据游戏类型添加必要的叠加层
        switch (GameType)
        {
            case GameType.Diagonal:
                _overlayManager.AddOverlay(new DiagonalOverlayView());
                break;
            case GameType.Killer:
                _overlayManager.AddOverlay(new KillerCageOverlay());
                _overlayManager.AddOverlay(new KillerCageBackgroundOverlay());
                break;
            case GameType.Window:
                _overlayManager.AddOverlay(new RegionBorderView());
                break;
        }
    }
}
```

- [ ] **步骤 7：Commit**

```bash
git add Controls/Renderers/*.cs Controls/OverlayManager.cs Controls/SudokuBoardView.cs
git commit -m "refactor: 重构 SudokuBoardView 为渲染器模式"
```

---

## 任务 4：重构 GameViewModel 进一步拆分职责（基于现有 Mixin Handler）

**文件：**
- 创建：`ViewModels/Mixins/GameTimerHandler.cs`
- 创建：`ViewModels/Mixins/GameCompletionHandler.cs`
- 创建：`ViewModels/Mixins/GamePropertyNotificationHandler.cs`
- 创建：`ViewModels/Mixins/GameAutoMarkHandler.cs`
- 修改：`ViewModels/GameViewModel.cs`

**当前状况分析：**
- GameViewModel 已有 4 个 Handler（Input, Lifecycle, Assist, Persistence）
- 但 GameViewModel 仍约 1460 行代码，承担过多职责
- 计时器、自动标记、属性通知等逻辑仍集中在 ViewModel

**优化方案：** 在现有 Handler 基础上，进一步提取以下职责：

- [ ] **步骤 1：创建 GameTimerHandler.cs**

将计时器相关逻辑提取为独立 Handler：

```csharp
// ViewModels/Mixins/GameTimerHandler.cs
namespace SudoKu.ViewModels.Mixins;

using Microsoft.Maui.Controls;

public class GameTimerHandler
{
    private readonly Func<int> _getElapsedTime;
    private readonly Action<int> _updateElapsedTime;
    private IDispatcherTimer? _timer;

    public GameTimerHandler(
        Func<int> getElapsedTime,
        Action<int> updateElapsedTime)
    {
        _getElapsedTime = getElapsedTime;
        _updateElapsedTime = updateElapsedTime;
    }

    public void StartTimer(Action onTick)
    {
        StopTimer();
        _timer = Application.Current!.Dispatcher.CreateTimer();
        _timer.Interval = TimeSpan.FromMilliseconds(Constants.TimerUpdateIntervalMs);
        _timer.IsRepeating = true;
        _timer.Tick += (_, _) => {
            var newTime = _getElapsedTime() + 1;
            _updateElapsedTime(newTime);
            onTick?.Invoke();
        };
        _timer.Start();
    }

    public void StopTimer()
    {
        _timer?.Stop();
        _timer = null;
    }

    public bool IsRunning => _timer?.IsRunning ?? false;

    public void Dispose()
    {
        StopTimer();
    }
}
```

- [ ] **步骤 2：创建 GameCompletionHandler.cs**

将游戏完成处理逻辑提取：

```csharp
// ViewModels/Mixins/GameCompletionHandler.cs
namespace SudoKu.ViewModels.Mixins;

using SudoKu.Models;
using SudoKu.Services;

public class GameCompletionHandler
{
    private readonly Func<GameState<Board>?> _getState;
    private readonly Action<GameState<Board>> _setState;
    private readonly StatisticsStorageService _statisticsService;
    private readonly AudioService _audioService;

    public GameCompletionHandler(
        Func<GameState<Board>?> getState,
        Action<GameState<Board>> setState,
        StatisticsStorageService statisticsService,
        AudioService audioService)
    {
        _getState = getState;
        _setState = setState;
        _statisticsService = statisticsService;
        _audioService = audioService;
    }

    public async Task HandleCompletionAsync(Func<Task> onNavigateToCompletion)
    {
        var state = _getState();
        if (state == null) return;

        await _statisticsService.RecordGameAsync(
            state.GameType,
            state.Difficulty,
            state.ElapsedTime,
            state.Mistakes,
            state.HintsUsed,
            true);

        await GameStorageService.DeleteGameAsync(state.GameType, state.Difficulty);

        var isNewRecord = await _statisticsService.IsNewBestScoreAsync(
            state.GameType,
            state.Difficulty,
            state.ElapsedTime,
            state.Mistakes);

        await _audioService.PlayCompleteSoundAsync();
        await onNavigateToCompletion();
    }
}
```

- [ ] **步骤 3：创建 GamePropertyNotificationHandler.cs**

将属性通知逻辑提取：

```csharp
// ViewModels/Mixins/GamePropertyNotificationHandler.cs
namespace SudoKu.ViewModels.Mixins;

using CommunityToolkit.Mvvm.ComponentModel;

public class GamePropertyNotificationHandler
{
    private readonly Action<string> _notifyPropertyChanged;
    private readonly Action _notifyAllCommands;

    public GamePropertyNotificationHandler(
        Action<string> notifyPropertyChanged,
        Action notifyAllCommands)
    {
        _notifyPropertyChanged = notifyPropertyChanged;
        _notifyAllCommands = notifyAllCommands;
    }

    public void NotifyGameStateChanged()
    {
        var props = new[] {
            nameof(Board), nameof(CanUndo), nameof(CanRedo),
            nameof(CanSelectCell), nameof(IsMarkMode),
            nameof(IsAutoMarkMode), nameof(NumberCounts),
            nameof(LocalizedDifficulty)
        };

        foreach (var prop in props)
            _notifyPropertyChanged(prop);

        _notifyAllCommands();
    }

    public void NotifyTimerTick()
    {
        _notifyPropertyChanged(nameof(ViewModels.GameViewModel.ElapsedTimeDisplay));
    }
}
```

- [ ] **步骤 4：创建 GameAutoMarkHandler.cs**

将自动标记候选数逻辑提取：

```csharp
// ViewModels/Mixins/GameAutoMarkHandler.cs
namespace SudoKu.ViewModels.Mixins;

using System.Collections.Immutable;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving;

public class GameAutoMarkHandler
{
    private readonly Func<GameState<Board>?> _getState;
    private readonly Action<GameState<Board>> _setState;
    private readonly SettingsService _settingsService;
    private CancellationTokenSource? _debounceCts;

    public GameAutoMarkHandler(
        Func<GameState<Board>?> getState,
        Action<GameState<Board>> setState,
        SettingsService settingsService)
    {
        _getState = getState;
        _setState = setState;
        _settingsService = settingsService;
    }

    public async Task AutoMarkCandidatesAsync(int[]? visibleSubBoards = null)
    {
        CancelDebounce();
        _debounceCts = new CancellationTokenSource();

        try
        {
            await Task.Delay(100, _debounceCts.Token);
            if (_debounceCts.Token.IsCancellationRequested) return;

            var state = _getState();
            if (state?.Board == null) return;

            var calculator = new CandidateCalculator(state.Board);
            var useAdvanced = _settingsService.IsAdvancedStrategyEnabled;
            var candidates = calculator.ComputeAllCandidates(useAdvanced);

            var newBoard = state.Board;
            foreach (var (key, cellCandidates) in candidates)
            {
                var parts = key.Split(',');
                if (parts.Length == 2 &&
                    int.TryParse(parts[0], out var row) &&
                    int.TryParse(parts[1], out var col))
                {
                    newBoard = newBoard.SetCellCandidates(
                        row, col, cellCandidates.ToImmutableHashSet());
                }
            }

            _setState(state with { Board = newBoard });
        }
        catch (OperationCanceledException) { }
        finally { _debounceCts = null; }
    }

    public void CancelDebounce()
    {
        _debounceCts?.Cancel();
        _debounceCts?.Dispose();
        _debounceCts = null;
    }
}
```

- [ ] **步骤 5：重构 GameViewModel 使用新 Handler**

修改 GameViewModel.cs 构造函数，添加新 Handler：

```csharp
public partial class GameViewModel : BaseViewModel
{
    // ... 现有代码 ...

    private GameTimerHandler? _timerHandler;
    private GameCompletionHandler? _completionHandler;
    private GamePropertyNotificationHandler? _notificationHandler;
    private GameAutoMarkHandler? _autoMarkHandler;

    private void InitializeHandlers()
    {
        // ... 现有 Handler 初始化 ...

        _timerHandler = new GameTimerHandler(
            () => _currentState?.ElapsedTime ?? 0,
            newTime => CurrentState = CurrentState?.UpdateElapsedTime(newTime)
        );

        _completionHandler = new GameCompletionHandler(
            () => _currentState,
            state => CurrentState = state,
            _statisticsService,
            _audioService
        );

        _notificationHandler = new GamePropertyNotificationHandler(
            OnPropertyChanged,
            () => {
                SelectCellCommand.NotifyCanExecuteChanged();
                UndoCommand.NotifyCanExecuteChanged();
                // ... 其他命令通知
            }
        );

        _autoMarkHandler = new GameAutoMarkHandler(
            () => _currentState,
            state => CurrentState = state,
            _settingsService
        );
    }

    // 使用新的 Timer Handler
    private void StartTimer() => _timerHandler?.StartTimer(OnTimerTick);
    private void StopTimer() => _timerHandler?.StopTimer();

    // 使用新的通知 Handler
    private void UpdateDerivedProperties()
    {
        // ... 现有逻辑 ...
        _notificationHandler?.NotifyGameStateChanged();
    }
}
```

- [ ] **步骤 6：Commit**

```bash
git add ViewModels/Mixins/GameTimerHandler.cs ViewModels/Mixins/GameCompletionHandler.cs
git add ViewModels/Mixins/GamePropertyNotificationHandler.cs ViewModels/Mixins/GameAutoMarkHandler.cs
git add ViewModels/GameViewModel.cs
git commit -m "refactor: 进一步拆分 GameViewModel 职责到 Handler"
```

---

## 任务 5：添加性能监控和调试日志

**文件：**
- 创建：`Services/PerformanceMonitor.cs`
- 创建：`Services/DebugLogger.cs`
- 修改：`Helpers/AppLogger.cs`

- [ ] **步骤 1：创建 PerformanceMonitor**

```csharp
// Services/PerformanceMonitor.cs
using System.Diagnostics;

namespace SudoKu.Services;

public static class PerformanceMonitor
{
    private static readonly Dictionary<string, Stopwatch> _traces = new();
    private static readonly Dictionary<string, List<double>> _metrics = new();
    private static readonly object _lock = new();

    public static bool IsEnabled { get; set; } = false;

    public static void StartTrace(string name)
    {
        if (!IsEnabled) return;

        lock (_lock)
        {
            var sw = Stopwatch.StartNew();
            _traces[name] = sw;
        }
    }

    public static long EndTrace(string name)
    {
        if (!IsEnabled) return 0;

        lock (_lock)
        {
            if (_traces.TryGetValue(name, out var sw))
            {
                sw.Stop();
                _traces.Remove(name);
                var elapsed = sw.ElapsedMilliseconds;
                LogMetric(name, elapsed);
                return elapsed;
            }
        }
        return 0;
    }

    public static void LogMetric(string name, double value)
    {
        if (!IsEnabled) return;

        lock (_lock)
        {
            if (!_metrics.ContainsKey(name))
                _metrics[name] = new List<double>();

            _metrics[name].Add(value);
        }
    }

    public static (double avg, double min, double max) GetMetricStats(string name)
    {
        lock (_lock)
        {
            if (_metrics.TryGetValue(name, out var values) && values.Count > 0)
            {
                return (values.Average(), values.Min(), values.Max());
            }
        }
        return (0, 0, 0);
    }

    public static void Clear()
    {
        lock (_lock)
        {
            _traces.Clear();
            _metrics.Clear();
        }
    }
}
```

- [ ] **步骤 2：创建 DebugLogger**

```csharp
// Services/DebugLogger.cs
namespace SudoKu.Services;

public static class DebugLogger
{
    public static bool EnableDebugLogging { get; set; } = false;
    public static bool EnablePerformanceLogging { get; set; } = false;

    private static readonly string[] EnabledModules = new[]
    {
        "DiggingAlgorithm",
        "PuzzleGenerator",
        "DLXSolver"
    };

    public static bool IsModuleEnabled(string moduleName)
    {
        return EnableDebugLogging && EnabledModules.Contains(moduleName);
    }

    public static void Debug(string module, string message)
    {
        if (IsModuleEnabled(module))
        {
            AppLogger.Debug($"[{module}] {message}");
        }
    }

    public static void Debug(string module, string message, params object[] args)
    {
        if (IsModuleEnabled(module))
        {
            AppLogger.Debug($"[{module}] {string.Format(message, args)}");
        }
    }

    public static void Performance(string operation, Action action)
    {
        if (!EnablePerformanceLogging)
        {
            action();
            return;
        }

        var sw = Stopwatch.StartNew();
        action();
        sw.Stop();
        AppLogger.Debug($"[PERF] {operation}: {sw.ElapsedMilliseconds}ms");
    }
}
```

- [ ] **步骤 3：在 MauiProgram.cs 中启用调试日志**

```csharp
// 在 InitializeApplicationAsync 中添加
DebugLogger.EnableDebugLogging = AppDebugMode.IsDebugEnabled;
DebugLogger.EnablePerformanceLogging = AppDebugMode.IsDebugEnabled;
PerformanceMonitor.IsEnabled = AppDebugMode.IsDebugEnabled;
```

- [ ] **步骤 4：在关键位置添加性能追踪**

在 `PuzzleGenerator.cs` 中：
```csharp
public async Task<GenerationResult> GenerateAsync(...)
{
    PerformanceMonitor.StartTrace("PuzzleGeneration");
    try
    {
        // ... 生成逻辑
    }
    finally
    {
        PerformanceMonitor.EndTrace("PuzzleGeneration");
    }
}
```

- [ ] **步骤 5：Commit**

```bash
git add Services/PerformanceMonitor.cs Services/DebugLogger.cs MauiProgram.cs
git commit -m "feat: 添加性能监控和调试日志系统"
```

---

## 任务 6：完善应用初始化流程

**文件：**
- 修改：`Services/AppInitializer.cs`
- 修改：`App.xaml.cs`

- [ ] **步骤 1：增强 AppInitializer 添加资源预加载**

```csharp
// 修改 Services/AppInitializer.cs
public static async Task<bool> InitializeAsync(IServiceProvider services)
{
    if (_isInitialized) return true;

    _status = InitializationStatus.Initializing;
    var stopwatch = Stopwatch.StartNew();

    try
    {
        await InitializeSettingsAsync(services);
        await PreloadResourcesAsync();  // 新增
        await PreloadTemplatesAsync(services);
        ValidateServices(services);

        _status = InitializationStatus.Completed;
        _isInitialized = true;
        stopwatch.Stop();
        AppLogger.Info($"应用初始化完成，耗时 {stopwatch.ElapsedMilliseconds}ms");
        return true;
    }
    catch (Exception ex)
    {
        _status = InitializationStatus.Failed;
        AppLogger.Error("应用初始化失败", ex);
        return false;
    }
}

private static async Task PreloadResourcesAsync()
{
    // 预加载图片资源
    var imageAssets = new[] {
        "splash.svg",
        "sudoku.png",
        "arrow_back.png"
    };

    // 使用 ImageSource.Cache 方法预加载
    foreach (var asset in imageAssets)
    {
        try
        {
            await Task.Run(() => {
                // MAUI 平台特定资源预加载
                if (DeviceInfo.Platform == DevicePlatform.Android)
                {
                    Android.UI.Graphics.BitmapFactory.DecodeFile($"Resources/Images/{asset}");
                }
            });
        }
        catch (Exception ex)
        {
            AppLogger.Warning($"资源预加载失败: {asset}", ex);
        }
    }
}
```

- [ ] **步骤 2：添加初始化状态属性供 UI 绑定**

```csharp
public static InitializationStatus Status => _status;
public static double InitializationProgress => _progress;

private static double _progress = 0;

private static void UpdateProgress(double progress, string message)
{
    _progress = progress;
    AppLogger.Debug($"初始化进度: {progress * 100}% - {message}");
}
```

- [ ] **步骤 3：Commit**

```bash
git add Services/AppInitializer.cs App.xaml.cs
git commit -m "feat: 完善应用初始化流程，添加资源预加载"
```

---

## 任务 7：优化 DI 生命周期

**文件：**
- 修改：`MauiProgram.cs`

- [ ] **步骤 1：审查和修正服务注册**

```csharp
private static void RegisterServices(IServiceCollection services)
{
    // 核心服务 - Singleton（全局共享）
    services.AddSingleton<TemplateManager>();
    services.AddSingleton<PuzzleGenerator>();
    services.AddSingleton<Services.Interfaces.IPuzzleSolver, Services.Solving.PuzzleSolver>();

    // 数据服务 - Singleton（数据库连接池）
    services.AddSingleton<Services.Storage.Database.SudokuDatabase>();

    // 设置服务 - Singleton（全局共享设置）
    services.AddSingleton<SettingsService>();

    // 存储服务 - Singleton（游戏存档管理）
    services.AddSingleton<GameStorageService>();
    services.AddSingleton<StatisticsStorageService>();

    // 游戏服务 - Scoped（每个游戏会话一个新实例）
    services.AddScoped<IGameService<Board>, GameService>();

    // 音频服务 - Singleton（单一音频播放器）
    services.AddSingleton<AudioService>();

    // ViewModels - Scoped（每个页面一个新实例）
    services.AddScoped<HomeViewModel>();
    services.AddScoped<GameViewModel>();
    services.AddScoped<CompletionViewModel>();
    services.AddScoped<CustomGameViewModel>();
    services.AddScoped<SettingsViewModel>();
    services.AddScoped<StatisticsViewModel>();
    services.AddScoped<RulesViewModel>();

    // Views - Transient（每次请求创建新实例）
    services.AddTransient<HomePage>();
    services.AddTransient<GamePage>();
    services.AddTransient<CompletionPage>();
    services.AddTransient<CustomGamePage>();
    services.AddTransient<SettingsPage>();
    services.AddTransient<StatisticsPage>();
    services.AddTransient<RulesPage>();
}
```

- [ ] **步骤 2：Commit**

```bash
git add MauiProgram.cs
git commit -m "fix: 优化 DI 生命周期配置"
```

---

## 任务 8：验证和测试

**文件：**
- 测试所有修改的功能

- [ ] **步骤 1：编译验证**

```bash
cd e:\MAUI\SudoKuMaui\SudoKu
dotnet build
```

- [ ] **步骤 2：运行应用测试初始化流程**

测试应用启动，确认：
1. 初始化状态正确显示
2. 设置正确加载和迁移
3. 无未处理异常

- [ ] **步骤 3：测试游戏生成**

测试各难度级别和游戏类型的生成。

- [ ] **步骤 4：Commit 最终版本**

```bash
git add -A
git commit -m "chore: 完成全面代码优化"
```

---

## 计划执行交接

计划已完成并保存。

**两种执行方式：**

**1. 子代理驱动（推荐）** - 每个任务调度一个新的子代理，任务间进行审查，快速迭代
- **必需子技能：** 使用 superpowers:subagent-driven-development

**2. 内联执行** - 在当前会话中使用 executing-plans 执行任务，批量执行并设有检查点
- **必需子技能：** 使用 superpowers:executing-plans

**请选择执行方式。**
