namespace SudoKu.Services;

public static class QueryParameterExtensions
{
    public static bool TryGetValue<T>(this IDictionary<string, object> parameters, string key, out T? value)
    {
        value = default;
        if (!parameters.TryGetValue(key, out var obj)) return false;

        try
        {
            value = (T?)obj;
            return true;
        }
        catch
        {
            Helpers.AppLogger.Warning($"无法将参数 {key} 转换为类型 {typeof(T).Name}");
            return false;
        }
    }

    public static T GetRequiredValue<T>(this IDictionary<string, object> parameters, string key)
    {
        if (!parameters.TryGetValue(key, out var obj))
        {
            throw new ArgumentException($"缺少必需的路由参数: {key}");
        }

        try
        {
            return (T)obj;
        }
        catch (Exception ex)
        {
            Helpers.AppLogger.Error($"路由参数 {key} 类型转换失败", ex);
            throw new ArgumentException($"路由参数 {key} 类型不匹配", ex);
        }
    }

    public static bool ValidateGamePageParameters(this IDictionary<string, object> parameters)
    {
        if (!parameters.ContainsKey("GameType"))
        {
            Helpers.AppLogger.Warning("缺少 GameType 参数");
            return false;
        }
        if (!parameters.ContainsKey("Difficulty"))
        {
            Helpers.AppLogger.Warning("缺少 Difficulty 参数");
            return false;
        }
        return true;
    }
}
