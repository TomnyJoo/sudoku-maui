namespace SudoKu.Services;

using System.Text.Json;
using SudoKu.Models;

public sealed class AppConfig
{
    public static AppConfig Instance { get; } = new();

    private AppConfig() { }

    private Dictionary<string, object>? _gameTypesConfig;
    private List<object>? _difficultyConfig;
    private bool _initialized;

    public bool IsInitialized => _initialized;

    public async Task InitializeAsync()
    {
        if (_initialized) return;

        try
        {
            var gameTypesPath = Path.Combine(AppContext.BaseDirectory, "Resources", "Configs", "game_types.json");
            if (File.Exists(gameTypesPath))
            {
                var json = await File.ReadAllTextAsync(gameTypesPath);
                _gameTypesConfig = JsonSerializer.Deserialize<Dictionary<string, object>>(json);
            }

            var difficultyPath = Path.Combine(AppContext.BaseDirectory, "Resources", "Configs", "difficulty_config.json");
            if (File.Exists(difficultyPath))
            {
                var json = await File.ReadAllTextAsync(difficultyPath);
                _difficultyConfig = JsonSerializer.Deserialize<List<object>>(json);
            }

            _initialized = true;
        }
        catch
        {
            _initialized = true;
        }
    }

    public Dictionary<string, object>? GetGameTypeConfig(GameType gameType)
    {
        if (_gameTypesConfig is null) return null;
        var key = gameType.ToString().ToLower();
        if (_gameTypesConfig.TryGetValue(key, out var config))
        {
            return (config as JsonElement?)?.Deserialize<Dictionary<string, object>>();
        }
        return null;
    }

    public List<string> GetDifficultyLevels(GameType gameType)
    {
        if (_difficultyConfig is null) return ["beginner", "easy", "medium", "hard", "expert", "master"];

        return _difficultyConfig
            .Select(o => (o as JsonElement?)?.GetProperty("level").GetString())
            .Where(s => s != null && s != "custom")
            .Cast<string>()
            .ToList();
    }

    public Dictionary<string, object>? GetDifficultyParams(GameType gameType, string difficulty)
    {
        if (_difficultyConfig is null) return null;

        foreach (var item in _difficultyConfig)
        {
            var element = item as JsonElement?;
            if (element?.GetProperty("level").GetString() == difficulty)
            {
                var gameTypeStr = gameType.ToString().ToLower();
                var minKey = $"{gameTypeStr}minfilled";
                var maxKey = $"{gameTypeStr}maxfilled";

                var result = new Dictionary<string, object>();
                if (element.Value.TryGetProperty(minKey, out var minVal))
                    result["minFilledCells"] = minVal.GetInt32();
                if (element.Value.TryGetProperty(maxKey, out var maxVal))
                    result["maxFilledCells"] = maxVal.GetInt32();
                if (element.Value.TryGetProperty("difficultyScore", out var score))
                    result["difficultyScore"] = score.GetDouble();

                return result;
            }
        }
        return null;
    }

    public int GetMinFilledCells(GameType gameType, string difficulty)
    {
        var key = $"{gameType.ToString().ToLower()}minfilled";
        if (_difficultyConfig is null) return 30;

        foreach (var item in _difficultyConfig)
        {
            var element = item as JsonElement?;
            if (element?.GetProperty("level").GetString() == difficulty)
            {
                if (element.Value.TryGetProperty(key, out var val))
                    return val.GetInt32();
            }
        }
        return 30;
    }

    public int GetMaxFilledCells(GameType gameType, string difficulty)
    {
        var key = $"{gameType.ToString().ToLower()}maxfilled";
        if (_difficultyConfig is null) return 45;

        foreach (var item in _difficultyConfig)
        {
            var element = item as JsonElement?;
            if (element?.GetProperty("level").GetString() == difficulty)
            {
                if (element.Value.TryGetProperty(key, out var val))
                    return val.GetInt32();
            }
        }
        return 45;
    }

    public bool SupportsRule(GameType gameType, string rule)
    {
        var config = GetGameTypeConfig(gameType);
        if (config is null) return false;

        if (config.TryGetValue("supportedRegionTypes", out var regions))
        {
            var regionList = regions as List<object>;
            return regionList?.Any(r => r?.ToString()?.ToLower() == rule.ToLower()) ?? false;
        }
        return false;
    }

    public int GetBoardSize(GameType gameType)
    {
        var config = GetGameTypeConfig(gameType);
        if (config is null) return 9;

        if (config.TryGetValue("boardSize", out var size))
        {
            return ((JsonElement)size).GetInt32();
        }
        return 9;
    }

    public bool ShowCustomGame(GameType gameType)
    {
        var config = GetGameTypeConfig(gameType);
        if (config is null) return false;

        if (config.TryGetValue("showCustomGame", out var show))
        {
            return ((JsonElement)show).GetBoolean();
        }
        return false;
    }
}
