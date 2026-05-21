namespace SudoKu.Resources;

using System.Globalization;
using System.Resources;

/// <summary>
/// 本地化资源统一入口，支持运行时语言切换
/// </summary>
public static class AppResources
{
    private static CultureInfo? _culture;

    /// <summary>
    /// 语言变化事件，当 Culture 属性改变时触发。
    /// </summary>
    public static event EventHandler? LanguageChanged;

    /// <summary>
    /// 获取 Designer.cs 生成的强类型 ResourceManager
    /// </summary>
    public static ResourceManager ResourceManager => Localization.AppResources.ResourceManager;

    /// <summary>
    /// 获取或设置当前语言文化
    /// 设置时会同步更新 Designer.cs 的 Culture，支持强类型属性响应语言变化
    /// </summary>
    public static CultureInfo? Culture
    {
        get => _culture;
        set
        {
            if (_culture != value)
            {
                _culture = value;
                // 同步更新 Designer.cs 的 Culture，使强类型属性也能响应变化
                Localization.AppResources.Culture = value;
                LanguageChanged?.Invoke(null, EventArgs.Empty);
            }
        }
    }

    /// <summary>
    /// 获取本地化字符串
    /// </summary>
    public static string GetString(string key)
    {
        try
        {
            return ResourceManager.GetString(key, _culture) ?? key;
        }
        catch
        {
            return key;
        }
    }

    // 游戏类型
    public static string StandardSudoku => GetString("GameType_Standard");
    public static string DiagonalSudoku => GetString("GameType_Diagonal");
    public static string JigsawSudoku => GetString("GameType_Jigsaw");
    public static string KillerSudoku => GetString("GameType_Killer");
    public static string WindowSudoku => GetString("GameType_Window");
    public static string SamuraiSudoku => GetString("GameType_Samurai");
    public static string CustomSudoku => GetString("GameType_Custom");

    // 游戏类型描述
    public static string StandardSudokuDesc => GetString("GameType_Standard_Desc");
    public static string DiagonalSudokuDesc => GetString("GameType_Diagonal_Desc");
    public static string JigsawSudokuDesc => GetString("GameType_Jigsaw_Desc");
    public static string KillerSudokuDesc => GetString("GameType_Killer_Desc");
    public static string WindowSudokuDesc => GetString("GameType_Window_Desc");
    public static string SamuraiSudokuDesc => GetString("GameType_Samurai_Desc");
    public static string CustomSudokuDesc => GetString("GameType_Custom_Desc");
    public static string GameTypeStandardDescription => GetString("GameTypeStandardDescription");
    public static string GameTypeDiagonalDescription => GetString("GameTypeDiagonalDescription");
    public static string GameTypeWindowDescription => GetString("GameTypeWindowDescription");
    public static string GameTypeJigsawDescription => GetString("GameTypeJigsawDescription");
    public static string GameTypeKillerDescription => GetString("GameTypeKillerDescription");
    public static string GameTypeSamuraiDescription => GetString("GameTypeSamuraiDescription");

    // 难度
    public static string Beginner => GetString("Difficulty_Beginner");
    public static string Easy => GetString("Difficulty_Easy");
    public static string Medium => GetString("Difficulty_Medium");
    public static string Hard => GetString("Difficulty_Hard");
    public static string Expert => GetString("Difficulty_Expert");
    public static string Master => GetString("Difficulty_Master");

    // 通用按钮
    public static string AppTitle => GetString("App_Title");
    public static string StartNewGame => GetString("Button_StartNewGame");
    public static string ContinueGame => GetString("Button_ContinueGame");
    public static string CustomGame => GetString("Button_CustomGame");
    public static string LoadGame => GetString("Button_LoadGame");
    public static string Save => GetString("Button_Save");
    public static string Cancel => GetString("Button_Cancel");
    public static string Undo => GetString("Button_Undo");
    public static string Redo => GetString("Button_Redo");
    public static string Hint => GetString("Button_Hint");
    public static string Erase => GetString("Button_Erase");
    public static string Notes => GetString("Button_Notes");
    public static string Solution => GetString("Button_Solution");
    public static string PlayAgain => GetString("Button_PlayAgain");
    public static string BackToMenu => GetString("Button_BackToMenu");
    public static string Refresh => GetString("Button_Refresh");
    public static string ClearStatistics => GetString("Button_ClearStatistics");
    public static string Button_Cancel => GetString("Button_Cancel");
    public static string OK => GetString("Common_Button_OK");
    public static string Button_OK => GetString("Common_Button_OK");

