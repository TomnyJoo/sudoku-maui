import 'package:meta/meta.dart';
import 'package:sudoku/index.dart';

/// 通用游戏服务类，负责游戏状态管理、持久化和用户操作
/// 整合游戏逻辑处理游戏规则，通过 GameStorageService 统一处理持久化
///
/// 泛型 B 表示具体的 Board 子类型
/// 通过 boardFromJson 工厂函数参数支持所有 Board 类型的序列化/反序列化
class GameService<B extends Board> {
  GameService({
    required this.gameType,
    required GameValidator validator,
    required this.boardFromJson,
  }) : _validator = validator;

  final String gameType;
  final GameValidator _validator;

  /// 从 JSON 创建 Board 实例的工厂函数（由子类或构造时提供）
  final B Function(Map<String, dynamic>) boardFromJson;

  /// 生成新游戏
  Future<GameState<B>> generateGame({
    required Difficulty difficulty,
    int? size,
    final Map<String, dynamic>? options,
    Function(GenerationStage)? onStageUpdate,
  }) async {
    final isCancelled = options?['isCancelled'] as bool Function()?;

    final gameTypeEnum = _parseGameType(gameType);
    // 武士数独默认使用21x21棋盘
    final boardSize = size ?? (gameTypeEnum == GameType.samurai ? AppConstants.samuraiBoardSize : AppConstants.standardBoardSize);

    GenerationResult result;

    // 使用游戏生成门面
    result = await PuzzleGenerator.generateGame(
      gameType: gameTypeEnum,
      size: boardSize,
      difficulty: difficulty,
      onStageUpdate: onStageUpdate,
      isCancelled: isCancelled,
    );

    return createGameState(
      puzzle: result.puzzle as B,
      solution: result.solution as B,
      difficulty: difficulty,
    );
  }

  /// 解析游戏类型
  GameType _parseGameType(String type) {
    switch (type.toLowerCase()) {
      case 'standard':
        return GameType.standard;
      case 'diagonal':
        return GameType.diagonal;
      case 'window':
        return GameType.window;
      case 'jigsaw':
        return GameType.jigsaw;
      case 'killer':
        return GameType.killer;
      case 'samurai':
        return GameType.samurai;
      default:
        return GameType.standard;
    }
  }

  /// 创建游戏状态
  GameState<B> createGameState({
    required B puzzle,
    required B solution,
    required Difficulty difficulty,
  }) {
    // 确保棋盘有区域（容错机制）
    final finalPuzzle = puzzle.regions.isEmpty
        ? puzzle.createInstance(puzzle.cells, regions: puzzle.createRegions()) as B
        : puzzle;

    final finalSolution = solution.regions.isEmpty
        ? solution.createInstance(solution.cells, regions: solution.createRegions()) as B
        : solution;

    return _createSpecificGameState(
      finalPuzzle,
      finalSolution,
      difficulty,
    );
  }

