using SQLite;

namespace SudoKu.Services.Storage.Database;

/// <summary>
/// 自定义游戏实体类，对应数据库中的 CustomGame 表。
/// 存储用户创建或导入的自定义数独谜题。
/// </summary>
[Table("CustomGame")]
public class CustomGameEntity
{
    /// <summary>获取或设置记录主键。</summary>
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    /// <summary>获取或设置游戏类型字符串（枚举序列化）。</summary>
    [Indexed]
    public string GameTypeStr { get; set; } = string.Empty;

    /// <summary>获取或设置谜题棋盘的JSON序列化字符串。</summary>
    public string PuzzleJson { get; set; } = string.Empty;

    /// <summary>获取或设置解答棋盘的JSON序列化字符串。</summary>
    public string SolutionJson { get; set; } = string.Empty;

    /// <summary>获取或设置创建时间。</summary>
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    /// <summary>获取或设置自定义游戏名称。</summary>
    public string? Name { get; set; }
}
