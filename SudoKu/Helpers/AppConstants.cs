namespace SudoKu.Helpers;

public static class AppConstants
{
    public const int TemplateLoadMaxRetries = 3;
    public const string AppName = "数独";
    public const string Version = "1.0.0";

    public static class GameDefaults
    {
        public const Models.Difficulty DefaultDifficulty = Models.Difficulty.Medium;
        public const Models.GameType DefaultGameType = Models.GameType.Standard;
    }

    public static class PreferencesKeys
    {
        public const string Prefix = "settings_";
        public const string Version = "version";
        public const string Theme = "theme";
        public const string Language = "language";
        public const string BackgroundMusic = "background_music";
        public const string SoundEffects = "sound_effects";
        public const string MusicVolume = "music_volume";
        public const string EffectsVolume = "effects_volume";
        public const string ErrorHighlight = "error_highlight";
        public const string HighlightSameNumbers = "highlight_same_numbers";
        public const string HighlightRelatedCells = "highlight_related_cells";
        public const string AutoCheckErrors = "auto_check_errors";
        public const string ShowTimer = "show_timer";
        public const string AdvancedStrategy = "advanced_strategy";
    }
}
