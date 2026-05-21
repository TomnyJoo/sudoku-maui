using System.Collections.Immutable;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Solving.Solvers;

namespace SudoKu.Services.Generation;

/// <summary>
/// 杀手数独专用生成器
/// 
/// 完全参照 Flutter 的 killer_generator.dart 实现
/// 生成策略：先有终盘，再根据终盘动态划分笼子，天然保证兼容性
/// </summary>
public class KillerGenerator(Random? random = null) : SudokuGenerator
{
    private readonly Random _random = random ?? new Random();

    /// <summary>
    /// 支持的游戏类型
    /// </summary>
    public override GameType SupportedGameType => GameType.Killer;

    public override async Task<GenerationResult> GenerateAsync(
        Difficulty difficulty,
        int size,
        Func<bool>? isCancelled = null,
        Dictionary<string, object>? templateData = null,
        IProgress<GenerationStage>? progress = null)
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();

        Board standardSolution;
        List<KillerCage> cages;
        KillerBoard finalPuzzle;
        KillerBoard finalKillerSolution;

        try
        {
            // 1. 生成标准数独终盘（优先使用 rrn17 模板变换）
            progress?.Report(GenerationStage.GeneratingSolution);
            standardSolution = await GenerateStandardSolution(isCancelled, templateData);

            // 2. 在终盘上动态划分笼子（根据难度调整笼子大小）
            progress?.Report(GenerationStage.LoadingTemplate);
            cages = GenerateCagesDynamically(standardSolution, size, difficulty);

            // 3. 生成谜题和终盘棋盘
            var emptyCells = CreateEmptyCells(size);
            var solutionCells = CreateSolutionCells(standardSolution, size);

            // 使用统一的 KillerBoard
            var puzzle = new KillerBoard(size, emptyCells, cages: cages);
            var killerSolution = new KillerBoard(size, solutionCells, cages: cages);

            // 4. 创建区域
            progress?.Report(GenerationStage.CreatingRegions);
            var puzzleRegions = puzzle.CreateRegions();
            var solutionRegions = killerSolution.CreateRegions();

            finalPuzzle = new KillerBoard(size, emptyCells, puzzleRegions, cages);
            finalKillerSolution = new KillerBoard(size, solutionCells, solutionRegions, cages);

            // 5. 验证
            progress?.Report(GenerationStage.Validating);
            if (!ValidatePuzzleSolution(finalPuzzle, finalKillerSolution))
            {
                throw new InvalidOperationException("游戏验证失败");
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[KillerGenerator] Generation failed: {ex.Message}");
            throw;
        }

        stopwatch.Stop();

        // 6. 【关键】杀手数独没有挖空过程，需要手动标记终盘 isFixed
        // 谜题为空棋盘，终盘全部标记为 isFixed=true
        var markedSolution = MarkAllAsFixed(finalKillerSolution);

        return new GenerationResult
        {
            Solution = markedSolution,
            Puzzle = finalPuzzle,
            GenerationTime = stopwatch.ElapsedMilliseconds
        };
    }

