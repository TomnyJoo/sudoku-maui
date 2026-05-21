namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// 时间格式转换器，将秒数转换为可读的时间格式字符串。
/// </summary>
public class TimeFormatConverter : IValueConverter
{
    /// <summary>
    /// 将秒数转换为格式化的时间字符串。
    /// </summary>
    /// <param name="value">秒数（int 类型）。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数，"short" 表示简短格式。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>格式化的时间字符串（如 "05:30" 或 "1:05:30"）。</returns>
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int totalSeconds)
        {
            return FormatTime(totalSeconds);
        }

        if (value is double doubleSeconds)
        {
            return FormatTime((int)doubleSeconds);
        }

        return "00:00";
    }

    /// <summary>
    /// 将时间字符串转换回秒数（未实现）。
    /// </summary>
    /// <param name="value">时间字符串。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>转换后的秒数。</returns>
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }

    /// <summary>
    /// 将秒数格式化为时间字符串。
    /// </summary>
    /// <param name="totalSeconds">总秒数。</param>
    /// <returns>格式化的时间字符串。</returns>
    private static string FormatTime(int totalSeconds)
    {
        if (totalSeconds < 0)
            totalSeconds = 0;

        int hours = totalSeconds / 3600;
        int minutes = (totalSeconds % 3600) / 60;
        int seconds = totalSeconds % 60;

        if (hours > 0)
        {
            return $"{hours}:{minutes:D2}:{seconds:D2}";
        }

        return $"{minutes:D2}:{seconds:D2}";
    }
}
