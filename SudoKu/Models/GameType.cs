namespace SudoKu.Models;

using System.ComponentModel;
using global::SudoKu.Resources;
using Microsoft.Maui.Graphics;

/// <summary>
/// 游戏类型枚举，定义支持的数独变体类型。
/// </summary>
public enum GameType
{
    /// <summary>标准9x9数独。</summary>
    Standard,

    /// <summary>锯齿数独（不规则宫格）。</summary>
    Jigsaw,

    /// <summary>对角线数独。</summary>
    Diagonal,

    /// <summary>窗口数独（Windoku）。</summary>
    Window,

    /// <summary>杀手数独。</summary>
    Killer,

    /// <summary>武士数独（五联数独）。</summary>
    Samurai,

    /// <summary>自定义数独。</summary>
    Custom
}

/// <summary>
/// 游戏类型配置类，包含每种游戏类型的元数据和规则定义。
/// </summary>
public class GameTypeConfig
{
    /// <summary>获取游戏类型。</summary>
    public GameType Type { get; init; }

    /// <summary>获取显示名称的资源键。</summary>
    public string NameKey { get; init; } = string.Empty;

    /// <summary>获取棋盘尺寸。</summary>
    public int BoardSize { get; init; } = 9;

    /// <summary>获取支持的区域类型列表。</summary>
    public List<RegionType> SupportedRegionTypes { get; init; } = [];

    /// <summary>获取是否支持自定义规则。</summary>
    public bool SupportsCustomRules { get; init; }

    /// <summary>获取是否支持难度选择。</summary>
    public bool SupportsDifficulty { get; init; } = true;

    /// <summary>获取图标路径。</summary>
    public string IconPath { get; init; } = string.Empty;

    /// <summary>获取描述信息的资源键。</summary>
    public string DescriptionKey { get; init; } = string.Empty;

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
}

/// <summary>
/// 游戏类型配置工厂，提供游戏类型配置的注册和查询功能。
/// </summary>
public static class GameTypeConfigFactory
{
    private static readonly Dictionary<GameType, GameTypeConfig> _configs = [];

    /// <summary>
    /// 静态构造函数，注册所有预定义的游戏类型配置。
    /// </summary>
    static GameTypeConfigFactory()
    {
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
            RegionColorsLight =
            [
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            ],
            RegionColorsDark =
            [
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            ]
        };

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
            RegionColorsLight =
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
            ],
            RegionColorsDark =
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
            ]
        };

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
            RegionColorsLight =
            [
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            ],
            RegionColorsDark =
            [
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            ]   
        };

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
            RegionColorsLight =
            [
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            ],
            RegionColorsDark =
            [
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            ]
        };

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
            RegionColorsLight =
            [
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            ],
            RegionColorsDark =
            [
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            ]
        };

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
            RegionColorsLight =
            [
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            ],
            RegionColorsDark =
            [
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            ]
        };

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
            RegionColorsLight =
            [
                Color.FromArgb("#FFFFFF"),
                Color.FromArgb("#F5F5F5"),
            ],
            RegionColorsDark =
            [
                Color.FromArgb("#2D2D2D"),
                Color.FromArgb("#383838"),
            ]
        };
    }

    /// <summary>
    /// 获取指定游戏类型的配置。
    /// </summary>
    /// <param name="type">游戏类型。</param>
    /// <returns>对应的游戏类型配置。</returns>
    /// <exception cref="ArgumentException">当游戏类型未注册时抛出。</exception>
    public static GameTypeConfig GetConfig(GameType type)
    {
        return _configs.TryGetValue(type, out var config)
            ? config
            : throw new ArgumentException($"未注册的游戏类型: {type}", nameof(type));
    }

    /// <summary>
    /// 获取所有已注册的游戏类型配置。
    /// </summary>
    /// <returns>所有游戏类型配置的只读列表。</returns>
    public static IReadOnlyList<GameTypeConfig> GetAllConfigs()
    {
        return _configs.Values.ToList().AsReadOnly();
    }

    /// <summary>
    /// 获取指定游戏类型的显示名称。
    /// </summary>
    /// <param name="type">游戏类型。</param>
    /// <returns>游戏类型的显示名称键。</returns>
    public static string GetDisplayName(GameType type)
    {
        return GetConfig(type).NameKey;
    }
}

/// <summary>
/// 游戏类型显示模型，用于 UI 层展示游戏类型信息。
/// 实现 INotifyPropertyChanged 以支持数据绑定。
/// </summary>
/// <remarks>
/// 初始化游戏类型显示模型的新实例。
/// </remarks>
/// <param name="type">游戏类型。</param>
/// <param name="displayName">显示名称。</param>
/// <param name="description">描述信息。</param>
/// <param name="iconPath">图标路径。</param>
/// <param name="themeColor">主题颜色。</param>
public partial class GameTypeDisplay(
    GameType type,
    string displayName,
    string description,
    string iconPath,
    Color themeColor) : INotifyPropertyChanged
{
    private string _displayName = displayName;
    private string _description = description;
    private string _iconPath = iconPath;
    private Color _themeColor = themeColor;
    private bool _isSelected;

    /// <summary>获取游戏类型。</summary>
    public GameType Type { get; } = type;

    /// <summary>获取游戏类型（用于 XAML 绑定）。</summary>
    public GameType GameType => Type;

    /// <summary>获取或设置显示名称。</summary>
    public string DisplayName
    {
        get => _displayName;
        set { _displayName = value; OnPropertyChanged(); }
    }

    /// <summary>获取或设置描述信息。</summary>
    public string Description
    {
        get => _description;
        set { _description = value; OnPropertyChanged(); }
    }

    /// <summary>获取或设置图标路径。</summary>
    public string IconPath
    {
        get => _iconPath;
        set { _iconPath = value; OnPropertyChanged(); }
    }

    /// <summary>获取或设置主题颜色。</summary>
    public Color ThemeColor
    {
        get => _themeColor;
        set { _themeColor = value; OnPropertyChanged(); }
    }

    /// <summary>获取或设置是否被选中。</summary>
    public bool IsSelected
    {
        get => _isSelected;
        set { _isSelected = value; OnPropertyChanged(); }
    }

    /// <summary>
    /// 刷新显示信息（从配置重新加载）。
    /// </summary>
    public void Refresh()
    {
        var config = GameTypeConfigFactory.GetConfig(Type);
        DisplayName = config.LocalizedName;
        Description = AppResources.ResourceManager.GetString(config.DescriptionKey) ?? config.DescriptionKey;
        IconPath = config.IconPath;
    }

    /// <summary>属性更改事件。</summary>
    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
