namespace SudoKu.Helpers;

public static class TemplateObjectPool
{
    private static List<List<int?>>? _cachedTemplate;

    public static List<List<int?>> GetTemplate()
    {
        if (_cachedTemplate == null)
        {
            _cachedTemplate = new List<List<int?>>(StandardConstants.BoardSize);
            for (int r = 0; r < StandardConstants.BoardSize; r++)
                _cachedTemplate.Add(new List<int?>(new int?[StandardConstants.BoardSize]));
        }
        return _cachedTemplate;
    }

    public static void ReturnTemplate(List<List<int?>> template)
    {
        for (int r = 0; r < StandardConstants.BoardSize; r++)
            for (int c = 0; c < StandardConstants.BoardSize; c++)
                template[r][c] = null;
    }
}