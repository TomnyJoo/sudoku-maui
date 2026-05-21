import 'dart:math';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/game_validator.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';

/// 杀手数独专用生成器
/// 生成策略：先有终盘，再根据终盘动态划分笼子，天然保证兼容性
class KillerGenerator implements IGameGenerator {
  KillerGenerator({
    GameValidator? validator,
    Random? random,
  }) : _validator = validator ?? GameValidator(),
       _random = random ?? Random();
  final GameValidator _validator;
  final Random _random;

  @override
  GameType get supportedGameType => GameType.killer;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Map<String, dynamic>? templateData,
    Function(GenerationStage)? onStageUpdate,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. 生成标准数独终盘（优先使用 rrn17 模板变换）
    onStageUpdate?.call(GenerationStage.generatingSolution);
    final standardSolution = await _generateSolution(
      isCancelled: isCancelled,
      templateData: templateData,
    );

    // 2. 在终盘上动态划分笼子（根据难度调整笼子大小）
    onStageUpdate?.call(GenerationStage.loadingTemplate);
    final cages = _generateCagesDynamically(standardSolution, size, difficulty);

    // 3. 生成谜题和终盘棋盘
    final emptyCells = List.generate(
      size,
      (row) => List.generate(size, (col) => Cell(row: row, col: col)),
    );

    final solutionCells = List.generate(size, (row) => List.generate(size, (col) {
        final value = standardSolution.getCell(row, col).value;
        return Cell(row: row, col: col, value: value);
      }));

    final puzzle = KillerBoard(size: size, cells: emptyCells, cages: cages);
    final killerSolution = KillerBoard(size: size, cells: solutionCells, cages: cages);

    // 4. 创建区域
    onStageUpdate?.call(GenerationStage.creatingRegions);
    final puzzleRegions = puzzle.createRegions();
    final solutionRegions = killerSolution.createRegions();

    final finalPuzzle = KillerBoard(
      size: size, cells: emptyCells, regions: puzzleRegions, cages: cages,
    );
    final finalKillerSolution = KillerBoard(
      size: size, cells: solutionCells, regions: solutionRegions, cages: cages,
    );

    // 5. 验证
    onStageUpdate?.call(GenerationStage.validating);
    if (!_validator.validatePuzzleSolution(finalPuzzle, finalKillerSolution)) {
      throw GameGenerationException('游戏验证失败');
    }

    stopwatch.stop();
    return GenerationResult(
      solution: finalKillerSolution,
      puzzle: finalPuzzle,
      generationTime: stopwatch.elapsed,
    );
  }

  /// 生成标准数独终盘（优先使用 rrn17 模板变换）
  Future<Board> _generateSolution({
    bool Function()? isCancelled,
    Map<String, dynamic>? templateData,
  }) async {
    // 优先使用传入的 rrn17 模板数据
    if (templateData != null && templateData.containsKey('solutionData')) {
      final solutionData = (templateData['solutionData'] as List)
          .map((row) => (row as List).map((v) => v as int?).toList())
          .toList();
      return _createStandardBoardFromTemplate(solutionData);
    }

    // 备用：使用 DLX 求解器生成
    final solver = StandardDLXSolver.create(random: _random);
    final board = solver.generateSolution(isCancelled: isCancelled);
    if (board == null) {
      throw GameGenerationException('无法生成标准数独终盘');
    }
    return board;
  }

  /// 动态划分笼子（保证与终盘兼容）
  /// 使用随机贪心算法：随机选择起始格，向相邻格扩展，确保笼子内数字互不相同
  /// [difficulty] 控制笼子大小分布，影响难度
  List<KillerCage> _generateCagesDynamically(Board solution, int size, Difficulty difficulty) {
    final assigned = List.generate(size, (_) => List.filled(size, false));
    final cages = <KillerCage>[];
    const directions = [(0, 1), (0, -1), (1, 0), (-1, 0)];

    // 根据难度调整笼子大小范围
    // 简单：更多小笼子（2-3格）→ 约束更强 → 更容易推理
    // 困难：更多大笼子（3-5格）→ 约束更弱 → 更难推理
    final int minSize, maxSize;
    switch (difficulty) {
      case Difficulty.beginner:
        minSize = 2;
        maxSize = 3;
      case Difficulty.easy:
        minSize = 2;
        maxSize = 3;
      case Difficulty.medium:
        minSize = 2;
        maxSize = 4;
      case Difficulty.hard:
        minSize = 2;
        maxSize = 5;
      case Difficulty.expert:
        minSize = 3;
        maxSize = 5;
      case Difficulty.master:
        minSize = 3;
        maxSize = 5;
      case Difficulty.custom:
        minSize = 2;
        maxSize = 5;
    }

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (assigned[r][c]) continue;

        // 开始新笼子
        final cageCells = <(int, int)>[(r, c)];
        final cageValues = {solution.getCell(r, c).value!};
        assigned[r][c] = true;
        final targetSize = minSize + _random.nextInt(maxSize - minSize + 1);

        // 随机贪心扩展
        var attempts = 0;
        while (cageCells.length < targetSize && attempts < 20) {
          attempts++;
          // 收集边界格
          final borderCells = <(int, int)>[];
          for (final (cr, cc) in cageCells) {
            for (final (dr, dc) in directions) {
              final nr = cr + dr;
              final nc = cc + dc;
              if (nr >= 0 && nr < size && nc >= 0 && nc < size && !assigned[nr][nc]) {
                borderCells.add((nr, nc));
              }
            }
          }
          if (borderCells.isEmpty) break;

          // 随机打乱边界格，尝试扩展
          borderCells.shuffle(_random);
          bool expanded = false;
          for (final (nr, nc) in borderCells) {
            final value = solution.getCell(nr, nc).value;
            if (value != null && !cageValues.contains(value)) {
              cageCells.add((nr, nc));
              cageValues.add(value);
              assigned[nr][nc] = true;
              expanded = true;
              break;
            }
          }
          if (!expanded) break;
        }

        // 计算笼子 sum
        int sum = 0;
        for (final (cr, cc) in cageCells) {
          sum += solution.getCell(cr, cc).value ?? 0;
        }

        cages.add(KillerCage(
          id: 'cage_${cages.length}',
          cellCoordinates: cageCells,
          sum: sum,
        ));
      }
    }

    return cages;
  }

  /// 从模板数据创建标准数独棋盘
  StandardBoard _createStandardBoardFromTemplate(List<List<int?>> data) {
    final size = data.length;
    final cells = List.generate(size, (row) => List.generate(size, (col) {
        final value = data[row][col];
        return Cell(
          row: row,
          col: col,
          value: value == 0 ? null : value,
          isFixed: value != 0,
        );
      }));
    return StandardBoard(size: size, cells: cells);
  }
}
