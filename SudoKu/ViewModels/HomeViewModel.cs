namespace SudoKu.ViewModels;

using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Maui.Graphics;
using SudoKu.Models;
using SudoKu.Resources;
using SudoKu.Services;

/// <summary>
/// 首页 ViewModel，管理游戏类型选择、难度选择和游戏启动操作。
/// 参照 Flutter 项目的 HomeViewModel 实现。
/// </summary>
public partial class HomeViewModel : ObservableObject, IDisposable
{
    private readonly IServiceProvider _serviceProvider;
    private readonly GameStorageService _storageService;

    /// <summary>当前页面索引（0=游戏类型列表, 1=难度选择）。</summary>
    [ObservableProperty]
    public partial int CurrentPage { get; set; }

    /// <summary>当前选中的游戏类型。</summary>
    [ObservableProperty]
    public partial GameType? SelectedGameType { get; set; }

    /// <summary>当前选中的游戏名称。</summary>
    [ObservableProperty]
    public partial string SelectedGameName { get; set; } = string.Empty;

    /// <summary>是否显示难度选择页面。</summary>
    [ObservableProperty]
    public partial bool IsDifficultyPage { get; set; }

    /// <summary>是否显示自定义游戏按钮。</summary>
    [ObservableProperty]
    public partial bool IsCustomGameVisible { get; set; }

    /// <summary>是否有保存的游戏。</summary>
    [ObservableProperty]
    public partial bool HasSavedGame { get; set; }

    /// <summary>是否正在生成游戏。</summary>
    [ObservableProperty]
    public partial bool IsGenerating { get; set; }

    /// <summary>应用版本号。</summary>
    [ObservableProperty]
    public partial string Version { get; set; } = string.Empty;

    /// <summary>页面宽度。</summary>
    [ObservableProperty]
    public partial double PageWidth { get; set; }

    /// <summary>页面高度。</summary>
    [ObservableProperty]
    public partial double PageHeight { get; set; }

    /// <summary>游戏类型显示项集合。</summary>
    public ObservableCollection<GameTypeDisplay> GameTypeItems { get; }

    /// <summary>难度显示项集合。</summary>
    public ObservableCollection<DifficultyDisplay> DifficultyItems { get; }

    // Flutter 游戏类型配色 (primaryColor, lightColor)
    // 顺序: Standard(0), Jigsaw(1), Diagonal(2), Window(3), Killer(4), Samurai(5)
    private static readonly (Color Primary, Color Light)[] GameTypeColors =
    [
        (Color.FromArgb("#6366F1"), Color.FromArgb("#818CF8")), // Standard
        (Color.FromArgb("#06B6D4"), Color.FromArgb("#22D3EE")), // Jigsaw
        (Color.FromArgb("#A855F7"), Color.FromArgb("#C084FC")), // Diagonal
        (Color.FromArgb("#3B82F6"), Color.FromArgb("#60A5FA")), // Window
        (Color.FromArgb("#EF4444"), Color.FromArgb("#F87171")), // Killer
        (Color.FromArgb("#F97316"), Color.FromArgb("#FB923C")), // Samurai
    ];

    // Flutter 难度配色
    private static readonly (Color Primary, Color Light, string Stars)[] DifficultyStyles =
    [
        (Color.FromArgb("#22C55E"), Color.FromArgb("#4ADE80"), "★"),
        (Color.FromArgb("#10B981"), Color.FromArgb("#34D399"), "★★"),
        (Color.FromArgb("#EAB308"), Color.FromArgb("#FACC15"), "★★★"),
        (Color.FromArgb("#F97316"), Color.FromArgb("#FB923C"), "★★★★"),
        (Color.FromArgb("#EF4444"), Color.FromArgb("#F87171"), "★★★★★"),
        (Color.FromArgb("#A855F7"), Color.FromArgb("#C084FC"), "★★★★★★"),
    ];

