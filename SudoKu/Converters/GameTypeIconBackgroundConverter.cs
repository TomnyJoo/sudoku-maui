namespace SudoKu.Converters;

using System.Globalization;
using SudoKu.Models;

/// <summary>
/// 游戏类型图标背景色转换器，将 GameType 或 Color 转换为对应的背景颜色。
/// </summary>
public class GameTypeIconBackgroundConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is GameType gameType)
        {
            return gameType switch
            {
                GameType.Standard => Microsoft.Maui.Graphics.Color.FromArgb("#E8EAF6"),
                GameType.Jigsaw => Microsoft.Maui.Graphics.Color.FromArgb("#FFF3E0"),
                GameType.Diagonal => Microsoft.Maui.Graphics.Color.FromArgb("#E0F7FA"),
                GameType.Killer => Microsoft.Maui.Graphics.Color.FromArgb("#FFEBEE"),
                GameType.Window => Microsoft.Maui.Graphics.Color.FromArgb("#E8F5E9"),
                GameType.Samurai => Microsoft.Maui.Graphics.Color.FromArgb("#F3E5F5"),
                _ => Microsoft.Maui.Graphics.Color.FromArgb("#F5F5F5")
            };
        }
        
        // 如果传入的是 Color，返回一个半透明的版本作为背景
        if (value is Microsoft.Maui.Graphics.Color color)
        {
            // 返回 20% 透明度的颜色作为背景
            return Microsoft.Maui.Graphics.Color.FromRgba(color.Red, color.Green, color.Blue, 0.2);
        }
        
        return Microsoft.Maui.Graphics.Color.FromArgb("#F5F5F5");
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
