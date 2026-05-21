using System.Buffers;
using System.Text.Json;
using SudoKu.Helpers;

namespace SudoKu.Services.Generation;

public class TemplateManager
{
    private static List<int[][]>? _rrn17TemplatesParsed;
    private static List<List<List<int>>>? _regionTemplates;
    private static readonly Lock _lock = new();
    private const int MaxRrn17Templates = 50; // 限制加载数量

    public static async Task PreloadAsync()
    {
        await Task.Run(() =>
        {
            LoadRrn17Templates();
            LoadRegionTemplates();
        });
    }

    public List<List<int?>>? GetRrn17Template(Random random)
    {
        var templates = LoadRrn17Templates();
        if (templates == null || templates.Count == 0) return null;

        var template = templates[random.Next(templates.Count)];
        var mapping = GenerateRandomPermutation(9, random);

        var data = TemplateObjectPool.GetTemplate();
        try
        {
            for (int r = 0; r < StandardConstants.BoardSize; r++)
                for (int c = 0; c < StandardConstants.BoardSize; c++)
                    data[r][c] = template[r][c] >= 1 && template[r][c] <= 9 ? mapping[template[r][c] - 1] : null;

            var result = new List<List<int?>>(StandardConstants.BoardSize);
            for (int r = 0; r < StandardConstants.BoardSize; r++)
                result.Add([.. data[r]]);
            return result;
        }
        finally { TemplateObjectPool.ReturnTemplate(data); }
    }

    public List<List<int>>? GetRegionTemplate(Random random)
    {
        var templates = LoadRegionTemplates();
        if (templates == null || templates.Count == 0)
            return null;

        return templates[random.Next(templates.Count)];
    }

    public static int RegionTemplateCount => _regionTemplates?.Count ?? 0;

    public static int Rrn17TemplateCount => _rrn17TemplatesParsed?.Count ?? 0;

    private static List<int[][]>? LoadRrn17Templates()
    {
        if (_rrn17TemplatesParsed != null) return _rrn17TemplatesParsed;

        lock (_lock)
        {
            if (_rrn17TemplatesParsed != null) return _rrn17TemplatesParsed;

            try
            {
                var assembly = typeof(TemplateManager).Assembly;
                var resourceName = FindResourceName("rrn17_solutions.json");
                if (resourceName == null)
                {
                    System.Diagnostics.Debug.WriteLine("未找到 rrn17_solutions.json 资源");
                    return null;
                }

                using var stream = assembly.GetManifestResourceStream(resourceName);
                if (stream == null) return null;

                using var doc = JsonDocument.Parse(stream);
                if (!doc.RootElement.TryGetProperty("solutions", out var solutions)) return null;

                // 读取所有模板字符串
                var allTemplateStrings = new List<string>();
                foreach (var solution in solutions.EnumerateArray())
                {
                    var templateStr = solution.GetString();
                    if (!string.IsNullOrEmpty(templateStr))
                        allTemplateStrings.Add(templateStr);
                }

                if (allTemplateStrings.Count == 0) return null;

                var random = new Random();
                int takeCount = Math.Min(MaxRrn17Templates, allTemplateStrings.Count);
                var selectedIndices = Enumerable.Range(0, allTemplateStrings.Count)
                                                .OrderBy(_ => random.Next())
                                                .Take(takeCount)
                                                .ToList();

                var parsedTemplates = new List<int[][]>();
                for (int i = 0; i < selectedIndices.Count; i++)
                {
                    var templateStr = allTemplateStrings[selectedIndices[i]];
                    var mapping = GenerateRandomPermutation(StandardConstants.BoardSize, random);

                    var template = new int[StandardConstants.BoardSize][];
                    for (int r = 0; r < StandardConstants.BoardSize; r++)
                    {
                        template[r] = new int[StandardConstants.BoardSize];
                        for (int c = 0; c < StandardConstants.BoardSize; c++)
                        {
                            int originalValue = templateStr[r * StandardConstants.BoardSize + c] - '0';
                            template[r][c] = (originalValue >= 1 && originalValue <= 9) ? mapping[originalValue - 1] : 0;
                        }
                    }
                    parsedTemplates.Add(template);
                }

                _rrn17TemplatesParsed = parsedTemplates;
                System.Diagnostics.Debug.WriteLine($"已随机加载 {_rrn17TemplatesParsed.Count} rrn17 模板 (从 {allTemplateStrings.Count} 个中随机选择并映射)");
                return _rrn17TemplatesParsed;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"加载rrn17模板失败: {ex.Message}");
                return null;
            }
        }
    }

    private static int[] GenerateRandomPermutation(int n, Random random)
    {
        var result = Enumerable.Range(1, n).ToArray();
        
        for (int i = n - 1; i > 0; i--)
        {
            int j = random.Next(i + 1);
            (result[i], result[j]) = (result[j], result[i]);
        }
        
        return result;
    }

    private static List<List<List<int>>>? LoadRegionTemplates()
    {
        if (_regionTemplates != null) return _regionTemplates;

        lock (_lock)
        {
            if (_regionTemplates != null) return _regionTemplates;

            try
            {
                var assembly = typeof(TemplateManager).Assembly;
                var resourceName = FindResourceName("regions.json");
                if (resourceName == null)
                {
                    System.Diagnostics.Debug.WriteLine("未找到 regions.json 资源");
                    return null;
                }

                using var stream = assembly.GetManifestResourceStream(resourceName);
                if (stream == null) return null;

                using var doc = JsonDocument.Parse(stream);
                if (!doc.RootElement.TryGetProperty("templates", out var templates)) return null;

                _regionTemplates = new List<List<List<int>>>();
                foreach (var template in templates.EnumerateArray())
                {
                    if (template.TryGetProperty("regionMatrix", out var regionMatrix))
                    {
                        var matrix = new List<List<int>>(StandardConstants.BoardSize);
                        foreach (var row in regionMatrix.EnumerateArray())
                        {
                            var rowList = new List<int>(StandardConstants.BoardSize);
                            foreach (var val in row.EnumerateArray())
                                rowList.Add(val.GetInt32());
                            matrix.Add(rowList);
                        }
                        _regionTemplates.Add(matrix);
                    }
                }

                System.Diagnostics.Debug.WriteLine($"已加载 {_regionTemplates.Count} 个区域模板");
                return _regionTemplates;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"加载区域模板失败: {ex.Message}");
                return null;
            }
        }
    }

    private static string? FindResourceName(string fileNamePattern)
    {
        var assembly = typeof(TemplateManager).Assembly;
        return assembly.GetManifestResourceNames()
                       .FirstOrDefault(name => name.EndsWith(fileNamePattern, StringComparison.OrdinalIgnoreCase));
    }

    public static void ClearCache()
    {
        lock (_lock)
        {
            _rrn17TemplatesParsed = null;
            _regionTemplates = null;
        }
    }
}