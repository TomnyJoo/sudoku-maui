namespace SudoKu.Converters;

using System.Globalization;

/// <summary>
/// Tab背景色转换器 - 根据选中状态返回对应颜色
/// 用于设置页面的Tab切换器背景色
/// </summary>
public class TabBackgroundConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue && parameter is string paramStr && int.TryParse(paramStr, out int paramValue))
        {
            // 选中时返回蓝色，未选中时返回透明
            return intValue == paramValue 
                ? Color.FromArgb("#2563EB") 
                : Colors.Transparent;
        }
        return Colors.Transparent;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// Tab文字颜色转换器 - 根据选中状态返回对应颜色
/// 用于设置页面的Tab切换器文字颜色
/// </summary>
public class TabTextColorConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue && parameter is string paramStr && int.TryParse(paramStr, out int paramValue))
        {
            // 选中时返回白色
            if (intValue == paramValue)
                return Colors.White;
        }
        
        // 未选中时根据主题返回对应颜色
        return Application.Current?.RequestedTheme == AppTheme.Dark 
            ? Colors.White 
            : Color.FromArgb("#1E1B4B");
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// 分段按钮背景色转换器 - 根据选中状态返回对应颜色
/// 用于设置页面的语言/主题分段按钮背景色
/// </summary>
public class SegmentBackgroundConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue && parameter is string paramStr && int.TryParse(paramStr, out int paramValue))
        {
            // 选中时返回蓝色，未选中时根据主题返回对应颜色
            if (intValue == paramValue)
                return Color.FromArgb("#2563EB");
        }
        
        // 未选中时根据主题返回对应颜色
        return Application.Current?.RequestedTheme == AppTheme.Dark 
            ? Color.FromArgb("#374151") 
            : Color.FromArgb("#F3F4F6");
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// 分段按钮文字颜色转换器 - 根据选中状态返回对应颜色
/// 用于设置页面的语言/主题分段按钮文字颜色
/// </summary>
public class SegmentTextColorConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue && parameter is string paramStr && int.TryParse(paramStr, out int paramValue))
        {
            // 选中时返回白色
            if (intValue == paramValue)
                return Colors.White;
        }
        
        // 未选中时根据主题返回对应颜色
        return Application.Current?.RequestedTheme == AppTheme.Dark 
            ? Color.FromArgb("#D1D5DB") 
            : Color.FromArgb("#374151");
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
