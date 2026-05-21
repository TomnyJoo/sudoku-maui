namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// 页面指示器转换器，根据当前页索引和参数判断是否为当前页。
/// 用于 CarouselView 的页面指示点颜色切换。
/// </summary>
public class PageIndicatorConverter : IValueConverter
{
    /// <summary>
    /// 将当前页索引转换为对应颜色。
    /// </summary>
    /// <param name="value">当前页索引（int）。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">目标页索引（int）。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>当前页返回主题色，非当前页返回灰色。</returns>
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int currentIndex && parameter is not null)
        {
            var targetIndex = System.Convert.ToInt32(parameter);
            return currentIndex == targetIndex
                ? Microsoft.Maui.Graphics.Color.FromArgb("#6366F1")
                : Microsoft.Maui.Graphics.Color.FromArgb("#C7D2FE");
        }
        return Microsoft.Maui.Graphics.Color.FromArgb("#C7D2FE");
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
