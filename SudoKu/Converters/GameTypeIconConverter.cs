namespace SudoKu.Converters;

using System.Globalization;
using SudoKu.Models;

/// <summary>
/// 游戏类型图标转换器，将 GameType 转换为图标文本。
/// </summary>
public class GameTypeIconConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is GameType gameType)
        {
            return gameType switch
            {
                GameType.Standard => "\u25A3",
                GameType.Jigsaw => "\u25C7",
                GameType.Diagonal => "\u2571",
                GameType.Window => "\u25A1",
                GameType.Killer => "\u25A0",
                GameType.Samurai => "\u2605",
                GameType.Custom => "\u270E",
                _ => "?"
            };
        }
        return "?";
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
