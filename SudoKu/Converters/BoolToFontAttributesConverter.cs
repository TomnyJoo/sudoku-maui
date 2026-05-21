namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// Converts boolean to FontAttributes.
/// </summary>
public class BoolToFontAttributesConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is not bool boolValue)
        {
            return FontAttributes.None;
        }

        if (parameter is string strParam)
        {
            var parts = strParam.Split(',');
            if (parts.Length == 2)
            {
                var trueAttr = parts[0].Equals("Bold", StringComparison.OrdinalIgnoreCase) ? FontAttributes.Bold : FontAttributes.None;
                var falseAttr = parts[1].Equals("Bold", StringComparison.OrdinalIgnoreCase) ? FontAttributes.Bold : FontAttributes.None;
                return boolValue ? trueAttr : falseAttr;
            }
        }

        return boolValue ? FontAttributes.Bold : FontAttributes.None;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