    public IRelayCommand<GameType> SelectGameTypeCommand { get; }
    public IRelayCommand<Difficulty> SelectDifficultyCommand { get; }
    public IRelayCommand LoadGameCommand { get; }
    public IRelayCommand CustomGameCommand { get; }
    public IRelayCommand CancelGenerationCommand { get; }
    public IRelayCommand HelpCommand { get; }
    public IRelayCommand StatisticsCommand { get; }
    public IRelayCommand SettingsCommand { get; }
    public IRelayCommand BackToGamesCommand { get; }

    /// <summary>
    /// 初始化首页 ViewModel 的新实例。
    /// </summary>
    public HomeViewModel(GameStorageService storageService, IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
        _storageService = storageService;

        // 初始化游戏类型项 - 参照 Flutter 的 GameType.values 顺序
        // 顺序: Standard(0), Jigsaw(1), Diagonal(2), Window(3), Killer(4), Samurai(5)
        GameTypeItems =
        [
            CreateGameTypeDisplay(GameType.Standard, AppResources.StandardSudoku, AppResources.GameTypeStandardDescription),
            CreateGameTypeDisplay(GameType.Jigsaw, AppResources.JigsawSudoku, AppResources.GameTypeJigsawDescription),
            CreateGameTypeDisplay(GameType.Diagonal, AppResources.DiagonalSudoku, AppResources.GameTypeDiagonalDescription),
            CreateGameTypeDisplay(GameType.Window, AppResources.WindowSudoku, AppResources.GameTypeWindowDescription),
            CreateGameTypeDisplay(GameType.Killer, AppResources.KillerSudoku, AppResources.GameTypeKillerDescription),
            CreateGameTypeDisplay(GameType.Samurai, AppResources.SamuraiSudoku, AppResources.GameTypeSamuraiDescription),
        ];

        // 初始化难度项 - 参照 Flutter 的 difficultyStyles
        DifficultyItems =
        [
            CreateDifficultyDisplay(Difficulty.Beginner, AppResources.Beginner, 0),
            CreateDifficultyDisplay(Difficulty.Easy, AppResources.Easy, 1),
            CreateDifficultyDisplay(Difficulty.Medium, AppResources.Medium, 2),
            CreateDifficultyDisplay(Difficulty.Hard, AppResources.Hard, 3),
            CreateDifficultyDisplay(Difficulty.Expert, AppResources.Expert, 4),
            CreateDifficultyDisplay(Difficulty.Master, AppResources.Master, 5),
        ];

        // 初始化命令
        SelectGameTypeCommand = new RelayCommand<GameType>(OnSelectGameType);
        SelectDifficultyCommand = new RelayCommand<Difficulty>(OnSelectDifficulty);
        LoadGameCommand = new RelayCommand(OnLoadGame);
        CustomGameCommand = new RelayCommand(OnCustomGame);
        CancelGenerationCommand = new RelayCommand(OnCancelGeneration);
        HelpCommand = new RelayCommand(OnHelpClicked);
        StatisticsCommand = new RelayCommand(OnStatisticsClicked);
        SettingsCommand = new RelayCommand(OnSettingsClicked);
        BackToGamesCommand = new RelayCommand(OnBackToGames);

        // 订阅语言变化事件
        AppResources.LanguageChanged += OnLanguageChanged;

        // 加载版本号
        _ = LoadVersionAsync();
    }

    /// <summary>
    /// 创建游戏类型显示项。
    /// </summary>
    private GameTypeDisplay CreateGameTypeDisplay(GameType type, string displayName, string description)
    {
        var colorIdx = GetGameTypeColorIndex(type);
        var (primaryColor, _) = GameTypeColors[colorIdx];
        return new GameTypeDisplay(type, displayName, description, "", primaryColor);
    }

    /// <summary>
    /// 创建难度显示项。
    /// </summary>
    private DifficultyDisplay CreateDifficultyDisplay(Difficulty level, string displayName, int index)
    {
        var (primaryColor, _, stars) = DifficultyStyles[index];
        var display = new DifficultyDisplay(level, displayName, primaryColor, index + 1);
        display.Stars = stars;
        return display;
    }