    /// <summary>
    /// 生成标准数独终盘（优先使用 rrn17 模板变换）
    /// 
    /// 参照 Flutter 的 KillerGenerator._generateSolution
    /// </summary>
    private async Task<Board> GenerateStandardSolution(Func<bool>? isCancelled, Dictionary<string, object>? templateData)
    {
        return await Task.Run(() =>
        {
            // 优先使用传入的模板数据
            if (templateData != null && templateData.TryGetValue("solutionData", out var data))
            {
                var solutionData = ConvertToSolutionData(data);
                if (solutionData != null)
                {
                    return KillerGenerator.CreateStandardBoardFromTemplate(solutionData);
                }
            }

            // 备用：使用 DLX 求解器生成
            const int maxAttempts = 3;
            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                if (CheckCancelled(isCancelled)) return null!;

                var solver = StandardDLXSolver.Create(_random);
                var board = solver.GenerateSolution(() => isCancelled?.Invoke() ?? false);
                if (board != null)
                {
                    return ConvertToStandardBoard(board);
                }
            }

            throw new InvalidOperationException("无法生成标准数独终盘");
        });
    }

    /// <summary>
    /// 动态划分笼子（保证与终盘兼容）
    /// 
    /// 使用随机贪心算法：随机选择起始格，向相邻格扩展，确保笼子内数字互不相同
    /// 参照 Flutter 的 KillerGenerator._generateCagesDynamically
    /// </summary>
    private List<KillerCage> GenerateCagesDynamically(Board solution, int size, Difficulty difficulty)
    {
        var assigned = new bool[size, size];
        var cages = new List<KillerCage>();
        var directions = new (int dr, int dc)[] { (0, 1), (0, -1), (1, 0), (-1, 0) };

        // 根据难度调整笼子大小范围
        // 简单：更多小笼子（2-3格）→ 约束更强 → 更容易推理
        // 困难：更多大笼子（3-5格）→ 约束更弱 → 更难推理
        var (minSize, maxSize) = GetCageSizeRange(difficulty);

        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (assigned[r, c]) continue;

                // 开始新笼子
                var cageCells = new List<(int row, int col)> { (r, c) };
                var cageValues = new HashSet<int> { solution.GetCell(r, c).Value!.Value };
                assigned[r, c] = true;
                var targetSize = minSize + _random.Next(maxSize - minSize + 1);

                // 随机贪心扩展
                var attempts = 0;
                while (cageCells.Count < targetSize && attempts < 20)
                {
                    attempts++;

                    // 收集边界格
                    var borderCells = new List<(int row, int col)>();
                    foreach (var (cr, cc) in cageCells)
                    {
                        foreach (var (dr, dc) in directions)
                        {
                            var nr = cr + dr;
                            var nc = cc + dc;
                            if (nr >= 0 && nr < size && nc >= 0 && nc < size && !assigned[nr, nc])
                            {
                                borderCells.Add((nr, nc));
                            }
                        }
                    }

                    if (borderCells.Count == 0) break;

                    // 随机打乱边界格，尝试扩展
                    Shuffle(borderCells);
                    var expanded = false;

                    foreach (var (nr, nc) in borderCells)
                    {
                        var value = solution.GetCell(nr, nc).Value;
                        if (value.HasValue && !cageValues.Contains(value.Value))
                        {
                            cageCells.Add((nr, nc));
                            cageValues.Add(value.Value);
                            assigned[nr, nc] = true;
                            expanded = true;
                            break;
                        }
                    }

                    if (!expanded) break;
                }

                // 计算笼子 sum
                var sum = 0;
                foreach (var (cr, cc) in cageCells)
                {
                    sum += solution.GetCell(cr, cc).Value ?? 0;
                }

                cages.Add(new KillerCage(
                    id: $"cage_{cages.Count}",
                    cellCoordinates: cageCells,
                    sum: sum
                ));
            }
        }

        return cages;
    }

    /// <summary>
    /// 根据难度获取笼子大小范围
    /// 
    /// 参照 Flutter 的 KillerGenerator._generateCagesDynamically 中的 switch 语句
    /// </summary>
    private static (int minSize, int maxSize) GetCageSizeRange(Difficulty difficulty)
    {
        return difficulty switch
        {
            Difficulty.Beginner => (2, 3),
            Difficulty.Easy => (2, 3),
            Difficulty.Medium => (2, 4),
            Difficulty.Hard => (2, 5),
            Difficulty.Expert => (3, 5),
            Difficulty.Master => (3, 5),
            Difficulty.Custom => (2, 5),
            _ => (2, 4)
        };
    }

    /// <summary>
    /// 创建空单元格矩阵
    /// </summary>
    private static List<IReadOnlyList<SudokuCell>> CreateEmptyCells(int size)
    {
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                row.Add(SudokuCell.CreateInstance(row: r, col: c));
            }
            cells.Add(row);
        }
        return cells;
    }

    /// <summary>
    /// 从标准终盘创建解答单元格矩阵
    /// </summary>
    private static List<IReadOnlyList<SudokuCell>> CreateSolutionCells(Board solution, int size)
    {
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                var value = solution.GetCell(r, c).Value;
                row.Add(SudokuCell.CreateInstance(row: r, col: c, value: value));
            }
            cells.Add(row);
        }
        return cells;
    }

    /// <summary>
    /// 从模板数据创建标准数独棋盘
    /// 
    /// 参照 Flutter 的 KillerGenerator._createStandardBoardFromTemplate
    /// 修复：终盘全部 isFixed=false，由挖空后 SetFixedCells 统一处理
    /// </summary>
    private static Board CreateStandardBoardFromTemplate(List<List<int?>> data)
    {
        var size = data.Count;
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                var val = data[r][c];
                // 修复：终盘全部 isFixed=false，由挖空后 SetFixedCells 统一处理
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: val == 0 ? null : val,
                    isFixed: false
                ));
            }
            cells.Add(row);
        }

        // 使用统一的 StandardBoard
        return new StandardBoard(size, cells);
    }

    /// <summary>
    /// 将 DLX 生成的矩阵转换为标准棋盘
    /// 修复：终盘全部 isFixed=false，由挖空后 SetFixedCells 统一处理
    /// </summary>
    private static Board ConvertToStandardBoard(int[,] matrix)
    {
        var size = matrix.GetLength(0);
        var cells = new List<IReadOnlyList<SudokuCell>>(size);
        for (int r = 0; r < size; r++)
        {
            var row = new List<SudokuCell>(size);
            for (int c = 0; c < size; c++)
            {
                // 修复：终盘全部 isFixed=false，由挖空后 SetFixedCells 统一处理
                row.Add(SudokuCell.CreateInstance(
                    row: r,
                    col: c,
                    value: matrix[r, c],
                    isFixed: false
                ));
            }
            cells.Add(row);
        }

        // 使用统一的 StandardBoard
        return new StandardBoard(size, cells);
    }

    /// <summary>
    /// 验证谜题与答案匹配
    /// 
    /// 参照 Flutter 的 GameValidator.validatePuzzleSolution
    /// </summary>
    private static bool ValidatePuzzleSolution(Board puzzle, Board solution)
    {
        for (int r = 0; r < puzzle.Size; r++)
        {
            for (int c = 0; c < puzzle.Size; c++)
            {
                var puzzleCell = puzzle.GetCell(r, c);
                if (puzzleCell.IsFixed && puzzleCell.Value.HasValue)
                {
                    var solutionCell = solution.GetCell(r, c);
                    if (solutionCell.Value != puzzleCell.Value)
                        return false;
                }
            }
        }
        return true;
    }

    /// <summary>
    /// 标记终盘所有有值单元格为固定
    /// 
    /// 杀手数独没有挖空过程，谜题为空棋盘，终盘全部标记为 isFixed=true
    /// </summary>
    private static Board MarkAllAsFixed(Board board)
    {
        var newCells = new List<IReadOnlyList<SudokuCell>>(board.Size);
        for (int r = 0; r < board.Size; r++)
        {
            var row = new List<SudokuCell>(board.Size);
            for (int c = 0; c < board.Size; c++)
            {
                var cell = board.GetCell(r, c);
                if (cell.Value != null && !cell.IsFixed)
                {
                    row.Add(SudokuCell.CreateInstance(
                        row: r,
                        col: c,
                        value: cell.Value,
                        isFixed: true
                    ));
                }
                else
                {
                    row.Add(cell);
                }
            }
            newCells.Add(row);
        }
        return board.CreateInstance(newCells, board.Regions);
    }

    /// <summary>
    /// 打乱列表顺序
    /// </summary>
    private void Shuffle<T>(List<T> list)
    {
        var n = list.Count;
        for (int i = n - 1; i > 0; i--)
        {
            var j = _random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }

    /// <summary>
    /// 将模板数据转换为解决方案数据格式
    /// </summary>
    private static List<List<int?>>? ConvertToSolutionData(object data)
    {
        try
        {
            if (data is List<List<int?>> list)
            {
                return list;
            }

            if (data is System.Text.Json.JsonElement jsonElement && jsonElement.ValueKind == System.Text.Json.JsonValueKind.Array)
            {
                var result = new List<List<int?>>();
                foreach (var row in jsonElement.EnumerateArray())
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

    }
