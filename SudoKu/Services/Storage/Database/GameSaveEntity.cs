using SQLite;
using SudoKu.Models;

namespace SudoKu.Services.Storage.Database;

/// <summary>
/// 游戏存档实体类，对应数据库中的 GameSave 表。
/// 存储游戏类型的当前进度，每个游戏类型和难度组合最多保存一个存档。
/// </summary>
[Table("GameSave")]
public class GameSaveEntity
{
    /// <summary>获取或设置记录主键。</summary>
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    /// <summary>获取或设置游戏类型字符串（枚举序列化）。</summary>
    [Column("GameType")]
    public string GameTypeStr { get; set; } = string.Empty;

    /// <summary>获取或设置难度等级字符串（枚举序列化）。</summary>
    [Indexed]
    public string DifficultyStr { get; set; } = string.Empty;

    /// <summary>获取或设置游戏状态的JSON序列化字符串。</summary>
    public string GameStateJson { get; set; } = string.Empty;

    /// <summary>获取或设置存档保存时间。</summary>
    public DateTime SavedAt { get; set; } = DateTime.Now;

    /// <summary>获取或设置最后游玩时间。</summary>
    public DateTime LastPlayedAt { get; set; } = DateTime.Now;

    /// <summary>获取解析后的游戏类型枚举值。</summary>
    [Ignore]
    public GameType GameType => Enum.Parse<GameType>(GameTypeStr);

    /// <summary>获取解析后的难度等级枚举值。</summary>
    [Ignore]
    public Difficulty Difficulty => Enum.Parse<Difficulty>(DifficultyStr);
}
