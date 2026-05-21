namespace SudoKu.Models.Commands;

using SudoKu.Models.Boards;

public interface IBoardCommand
{
    string Type { get; }
    Board Execute(Board board);
    Dictionary<string, object> ToJson();
}

public static class BoardCommandFactory
{
    public static IBoardCommand FromJson(Dictionary<string, object> json)
    {
        var type = json["type"] as string;
        return type switch
        {
            "setValue" => SetValueCommand.FromJson(json),
            "toggleCandidate" => ToggleCandidateCommand.FromJson(json),
            "clearCell" => ClearCellCommand.FromJson(json),
            "clearCandidates" => ClearCandidatesCommand.FromJson(json),
            _ => SetValueCommand.FromJson(json)
        };
    }
}

public sealed record SetValueCommand(
    int Row,
    int Col,
    int? Value,
    bool IsError = false) : IBoardCommand
{
    public string Type => "setValue";

    public Board Execute(Board board)
    {
        var newBoard = board.SetCellValue(Row, Col, Value);
        if (IsError)
        {
            newBoard = newBoard.SetCellError(Row, Col, true);
        }
        return newBoard;
    }

    public Dictionary<string, object> ToJson() => new()
    {
        ["type"] = Type,
        ["row"] = Row,
        ["col"] = Col,
        ["value"] = Value!,
        ["isError"] = IsError
    };

    public static SetValueCommand FromJson(Dictionary<string, object> json) => new(
        Row: Convert.ToInt32(json["row"]),
        Col: Convert.ToInt32(json["col"]),
        Value: json["value"] != null ? Convert.ToInt32(json["value"]) : null,
        IsError: json.TryGetValue("isError", out var e) && e is bool b && b
    );
}

public sealed record ToggleCandidateCommand(
    int Row,
    int Col,
    int Candidate) : IBoardCommand
{
    public string Type => "toggleCandidate";

    public Board Execute(Board board) => board.ToggleCellCandidate(Row, Col, Candidate);

    public Dictionary<string, object> ToJson() => new()
    {
        ["type"] = Type,
        ["row"] = Row,
        ["col"] = Col,
        ["candidate"] = Candidate
    };

    public static ToggleCandidateCommand FromJson(Dictionary<string, object> json) => new(
        Row: Convert.ToInt32(json["row"]),
        Col: Convert.ToInt32(json["col"]),
        Candidate: Convert.ToInt32(json["candidate"])
    );
}

public sealed record ClearCellCommand(
    int Row,
    int Col) : IBoardCommand
{
    public string Type => "clearCell";

    public Board Execute(Board board) => board.ClearCell(Row, Col);

    public Dictionary<string, object> ToJson() => new()
    {
        ["type"] = Type,
        ["row"] = Row,
        ["col"] = Col
    };

    public static ClearCellCommand FromJson(Dictionary<string, object> json) => new(
        Row: Convert.ToInt32(json["row"]),
        Col: Convert.ToInt32(json["col"])
    );
}

public sealed record ClearCandidatesCommand(
    int Row,
    int Col) : IBoardCommand
{
    public string Type => "clearCandidates";

    public Board Execute(Board board) => board.SetCellCandidates(Row, Col, []);

    public Dictionary<string, object> ToJson() => new()
    {
        ["type"] = Type,
        ["row"] = Row,
        ["col"] = Col
    };

    public static ClearCandidatesCommand FromJson(Dictionary<string, object> json) => new(
        Row: Convert.ToInt32(json["row"]),
        Col: Convert.ToInt32(json["col"])
    );
}
