namespace SudoKu.Models;

/// <summary>
/// 最佳成绩记录类，存储特定游戏类型和难度下的最佳成绩。
/// </summary>
/// <param name="time">完成时间（秒）。</param>
/// <param name="mistakes">错误次数。</param>
/// <param name="timestamp">记录时间。</param>
public class BestScore(int time, int mistakes, DateTime? timestamp = null)
{
    /// <summary>获取完成时间（秒）。</summary>
    public int Time { get; init; } = time;

    /// <summary>获取错误次数。</summary>
    public int Mistakes { get; init; } = mistakes;

    /// <summary>获取记录时间。</summary>
    public DateTime Timestamp { get; init; } = timestamp ?? DateTime.Now;

    /// <summary>
    /// 创建当前最佳成绩的副本，可选择性地覆盖任意属性。
    /// </summary>
    /// <param name="time">新的完成时间。</param>
    /// <param name="mistakes">新的错误次数。</param>
    /// <param name="timestamp">新的记录时间。</param>
    /// <returns>包含指定属性更改的新最佳成绩实例。</returns>
    public BestScore CopyWith(int? time = null, int? mistakes = null, DateTime? timestamp = null)
    {
        return new BestScore(
            time ?? Time,
            mistakes ?? Mistakes,
            timestamp ?? Timestamp);
    }
}
