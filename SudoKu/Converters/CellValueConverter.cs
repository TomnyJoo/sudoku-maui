namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// 单元格值转换器，将单元格的值转换为显示字符串。
/// </summary>
public class CellValueConverter : IValueConverter
{
    /// <summary>
    /// 将单元格值转换为显示字符串。
    /// </summary>
    /// <param name="value">单元格值（int? 类型）。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>值的字符串表示，null 或 0 返回空字符串。</returns>
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value switch
        {
            int intValue when intValue > 0 => intValue.ToString(),
            null => string.Empty,
            _ => string.Empty
        };
    }

    /// <summary>
    /// 将显示字符串转换回单元格值（未实现）。
    /// </summary>
    /// <param name="value">显示字符串。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>转换后的值。</returns>
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