    // 页面标题
    public static string HomePageTitle => GetString("Page_Home");
    public static string GamePageTitle => GetString("Page_Game");
    public static string SettingsPageTitle => GetString("Page_Settings");
    public static string StatisticsPageTitle => GetString("Page_Statistics");
    public static string RulesPageTitle => GetString("Page_Rules");
    public static string CompletionPageTitle => GetString("Page_Completion");
    public static string CustomGamePageTitle => GetString("Page_CustomGame");

    // 游戏状态
    public static string GeneratingPuzzle => GetString("Game_GeneratingPuzzle");
    public static string Congratulations => GetString("Game_Congratulations");
    public static string NewRecord => GetString("Game_NewRecord");
    public static string GameOver => GetString("Game_GameOver");
    public static string Mistakes => GetString("Game_Mistakes");
    public static string BestTime => GetString("Game_BestTime");
    public static string ElapsedTime => GetString("Game_ElapsedTime");
    public static string CompletionPercentage => GetString("Game_CompletionPercentage");
    public static string GameGeneratingPuzzle => GetString("Game_GeneratingPuzzle");

    // 统计
    public static string TotalGamesPlayed => GetString("Stats_TotalGamesPlayed");
    public static string TotalGamesWon => GetString("Stats_TotalGamesWon");
    public static string WinRate => GetString("Stats_WinRate");
    public static string CurrentStreak => GetString("Stats_CurrentStreak");
    public static string BestStreak => GetString("Stats_BestStreak");
    public static string TotalPlayTime => GetString("Stats_TotalPlayTime");
    public static string GamesPlayed => GetString("Stats_GamesPlayed");
    public static string GamesWon => GetString("Stats_GamesWon");
    public static string BestTimeStat => GetString("Stats_BestTime");
    public static string AvgTime => GetString("Stats_AvgTime");
    public static string StatsOverview => GetString("Stats_Overview");
    public static string StatsComparison => GetString("Stats_Comparison");
    public static string StatsDetails => GetString("Stats_Details");
    public static string StatsDetailedDescription => GetString("Stats_DetailedDescription");
    public static string StatsGamesPlayedFormat => GetString("Stats_GamesPlayedFormat");
    public static string StatsGamesWonFormat => GetString("Stats_GamesWonFormat");
    public static string Overview => GetString("Stats_Overview");
    public static string Comparison => GetString("Stats_Comparison");
    public static string Details => GetString("Stats_Details");
    public static string TotalGames => GetString("Stats_TotalGames");
    public static string TotalWins => GetString("Stats_TotalWins");
    public static string WinRateLabel => GetString("Stats_WinRate");
    public static string CurrentWinStreak => GetString("Stats_CurrentWinStreak");
    public static string BestWinStreak => GetString("Stats_BestWinStreak");
    public static string TotalPlayTimeLabel => GetString("Stats_TotalPlayTime");
    public static string Games => GetString("Stats_Games");
    public static string Wins => GetString("Stats_Wins");
    public static string BestTimeLabel => GetString("Stats_BestTime");
    public static string AvgTimeLabel => GetString("Stats_AvgTime");
    public static string GameTypeStats => GetString("Stats_GameTypeStats");
    public static string GameTypeStatsDetail => GetString("Stats_GameTypeStatsDetail");

