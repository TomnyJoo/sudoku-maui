using System.Collections.Immutable;

namespace SudoKu.ViewModels;

using CommunityToolkit.Mvvm.Input;
using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Resources;
using SudoKu.Services;
using SudoKu.Services.Interfaces;
using SudoKu.Services.Solving;
using SudoKu.ViewModels.Mixins;

/// <summary>
/// 统一游戏视图模型，负责游戏的核心逻辑和状态管理。
/// </summary>
public partial class GameViewModel : BaseViewModel
{
    #region 服务依赖

    /// <summary>泛型游戏服务接口。</summary>
    private readonly IGameService<Board> _gameService;

    /// <summary>游戏存储服务实例。</summary>
    private readonly GameStorageService _storageService;

    /// <summary>统计服务实例。</summary>
    private readonly StatisticsStorageService _statisticsService;

    /// <summary>设置服务实例。</summary>
    private readonly SettingsService _settingsService;

    /// <summary>音频服务实例。</summary>
    private readonly AudioService _audioService;

    #endregion

    #region Handler 实例

    private GameInputHandler<Board>? _inputHandler;
    private GameLifecycleHandler<Board>? _lifecycleHandler;
    private GameAssistHandler<Board>? _assistHandler;
    private GamePersistenceHandler<Board>? _persistenceHandler;
    private GameTimerHandler? _timerHandler;
    private GameCompletionHandler? _completionHandler;
    private GamePropertyNotificationHandler? _notificationHandler;
    private GameAutoMarkHandler? _autoMarkHandler;

    #endregion

    #region 初始化

    public GameViewModel(
        IGameService<Board> gameService,
        GameStorageService storageService,
        StatisticsStorageService statisticsService,
        SettingsService settingsService,
        AudioService audioService) : base()
    {
        _gameService = gameService;
        _storageService = storageService;
        _statisticsService = statisticsService;
        _settingsService = settingsService;
        _audioService = audioService;
        InitializeHandlers();
    }

    private void InitializeHandlers()
    {
        _inputHandler = new GameInputHandler<Board>(
            () => _currentState,
            state => CurrentState = state,
            () => IsPlaying);

        _lifecycleHandler = new GameLifecycleHandler<Board>(
            () => _currentState,
            state => CurrentState = state,
            () => IsShowingSolution);

        _assistHandler = new GameAssistHandler<Board>(
            () => _currentState,
            state => CurrentState = state,
            () => IsPlaying,
            msg => _lastHintMessage = msg,
            () => _currentState?.Solution);

        _persistenceHandler = new GamePersistenceHandler<Board>(
            () => _currentState,
            state => CurrentState = state,
            HandleError,
            async () => await _storageService.SaveGameAsync(_currentState!),
            async () => await _storageService.LoadGameAsync(_currentState?.GameType ?? GameType.Standard, _currentState?.Difficulty ?? Difficulty.Medium),
            async () => await GameStorageService.HasSavedGameAsync(_currentState?.GameType ?? GameType.Standard, _currentState?.Difficulty ?? Difficulty.Medium));

        _timerHandler = new GameTimerHandler(
            () => _currentState?.ElapsedTime ?? 0,
            newTime => CurrentState = CurrentState?.UpdateElapsedTime(newTime));

        _completionHandler = new GameCompletionHandler(
            () => _currentState,
            state => CurrentState = state,
            _statisticsService,
            _audioService);

        _notificationHandler = new GamePropertyNotificationHandler(
            propName => OnPropertyChanged(propName),
            () => {
                SelectCellCommand.NotifyCanExecuteChanged();
                UndoCommand.NotifyCanExecuteChanged();
                RedoCommand.NotifyCanExecuteChanged();
                EraseCommand.NotifyCanExecuteChanged();
                InputNumberCommand.NotifyCanExecuteChanged();
                ToggleMarkModeCommand.NotifyCanExecuteChanged();
            });

        _autoMarkHandler = new GameAutoMarkHandler(
            () => _currentState,
            state => CurrentState = state,
            _settingsService);
    }

    #endregion

    #region 私有字段

    /// <summary>当前游戏状态。</summary>
    private GameState<Board>? _currentState;

    /// <summary>游戏生成取消令牌源。</summary>
    private CancellationTokenSource? _generationCts;

    /// <summary>是否正在生成谜题。</summary>
    private bool _isGenerating;

    /// <summary>当前生成阶段。</summary>
    private GenerationStage _currentGenerationStage = GenerationStage.Initializing;

    /// <summary>已用时间显示字符串。</summary>
    private string _elapsedTimeDisplay = "00:00";

    /// <summary>最佳时间显示字符串。</summary>
    private string _bestTimeDisplay = "--:--";

    /// <summary>完成百分比。</summary>
    private double _completionPercentage;

    /// <summary>当前选中的单元格。</summary>
    private SudokuCell? _selectedCell;

    /// <summary>武士数独当前子网格索引（0-4）。</summary>
    private int _currentSubGridIndex = 4; // 默认显示中心网格

    /// <summary>是否处于武士数独总览模式。</summary>
    private bool _isOverviewMode;

    /// <summary>是否显示对角线。</summary>
    private bool _showDiagonalLines = true;

    /// <summary>是否显示区域编号。</summary>
    private bool _showRegionNumbers = true;

    /// <summary>最佳成绩缓存。</summary>
    private BestScore? _cachedBestScore;

    /// <summary>最佳成绩是否已加载。</summary>
    private bool _isBestScoreLoaded;

    /// <summary>最后一次提示消息。</summary>
    private string? _lastHintMessage;

    /// <summary>自动标记防抖计时器。</summary>
    private CancellationTokenSource? _autoMarkDebounceCts;

    /// <summary>导航状态：是否首次导航。</summary>
    private bool _isFirstNavigation = true;

    /// <summary>导航状态：是否有活跃游戏。</summary>
    private bool _hasActiveGame = false;

    /// <summary>导航状态：最后一次游戏类型。</summary>
    private GameType? _lastGameType;

    /// <summary>导航状态：最后一次难度。</summary>
    private Difficulty? _lastDifficulty;

    /// <summary>是否正在计算候选数。</summary>
    private bool _isCalculatingCandidates;

