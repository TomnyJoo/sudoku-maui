using System.Text.Json;
using System.Text.Json.Serialization;
using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Serialization;

/// <summary>
/// 棋盘类型的JSON转换器，处理Board抽象类的序列化和反序列化。
/// </summary>
public class BoardJsonConverter : JsonConverter<Board>
{
    /// <inheritdoc/>
    public override bool CanConvert(Type typeToConvert)
    {
        return typeof(Board).IsAssignableFrom(typeToConvert);
    }

    /// <inheritdoc/>
    public override Board? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        // 解析JSON为DOM
        using var jsonDocument = JsonDocument.ParseValue(ref reader);
        var root = jsonDocument.RootElement;

        // 读取必要的属性
        if (!root.TryGetProperty("Size", out var sizeElement) ||
            !root.TryGetProperty("Cells", out var cellsElement) ||
            !root.TryGetProperty("Regions", out var regionsElement) ||
            !root.TryGetProperty("GameType", out var gameTypeElement))
        {
            return null;
        }

        int size = sizeElement.GetInt32();
        string gameTypeStr = gameTypeElement.GetString() ?? GameType.Standard.ToString();
        GameType gameType;
        if (!Enum.TryParse<GameType>(gameTypeStr, out gameType))
        {
            gameType = GameType.Standard;
        }

        // 反序列化单元格 - 使用SudokuCell避免歧义
        var cells = JsonSerializer.Deserialize<List<List<SudokuCell>>>(cellsElement.GetRawText(), options);
        if (cells == null)
        {
            return null;
        }
        // 转换为 IReadOnlyList<IReadOnlyList<SudokuCell>>
        var cellsReadOnly = cells.Select(r => r.Cast<SudokuCell>().ToList().AsReadOnly()).ToList().AsReadOnly();

        // 反序列化区域 - 使用SudokuRegion避免歧义
        var regions = JsonSerializer.Deserialize<List<SudokuRegion>>(regionsElement.GetRawText(), options);
        if (regions == null)
        {
            return null;
        }
        var regionsReadOnly = regions.Cast<SudokuRegion>().ToList();

        // 根据游戏类型创建相应的棋盘实例
        return gameType switch
        {
            GameType.Standard => new StandardBoard(size, cellsReadOnly, regionsReadOnly),
            GameType.Diagonal => new DiagonalBoard(size, cellsReadOnly, regionsReadOnly),
            GameType.Window => new WindowBoard(size, cellsReadOnly, regionsReadOnly),
            GameType.Jigsaw => new JigsawBoard(size, cellsReadOnly, regionsReadOnly),
            GameType.Killer => new KillerBoard(size, cellsReadOnly, regionsReadOnly, new List<KillerCage>()),
            GameType.Samurai => new SamuraiBoard(cellsReadOnly, regionsReadOnly),
            _ => new StandardBoard(size, cellsReadOnly, regionsReadOnly)
        };
    }

    /// <inheritdoc/>
    public override void Write(Utf8JsonWriter writer, Board value, JsonSerializerOptions options)
    {
        // 序列化Board的所有属性
        writer.WriteStartObject();
        writer.WriteNumber("Size", value.Size);
        writer.WritePropertyName("Cells");
        JsonSerializer.Serialize(writer, value.Cells, options);
        writer.WritePropertyName("Regions");
        JsonSerializer.Serialize(writer, value.Regions, options);
        writer.WriteString("GameType", value.GameType.ToString());
        writer.WriteEndObject();
    }
}