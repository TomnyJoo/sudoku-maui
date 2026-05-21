using System.Collections.Immutable;

namespace SudoKu.Models;

/// <summary>
/// 数独单元格具体类（表示数独棋盘中的单个单元格，包含位置、值、状态等信息）
/// </summary>
public sealed record SudokuCell
{
    /// <summary>
    /// 构造单元格模型
    /// </summary>
    public SudokuCell(
        int row,
        int col,
        int? value = null,
        bool isFixed = false,
        bool isError = false,
        ImmutableHashSet<int>? candidates = null,
        bool isSelected = false,
        bool isHighlighted = false,
        int? colorIndex = null)
    {
        Row = row;
        Col = col;
        Value = value;
        IsFixed = isFixed;
        IsError = isError;
        Candidates = candidates ?? ImmutableHashSet<int>.Empty;
        IsSelected = isSelected;
        IsHighlighted = isHighlighted;
        ColorIndex = colorIndex;
    }

    /// <summary>
    /// 从JSON创建单元格实例
    /// </summary>
    public static SudokuCell FromJson(Dictionary<string, object> json)
    {
        var candidates = json.TryGetValue("candidates", out var c) && c is List<object> list
            ? list.Cast<int>().ToImmutableHashSet()
            : null;

        return new SudokuCell(
            row: (int)json["row"],
            col: (int)json["col"],
            value: json.TryGetValue("value", out var v) ? (int?)v : null,
            isFixed: json.TryGetValue("isFixed", out var f) && f is true,
            isError: json.TryGetValue("isError", out var e) && e is true,
            candidates: candidates,
            isSelected: json.TryGetValue("isSelected", out var s) && s is true,
            isHighlighted: json.TryGetValue("isHighlighted", out var h) && h is true,
            colorIndex: json.TryGetValue("colorIndex", out var ci) && ci is int index ? index : null
        );
    }

    /// <summary>
    /// 行索引（0-based）
    /// </summary>
    public int Row { get; }

    /// <summary>
    /// 列索引（0-based）
    /// </summary>
    public int Col { get; }

    /// <summary>
    /// 当前填入的数字（null表示未填）
    /// </summary>
    public int? Value { get; }

    /// <summary>
    /// 是否固定数字（游戏开始时存在的不可修改数字）
    /// </summary>
    public bool IsFixed { get; }

    /// <summary>
    /// 是否数字冲突（违反数独规则）
    /// </summary>
    public bool IsError { get; }

    /// <summary>
    /// 候选数字集合（用于提示模式）
    /// </summary>
    public ImmutableHashSet<int> Candidates { get; }

    /// <summary>
    /// 是否被选中
    /// </summary>
    public bool IsSelected { get; }

    /// <summary>
    /// 是否高亮显示（同行/同列/同区域高亮）
    /// </summary>
    public bool IsHighlighted { get; }

    /// <summary>
    /// 单元格颜色索引（用于标记不同区域或状态）
    /// </summary>
    public int? ColorIndex { get; }

    /// <summary>
    /// 生成新单元格副本，允许覆盖指定属性，返回新的单元格实例
    /// </summary>
    public SudokuCell CopyWith(
        int? value = null,
        bool clearValue = false,
        bool? isFixed = null,
        bool? isError = null,
        ImmutableHashSet<int>? candidates = null,
        bool? isSelected = null,
        bool? isHighlighted = null,
        int? colorIndex = null)
    {
        return CreateInstance(
            row: Row,
            col: Col,
            value: clearValue ? null : (value ?? Value),
            isFixed: isFixed ?? IsFixed,
            isError: isError ?? IsError,
            candidates: candidates ?? Candidates,
            isSelected: isSelected ?? IsSelected,
            isHighlighted: isHighlighted ?? IsHighlighted,
            colorIndex: colorIndex ?? ColorIndex
        );
    }

    /// <summary>
    /// 创建单元格实例
    /// </summary>
    public static SudokuCell CreateInstance(
        int row,
        int col,
        int? value = null,
        bool isFixed = false,
        bool isError = false,
        ImmutableHashSet<int>? candidates = null,
        bool isSelected = false,
        bool isHighlighted = false,
        int? colorIndex = null)
    {
        return new SudokuCell(
            row: row,
            col: col,
            value: value,
            isFixed: isFixed,
            isError: isError,
            candidates: candidates ?? ImmutableHashSet<int>.Empty,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            colorIndex: colorIndex
        );
    }

