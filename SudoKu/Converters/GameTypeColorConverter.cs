namespace SudoKu.Converters;

using System.Globalization;
using SudoKu.Models;

/// <summary>
/// Converts GameType to various visual properties based on theme colors.
/// </summary>
public class GameTypeColorConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is not GameType gameType)
        {
            return parameter?.ToString() switch
            {
                _ => Colors.Gray
            };
        }

        var colorKey = $"{gameType}SudokuColor";
        var color = Colors.Gray;

        try
        {
            if (Application.Current?.Resources.TryGetValue(colorKey, out var resourceColor) == true)
            {
                color = resourceColor as Color ?? Colors.Gray;
            }
        }
        catch
        {
            color = Colors.Gray;
        }

        return parameter?.ToString() switch
        {
            "StrokeColor" => color,
            "BackgroundColor" => color,
            "TextColor" => Colors.White,
            _ => color
        };
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