    /// <summary>
    /// 获取游戏类型的颜色索引。
    /// 顺序: Standard(0), Jigsaw(1), Diagonal(2), Window(3), Killer(4), Samurai(5)
    /// </summary>
    private static int GetGameTypeColorIndex(GameType type)
    {
        return type switch
        {
            GameType.Standard => 0,
            GameType.Jigsaw => 1,
            GameType.Diagonal => 2,
            GameType.Window => 3,
            GameType.Killer => 4,
            GameType.Samurai => 5,
            _ => 0
        };
    }

    /// <summary>
    /// 异步加载应用版本号。
    /// </summary>
    private async Task LoadVersionAsync()
    {
        try
        {
            var version = AppInfo.Current.Version;
            Version = $"{version.Major}.{version.Minor}.{version.Build}";
        }
        catch
        {
            Version = "1.0.0";
        }
    }

    /// <summary>
    /// 选择游戏类型 - 参照 Flutter: navigateToDifficulty
    /// </summary>
    private async void OnSelectGameType(GameType gameType)
    {
        SelectedGameType = gameType;
        SelectedGameName = GetGameTypeDisplayName(gameType);

        // 检查是否支持自定义游戏 - 参照 Flutter: showCustomGame
        IsCustomGameVisible = GameTypeConfigFactory.GetConfig(gameType).ShowCustomGame;

        // 切换到难度选择页面
        CurrentPage = 1;
        IsDifficultyPage = true;

        // 检查是否有保存的游戏
        await CheckSavedGameAsync();
    }

    /// <summary>
    /// 返回游戏类型列表 - 参照 Flutter: backToGames
    /// </summary>
    private void OnBackToGames()
    {
        CurrentPage = 0;
        IsDifficultyPage = false;
        SelectedGameType = null;
        SelectedGameName = string.Empty;
    }

    /// <summary>
    /// 选择难度并开始游戏 - 参照 Flutter: _startGame
    /// </summary>
    private async void OnSelectDifficulty(Difficulty difficulty)
    {
        if (SelectedGameType == null) return;

        IsGenerating = true;
        try
        {
            await Shell.Current.GoToAsync(nameof(Views.GamePage), new Dictionary<string, object>
            {
                ["GameType"] = SelectedGameType.Value,
                ["Difficulty"] = difficulty,
                ["IsNewGame"] = true
            });
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync("Error", $"Failed to start game: {ex.Message}", "OK");
        }
        finally
        {
            IsGenerating = false;
        }
    }

    /// <summary>
    /// 加载保存的游戏 - 参照 Flutter: _continueSavedGame
    /// </summary>
    private async void OnLoadGame()
    {
        if (SelectedGameType == null || !HasSavedGame) return;

        try
        {
            var info = await _storageService.GetSavedGameInfoAsync(SelectedGameType.Value);
            if (info == null) return;

            await Shell.Current.GoToAsync(nameof(Views.GamePage), new Dictionary<string, object>
            {
                ["GameType"] = SelectedGameType.Value,
                ["Difficulty"] = info.Value.Item1,
                ["IsNewGame"] = false
            });
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync("Error", $"Failed to load game: {ex.Message}", "OK");
        }
    }

    /// <summary>
    /// 打开自定义游戏 - 参照 Flutter: _openCustomGame
    /// </summary>
    private async void OnCustomGame()
    {
        if (SelectedGameType == null) return;

        try
        {
            await Shell.Current.GoToAsync(nameof(Views.CustomGamePage), new Dictionary<string, object>
            {
                ["GameType"] = SelectedGameType.Value
            });
        }
        catch (Exception ex)
        {
            await Shell.Current.DisplayAlertAsync("Error", $"Failed to open custom game: {ex.Message}", "OK");
        }
    }

    /// <summary>
    /// 取消游戏生成。
    /// </summary>
    private void OnCancelGeneration() => IsGenerating = false;

