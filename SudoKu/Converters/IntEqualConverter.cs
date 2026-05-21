namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// 整数到布尔值转换器，将 int 值与参数比较后返回 bool。
/// 用于 Tab 切换器中根据 SelectedTabIndex 控制内容可见性。
/// </summary>
public class IntEqualConverter : IValueConverter
{
    /// <summary>
    /// 将整数与参数比较，相等返回 true，否则返回 false。
    /// </summary>
    /// <param name="value">当前选中的索引值。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">期望匹配的索引值（字符串形式的整数）。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>如果 value 等于参数则为 true。</returns>
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue && parameter is string paramStr && int.TryParse(paramStr, out int paramValue))
        {
            return intValue == paramValue;
        }
        return false;
    }

    /// <summary>
    /// 反向转换（未实现）。
    /// </summary>
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
