using SudoKu.Helpers;

namespace SudoKu.Services;

public class SettingsService
{
    private const int CurrentVersion = 1;

    private AppTheme? _theme;
    private bool _isLoaded;
    private bool _isBackgroundMusicEnabled;
    private bool _areSoundEffectsEnabled;
    private double _musicVolume;
    private double _effectsVolume;
    private string _language = "zh-CN";
    private bool _isErrorHighlightEnabled;
    private bool _isHighlightSameNumbersEnabled;
    private bool _isHighlightRelatedCellsEnabled;
    private bool _isAutoCheckErrorsEnabled;
    private bool _isShowTimerEnabled;
    private bool _isAdvancedStrategyEnabled;

    public SettingsService()
    {
    }

    public event Action<string>? SettingChanged;

    public async Task LoadAsync()
    {
        if (_isLoaded) return;

        await MigrateSettingsIfNeeded();

        _theme = LoadTheme();
        _isBackgroundMusicEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.BackgroundMusic}", true);
        _areSoundEffectsEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.SoundEffects}", true);
        _musicVolume = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.MusicVolume}", 0.5);
        _effectsVolume = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.EffectsVolume}", 0.7);
        _language = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.Language}", "zh-CN");
        _isErrorHighlightEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.ErrorHighlight}", true);
        _isHighlightSameNumbersEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.HighlightSameNumbers}", true);
        _isHighlightRelatedCellsEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.HighlightRelatedCells}", true);
        _isAutoCheckErrorsEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.AutoCheckErrors}", false);
        _isShowTimerEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.ShowTimer}", true);
        _isAdvancedStrategyEnabled = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.AdvancedStrategy}", false);

        _isLoaded = true;
        AppLogger.Debug("设置服务加载完成");
    }

    private async Task MigrateSettingsIfNeeded()
    {
        var version = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.Version}", 0);
        if (version >= CurrentVersion) return;

        AppLogger.Info($"正在迁移设置: v{version} -> v{CurrentVersion}");

        if (version < 1)
        {
            await MigrateToV1();
        }

        Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.Version}", CurrentVersion);
    }

    private Task MigrateToV1()
    {
        var oldAutoCheckKeys = new[] {
            "standard_auto_check", "diagonal_auto_check", "killer_auto_check",
            "jigsaw_auto_check", "window_auto_check"
        };
        foreach (var key in oldAutoCheckKeys)
        {
            if (Preferences.ContainsKey(key))
            {
                _isAutoCheckErrorsEnabled = Preferences.Get(key, false);
                Preferences.Remove(key);
                AppLogger.Debug($"迁移设置: {key} -> IsAutoCheckErrorsEnabled");
                break;
            }
        }

        var oldHighlightKeys = new[] {
            "standard_highlight_mistakes", "diagonal_highlight_mistakes", "killer_highlight_mistakes",
            "jigsaw_highlight_mistakes", "window_highlight_mistakes"
        };
        foreach (var key in oldHighlightKeys)
        {
            if (Preferences.ContainsKey(key))
            {
                _isErrorHighlightEnabled = Preferences.Get(key, true);
                Preferences.Remove(key);
                AppLogger.Debug($"迁移设置: {key} -> IsErrorHighlightEnabled");
                break;
            }
        }

        if (Preferences.ContainsKey("game_use_advanced_strategy"))
        {
            _isAdvancedStrategyEnabled = Preferences.Get("game_use_advanced_strategy", false);
            Preferences.Remove("game_use_advanced_strategy");
            AppLogger.Debug("迁移设置: game_use_advanced_strategy -> IsAdvancedStrategyEnabled");
        }

        if (Preferences.ContainsKey("show_timer"))
        {
            _isShowTimerEnabled = Preferences.Get("show_timer", true);
            Preferences.Remove("show_timer");
            AppLogger.Debug("迁移设置: show_timer -> IsShowTimerEnabled");
        }

        if (Preferences.ContainsKey("highlight_same_numbers"))
        {
            _isHighlightSameNumbersEnabled = Preferences.Get("highlight_same_numbers", true);
            Preferences.Remove("highlight_same_numbers");
            AppLogger.Debug("迁移设置: highlight_same_numbers -> IsHighlightSameNumbersEnabled");
        }

        if (Preferences.ContainsKey("highlight_related_cells"))
        {
            _isHighlightRelatedCellsEnabled = Preferences.Get("highlight_related_cells", true);
            Preferences.Remove("highlight_related_cells");
            AppLogger.Debug("迁移设置: highlight_related_cells -> IsHighlightRelatedCellsEnabled");
        }

        AppLogger.Info("设置迁移到 V1 完成");
        return Task.CompletedTask;
    }

    private AppTheme LoadTheme()
    {
        var themeStr = Preferences.Get($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.Theme}", "Unspecified");
        if (Enum.TryParse<AppTheme>(themeStr, out var theme))
        {
            return theme;
        }
        return AppTheme.Unspecified;
    }

    public AppTheme Theme
    {
        get => _theme ?? AppTheme.Unspecified;
        set
        {
            _theme = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.Theme}", value.ToString());
            OnSettingChanged(nameof(Theme));
        }
    }

    public bool IsBackgroundMusicEnabled
    {
        get => _isBackgroundMusicEnabled;
        set
        {
            _isBackgroundMusicEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.BackgroundMusic}", value);
            OnSettingChanged(nameof(IsBackgroundMusicEnabled));
        }
    }

    public bool AreSoundEffectsEnabled
    {
        get => _areSoundEffectsEnabled;
        set
        {
            _areSoundEffectsEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.SoundEffects}", value);
            OnSettingChanged(nameof(AreSoundEffectsEnabled));
        }
    }

    public double MusicVolume
    {
        get => _musicVolume;
        set
        {
            var clamped = Math.Clamp(value, 0.0, 1.0);
            _musicVolume = clamped;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.MusicVolume}", clamped);
            OnSettingChanged(nameof(MusicVolume));
        }
    }

    public double EffectsVolume
    {
        get => _effectsVolume;
        set
        {
            var clamped = Math.Clamp(value, 0.0, 1.0);
            _effectsVolume = clamped;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.EffectsVolume}", clamped);
            OnSettingChanged(nameof(EffectsVolume));
        }
    }

    public string Language
    {
        get => _language;
        set
        {
            _language = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.Language}", value);
            OnSettingChanged(nameof(Language));
        }
    }

    public bool IsErrorHighlightEnabled
    {
        get => _isErrorHighlightEnabled;
        set
        {
            _isErrorHighlightEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.ErrorHighlight}", value);
            OnSettingChanged(nameof(IsErrorHighlightEnabled));
        }
    }

    public bool IsHighlightSameNumbersEnabled
    {
        get => _isHighlightSameNumbersEnabled;
        set
        {
            _isHighlightSameNumbersEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.HighlightSameNumbers}", value);
            OnSettingChanged(nameof(IsHighlightSameNumbersEnabled));
        }
    }

    public bool IsHighlightRelatedCellsEnabled
    {
        get => _isHighlightRelatedCellsEnabled;
        set
        {
            _isHighlightRelatedCellsEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.HighlightRelatedCells}", value);
            OnSettingChanged(nameof(IsHighlightRelatedCellsEnabled));
        }
    }

    public bool IsAutoCheckErrorsEnabled
    {
        get => _isAutoCheckErrorsEnabled;
        set
        {
            _isAutoCheckErrorsEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.AutoCheckErrors}", value);
            OnSettingChanged(nameof(IsAutoCheckErrorsEnabled));
        }
    }

    public bool IsShowTimerEnabled
    {
        get => _isShowTimerEnabled;
        set
        {
            _isShowTimerEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.ShowTimer}", value);
            OnSettingChanged(nameof(IsShowTimerEnabled));
        }
    }

    public bool IsAdvancedStrategyEnabled
    {
        get => _isAdvancedStrategyEnabled;
        set
        {
            _isAdvancedStrategyEnabled = value;
            Preferences.Set($"{AppConstants.PreferencesKeys.Prefix}{AppConstants.PreferencesKeys.AdvancedStrategy}", value);
            OnSettingChanged(nameof(IsAdvancedStrategyEnabled));
        }
    }

    protected virtual void OnSettingChanged(string propertyName)
    {
        SettingChanged?.Invoke(propertyName);
    }

    public MigrationTestResult TestMigrationV1()
    {
        var result = new MigrationTestResult { IsSuccess = true };

        var oldKeys = new[] {
            "standard_auto_check", "diagonal_auto_check", "killer_auto_check",
            "jigsaw_auto_check", "window_auto_check",
            "standard_highlight_mistakes", "diagonal_highlight_mistakes", "killer_highlight_mistakes",
            "jigsaw_highlight_mistakes", "window_highlight_mistakes",
            "game_use_advanced_strategy", "show_timer", "highlight_same_numbers", "highlight_related_cells"
        };

        foreach (var key in oldKeys)
        {
            if (Preferences.ContainsKey(key))
            {
                result.IsSuccess = false;
                result.FoundOldKeys.Add(key);
            }
        }

        result.NewSettingsValid = _isAutoCheckErrorsEnabled || _isErrorHighlightEnabled ||
                                  _isAdvancedStrategyEnabled || _isShowTimerEnabled ||
                                  _isHighlightSameNumbersEnabled || _isHighlightRelatedCellsEnabled;

        AppLogger.Info($"设置迁移测试完成: 成功={result.IsSuccess}, 旧键数量={result.FoundOldKeys.Count}");
        return result;
    }
}

public class MigrationTestResult
{
    public bool IsSuccess { get; set; }
    public List<string> FoundOldKeys { get; set; } = new();
    public bool NewSettingsValid { get; set; }
}
