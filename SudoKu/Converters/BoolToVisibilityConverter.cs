namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// 布尔值到可见性转换器，将 bool 值转换为 UI 可见性状态。
/// </summary>
public class BoolToVisibilityConverter : IValueConverter
{
    /// <summary>
    /// 将布尔值转换为可见性状态。
    /// </summary>
    /// <param name="value">布尔值。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数，"invert" 表示反转逻辑。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>true 返回可见，false 返回折叠。</returns>
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool boolValue)
        {
            bool isInverted = parameter?.ToString()?.Equals("invert", StringComparison.OrdinalIgnoreCase) == true;
            bool result = isInverted ? !boolValue : boolValue;
            return result;
        }
        return false;
    }

    /// <summary>
    /// 将可见性状态转换回布尔值（未实现，返回原值）。
    /// </summary>
    /// <param name="value">可见性状态。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>转换后的布尔值。</returns>
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