    /// <summary>
    /// 转换为JSON格式，用于持久化存储，返回：包含单元格数据的Map
    /// </summary>
    public Dictionary<string, object?> ToJson()
    {
        return new Dictionary<string, object?>
        {
            ["row"] = Row,
            ["col"] = Col,
            ["value"] = Value,
            ["isFixed"] = IsFixed,
            ["isError"] = IsError,
            ["candidates"] = Candidates.ToList(),
            ["isSelected"] = IsSelected,
            ["isHighlighted"] = IsHighlighted,
            ["colorIndex"] = ColorIndex
        };
    }

    /// <summary>
    /// 检查单元格是否为空（未填数字）
    /// </summary>
    public bool IsEmpty => Value == null;

    /// <summary>
    /// 检查单元格是否可编辑（非固定单元格）
    /// </summary>
    public bool IsEditable => !IsFixed;

    /// <summary>
    /// 重置单元格状态（清除错误、选中、高亮状态）
    /// </summary>
    public SudokuCell ResetState() => CopyWith(
        isError: false,
        isSelected: false,
        isHighlighted: false
    );

    /// <summary>
    /// 清除单元格内容（保留固定状态）
    /// </summary>
    public SudokuCell Clear()
    {
        if (IsFixed) return this;
        return CopyWith(
            clearValue: true,
            candidates: ImmutableHashSet<int>.Empty,
            isError: false
        );
    }

    /// <summary>
    /// 添加候选数字
    /// </summary>
    public SudokuCell AddCandidate(int number)
    {
        if (number < 1)
        {
            throw new ArgumentException($"候选数字必须为正数: {number}");
        }
        return CopyWith(candidates: Candidates.Add(number));
    }

    /// <summary>
    /// 移除候选数字
    /// </summary>
    public SudokuCell RemoveCandidate(int number)
    {
        return CopyWith(candidates: Candidates.Remove(number));
    }

    /// <summary>
    /// 切换候选数字
    /// </summary>
    public SudokuCell ToggleCandidate(int number)
    {
        if (number < 1)
        {
            throw new ArgumentException($"候选数字必须为正数: {number}");
        }
        var newCandidates = Candidates.Contains(number) 
            ? Candidates.Remove(number) 
            : Candidates.Add(number);
        return CopyWith(candidates: newCandidates);
    }

    /// <summary>
    /// 清除所有候选数字
    /// </summary>
    public SudokuCell ClearCandidates() => CopyWith(candidates: ImmutableHashSet<int>.Empty);

    /// <summary>
    /// 设置单元格值，并清除候选数字
    /// </summary>
    public SudokuCell SetValue(int? newValue)
    {
        if (newValue != null && newValue < 1)
        {
            throw new ArgumentException($"数字值必须为正数: {newValue}");
        }
        return CreateInstance(
            row: Row,
            col: Col,
            value: newValue,
            isFixed: IsFixed,
            candidates: [],
            isSelected: IsSelected,
            isHighlighted: IsHighlighted,
            colorIndex: ColorIndex
        );
    }

    /// <summary>
    /// 检查单元格是否包含指定候选数字
    /// </summary>
    public bool HasCandidate(int number) => Candidates.Contains(number);

    /// <summary>
    /// 获取显示值（用于UI显示）
    /// </summary>
    public string DisplayValue => Value?.ToString() ?? "";

    /// <summary>
    /// 获取候选数字的字符串表示（用于UI显示）
    /// </summary>
    public string GetCandidatesDisplay(string separator = ", ")
    {
        if (Candidates.Count == 0) return "";
        var sortedCandidates = Candidates.OrderBy(x => x).ToList();
        return string.Join(separator, sortedCandidates);
    }

    /// <summary>
    /// 获取用于调试的字符串表示（不依赖国际化），返回调试用的字符串表示
    /// </summary>
    public string ToDebugString() =>
        $"SudokuCell(row: {Row}, col: {Col}, value: {Value}, isFixed: {IsFixed}, " +
        $"isError: {IsError}, isSelected: {IsSelected}, isHighlighted: {IsHighlighted}, colorIndex: {ColorIndex})";

    public override string ToString() => ToDebugString();
}