    /// <summary>
    /// 检查是否有保存的游戏 - 参照 Flutter: hasSavedGame
    /// </summary>
    private async Task CheckSavedGameAsync()
    {
        if (SelectedGameType == null)
        {
            HasSavedGame = false;
            return;
        }

        try
        {
            HasSavedGame = await GameStorageService.HasAnySavedGameAsync(SelectedGameType.Value);
        }
        catch
        {
            HasSavedGame = false;
        }
    }

    /// <summary>
    /// 获取游戏类型的显示名称。
    /// </summary>
    private static string GetGameTypeDisplayName(GameType gameType)
    {
        return gameType switch
        {
            GameType.Standard => AppResources.StandardSudoku,
            GameType.Jigsaw => AppResources.JigsawSudoku,
            GameType.Diagonal => AppResources.DiagonalSudoku,
            GameType.Window => AppResources.WindowSudoku,
            GameType.Killer => AppResources.KillerSudoku,
            GameType.Samurai => AppResources.SamuraiSudoku,
            _ => gameType.ToString()
        };
    }

    /// <summary>
    /// 显示帮助对话框 - 参照 Flutter: _showHelpDialog
    /// </summary>
    private async void OnHelpClicked()
    {
        var helpPage = _serviceProvider.GetRequiredService<Views.RulesPage>();
        await Shell.Current.Navigation.PushAsync(helpPage);
    }

    /// <summary>
    /// 打开统计页面。
    /// </summary>
    private async void OnStatisticsClicked()
    {
        var statisticsPage = _serviceProvider.GetRequiredService<Views.StatisticsPage>();
        await Shell.Current.Navigation.PushAsync(statisticsPage);
    }

    /// <summary>
    /// 打开设置页面。
    /// </summary>
    private async void OnSettingsClicked()
    {
        var settingsPage = _serviceProvider.GetRequiredService<Views.SettingsPage>();
        await Shell.Current.Navigation.PushAsync(settingsPage);
    }

    /// <summary>
    /// 语言变化时刷新显示文本。
    /// </summary>
    private void OnLanguageChanged(object? sender, EventArgs e)
    {
        // 刷新游戏类型显示名称
        foreach (var item in GameTypeItems)
        {
            item.DisplayName = item.Type switch
            {
                GameType.Standard => AppResources.StandardSudoku,
                GameType.Diagonal => AppResources.DiagonalSudoku,
                GameType.Window => AppResources.WindowSudoku,
                GameType.Jigsaw => AppResources.JigsawSudoku,
                GameType.Killer => AppResources.KillerSudoku,
                GameType.Samurai => AppResources.SamuraiSudoku,
                _ => item.DisplayName
            };
            item.Description = item.Type switch
            {
                GameType.Standard => AppResources.GameTypeStandardDescription,
                GameType.Diagonal => AppResources.GameTypeDiagonalDescription,
                GameType.Window => AppResources.GameTypeWindowDescription,
                GameType.Jigsaw => AppResources.GameTypeJigsawDescription,
                GameType.Killer => AppResources.GameTypeKillerDescription,
                GameType.Samurai => AppResources.GameTypeSamuraiDescription,
                _ => item.Description
            };
        }

        // 刷新难度显示名称
        foreach (var item in DifficultyItems)
        {
            item.DisplayName = item.Level switch
            {
                Difficulty.Beginner => AppResources.Beginner,
                Difficulty.Easy => AppResources.Easy,
                Difficulty.Medium => AppResources.Medium,
                Difficulty.Hard => AppResources.Hard,
                Difficulty.Expert => AppResources.Expert,
                Difficulty.Master => AppResources.Master,
                _ => item.DisplayName
            };
        }

        // 刷新选中的游戏名称
        if (SelectedGameType != null)
        {
            SelectedGameName = GetGameTypeDisplayName(SelectedGameType.Value);
        }
    }

    /// <summary>
    /// 释放资源。
    /// </summary>
    public void Dispose()
    {
        AppResources.LanguageChanged -= OnLanguageChanged;
        GC.SuppressFinalize(this);
    }
}
