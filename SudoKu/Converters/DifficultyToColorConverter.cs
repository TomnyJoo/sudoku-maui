namespace SudoKu.Converters;

using System.Globalization;
using SudoKu.Models;

/// <summary>
/// 难度到颜色转换器，将难度等级转换为对应的主题颜色。
/// </summary>
public class DifficultyToColorConverter : IValueConverter
{
    /// <summary>
    /// 将难度等级转换为对应的颜色。
    /// </summary>
    /// <param name="value">难度等级枚举值。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>对应的颜色值。</returns>
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is Difficulty difficulty)
        {
            return difficulty switch
            {
                Difficulty.Beginner => Colors.Green,
                Difficulty.Easy => Colors.LightGreen,
                Difficulty.Medium => Colors.Orange,
                Difficulty.Hard => Colors.OrangeRed,
                Difficulty.Expert => Colors.Red,
                Difficulty.Master => Colors.DarkRed,
                Difficulty.Custom => Colors.Purple,
                _ => Colors.Gray
            };
        }
        return Colors.Gray;
    }

    /// <summary>
    /// 将颜色转换回难度等级（未实现）。
    /// </summary>
    /// <param name="value">颜色值。</param>
    /// <param name="targetType">目标类型。</param>
    /// <param name="parameter">可选参数。</param>
    /// <param name="culture">区域信息。</param>
    /// <returns>转换后的难度等级。</returns>
    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
