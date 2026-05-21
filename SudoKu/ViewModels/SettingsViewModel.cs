namespace SudoKu.ViewModels;

using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using SudoKu.Services;

/// <summary>
/// 设置页 ViewModel
///
/// 封装设置相关的业务逻辑，将 UI 与 SettingsService 解耦
/// </summary>
public partial class SettingsViewModel : BaseViewModel
{
    private readonly SettingsService _settingsService;
    private readonly AudioService _audioService;

    // ========== 私有字段 ==========
    private int _selectedTabIndex;
    private string _language = "zh";
    private string _themeMode = "system";

    /// <summary>
    /// 初始化设置 ViewModel 的新实例。
    /// </summary>
    /// <param name="settingsService">设置服务实例。</param>
    /// <param name="audioService">音频服务实例。</param>
    public SettingsViewModel(SettingsService settingsService, AudioService audioService)
    {
        _settingsService = settingsService;
        _audioService = audioService;
        Title = "设置";
        _selectedTabIndex = 0;
        LoadSettings();
    }

    // ========== Tab 相关 ==========

    /// <summary>获取或设置当前选中的 Tab 索引（0=基本设置，1=游戏设置）。</summary>
    public int SelectedTabIndex
    {
        get => _selectedTabIndex;
        set => SetProperty(ref _selectedTabIndex, value);
    }

    // ========== 语言相关 ==========

    /// <summary>获取或设置语言代码（'en' 或 'zh'）。</summary>
    public string Language
    {
        get => _language;
        set
        {
            if (SetProperty(ref _language, value))
            {
                _settingsService.Language = value;
            }
        }
    }

    /// <summary>获取语言索引（0=英文，1=中文）。</summary>
    public int LanguageIndex => Language == "zh" ? 1 : 0;

    // ========== 主题相关 ==========

    /// <summary>获取或设置主题模式（'light', 'dark', 'system'）。</summary>
    public string ThemeMode
    {
        get => _themeMode;
        set
        {
            if (SetProperty(ref _themeMode, value))
            {
                ApplyTheme(value);
            }
        }
    }

    /// <summary>获取主题索引（0=浅色，1=深色，2=跟随系统）。</summary>
    public int ThemeIndex => ThemeMode switch
    {
        "light" => 0,
        "dark" => 1,
        _ => 2
    };

    // ========== 音频相关 ==========

    /// <summary>获取或设置是否启用背景音乐。</summary>
    public bool MusicEnabled
    {
        get => _settingsService.IsBackgroundMusicEnabled;
        set
        {
            _settingsService.IsBackgroundMusicEnabled = value;
            _audioService.SetMusicEnabled(value);
            if (value)
            {
                _audioService.PlayMusicAsync();
            }
            else
            {
                _audioService.PauseMusicAsync();
            }
            OnPropertyChanged();
        }
    }

    /// <summary>获取或设置是否启用音效。</summary>
    public bool SoundEffectsEnabled
    {
        get => _settingsService.AreSoundEffectsEnabled;
        set
        {
            _settingsService.AreSoundEffectsEnabled = value;
            _audioService.SetSoundEffectsEnabled(value);
            OnPropertyChanged();
        }
    }

    // ========== 游戏设置相关 ==========

    /// <summary>获取或设置是否启用自动检查错误。</summary>
    public bool AutoCheckEnabled
    {
        get => _settingsService.IsAutoCheckErrorsEnabled;
        set
        {
            _settingsService.IsAutoCheckErrorsEnabled = value;
            OnPropertyChanged();
        }
    }

    /// <summary>获取或设置是否启用错误高亮。</summary>
    public bool HighlightMistakesEnabled
    {
        get => _settingsService.IsErrorHighlightEnabled;
        set
        {
            _settingsService.IsErrorHighlightEnabled = value;
            OnPropertyChanged();
        }
    }

    /// <summary>获取或设置是否使用高级策略。</summary>
    public bool UseAdvancedStrategy
    {
        get => _settingsService.IsAdvancedStrategyEnabled;
        set
        {
            _settingsService.IsAdvancedStrategyEnabled = value;
            OnPropertyChanged();
        }
    }

    // ========== 命令 ==========

    /// <summary>
    /// Tab切换命令。
    /// </summary>
    [RelayCommand]
    private void SwitchTab(string? parameter)
    {
        if (int.TryParse(parameter, out var index))
        {
            SelectedTabIndex = index;
        }
    }

    /// <summary>
    /// 通过索引设置语言命令（用于分段按钮）。
    /// </summary>
    [RelayCommand]
    private void SetLanguageByIndex(string? indexStr)
    {
        if (int.TryParse(indexStr, out var index))
        {
            var newLanguage = index == 1 ? "zh" : "en";
            Language = newLanguage;
            OnPropertyChanged(nameof(LanguageIndex));
        }
    }

    /// <summary>
    /// 通过索引设置主题命令（用于分段按钮）。
    /// </summary>
    [RelayCommand]
    private void SetThemeByIndex(string? indexStr)
    {
        if (int.TryParse(indexStr, out var index))
        {
            var newTheme = index switch
            {
                0 => "light",
                1 => "dark",
                _ => "system"
            };
            ThemeMode = newTheme;
            OnPropertyChanged(nameof(ThemeIndex));
        }
    }

    /// <summary>
    /// 返回命令。
    /// </summary>
    [RelayCommand]
    private async Task BackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    /// <summary>
    /// 初始化设置。
    /// </summary>
    public Task InitializeAsync()
    {
        LoadSettings();
        return Task.CompletedTask;
    }

    /// <summary>
    /// 从设置服务加载当前设置值。
    /// </summary>
    private void LoadSettings()
    {
        // 语言
        _language = _settingsService.Language switch
        {
            "zh" or "zh-CN" or "zh-Hans" => "zh",
            _ => "en"
        };

        // 主题
        _themeMode = _settingsService.Theme switch
        {
            AppTheme.Light => "light",
            AppTheme.Dark => "dark",
            _ => "system"
        };

        OnPropertyChanged(nameof(Language));
        OnPropertyChanged(nameof(LanguageIndex));
        OnPropertyChanged(nameof(ThemeMode));
        OnPropertyChanged(nameof(ThemeIndex));
        OnPropertyChanged(nameof(MusicEnabled));
        OnPropertyChanged(nameof(SoundEffectsEnabled));
        OnPropertyChanged(nameof(AutoCheckEnabled));
        OnPropertyChanged(nameof(HighlightMistakesEnabled));
        OnPropertyChanged(nameof(UseAdvancedStrategy));
    }

    /// <summary>
    /// 应用主题设置。
    /// </summary>
    private void ApplyTheme(string themeMode)
    {
        var appTheme = themeMode switch
        {
            "light" => AppTheme.Light,
            "dark" => AppTheme.Dark,
            _ => AppTheme.Unspecified
        };
        _settingsService.Theme = appTheme;
        if (Application.Current != null)
        {
            Application.Current.UserAppTheme = appTheme;
        }
    }
}
