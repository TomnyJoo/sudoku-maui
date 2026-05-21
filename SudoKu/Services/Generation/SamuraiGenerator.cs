using System.Diagnostics;
using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

public class SamuraiGenerator : SudokuGenerator
{
    private readonly Random _random;
    private readonly TemplateManager _templateManager;
    private readonly StandardGenerator _standardGenerator;
    private readonly DiggingAlgorithm _diggingAlgorithm;

    public SamuraiGenerator(
        TemplateManager templateManager,
        Random? random = null,
        StandardGenerator? standardGenerator = null,
        DiggingAlgorithm? diggingAlgorithm = null)
    {
        _random = random ?? new Random();
        _templateManager = templateManager;
        _standardGenerator = standardGenerator ?? new StandardGenerator(_random);
        _diggingAlgorithm = diggingAlgorithm ?? new DiggingAlgorithm(_random);
    }

    public override GameType SupportedGameType => GameType.Samurai;

    public override async Task<GenerationResult> GenerateAsync(
        Difficulty difficulty,
        int size,
        Func<bool>? isCancelled = null,
        Dictionary<string, object>? templateData = null,
        IProgress<GenerationStage>? progress = null)
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();

        Board solution;
        Board puzzle;

        try
        {
            progress?.Report(GenerationStage.GeneratingSolution);
            solution = await GenerateSolution(isCancelled, templateData);

            progress?.Report(GenerationStage.DiggingPuzzle);
            puzzle = await GeneratePuzzle(solution, difficulty, isCancelled);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[SamuraiGenerator] 生成失败: {ex.Message}");
            throw;
        }

        stopwatch.Stop();

        var finalPuzzle = puzzle;
        var finalSolution = MarkAllAsFixed(solution);