    /// <summary>保存防抖计时器。</summary>
    private CancellationTokenSource? _saveDebounceCts;

    #endregion

    #region 游戏状态属性

    /// <summary>获取或设置当前游戏状态。</summary>
    public GameState<Board>? CurrentState
    {
        get => _currentState;
        private set
        {
            if (SetProperty(ref _currentState, value))
            {
                OnPropertyChanged(nameof(LocalizedDifficulty));
                OnPropertyChanged(nameof(Board));
                OnPropertyChanged(nameof(GameType));
                OnPropertyChanged(nameof(IsSamuraiGame));
                OnPropertyChanged(nameof(IsDiagonalGame));
                OnPropertyChanged(nameof(IsJigsawGame));
                OnPropertyChanged(nameof(IsShowingSolution));
                OnPropertyChanged(nameof(SolutionBoard));
                UpdateDerivedProperties();
            }
        }
    }

    /// <summary>获取本地化的难度显示名称。</summary>
    public string LocalizedDifficulty => CurrentState?.Difficulty.GetDisplayName() ?? AppResources.Medium;

    /// <summary>获取当前棋盘（强制触发 OnPropertyChanged）。</summary>
    public Board? Board
    {
        get => CurrentState?.Board;
        private set { }
    }

    /// <summary>获取或设置是否正在生成谜题。</summary>
    public bool IsGenerating
    {
        get => _isGenerating;
        private set
        {
            if (SetProperty(ref _isGenerating, value))
            {
                OnPropertyChanged(nameof(IsStatusBarVisible));
                OnPropertyChanged(nameof(CurrentGenerationStageText));
            }
        }
    }

    /// <summary>获取或设置当前生成阶段。</summary>
    public GenerationStage CurrentGenerationStage
    {
        get => _currentGenerationStage;
        private set
        {
            if (SetProperty(ref _currentGenerationStage, value))
            {
                OnPropertyChanged(nameof(CurrentGenerationStageText));
            }
        }
    }

    /// <summary>获取当前生成阶段的本地化显示文本。</summary>
    public string CurrentGenerationStageText => GetLocalizedStageText(CurrentGenerationStage);

    /// <summary>
    /// 获取生成阶段的本地化文本。
    /// </summary>
    private static string GetLocalizedStageText(GenerationStage stage) => stage switch
    {
        GenerationStage.Initializing => AppResources.Gen_Initializing,
        GenerationStage.LoadingTemplate => AppResources.Gen_LoadingTemplate,
        GenerationStage.CreatingRegions => AppResources.Gen_CreatingRegions,
        GenerationStage.ApplyingSubstitution => AppResources.Gen_ApplyingSubstitution,
        GenerationStage.GeneratingSolution => AppResources.Gen_GeneratingSolution,
        GenerationStage.DiggingPuzzle => AppResources.Gen_DiggingPuzzle,
        GenerationStage.Validating => AppResources.Gen_Validating,
        GenerationStage.Completed => AppResources.Gen_Completed,
        GenerationStage.Failed => AppResources.Gen_Failed,
        _ => stage.ToString()
    };

    #endregion

    #region 游戏状态判断属性

    /// <summary>获取是否正在游戏中（已开始且未完成）。</summary>
    public bool IsPlaying => CurrentState?.StartTime != null && !CurrentState.IsCompleted;

    /// <summary>获取游戏是否已完成。</summary>
    public bool IsGameCompleted => CurrentState?.IsCompleted ?? false;

    /// <summary>获取是否可以撤销操作。</summary>
    public bool CanUndo => CurrentState?.CanUndo ?? false;

    /// <summary>获取是否可以重做操作。</summary>
    public bool CanRedo => CurrentState?.CanRedo ?? false;

    /// <summary>获取是否处于笔记模式。</summary>
    public bool IsMarkMode => CurrentState?.IsMarkMode ?? false;

    /// <summary>获取是否启用自动笔记模式。</summary>
    public bool IsAutoMarkMode => CurrentState?.IsAutoMarkMode ?? false;

    /// <summary>获取是否正在显示解答。</summary>
    public bool IsShowingSolution => CurrentState?.IsShowingSolution ?? false;

    /// <summary>获取答案棋盘。</summary>
    public Board? SolutionBoard => CurrentState?.Solution;

    #endregion

    #region 显示属性

    /// <summary>获取或设置已用时间的显示字符串。</summary>
    public string ElapsedTimeDisplay
    {
        get => _elapsedTimeDisplay;
        private set => SetProperty(ref _elapsedTimeDisplay, value);
    }

    /// <summary>获取或设置错误次数。</summary>
    public int MistakesCount => CurrentState?.Mistakes ?? 0;

    /// <summary>获取或设置最佳时间的显示字符串。</summary>
    public string BestTimeDisplay
    {
        get => _bestTimeDisplay;
        private set => SetProperty(ref _bestTimeDisplay, value);
    }

    /// <summary>获取或设置完成百分比。</summary>
    public double CompletionPercentage
    {
        get => _completionPercentage;
        private set => SetProperty(ref _completionPercentage, value);
    }

    /// <summary>获取或设置当前选中的单元格。</summary>
    public SudokuCell? SelectedCell
    {
        get => _selectedCell;
        private set => SetProperty(ref _selectedCell, value);
    }

    /// <summary>获取数字使用次数统计。</summary>
    /// <remarks>
    /// 对于武士数独，只计算当前子网格的数字计数（与Flutter实现一致）。
    /// </remarks>
    public Dictionary<int, int> NumberCounts
    {
        get
        {
            if (CurrentState?.Board is null) return [];

            // 使用 GameType 判断是否是武士数独
            if (CurrentState.GameType == GameType.Samurai && CurrentState.Board is Board board)
            {
                return CalculateSamuraiSubGridNumberCounts(board, CurrentSubGridIndex);
            }

            return CurrentState.NumberCounts;
        }
    }

