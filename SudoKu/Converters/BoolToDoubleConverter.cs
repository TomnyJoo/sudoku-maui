namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// Converts boolean to double value.
/// </summary>
public class BoolToDoubleConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is not bool boolValue)
        {
            return 1.0;
        }

        if (parameter is string strParam)
        {
            var parts = strParam.Split(',');
            if (parts.Length == 2 && double.TryParse(parts[0], out var trueValue) && double.TryParse(parts[1], out var falseValue))
            {
                return boolValue ? trueValue : falseValue;
            }
        }

        return boolValue ? 2.0 : 1.0;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