        return new GenerationResult
        {
            Solution = finalSolution,
            Puzzle = finalPuzzle,
            GenerationTime = stopwatch.ElapsedMilliseconds
        };
    }

    private async Task<Board> GenerateSolution(Func<bool>? isCancelled, Dictionary<string, object>? templateData)
    {
        return await Task.Run(() =>
        {
            var centerBoard = GenerateCenterSubGrid(isCancelled, templateData);
            if (centerBoard == null)
                throw new InvalidOperationException("无法生成武士数独中心子盘");

            var constraints = ExtractOverlapConstraints(centerBoard);

            var subSolutions = new Board[5];
            subSolutions[4] = centerBoard;

            foreach (int i in new[] { 0, 1, 2, 3 })
            {
                if (isCancelled?.Invoke() ?? false)
                    throw new OperationCanceledException();

                subSolutions[i] = GenerateCornerSubGrid(i, constraints[i], isCancelled);
                if (subSolutions[i] == null)
                    throw new InvalidOperationException($"无法生成武士数独角子盘 {i}");
            }

            return MergeSubSolutions(subSolutions);
        });
    }

    private Board? GenerateCenterSubGrid(Func<bool>? isCancelled, Dictionary<string, object>? templateData)
    {
        List<List<int?>>? solutionData = null;
        if (templateData != null && templateData.TryGetValue("solutionData", out var data))
        {
            solutionData = ConvertToNullableSolutionData(data);
        }

        if (solutionData == null)
        {
            solutionData = _templateManager.GetRrn17Template(_random);
        }

        if (solutionData != null)
        {
            return CreateBoardFromTemplate(solutionData);
        }

        const int maxAttempts = 3;
        for (int i = 0; i < maxAttempts; i++)
        {
            if (isCancelled?.Invoke() ?? false) return null;

            var solver = StandardDLXSolver.Create(_random);
            var matrix = solver.GenerateSolution(() => isCancelled?.Invoke() ?? false);
            if (matrix != null)
            {
                return CreateStandardBoard(matrix);
            }
        }
        return null;
    }

    private static List<List<int?>>? ConvertToNullableSolutionData(object data)
    {
        try
        {
            if (data is List<List<int?>> list)
                return list;

            if (data is List<List<int>> intList)
            {
                return intList.Select(row => row.Select(v => (int?)v).ToList()).ToList();
            }

            if (data is System.Text.Json.JsonElement json && json.ValueKind == System.Text.Json.JsonValueKind.Array)
            {
                var result = new List<List<int?>>();
                foreach (var row in json.EnumerateArray())
                {
                    var rowList = new List<int?>();
                    foreach (var val in row.EnumerateArray())
                    {
                        rowList.Add(val.ValueKind == System.Text.Json.JsonValueKind.Null ? null : val.GetInt32());
                    }
                    result.Add(rowList);
                }
                return result;
            }
            return null;
        }
        catch
        {
            return null;
        }
    }

    private static Board CreateBoardFromTemplate(List<List<int?>> data)
    {
        var cells = new List<IReadOnlyList<SudokuCell>>(9);
        for (int r = 0; r < 9; r++)
        {
            var row = new List<SudokuCell>(9);
            for (int c = 0; c < 9; c++)
            {
                var val = data[r][c];
                row.Add(SudokuCell.CreateInstance(r, c, val, isFixed: false));
            }
            cells.Add(row);
        }
        var tempBoard = new StandardBoard(9, cells, new List<SudokuRegion>());
        return new StandardBoard(9, cells, tempBoard.CreateRegions());
    }

    private static Board CreateStandardBoard(int[,] matrix)
    {
        var cells = new List<IReadOnlyList<SudokuCell>>(9);
        for (int r = 0; r < 9; r++)
        {
            var row = new List<SudokuCell>(9);
            for (int c = 0; c < 9; c++)
            {
                row.Add(SudokuCell.CreateInstance(r, c, matrix[r, c], isFixed: false));
            }
            cells.Add(row);
        }
        var tempBoard = new StandardBoard(9, cells, new List<SudokuRegion>());
        return new StandardBoard(9, cells, tempBoard.CreateRegions());
    }

    private int[][][] ExtractOverlapConstraints(Board centerBoard)
    {
        var constraints = new int[4][][];

        var overlapPositions = new[] {
            (rOffset: 0, cOffset: 0),
            (rOffset: 0, cOffset: 6),
            (rOffset: 6, cOffset: 0),
            (rOffset: 6, cOffset: 6),
        };

        for (int i = 0; i < 4; i++)
        {
            var (rOff, cOff) = overlapPositions[i];
            constraints[i] = new int[3][];
            for (int r = 0; r < 3; r++)
            {
                constraints[i][r] = new int[3];
                for (int c = 0; c < 3; c++)
                {
                    constraints[i][r][c] = centerBoard.GetCell(rOff + r, cOff + c).Value ?? 0;
                }
            }
        }
        return constraints;
    }

    private Board? GenerateCornerSubGrid(int cornerIndex, int[][] constraint, Func<bool>? isCancelled)
    {
        const int maxAttempts = 5;

        for (int attempt = 0; attempt < maxAttempts; attempt++)
        {
            if (isCancelled?.Invoke() ?? false) return null;

            var initialGrid = new int[9, 9];
            var (rStart, cStart) = GetConstraintPosition(cornerIndex);

            for (int r = 0; r < 3; r++)
            {
                for (int c = 0; c < 3; c++)
                {
                    initialGrid[rStart + r, cStart + c] = constraint[r][c];
                }
            }

            var solver = StandardDLXSolver.Create(_random);
            var matrix = solver.SolveFromGrid(initialGrid, () => isCancelled?.Invoke() ?? false);

            if (matrix != null)
            {
                return CreateStandardBoard(matrix);
            }
        }
        return null;
    }

    private static (int, int) GetConstraintPosition(int cornerIndex)
    {
        return cornerIndex switch
        {
            0 => (6, 6),
            1 => (6, 0),
            2 => (0, 6),
            3 => (0, 0),
            _ => (0, 0)
        };
    }

    private SamuraiBoard MergeSubSolutions(Board[] subSolutions)
    {
        var cells = new List<List<SudokuCell>>(21);
        for (int r = 0; r < 21; r++)
        {
            var row = new List<SudokuCell>(21);
            for (int c = 0; c < 21; c++)
            {
                row.Add(new SudokuCell(r, c));
            }
            cells.Add(row);
        }

        for (int sg = 0; sg < 5; sg++)
        {
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[sg];
            var subBoard = subSolutions[sg];

            for (int r = 0; r < 9; r++)
            {
                for (int c = 0; c < 9; c++)
                {
                    var val = subBoard.GetCell(r, c).Value;
                    if (val.HasValue)
                    {
                        cells[startRow + r][startCol + c] = SudokuCell.CreateInstance(
                            startRow + r, startCol + c, val.Value, isFixed: false);
                    }
                }
            }
        }

        return new SamuraiBoard(cells.Select(row => row.AsReadOnly()).ToList());
    }

    private async Task<Board> GeneratePuzzle(Board solution, Difficulty difficulty, Func<bool>? isCancelled)
    {
        var samuraiSolution = (SamuraiBoard)solution;
        var diggingConfig = DiggingConfig.FromDifficulty(difficulty, GameType.Samurai);

        var subBoards = new Board[5];
        for (int i = 0; i < 5; i++)
        {
            subBoards[i] = samuraiSolution.GetSubBoard(i);
        }

        var subPuzzles = new Board[5];
        for (int i = 0; i < 5; i++)
        {
            if (isCancelled?.Invoke() ?? false) return solution;

            var subDiggingConfig = new DiggingConfig
            {
                MinFilledCells = Math.Max(diggingConfig.MinFilledCells, 17),
                MaxFilledCells = diggingConfig.MaxFilledCells,
                MaxAttempts = diggingConfig.MaxAttempts,
                UseSymmetry = false,
                ValidateDifficulty = false
            };

            subPuzzles[i] = await _diggingAlgorithm.GeneratePuzzle(subBoards[i], subDiggingConfig, isCancelled);
        }

        return MergeSubPuzzles(subPuzzles);
    }

    private SamuraiBoard MergeSubPuzzles(Board[] subPuzzles)
    {
        var cells = new List<List<SudokuCell>>(21);
        for (int r = 0; r < 21; r++)
        {
            var row = new List<SudokuCell>(21);
            for (int c = 0; c < 21; c++)
            {
                row.Add(new SudokuCell(r, c));
            }
            cells.Add(row);
        }

        for (int sg = 0; sg < 5; sg++)
        {
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[sg];
            var subPuzzle = subPuzzles[sg];

            for (int r = 0; r < 9; r++)
            {
                for (int c = 0; c < 9; c++)
                {
                    var subCell = subPuzzle.GetCell(r, c);
                    cells[startRow + r][startCol + c] = SudokuCell.CreateInstance(
                        startRow + r, startCol + c,
                        subCell.Value,
                        isFixed: subCell.IsFixed);
                }
            }
        }

        ProcessOverlapFixedCells(cells);
        return new SamuraiBoard(cells.Select(row => row.AsReadOnly()).ToList());
    }

    private static void ProcessOverlapFixedCells(List<List<SudokuCell>> cells)
    {
        var overlapRegions = SamuraiConstants.OverlapRegions;

        foreach (var (startRow, startCol, endRow, endCol) in overlapRegions)
        {
            bool anyFixed = false;

            for (int r = startRow; r <= endRow; r++)
            {
                for (int c = startCol; c <= endCol; c++)
                {
                    if (cells[r][c].IsFixed)
                    {
                        anyFixed = true;
                        break;
                    }
                }
                if (anyFixed) break;
            }

            if (anyFixed)
            {
                for (int r = startRow; r <= endRow; r++)
                {
                    for (int c = startCol; c <= endCol; c++)
                    {
                        if (cells[r][c].Value.HasValue)
                        {
                            cells[r][c] = SudokuCell.CreateInstance(r, c, cells[r][c].Value.Value, isFixed: true);
                        }
                    }
                }
            }
        }
    }

    private static SamuraiBoard MarkAllAsFixed(Board board)
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(board.Size);
        for (int r = 0; r < board.Size; r++)
        {
            var row = new List<SudokuCell>();
            for (int c = 0; c < board.Size; c++)
            {
                var cell = board.GetCell(r, c);
                row.Add(SudokuCell.CreateInstance(r, c, cell.Value, isFixed: cell.Value != null));
            }
            newCells.Add(row);
        }
        return new SamuraiBoard(newCells);
    }
}