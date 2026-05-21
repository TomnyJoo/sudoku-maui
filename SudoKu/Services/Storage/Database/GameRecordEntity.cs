using SQLite;

namespace SudoKu.Services.Storage.Database;

/// <summary>
/// 游戏记录实体类，对应数据库中的 GameRecord 表。
/// 存储已完成或进行中的游戏统计数据。
/// </summary>
[Table("GameRecord")]
public class GameRecordEntity
{
    /// <summary>获取或设置记录主键。</summary>
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }

    /// <summary>获取或设置游戏类型字符串（枚举序列化）。</summary>
    [Indexed]
    public string GameTypeStr { get; set; } = string.Empty;

    /// <summary>获取或设置难度等级字符串（枚举序列化）。</summary>
    [Indexed]
    public string DifficultyStr { get; set; } = string.Empty;

    /// <summary>获取或设置完成时间（秒）。</summary>
    public int Time { get; set; }

    /// <summary>获取或设置错误次数。</summary>
    public int Mistakes { get; set; }

    /// <summary>获取或设置使用的提示次数。</summary>
    public int HintsUsed { get; set; }

    /// <summary>获取或设置游戏是否已完成。</summary>
    public bool IsCompleted { get; set; }

    /// <summary>获取或设置完成时间戳。</summary>
    [Indexed]
    public DateTime CompletedAt { get; set; } = DateTime.Now;

    /// <summary>获取或设置总游戏时间（秒）。</summary>
    public int ElapsedTime { get; set; }

    /// <summary>获取或设置准确率（0.0到1.0）。</summary>
    public double Accuracy { get; set; }
}