  /// 创建特定游戏类型的游戏状态
  /// Killer 类型有特殊逻辑（清除数字只保留cages）
  GameState<B> _createSpecificGameState(
    B puzzle,
    B solution,
    Difficulty difficulty,
  ) {
    final gameTypeEnum = _parseGameType(gameType);

    B actualPuzzle = puzzle;
    final B actualSolution = solution;

    // Killer 特殊处理：不提供任何预先填好的数字
    if (gameTypeEnum == GameType.killer) {
      actualPuzzle = _createEmptyKillerBoardWithCages(solution) as B;
    }

    // 构建历史记录管理器（命令模式）
    final history = HistoryManager(initialBoard: actualPuzzle);

    // 构建统计服务
    final stats = SessionStatistics(
      board: actualPuzzle,
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

    return GameState<B>(
      board: actualPuzzle,
      initialBoard: actualPuzzle,
      solution: actualSolution,
      difficulty: difficulty.name,
      history: history,
      stats: stats,
      startTime: DateTime.now(),
    );
  }

  /// 创建空的KillerBoard（只保留cages，清除所有数字）
  /// 杀手数独规则：不提供任何预先填好的数字
  Board _createEmptyKillerBoardWithCages(Board solutionBoard) {
    // 创建空的单元格（所有数字都为空）
    final emptyCells = List.generate(
      solutionBoard.size,
      (row) =>
          List.generate(solutionBoard.size, (col) => Cell(row: row, col: col)),
    );

    // 获取cages数据
    List<KillerCage> cages = [];
    if (solutionBoard is KillerBoard) {
      cages = solutionBoard.cages;
    } else {
      // 从 JSON 中提取 cages（兼容旧逻辑）
      final solutionJson = solutionBoard.toJson();
      final cagesJson = solutionJson['cages'] as List?;
      if (cagesJson != null) {
        cages = cagesJson
            .map((cageJson) => KillerCage.fromJson(cageJson as Map<String, dynamic>))
            .toList();
      }
    }

    // 创建新的KillerBoard
    final killerBoard = KillerBoard(
      size: solutionBoard.size,
      cells: emptyCells,
      cages: cages,
    );

    return KillerBoard(
      size: solutionBoard.size,
      cells: emptyCells,
      regions: killerBoard.createRegions(),
      cages: cages,
    );
  }

  /// 检查游戏是否完成
  /// Killer 类型需要额外检查笼子约束
  bool isGameCompleted(GameState<B> state) {
    final gameTypeEnum = _parseGameType(gameType);

    if (gameTypeEnum == GameType.killer) {
      final board = state.board;
      if (!board.isComplete()) {
        return false;
      }
      // Killer 需要检查所有笼子是否有效
      if (board is KillerBoard) {
        return board.areAllCagesValid;
      }
    }

    return state.board.isComplete();
  }

  /// 检查游戏是否有效
  bool isGameValid(GameState<B> state) => _validator.validateBoard(state.board);

  /// 保存游戏状态
  Future<void> saveGameState(GameState<B> state) async {
    await GameStorageService.saveGameState(
      state,
      '${gameType}_current',
    );
  }

  /// 加载游戏状态
  Future<GameState<B>?> loadGameState(String gameId) async => GameStorageService.loadGameState<B>(gameId, boardFromJson);

  /// 清除保存的游戏
  Future<void> clearSavedGame(String gameId) async {
    await GameStorageService.clearGameState(gameId);
  }

  /// 获取所有保存的游戏
  Future<List<GameState<B>>> getAllSavedGames() async {
    final gamesData = await GameStorageService.getAllSavedGames();
    return gamesData
        .map((data) => GameState<B>.fromJson(
              data['data'],
              boardFromJson,
            ))
        .toList();
  }

  /// 检查游戏是否有保存的状态
  Future<bool> hasSavedGame(String gameId) async =>
      GameStorageService.hasSavedGame(gameId);

  /// 辅助方法：基于当前状态创建新实例（仅替换指定字段）
  @protected
  GameState<B> _copyState(GameState<B> state, {
    B? board,
    B? initialBoard,
    HistoryManager? history,
    SessionStatistics? stats,
    bool? isCompleted,
    int? mistakes,
    int? elapsedTime,
    bool? isMarkMode,
    bool? isAutoMarkMode,
    int? hintsUsed,
    DateTime? startTime,
    DateTime? completionTime,
    bool? isShowingSolution,
    B? savedBoard,
  }) => state.createInstance(
    board: board ?? state.board,
    initialBoard: initialBoard ?? state.initialBoard,
    solution: state.solution,
    difficulty: state.difficulty,
    elapsedTime: elapsedTime ?? state.elapsedTime,
    mistakes: mistakes ?? state.mistakes,
    isCompleted: isCompleted ?? state.isCompleted,
    history: history ?? state.history,
    stats: stats ?? state.stats,
    startTime: startTime ?? state.startTime,
    completionTime: completionTime ?? state.completionTime,
    isShowingSolution: isShowingSolution ?? state.isShowingSolution,
    isMarkMode: isMarkMode ?? state.isMarkMode,
    isAutoMarkMode: isAutoMarkMode ?? state.isAutoMarkMode,
    hintsUsed: hintsUsed ?? state.hintsUsed,
    savedBoard: savedBoard ?? state.savedBoard,
  );

  /// 更新棋盘状态（无历史记录，用于选择单元格、自动标记等UI操作）
  GameState<B> updateBoard(GameState<B> state, B newBoard) {
    if (state.isShowingSolution) return state;
    return _copyState(state, board: newBoard);
  }

  /// 通过命令更新棋盘状态（有历史记录，用于用户主动操作）
  GameState<B> updateBoardWithCommand(GameState<B> state, BoardCommand command) {
    if (state.isShowingSolution) return state;
    final newBoard = command.execute(state.board) as B;
    final newHistory = state.history.addCommand(command);
    final newStats = state.stats
        .updateBoard(newBoard)
        .updateTotalMoves(newHistory.length - 1);
    return _copyState(state,
      board: newBoard,
      history: newHistory,
      stats: newStats,
    );
  }

  /// 撤销操作
  GameState<B> undo(GameState<B> state) {
    if (state.isShowingSolution) return state;

    final (newHistory, previousBoard) = state.history.undo();
    if (previousBoard == null) return state;

    return _copyState(state,
      board: previousBoard as B,
      history: newHistory,
      stats: state.stats.updateTotalMoves(newHistory.length - 1),
    );
  }

  /// 重做操作
  GameState<B> redo(GameState<B> state) {
    if (state.isShowingSolution) return state;

    final (newHistory, nextBoard) = state.history.redo();
    if (nextBoard == null) return state;

    return _copyState(state,
      board: nextBoard as B,
      history: newHistory,
      stats: state.stats.updateTotalMoves(newHistory.length - 1),
    );
  }

  /// 检查是否可以撤销
  bool canUndo(GameState<B> state) => !state.isShowingSolution && state.history.canUndo();

  /// 检查是否可以重做
  bool canRedo(GameState<B> state) => !state.isShowingSolution && state.history.canRedo();

  /// 清空历史记录（保留当前状态）
  GameState<B> clearHistory(GameState<B> state) =>
    _copyState(state,
      history: state.history.clear(),
      stats: state.stats.updateTotalMoves(0),
    );

  /// 重置游戏到初始状态
  GameState<B> resetGameState(GameState<B> state) {
    final newHistory = HistoryManager(initialBoard: state.initialBoard);
    final newStats = SessionStatistics(
      board: state.initialBoard,
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

    return _copyState(state,
      board: state.initialBoard,
      initialBoard: state.initialBoard,
      history: newHistory,
      stats: newStats,
      startTime: DateTime.now(),
      isCompleted: false,
      mistakes: 0,
      elapsedTime: 0,
    );
  }

  /// 显示完整答案（不经过历史记录，通过 savedBoard 恢复）
  GameState<B> showSolution(GameState<B> state) {
    final size = state.solution.size;
    final newCells = <List<Cell>>[];

    for (int row = 0; row < size; row++) {
      final rowCells = <Cell>[];
      for (int col = 0; col < size; col++) {
        final solutionCell = state.solution.getCell(row, col);
        final initialCell = state.initialBoard.getCell(row, col);

        rowCells.add(Cell(
          row: row,
          col: col,
          value: solutionCell.value,
          isFixed: initialCell.isFixed,
          candidates: const {},
        ));
      }
      newCells.add(rowCells);
    }

    final solutionBoard = state.solution.createInstance(newCells, regions: state.solution.regions) as B;

    return _copyState(state,
      board: solutionBoard,
      isShowingSolution: true,
    );
  }

  /// 隐藏答案，返回游戏状态（从 savedBoard 恢复，savedBoard 由 GameState 层面管理）
  GameState<B> hideSolution(GameState<B> state) =>
     _copyState(state,isShowingSolution: false,);

  /// 记录错误
  GameState<B> recordMistake(GameState<B> state) {
    final newMistakes = state.mistakes + 1;
    return _copyState(state,
      mistakes: newMistakes,
      stats: state.stats.updateMistakes(newMistakes),
    );
  }

  /// 更新游戏时间
  GameState<B> updateTime(GameState<B> state, Duration timeElapsed) =>
    _copyState(state,
      elapsedTime: timeElapsed.inSeconds,
      stats: state.stats.updateElapsedTime(timeElapsed.inSeconds),
    );

  /// 标记游戏为完成
  GameState<B> markAsCompleted(GameState<B> state) =>
    _copyState(state,
      isCompleted: true,
      stats: state.stats.updateCompletionStatus(true),
      completionTime: DateTime.now(),
    );

  /// 切换标记模式
  GameState<B> toggleMarkMode(GameState<B> state) => _copyState(state,
    isMarkMode: !state.isMarkMode,
  );

  /// 切换自动标记模式
  GameState<B> toggleAutoMarkMode(GameState<B> state) => _copyState(state,
    isAutoMarkMode: !state.isAutoMarkMode,
  );

  /// 检查移动是否有效
  bool isValidMove(GameState<B> state, int row, int col, int value) =>
      _validator.isValidMove(state.board, row, col, value);

  /// 检查移动是否正确
  bool isCorrectMove(GameState<B> state, int row, int col, int value) {
    final solutionValue = state.solution.getCell(row, col).value;
    return solutionValue == value;
  }

  /// 检查单元格是否已固定
  bool isCellFixed(GameState<B> state, int row, int col) =>
      state.board.getCell(row, col).isFixed;

  /// 检查单元格是否有值
  bool isCellFilled(GameState<B> state, int row, int col) =>
      !state.board.getCell(row, col).isEmpty;

  /// 获取单元格的值
  int? getCellValue(GameState<B> state, int row, int col) =>
      state.board.getCell(row, col).value;

  /// 获取单元格的正确值
  int getCellSolution(GameState<B> state, int row, int col) =>
      state.solution.getCell(row, col).value!;

  /// 获取单元格的候选数
  Set<int> getCellCandidates(GameState<B> state, int row, int col) =>
      state.board.getCell(row, col).candidates;

  /// 清除单元格的候选数
  B clearCellCandidates(GameState<B> state, int row, int col) =>
      state.board.setCellCandidates(row, col, <int>{}) as B;

  /// 检查单元格是否有错误
  bool isCellError(GameState<B> state, int row, int col) =>
      state.board.getCell(row, col).isError;

  /// 标记单元格为错误
  B markCellAsError(GameState<B> state, int row, int col) =>
      state.board.setCellError(row, col, true) as B;

  /// 清除单元格的错误标记
  B clearCellError(GameState<B> state, int row, int col) =>
      state.board.setCellError(row, col, false) as B;

  /// 清除所有错误标记
  B clearAllErrors(GameState<B> state) {
    B workingBoard = state.board;

    final size = state.board.size;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        workingBoard = workingBoard.setCellError(row, col, false) as B;
      }
    }

    return workingBoard;
  }