    // 设置
    public static string Theme => GetString("Settings_Theme");
    public static string Language => GetString("Settings_Language");
    public static string BackgroundMusic => GetString("Settings_BackgroundMusic");
    public static string SoundEffects => GetString("Settings_SoundEffects");
    public static string ErrorHighlight => GetString("Settings_ErrorHighlight");
    public static string HighlightSameNumbers => GetString("Settings_HighlightSameNumbers");
    public static string HighlightRelatedCells => GetString("Settings_HighlightRelatedCells");
    public static string AutoCheckErrors => GetString("Settings_AutoCheckErrors");
    public static string AutoMarkMode => GetString("Settings_AutoMarkMode");
    public static string ShowTimer => GetString("Settings_ShowTimer");
    public static string AdvancedStrategy => GetString("Settings_AdvancedStrategy");
    public static string SaveSettings => GetString("Settings_SaveSettings");
    public static string SystemSettings => GetString("Settings_SystemSettings");
    public static string GameSettings => GetString("Settings_GameSettings");
    public static string BasicSettings => GetString("Settings_BasicSettings");
    public static string HighlightSettings => GetString("Settings_HighlightSettings");
    public static string AdvancedSettings => GetString("Settings_AdvancedSettings");
    public static string EnableBackgroundMusic => GetString("Settings_EnableBackgroundMusic");
    public static string EnableSoundEffects => GetString("Settings_EnableSoundEffects");
    public static string Volume => GetString("Settings_Volume");
    public static string Language_Chinese => GetString("Language_Chinese");
    public static string Language_English => GetString("Language_English");
    public static string Theme_Light => GetString("Theme_Light");
    public static string Theme_Dark => GetString("Theme_Dark");
    public static string Theme_System => GetString("Theme_System");
    public static string SettingsBasicSettings => GetString("Settings_BasicSettings");
    public static string SettingsGameSettingsTab => GetString("Settings_GameSettings");
    public static string SettingsLanguage => GetString("Settings_Language");
    public static string SettingsTheme => GetString("Settings_Theme");
    public static string SettingsAudio => GetString("Settings_Audio");
    public static string SettingsMusic => GetString("Settings_BackgroundMusic");
    public static string SettingsSoundEffects => GetString("Settings_SoundEffects");
    public static string SettingsAutoCheck => GetString("Settings_AutoCheckErrors");
    public static string SettingsHighlightMistakes => GetString("Settings_ErrorHighlight");
    public static string SettingsCandidateSettings => GetString("Settings_CandidateSettings");
    public static string SettingsUseAdvancedStrategy => GetString("Settings_AdvancedStrategy");
    public static string SettingsGameSettingsTitle => GetString("Settings_GameSettings");
    public static string SettingsGameSettings => GetString("Settings_GameSettingsLabel");
    public static string Difficulty => GetString("Difficulty_Label");
    public static string SettingsThemeLight => GetString("Theme_Light");
    public static string SettingsThemeDark => GetString("Theme_Dark");
    public static string SettingsThemeSystem => GetString("Theme_System");

    // 完成页面
    public static string GameType => GetString("Completion_GameType");
    public static string DifficultyLabel => GetString("Completion_Difficulty");
    public static string TimeUsed => GetString("Completion_TimeUsed");
    public static string ErrorCount => GetString("Completion_ErrorCount");
    public static string Accuracy => GetString("Completion_Accuracy");
    public static string PuzzleCompleted => GetString("Completion_PuzzleCompleted");
    public static string Current => GetString("Completion_Current");
    public static string BestScore => GetString("Completion_BestScore");
    public static string NewRecordMessage => GetString("Completion_NewRecordMessage");
    public static string Time => GetString("Completion_Time");
    public static string Streak => GetString("Completion_Streak");
    public static string BackToHome => GetString("Completion_BackToHome");
    public static string ViewStatistics => GetString("Completion_ViewStatistics");

    // 主页
    public static string SelectGameType => GetString("Home_SelectGameType");
    public static string SelectDifficulty => GetString("Home_SelectDifficulty");

    // 版本和版权
    public static string Version => GetString("App_Version");
    public static string Copyright => GetString("App_Copyright");

    // 自定义游戏
    public static string FilledCells => GetString("CustomGame_FilledCells");
    public static string RemainingCells => GetString("CustomGame_RemainingCells");
    public static string Validate => GetString("CustomGame_Validate");

    // 规则页面
    public static string RulesTitle => GetString("Rules_Title");
    public static string RulesDescription => GetString("Rules_Description");

    // 通用
    public static string Error => GetString("Common_Error");

    // 生成阶段
    public static string Gen_Initializing => GetString("Gen_Initializing");
    public static string Gen_LoadingTemplate => GetString("Gen_LoadingTemplate");
    public static string Gen_CreatingRegions => GetString("Gen_CreatingRegions");
    public static string Gen_ApplyingSubstitution => GetString("Gen_ApplyingSubstitution");
    public static string Gen_GeneratingSolution => GetString("Gen_GeneratingSolution");
    public static string Gen_DiggingPuzzle => GetString("Gen_DiggingPuzzle");
    public static string Gen_Validating => GetString("Gen_Validating");
    public static string Gen_Completed => GetString("Gen_Completed");
    public static string Gen_Failed => GetString("Gen_Failed");
    public static string Gen_FailedMessage => GetString("Gen_FailedMessage");
    public static string Gen_UserCancelled => GetString("Gen_UserCancelled");

    // 武士数独子网格标签
    public static string SubGrid_TopLeft => GetString("SubGrid_TopLeft");
    public static string SubGrid_TopRight => GetString("SubGrid_TopRight");
    public static string SubGrid_BottomLeft => GetString("SubGrid_BottomLeft");
    public static string SubGrid_BottomRight => GetString("SubGrid_BottomRight");
    public static string SubGrid_Center => GetString("SubGrid_Center");
}