    /// <summary>计算武士数独子网格的数字计数。</summary>
    private static Dictionary<int, int> CalculateSamuraiSubGridNumberCounts(Board board, int subGridIndex)
    {
        var counts = new Dictionary<int, int>();
        for (int i = 1; i <= 9; i++)
        {
            counts[i] = 0;
        }

        // 边界检查
        if (subGridIndex < 0 || subGridIndex >= SamuraiConstants.SubGridCount)
        {
            return counts;
        }

        var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subGridIndex];
        for (int r = 0; r < SamuraiConstants.SubGridSize; r++)
        {
            for (int c = 0; c < SamuraiConstants.SubGridSize; c++)
            {
                var cell = board.Cells[startRow + r][startCol + c];
                if (cell.Value != null)
                {
                    counts[cell.Value.Value]++;
                }
            }
        }

        return counts;
    }

    /// <summary>获取每个数字的最大使用次数（武士数独为9，其他为9）。</summary>
    /// <remarks>
    /// 注意：武士数独虽然整个棋盘有21x21，但数字键盘只计算当前子网格的数字计数，
    /// 所以最大使用次数仍然是9（每个数字在9x9子网格中最多出现9次）。
    /// </remarks>
    public static int MaxNumberCount => 9;

    /// <summary>获取状态栏是否可见（生成期间隐藏）。</summary>
    public bool IsStatusBarVisible => !IsGenerating;

    #endregion

    #region 武士数独特有属性

    /// <summary>获取或设置武士数独当前显示的子网格索引（0-4）。</summary>
    public int CurrentSubGridIndex
    {
        get => _currentSubGridIndex;
        set
        {
            if (SetProperty(ref _currentSubGridIndex, value))
            {
                OnPropertyChanged(nameof(SubGridLabel));
                // 通知数字计数已变更（用于更新数字键盘）
                OnPropertyChanged(nameof(NumberCounts));
                // 如果处于自动候选模式且游戏正在进行中，重新计算候选数
                if (IsAutoMarkMode && IsPlaying && IsSamuraiGame)
                {
                    _ = AutoMarkCandidatesAsync([value]);
                }
            }
        }
    }

    /// <summary>获取或设置是否处于武士数独总览模式。</summary>
    public bool IsOverviewMode
    {
        get => _isOverviewMode;
        set => SetProperty(ref _isOverviewMode, value);
    }

    /// <summary>获取当前游戏类型（用于 UI 绑定）。</summary>
    public GameType GameType => CurrentState?.GameType ?? GameType.Standard;

    /// <summary>获取是否为武士数独游戏。</summary>
    public bool IsSamuraiGame => CurrentState?.GameType == GameType.Samurai;

    /// <summary>获取是否为对角线数独游戏。</summary>
    public bool IsDiagonalGame => CurrentState?.GameType == GameType.Diagonal;

    /// <summary>获取是否为锯齿数独游戏。</summary>
    public bool IsJigsawGame => CurrentState?.GameType == GameType.Jigsaw;

    /// <summary>获取是否为杀手数独游戏。</summary>
    public bool IsKillerGame => CurrentState?.GameType == GameType.Killer;

    /// <summary>获取或设置是否显示笼子（杀手数独）。</summary>
    public bool ShowCages
    {
        get => _showCages;
        set => SetProperty(ref _showCages, value);
    }
    private bool _showCages = true;

    /// <summary>获取武士数独子网格标签文本。</summary>
    public string SubGridLabel => _currentSubGridIndex switch
    {
        0 => AppResources.SubGrid_TopLeft,
        1 => AppResources.SubGrid_TopRight,
        2 => AppResources.SubGrid_BottomLeft,
        3 => AppResources.SubGrid_BottomRight,
        4 => AppResources.SubGrid_Center,
        _ => $"Grid {_currentSubGridIndex + 1}"
    };

    /// <summary>获取或设置是否显示对角线。</summary>
    public bool ShowDiagonalLines
    {
        get => _showDiagonalLines;
        set => SetProperty(ref _showDiagonalLines, value);
    }

    /// <summary>获取或设置是否显示区域编号。</summary>
    public bool ShowRegionNumbers
    {
        get => _showRegionNumbers;
        set => SetProperty(ref _showRegionNumbers, value);
    }

    #endregion

    #region 最佳成绩属性

    /// <summary>获取最佳成绩是否已加载。</summary>
    public bool IsBestScoreLoaded => _isBestScoreLoaded;

    /// <summary>获取最佳成绩的错误数（无记录时返回 null）。</summary>
    public int? BestScoreMistakes => _cachedBestScore?.Mistakes;

    #endregion

    #region 导航命令

    /// <summary>返回上一页面命令。</summary>
    [RelayCommand]
    private static async Task Back()
    {
        if (Shell.Current.Navigation.NavigationStack.Count > 1)
            await Shell.Current.Navigation.PopAsync();
        else
            await Shell.Current.GoToAsync("//home");
    }

    /// <summary>帮助页面导航命令。</summary>
    [RelayCommand]
    private static async Task Help() => await Shell.Current.Navigation.PushAsync(new Views.RulesPage());

    /// <summary>设置页面导航命令。</summary>
    [RelayCommand]
    private static async Task Settings() => await Shell.Current.Navigation.PushAsync(new Views.SettingsPage());

    #endregion

    #region 显示切换命令

    /// <summary>切换对角线显示命令。</summary>
    [RelayCommand]
    private void ToggleDiagonalLines() => ShowDiagonalLines = !ShowDiagonalLines;

    /// <summary>切换区域编号显示命令。</summary>
    [RelayCommand]
    private void ToggleRegionNumbers() => ShowRegionNumbers = !ShowRegionNumbers;

    /// <summary>切换笼子显示命令（杀手数独）。</summary>
    [RelayCommand]
    private void ToggleCages() => ShowCages = !ShowCages;

    /// <summary>切换武士数独总览模式命令。</summary>
    [RelayCommand]
    private void ToggleOverview() => IsOverviewMode = !IsOverviewMode;

    /// <summary>切换到上一个武士数独子网格。</summary>
    [RelayCommand]
    private void SwitchSubGridPrev()
    {
        CurrentSubGridIndex = (CurrentSubGridIndex + 4) % 5;
        IsOverviewMode = false;
    }

    /// <summary>切换到下一个武士数独子网格。</summary>
    [RelayCommand]
    private void SwitchSubGridNext()
    {
        CurrentSubGridIndex = (CurrentSubGridIndex + 1) % 5;
        IsOverviewMode = false;
    }

    #endregion

    #region 游戏生命周期方法

    /// <summary>
    /// 异步初始化游戏，根据参数决定创建新游戏或加载已保存的游戏。
    /// </summary>
    /// <param name="parameter">导航参数，包含 GameType、Difficulty、IsNewGame。</param>
    /// <returns>初始化完成的任务。</returns>
    public override async Task InitializeAsync(object? parameter = null)
    {
        // 如果参数是 Dictionary 且包含有效的游戏参数，才进行初始化
        if (parameter is not Dictionary<string, object> paramsDict)
            return;

        // 检查是否有有效的游戏参数
        bool hasValidGameParams = paramsDict.TryGetValue("GameType", out var gt) && gt is GameType &&
                                  paramsDict.TryGetValue("Difficulty", out var diff) && diff is Difficulty;

        if (!hasValidGameParams)
            return;

        var gameType = (GameType)paramsDict["GameType"];
        var difficulty = (Difficulty)paramsDict["Difficulty"];
        var isNewGame = paramsDict.TryGetValue("IsNewGame", out var isNew) && (bool)isNew;

        // 更新导航状态
        _isFirstNavigation = false;
        _hasActiveGame = true;
        _lastGameType = gameType;
        _lastDifficulty = difficulty;

        // 支持自定义棋盘
        if (paramsDict.TryGetValue("CustomBoardJson", out var boardJsonObj) && boardJsonObj is string boardJsonStr)
        {
            var customBoard = DeserializeCustomBoard(boardJsonStr, gameType);
            if (customBoard != null)
            {
                CurrentState = new GameState<Board>
                {
                    Board = customBoard,
                    InitialBoard = customBoard.DeepCopy(),
                    Solution = customBoard,
                    GameType = gameType,
                    Difficulty = difficulty,
                    Status = GameStatus.Playing,
                    StartTime = DateTime.Now,
                    History = [customBoard],
                    HistoryIndex = 0
                };
                Title = GetLocalizedGameTypeName(gameType);
                UpdateDerivedProperties();
                StartTimer();
                return;
            }
        }

        if (isNewGame)
        {
            await StartNewGameAsync(gameType, difficulty);
        }
        else
        {
            await LoadSavedGameAsync(gameType, difficulty);
        }

        // 并行加载最佳成绩
        _ = LoadBestScoreAsync(gameType, difficulty);
    }

    #region 导航状态管理

    /// <summary>
    /// 处理页面导航到事件
    /// </summary>
    public async Task HandleNavigatedToAsync(IDictionary<string, object>? parameters)
    {
        // 检查是否有有效的游戏参数（GameType 和 Difficulty）
        bool hasValidGameParams = parameters != null && 
                                  parameters.TryGetValue("GameType", out var gt) && gt is GameType &&
                                  parameters.TryGetValue("Difficulty", out var diff) && diff is Difficulty;

        if (hasValidGameParams)
        {
            // InitializeAsync 已经包含了状态更新逻辑
            await InitializeAsync(parameters);
        }
        else if (CurrentState != null)
        {
            // 从设置/规则页面返回，保持现有游戏状态
            _hasActiveGame = true;
        }
        else if (_lastGameType.HasValue && _lastDifficulty.HasValue)
        {
            // 从其他页面返回但游戏状态丢失，尝试恢复
            await InitializeAsync(new Dictionary<string, object>
            {
                { "GameType", _lastGameType.Value },
                { "Difficulty", _lastDifficulty.Value },
                { "IsNewGame", false }
            });
        }
    }

    /// <summary>
    /// 处理页面离开事件
    /// </summary>
    public void HandleNavigatedFrom()
    {
        SaveGameDebounced();
    }

    /// <summary>
    /// 检查是否需要重新初始化视图
    /// </summary>
    public bool ShouldReinitializeView()
    {
        return _isFirstNavigation || !_hasActiveGame;
    }

    #endregion

    /// <summary>
    /// 异步清理 ViewModel 资源。
    /// </summary>
    public override Task CleanupAsync()
    {
        StopTimer();
        CancelAutoMarkDebounce();
        CancelSaveDebounce();
        _generationCts?.Cancel();
        _generationCts?.Dispose();
        return base.CleanupAsync();
    }

    /// <summary>
    /// 异步开始新游戏。
    /// </summary>
    /// <param name="gameType">游戏类型。</param>
    /// <param name="difficulty">难度等级。</param>
    private async Task StartNewGameAsync(GameType gameType, Difficulty difficulty)
    {
        IsGenerating = true;
        Title = GetLocalizedGameTypeName(gameType);

        // Allow UI to update (show generation overlay and hide board/keyboard)
        // before heavy generation work starts. This yields to the message loop so
        // the view can reflect IsGenerating immediately.
        await Task.Yield();

        // 重置武士数独状态
        if (gameType == GameType.Samurai)
        {
            _currentSubGridIndex = 4; // 默认显示中心网格
            _isOverviewMode = false;
            OnPropertyChanged(nameof(CurrentSubGridIndex));
            OnPropertyChanged(nameof(IsOverviewMode));
        }

        _generationCts = new CancellationTokenSource();

        var progress = new Progress<GenerationStage>(stage =>
        {
            MainThread.BeginInvokeOnMainThread(() =>
            {
                CurrentGenerationStage = stage;
            });
        });

        try
        {
            // 将耗时的生成工作放到后台线程执行，允许 UI 线程保持响应并显示生成遮罩。
            var state = await Task.Run(async () => await _gameService.CreateNewGameAsync(gameType, difficulty, _generationCts.Token, progress));

            // 在主线程更新状态与 UI
            MainThread.BeginInvokeOnMainThread(() =>
            {
                CurrentState = state;
                IsGenerating = false;
                UpdateDerivedProperties();
                StartTimer();
            });

            // 播放开始音效（不依赖 UI 操作）
            await _audioService.PlayStartSoundAsync();
        }
        catch (OperationCanceledException)
        {
            // 取消时确保在主线程更新状态
            MainThread.BeginInvokeOnMainThread(() => IsGenerating = false);
            await Shell.Current.DisplayAlertAsync(
                AppResources.Cancel,
                AppResources.Gen_UserCancelled,
                AppResources.Button_OK);
            await NavigationService.GoToRootAsync();
        }
        catch (Exception ex)
        {
            MainThread.BeginInvokeOnMainThread(() => IsGenerating = false);
            await Shell.Current.DisplayAlertAsync(
                AppResources.Error,
                ex.Message,
                AppResources.Button_OK);
            await NavigationService.GoToRootAsync();
        }
    }

    /// <summary>
    /// 异步加载已保存的游戏。
    /// </summary>
    /// <param name="gameType">游戏类型。</param>
    /// <param name="difficulty">难度等级。</param>
    private async Task LoadSavedGameAsync(GameType gameType, Difficulty difficulty)
    {
        var savedState = await _storageService.LoadGameAsync(gameType, difficulty);
        if (savedState is not null)
        {
            CurrentState = savedState;
            Title = GetLocalizedGameTypeName(gameType);
            ElapsedTimeDisplay = FormatTime(savedState.ElapsedTime);
            UpdateDerivedProperties();

            if (!savedState.IsCompleted)
            {
                StartTimer();
            }
        }
        else
        {
            await StartNewGameAsync(gameType, difficulty);
        }
    }

    /// <summary>
    /// 取消游戏生成。
    /// </summary>
    [RelayCommand]
    private void CancelGeneration()
    {
        _generationCts?.Cancel();
        IsGenerating = false;
    }

    /// <summary>
    /// 开始新游戏命令，重新生成当前类型和难度的新游戏。
    /// </summary>
    [RelayCommand]
    private async Task NewGame()
    {
        if (CurrentState is null) return;
        StopTimer();
        await StartNewGameAsync(CurrentState.GameType, CurrentState.Difficulty);
    }

    /// <summary>
    /// 暂停游戏命令。
    /// </summary>
    [RelayCommand]
    private void Pause() => StopTimer();

    /// <summary>
    /// 恢复游戏命令。
    /// </summary>
    [RelayCommand]
    private void Resume() => StartTimer();

    /// <summary>
    /// 重置游戏命令，恢复到初始谜题状态。
    /// </summary>
    [RelayCommand]
    private void ResetGame()
    {
        if (CurrentState is null) return;
        StopTimer();
        CurrentState = CurrentState.ResetGame();
        ElapsedTimeDisplay = "00:00";
        UpdateDerivedProperties();
    }

    #endregion

    #region 单元格操作方法

    /// <summary>
    /// 选中单元格命令，更新选中状态。
    /// </summary>
    [RelayCommand(CanExecute = nameof(CanSelectCell))]
    private void SelectCell(SudokuCell? cell)
    {
        if (cell is null || CurrentState is null || CurrentState.Board is null || IsGameCompleted)
            return;

        _inputHandler?.SelectCell(cell.Row, cell.Col);
        SelectedCell = CurrentState.GetSelectedCell();
        UpdateDerivedProperties();
    }

    /// <summary>获取是否可以选中单元格。</summary>
    public bool CanSelectCell => CurrentState is not null && CurrentState.Board is not null && !IsGameCompleted;

    /// <summary>获取是否可以输入数字。</summary>
    public bool CanInputNumber => CurrentState is not null && CurrentState.Board is not null && !IsGameCompleted && CurrentState.GetSelectedCell() is not null && !CurrentState.GetSelectedCell()!.IsFixed;

    /// <summary>获取是否可以擦除。</summary>
    public bool CanErase => CurrentState is not null && CurrentState.Board is not null && !IsGameCompleted && CurrentState.GetSelectedCell() is not null && !CurrentState.GetSelectedCell()!.IsFixed;

    /// <summary>
    /// 处理单元格点击。
    /// </summary>
    /// <param name="row">行索引。</param>
    /// <param name="col">列索引。</param>
    public async Task HandleCellTapAsync(int row, int col)
    {
        if (!IsPlaying || CurrentState?.Board is null) return;

        try
        {
            // 使用 Handler 处理单元格点击
            _inputHandler?.SelectCell(row, col);
            
            // 更新选中单元格状态
            SelectedCell = CurrentState.GetSelectedCell();
        }
        catch (Exception ex)
        {
            HandleError("处理单元格点击失败", ex);
        }
    }

    /// <summary>
    /// 输入数字命令，在选中单元格填入指定数字。
    /// </summary>
    /// <param name="number">要填入的数字（1-9）。</param>
    [RelayCommand(CanExecute = nameof(CanInputNumber))]
    private async Task InputNumber(int number)
    {
        if (CurrentState is null || CurrentState.Board is null || IsGameCompleted)
            return;

        var cell = CurrentState.GetSelectedCell();
        if (cell is null || cell.IsFixed)
            return;

        if (CurrentState.IsMarkMode)
        {
            await ToggleCandidateAsync(cell.Row, cell.Col, number);
        }
        else
        {
            await SetCellValueAsync(cell.Row, cell.Col, number);
        }
    }

    /// <summary>
    /// 设置单元格值。
    /// </summary>
    /// <param name="row">行索引。</param>
    /// <param name="col">列索引。</param>
    /// <param name="value">要设置的值。</param>
    private async Task SetCellValueAsync(int row, int col, int? value)
    {
        if (!IsPlaying) return;

        try
        {
            // 使用 Handler 处理单元格值设置
            _inputHandler?.SetCellValue(row, col, value);

            // 更新派生属性（包括NumberCounts）
            UpdateDerivedProperties();

            // 检查游戏是否完成
            if (CurrentState?.IsCompleted == true)
            {
                StopTimer();
                await _audioService.PlayCompleteSoundAsync();
                await HandleGameCompletionAsync();
            }

            // 自动标记模式下重新计算候选数
            if (CurrentState?.IsAutoMarkMode == true && IsPlaying)
            {
                if (IsSamuraiGame)
                {
                    await AutoMarkCandidatesAsync([CurrentSubGridIndex]);
                }
                else
                {
                    await AutoMarkCandidatesAsync();
                }
            }

            await SaveGameAsync();
        }
        catch (Exception ex)
        {
            HandleError("设置单元格值失败", ex);
        }
    }

    /// <summary>
    /// 切换候选数标记。
    /// </summary>
    /// <param name="row">行索引。</param>
    /// <param name="col">列索引。</param>
    /// <param name="candidate">候选数字。</param>
    private async Task ToggleCandidateAsync(int row, int col, int candidate)
    {
        if (!IsPlaying || CurrentState?.Board is null) return;

        try
        {
            // 使用 Handler 处理候选数切换
            _inputHandler?.ToggleCandidate(row, col, candidate);
            await SaveGameAsync();
        }
        catch (Exception ex)
        {
            HandleError("切换候选数失败", ex);
        }
    }

    /// <summary>
    /// 擦除命令，清除选中单元格的数字。
    /// </summary>
    [RelayCommand(CanExecute = nameof(CanErase))]
    private async Task Erase()
    {
        if (CurrentState is null || IsGameCompleted) return;

        var selectedCell = CurrentState.GetSelectedCell();
        if (selectedCell is null || selectedCell.IsFixed) return;

        // 使用 Handler 处理擦除操作
        _inputHandler?.ClearCell(selectedCell.Row, selectedCell.Col);

        // 自动标记模式下重新计算候选数
        if (CurrentState?.IsAutoMarkMode == true && IsPlaying)
        {
            if (IsSamuraiGame)
            {
                await AutoMarkCandidatesAsync([CurrentSubGridIndex]);
            }
            else
            {
                await AutoMarkCandidatesAsync();
            }
        }

        await SaveGameAsync();
    }

    #endregion

    #region 功能键盘相关方法

    /// <summary>
    /// 撤销命令，恢复到上一步操作状态。
    /// </summary>
    [RelayCommand(CanExecute = nameof(CanUndo))]
    private void Undo()
    {
        if (CurrentState is null || !IsPlaying) return;
        // 使用 Handler 处理撤销操作
        _lifecycleHandler?.Undo();
        UpdateDerivedProperties();
        SaveGameDebounced();
    }

    /// <summary>
    /// 重做命令，恢复被撤销的操作。
    /// </summary>
    [RelayCommand(CanExecute = nameof(CanRedo))]
    private void Redo()
    {
        if (CurrentState is null || !IsPlaying) return;
        // 使用 Handler 处理重做操作
        _lifecycleHandler?.Redo();
        UpdateDerivedProperties();
        SaveGameDebounced();
    }

    /// <summary>
    /// 提示命令，在当前棋盘填入一个正确数字。
    /// </summary>
    [RelayCommand]
    private async Task Hint()
    {
        if (CurrentState is null || IsGameCompleted)
            return;

        // 使用 Handler 处理提示逻辑
        _assistHandler?.ProvideHint();

        // 检查游戏是否完成
        if (CurrentState?.IsCompleted == true)
        {
            StopTimer();
            await _audioService.PlayCompleteSoundAsync();
            await HandleGameCompletionAsync();
        }

        await SaveGameAsync();
    }

    /// <summary>
    /// 切换笔记模式命令。
    /// </summary>
    [RelayCommand]
    private void ToggleMarkMode()
    {
        if (CurrentState is null) return;
        // 使用 Handler 处理标记模式切换
        _lifecycleHandler?.ToggleMarkMode();
        OnPropertyChanged(nameof(IsMarkMode));
    }

    /// <summary>
    /// 切换自动笔记模式命令。
    /// </summary>
    [RelayCommand]
    private async Task ToggleAutoMarkMode()
    {
        if (CurrentState is null || CurrentState.Board is null) return;

        // 使用 Handler 处理自动标记模式切换
        _lifecycleHandler?.ToggleAutoMarkMode();

        // 如果刚开启自动标记，立即计算一次候选数
        if (CurrentState.IsAutoMarkMode && CurrentState.Board is not null)
        {
            if (IsSamuraiGame)
            {
                await AutoMarkCandidatesAsync([CurrentSubGridIndex]);
            }
            else
            {
                await AutoMarkCandidatesAsync();
            }
        }
        else if (!CurrentState.IsAutoMarkMode)
        {
            await ClearAllCandidatesAsync();
        }

        OnPropertyChanged(nameof(IsAutoMarkMode));
    }

    /// <summary>
    /// 显示解答命令。
    /// </summary>
    [RelayCommand]
    private void ShowSolution()
    {
        if (CurrentState is null) return;
        // 使用 Handler 处理解答显示切换
        _lifecycleHandler?.ToggleShowSolution();
        OnPropertyChanged(nameof(IsShowingSolution));
    }

    #endregion

    #region 自动标记候选数

    /// <summary>
    /// 自动标记候选数。
    /// </summary>
    /// <param name="visibleSubBoards">可见子网格索引列表（仅武士数独使用）。</param>
    private async Task AutoMarkCandidatesAsync(int[]? visibleSubBoards = null)
    {
        // 取消之前的防抖计时器
        CancelAutoMarkDebounce();

        _autoMarkDebounceCts = new CancellationTokenSource();
        var token = _autoMarkDebounceCts.Token;

        try
        {
            // 防抖延迟
            await Task.Delay(100, token);

            if (token.IsCancellationRequested || CurrentState?.Board is null || _isCalculatingCandidates)
                return;

            _isCalculatingCandidates = true;

            var board = CurrentState.Board;
            var calculator = new CandidateCalculator(board);
            var useAdvancedStrategies = _settingsService.IsAdvancedStrategyEnabled;

            Dictionary<string, HashSet<int>> candidates;

            // 如果是武士数独且有可见子棋盘，只计算可见子棋盘的候选数
            if (board is SamuraiBoard && visibleSubBoards != null)
            {
                candidates = calculator.ComputeSamuraiCandidates(visibleSubBoards, useAdvancedStrategies);
            }
            else
            {
                candidates = calculator.ComputeAllCandidates(useAdvancedStrategies);
            }

            // 更新棋盘候选数
            var newBoard = board;

            if (board is SamuraiBoard samuraiBoard && visibleSubBoards != null)
            {
                // 只更新可见子棋盘的候选数
                foreach (var subBoardIndex in visibleSubBoards)
                {
                    // 边界检查
                    if (subBoardIndex < 0 || subBoardIndex >= SamuraiConstants.SubGridCount)
                        continue;
                    
                    var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subBoardIndex];
                    for (int row = startRow; row < startRow + 9; row++)
                    {
                        for (int col = startCol; col < startCol + 9; col++)
                        {
                            var key = $"{row},{col}";
                            if (candidates.TryGetValue(key, out var cellCandidates))
                            {
                                newBoard = newBoard.SetCellCandidates(row, col, [.. cellCandidates]);
                            }
                        }
                    }
                }
            }
            else
            {
                // 更新整个棋盘的候选数
                for (int row = 0; row < newBoard.Size; row++)
                {
                    for (int col = 0; col < newBoard.Size; col++)
                    {
                        var key = $"{row},{col}";
                        if (candidates.TryGetValue(key, out var cellCandidates))
                        {
                            newBoard = newBoard.SetCellCandidates(row, col, [.. cellCandidates]);
                        }
                    }
                }
            }

            CurrentState = CurrentState.CopyWith(board: newBoard);
        }
        catch (OperationCanceledException)
        {
            // 防抖取消，正常情况
        }
        finally
        {
            _isCalculatingCandidates = false;
        }
    }

    /// <summary>
    /// 清除所有候选数。
    /// </summary>
    private async Task ClearAllCandidatesAsync()
    {
        if (CurrentState?.Board is null) return;

        var newBoard = CurrentState.Board;

        for (int row = 0; row < CurrentState.Board.Size; row++)
        {
            for (int col = 0; col < CurrentState.Board.Size; col++)
            {
                var cell = CurrentState.Board.GetCell(row, col);
                if (!cell.IsFixed && cell.Value == null)
                {
                    newBoard = newBoard.SetCellCandidates(row, col, []);
                }
            }
        }

        CurrentState = CurrentState.CopyWith(board: newBoard);
        await Task.CompletedTask;
    }

    /// <summary>
    /// 取消自动标记防抖计时器。
    /// </summary>
    private void CancelAutoMarkDebounce()
    {
        _autoMarkDebounceCts?.Cancel();
        _autoMarkDebounceCts?.Dispose();
        _autoMarkDebounceCts = null;
    }

    #endregion

    #region 游戏持久化

    /// <summary>
    /// 异步保存游戏到存储。
    /// </summary>
    private async Task SaveGameAsync()
    {
        if (CurrentState is null || CurrentState.Board is null || CurrentState.IsCompleted)
            return;

        try
        {
            await _storageService.SaveGameAsync(CurrentState);
        }
        catch
        {
            // 自动保存失败时静默处理
        }
    }

    /// <summary>
    /// 防抖保存游戏。
    /// </summary>
    public void SaveGameDebounced()
    {
        CancelSaveDebounce();

        _saveDebounceCts = new CancellationTokenSource();
        var token = _saveDebounceCts.Token;

        _ = Task.Run(async () =>
        {
            try
            {
                await Task.Delay(1000, token);
                if (!token.IsCancellationRequested)
                {
                    await SaveGameAsync();
                }
            }
            catch (OperationCanceledException)
            {
                // 防抖取消，正常情况
            }
        }, token);
    }

    /// <summary>
    /// 取消保存防抖计时器。
    /// </summary>
    private void CancelSaveDebounce()
    {
        _saveDebounceCts?.Cancel();
        _saveDebounceCts?.Dispose();
        _saveDebounceCts = null;
    }

    #endregion

    #region 计时器

    /// <summary>
    /// 启动计时器。
    /// </summary>
    private void StartTimer()
    {
        _timerHandler?.StartTimer(() => OnTimerTick(this, EventArgs.Empty));
    }

    /// <summary>
    /// 停止计时器。
    /// </summary>
    private void StopTimer()
    {
        _timerHandler?.StopTimer();
    }

    /// <summary>
    /// 计时器触发事件处理，更新已用时间。
    /// </summary>
    private void OnTimerTick(object? sender, EventArgs e)
    {
        if (CurrentState is null) return;
        var newTime = CurrentState.ElapsedTime + 1;
        CurrentState = CurrentState.UpdateElapsedTime(newTime);
        ElapsedTimeDisplay = FormatTime(newTime);
    }

    #endregion

    #region 游戏完成处理

    /// <summary>
    /// 检查游戏是否已完成，如果完成则记录统计并导航到完成页面。
    /// </summary>
    private async Task HandleGameCompletionAsync()
    {
        if (CurrentState is null || CurrentState.Board is null)
            return;

        var gameType = CurrentState.GameType;
        var difficulty = CurrentState.Difficulty;
        var time = CurrentState.ElapsedTime;
        var mistakes = CurrentState.Mistakes;
        var hintsUsed = CurrentState.HintsUsed;

        await _statisticsService.RecordGameAsync(gameType, difficulty, time, mistakes, hintsUsed, true);
        await GameStorageService.DeleteGameAsync(gameType, difficulty);

        var isNewRecord = await _statisticsService.IsNewBestScoreAsync(gameType, difficulty, time, mistakes);

        await NavigationService.GoToAsync(nameof(Views.CompletionPage), new Dictionary<string, object>
        {
            { "GameState", CurrentState },
            { "IsNewRecord", isNewRecord }
        });
    }

    #endregion

    #region 最佳成绩

    /// <summary>
    /// 异步加载最佳时间。
    /// </summary>
    /// <param name="gameType">游戏类型。</param>
    /// <param name="difficulty">难度等级。</param>
    private async Task LoadBestScoreAsync(GameType gameType, Difficulty difficulty)
    {
        try
        {
            _cachedBestScore = await _statisticsService.GetBestScoreAsync(gameType, difficulty);
            _isBestScoreLoaded = true;
            BestTimeDisplay = _cachedBestScore != null ? FormatTime(_cachedBestScore.Time) : "--:--";
            OnPropertyChanged(nameof(IsBestScoreLoaded));
            OnPropertyChanged(nameof(BestScoreMistakes));
        }
        catch
        {
            _cachedBestScore = null;
            _isBestScoreLoaded = true;
            BestTimeDisplay = "--:--";
        }
    }

    #endregion

    #region 辅助方法

    /// <summary>
    /// 更新从当前状态派生的属性。
    /// </summary>
    private void UpdateDerivedProperties()
    {
        if (CurrentState is null) return;

        CompletionPercentage = CurrentState.CompletionPercentage;
        SelectedCell = CurrentState.GetSelectedCell();

        OnPropertyChanged(nameof(Board));
        OnPropertyChanged(nameof(CanUndo));
        OnPropertyChanged(nameof(CanRedo));
        OnPropertyChanged(nameof(CanSelectCell));
        OnPropertyChanged(nameof(IsMarkMode));
        OnPropertyChanged(nameof(IsAutoMarkMode));
        OnPropertyChanged(nameof(IsShowingSolution));
        OnPropertyChanged(nameof(NumberCounts));
        OnPropertyChanged(nameof(LocalizedDifficulty));
        OnPropertyChanged(nameof(IsSamuraiGame));
        OnPropertyChanged(nameof(IsDiagonalGame));
        OnPropertyChanged(nameof(IsJigsawGame));
        OnPropertyChanged(nameof(IsKillerGame));
        OnPropertyChanged(nameof(SubGridLabel));
        OnPropertyChanged(nameof(IsPlaying));
        OnPropertyChanged(nameof(IsGameCompleted));
        OnPropertyChanged(nameof(MistakesCount));

        // 通知所有命令的CanExecute状态已改变
        SelectCellCommand.NotifyCanExecuteChanged();
        UndoCommand.NotifyCanExecuteChanged();
        RedoCommand.NotifyCanExecuteChanged();
        InputNumberCommand.NotifyCanExecuteChanged();
        EraseCommand.NotifyCanExecuteChanged();
        HintCommand.NotifyCanExecuteChanged();

        // 通知CanExecute相关属性
        OnPropertyChanged(nameof(CanInputNumber));
        OnPropertyChanged(nameof(CanErase));
    }

    /// <summary>
    /// 将秒数格式化为时间显示字符串。
    /// </summary>
    /// <param name="seconds">秒数。</param>
    /// <returns>格式化的时间字符串（MM:SS 或 HH:MM:SS）。</returns>
    private static string FormatTime(int seconds)
    {
        if (seconds < 0) seconds = 0;
        var ts = TimeSpan.FromSeconds(seconds);
        if (ts.TotalHours >= 1)
        {
            return ts.ToString(@"hh\:mm\:ss");
        }
        return ts.ToString(@"mm\:ss");
    }

    /// <summary>
    /// 获取本地化的游戏类型名称。
    /// </summary>
    /// <param name="gameType">游戏类型。</param>
    /// <returns>本地化的游戏类型名称。</returns>
    private static string GetLocalizedGameTypeName(GameType gameType)
    {
        return gameType switch
        {
            GameType.Standard => AppResources.StandardSudoku,
            GameType.Jigsaw => AppResources.JigsawSudoku,
            GameType.Diagonal => AppResources.DiagonalSudoku,
            GameType.Window => AppResources.WindowSudoku,
            GameType.Killer => AppResources.KillerSudoku,
            GameType.Samurai => AppResources.SamuraiSudoku,
            GameType.Custom => AppResources.CustomSudoku,
            _ => AppResources.StandardSudoku
        };
    }

    /// <summary>
    /// 获取数字使用次数。
    /// </summary>
    /// <param name="number">数字。</param>
    /// <returns>使用次数。</returns>
    public int? GetNumberCount(int number)
    {
        if (IsSamuraiGame && CurrentState?.Board is SamuraiBoard samuraiBoard)
        {
            // Samurai 仅计算当前子网格的数字计数
            var subBoard = samuraiBoard.GetSubBoard(CurrentSubGridIndex);
            int count = 0;
            for (int i = 0; i < subBoard.Size; i++)
            {
                for (int j = 0; j < subBoard.Size; j++)
                {
                    if (subBoard.Cells[i][j].Value == number)
                    {
                        count++;
                    }
                }
            }
            return count;
        }

        var counts = CurrentState?.NumberCounts;
        return counts?.TryGetValue(number, out var c) == true ? c : 0;
    }

    /// <summary>
    /// 处理错误。
    /// </summary>
    /// <param name="message">错误消息。</param>
    /// <param name="error">异常对象。</param>
    private static void HandleError(string message, Exception error)
    {
        System.Diagnostics.Debug.WriteLine($"{message}: {error}");
    }

    /// <summary>
    /// 处理错误（实例版本，用于 Handler）。
    /// </summary>
    /// <param name="message">错误消息。</param>
    private void HandleError(string message)
    {
        System.Diagnostics.Debug.WriteLine(message);
    }

    /// <summary>
    /// 反序列化自定义棋盘。
    /// </summary>
    private static CustomGameBoard? DeserializeCustomBoard(string json, GameType gameType)
    {
        try
        {
            var options = new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var cellsData = System.Text.Json.JsonSerializer.Deserialize<List<List<int?>>>(json, options);
            if (cellsData == null) return null;

            var size = cellsData.Count;
            var cells = new List<List<SudokuCell>>();
            for (int r = 0; r < size; r++)
            {
                var row = new List<SudokuCell>();
                for (int c = 0; c < size; c++)
                {
                    var val = cellsData[r].Count > c ? cellsData[r][c] : null;
                    row.Add(new SudokuCell(r, c, val, isFixed: val.HasValue));
                }
                cells.Add(row);
            }

            // 创建标准区域
            var regions = new List<SudokuRegion>();
            int blockSize = size == 9 ? 3 : 2;
            for (int br = 0; br < blockSize; br++)
            {
                for (int bc = 0; bc < blockSize; bc++)
                {
                    var blockCells = new List<SudokuCell>();
                    for (int r = br * blockSize; r < br * blockSize + blockSize; r++)
                        for (int c = bc * blockSize; c < bc * blockSize + blockSize; c++)
                            blockCells.Add(cells[r][c]);
                    regions.Add(new SudokuRegion($"block_{br}_{bc}", RegionType.Block, $"Block({br + 1},{bc + 1})", blockCells));
                }
            }
            for (int r = 0; r < size; r++)
                regions.Add(new SudokuRegion($"row_{r}", RegionType.Row, $"Row {r + 1}", [.. cells[r]]));
            for (int c = 0; c < size; c++)
            {
                var colCells = new List<SudokuCell>();
                for (int r = 0; r < size; r++) colCells.Add(cells[r][c]);
                regions.Add(new SudokuRegion($"col_{c}", RegionType.Column, $"Col {c + 1}", colCells));
            }

            return new CustomGameBoard(size, cells, regions, gameType);
        }
        catch
        {
            return null;
        }
    }

    #endregion
}