  /// 检查游戏是否有错误
  bool hasErrors(GameState<B> state) {
    final size = state.board.size;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (state.board.getCell(row, col).isError) {
          return true;
        }
      }
    }
    return false;
  }

  /// 计算游戏进度
  double calculateProgress(GameState<B> state) {
    final filledCount = getFilledCellCount(state);
    final totalCount = getTotalCellCount(state);
    return totalCount > 0 ? filledCount / totalCount : 0.0;
  }

  /// 获取已填充的单元格数量
  int getFilledCellCount(GameState<B> state) =>
      state.board.getFilledCells().length;

  /// 获取总单元格数量
  int getTotalCellCount(GameState<B> state) {
    final size = state.board.size;
    return size * size;
  }

  /// 设置单元格值
  GameState<B> setCellValue({
    required GameState<B> gameState,
    required int row,
    required int col,
    required int? value,
    required bool isMarkMode,
  }) {
    final currentCell = gameState.board.getCell(row, col);
    if (currentCell.isFixed) return gameState;

    BoardCommand command;
    if (isMarkMode) {
      // 标记模式：切换候选数
      if (value == null) return gameState;
      command = ToggleCandidateCommand(row: row, col: col, candidate: value);
    } else {
      // 普通模式：设置值（含错误标记）
      bool isError = false;
      if (value != null) {
        final tempBoard = gameState.board.setCellValue(row, col, null) as B;
        isError = !_validator.isValidMove(tempBoard, row, col, value);
      }
      command = SetValueCommand(row: row, col: col, value: value, isError: isError);
    }

    // 使用命令模式更新状态
    var newState = updateBoardWithCommand(gameState, command);

    // 检查游戏是否完成（只在普通模式且游戏未完成时检查）
    if (!isMarkMode && !newState.isCompleted) {
      if (isGameCompleted(newState)) {
        newState = markAsCompleted(newState);
      }
    }

    return newState;
  }

  /// 清除单元格值
  GameState<B> clearCellValue({
    required GameState<B> gameState,
    required int row,
    required int col,
  }) => setCellValue(
    gameState: gameState,
    row: row,
    col: col,
    value: null,
    isMarkMode: false,
  );
}
