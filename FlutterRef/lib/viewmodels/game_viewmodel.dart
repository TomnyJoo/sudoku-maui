import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 统一游戏视图模型
///
/// 负责游戏的核心逻辑和状态管理，通过混入（Mixin）实现各种功能
/// 泛型 B 表示棋盘类型
class GameViewModel<B extends Board> extends ChangeNotifier
    with
        GameStateMixin<B, GameState<B>>,
        GameLifecycleMixin<B, GameState<B>>,
        GameInputMixin<B, GameState<B>>,
        GameAssistMixin<B, GameState<B>>,
        GamePersistenceMixin<B, GameState<B>> {
  /// 构造游戏视图模型
  ///
  /// [gameType] - 游戏类型标识符
  /// [boardFromJson] - 棋盘 JSON 反序列化函数
  /// [createEmptyBoard] - 创建空棋盘的工厂函数
  /// [settings] - 应用设置（可选）
  /// [regionMatrix] - 区域矩阵（仅 Jigsaw 使用）
  GameViewModel({
    required String gameType,
    required B Function(Map<String, dynamic>) boardFromJson,
    required B Function() createEmptyBoard,
    AppSettings? settings,
    List<List<int>>? regionMatrix,
  })  : _gameType = gameType,
        _createEmptyBoard = createEmptyBoard,
        _regionMatrix = regionMatrix,
        _gameService = GameService<B>(
          gameType: gameType,
          validator: GameValidator(),
          boardFromJson: boardFromJson,
        ),
        _gameState = _createInitialState<B>(createEmptyBoard(), regionMatrix),
        _appSettings = settings {
    // 初始化游戏计时器
    _gameTimer = GameTimer(
      onTick: () {
        // 游戏未完成时更新计时
        if (!gameState.isCompleted) {
          gameState = gameState.copyWith(elapsedTime: _gameTimer.elapsedTime);
          notifyListeners();
        }
      },
      onComplete: () async {
        // 游戏完成时更新状态
        gameState = gameState.copyWith(isCompleted: true);
        notifyListeners();
      },
    );
  }

  /// 从已有状态构造（用于从保存的游戏列表加载）
  GameViewModel.withState({
    required String gameType,
    required B Function(Map<String, dynamic>) boardFromJson,
    required B Function() createEmptyBoard,
    required GameState<B> initialState,
    AppSettings? settings,
    List<List<int>>? regionMatrix,
  })  : _gameType = gameType,
        _createEmptyBoard = createEmptyBoard,
        _regionMatrix = regionMatrix,
        _gameService = GameService<B>(
          gameType: gameType,
          validator: GameValidator(),
          boardFromJson: boardFromJson,
        ),
        _gameState = initialState,
        _appSettings = settings {
    _gameTimer = GameTimer(
      onTick: () {
        if (!gameState.isCompleted) {
          gameState = gameState.copyWith(elapsedTime: _gameTimer.elapsedTime);
          notifyListeners();
        }
      },
      onComplete: () async {
        gameState = gameState.copyWith(isCompleted: true);
        notifyListeners();
      },
    );
  }

  /// 游戏类型标识符
  final String _gameType;

  /// 创建空棋盘的工厂函数
  final B Function() _createEmptyBoard;

  /// 区域矩阵（仅 Jigsaw 使用）
  final List<List<int>>? _regionMatrix;

  /// 游戏服务
  final GameService<B> _gameService;

  /// 应用设置
  AppSettings? _appSettings;

  /// 游戏计时器
  late final GameTimer _gameTimer;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否取消游戏生成
  bool _isCancelled = false;

  /// 游戏生成阶段
  GenerationStage _generationStage = GenerationStage.generatingSolution;

  /// 缓存的当前难度最佳成绩
  BestScoreRecord? _cachedBestScore;

  /// 最佳成绩是否已加载完成
  bool isBestScoreLoaded = false;

  // ========== Samurai 特有属性 ==========

  /// 当前子网格索引（仅 Samurai 使用）
  int _currentSubGridIndex = 4; // 默认显示中心网格

  /// 是否概览模式（仅 Samurai 使用）
  bool _isOverviewMode = false;

  /// 是否为 Samurai 游戏
  bool get isSamuraiGame => _gameType == 'samurai';

  /// 当前子网格索引
  int get currentSubGridIndex => _currentSubGridIndex;

  /// 是否概览模式
  bool get isOverviewMode => _isOverviewMode;

  /// 切换概览模式
  void toggleOverviewMode() {
    _isOverviewMode = !_isOverviewMode;
    notifyListeners();
  }

  /// 进入概览模式
  void enterOverviewMode() {
    if (!_isOverviewMode) {
      _isOverviewMode = true;
      notifyListeners();
    }
  }

  /// 退出概览模式
  void exitOverviewMode() {
    if (_isOverviewMode) {
      _isOverviewMode = false;
      notifyListeners();
    }
  }

  /// 切换子网格
  Future<void> switchSubGrid(int index) async {
    _currentSubGridIndex = index;
    notifyListeners();

    // 如果处于自动候选模式且游戏正在进行中，重新计算候选数
    if (gameState.isAutoMarkMode && isPlaying) {
      await autoMarkCandidates(visibleSubBoards: [index]);
    }
  }

  /// 创建初始游戏状态（静态方法）
  static GameState<B> _createInitialState<B extends Board>(
    B emptyBoard,
    List<List<int>>? regionMatrix,
  ) {
    final history = HistoryManager(initialBoard: emptyBoard);
    final stats = SessionStatistics(
      board: emptyBoard,
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

    return GameState<B>(
      board: emptyBoard,
      initialBoard: emptyBoard,
      solution: emptyBoard,
      difficulty: Difficulty.medium.name,
      history: history,
      stats: stats,
    );
  }

  /// 获取当前难度的最佳成绩（从缓存）
  BestScoreRecord? get cachedBestScore => _cachedBestScore;

  /// 获取最佳成绩的显示时间
  String? get bestScoreDisplayTime {
    if (!isBestScoreLoaded) return null;
    final score = _cachedBestScore;
    if (score == null || score.time <= 0) return null;
    return GameUtils.formatTime(score.time);
  }

  /// 获取最佳成绩的错误数（无记录时返回 null）
  int? get bestScoreMistakes => _cachedBestScore?.mistakes;

  /// 加载指定难度的最佳成绩
  @override
  Future<void> loadBestScore([String? difficulty]) async {
    try {
      final targetDifficulty = difficulty ?? gameState.difficulty;
      if (targetDifficulty.isEmpty) {
        _cachedBestScore = null;
        isBestScoreLoaded = true;
        notifyListeners();
        return;
      }
      final stats = await StatisticsManager.getGameStatistics(gameService.gameType);
      final difficultyStats = stats.difficultyStats[targetDifficulty];
      _cachedBestScore = difficultyStats?.bestScoreRecord;
      isBestScoreLoaded = true;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('加载最佳成绩失败: $e\n$st');
      _cachedBestScore = null;
      isBestScoreLoaded = true;
      notifyListeners();
    }
  }

  // Mixin 需要的 getter/setter 实现
  @override
  GameState<B> get gameState => _gameState;

  @override
  set gameState(GameState<B> value) {
    _gameState = value;
  }

  /// 游戏状态
  GameState<B> _gameState;

  /// 获取泛型游戏状态
  GameState<B> get state => _gameState;

  @override
  GameTimer get gameTimer => _gameTimer;

  @override
  GameService<B> get gameService => _gameService;

  @override
  AppSettings? get settings => _appSettings;

  @override
  bool get isPlaying => gameState.startTime != null && !gameState.isCompleted;

  @override
  bool get useAdvancedStrategy => _appSettings?.useAdvancedStrategy ?? true;

  @override
  bool get isLoading => _isLoading;

  @override
  set isLoading(bool value) => _isLoading = value;

  @override
  bool get isCancelled => _isCancelled;

  @override
  set isCancelled(bool value) => _isCancelled = value;

  @override
  GenerationStage get generationStage => _generationStage;

  @override
  set generationStage(GenerationStage value) => _generationStage = value;

  /// 获取当前游戏状态
  GameState<B> get currentGameState => gameState;

  /// 更新游戏设置
  void updateSettings(AppSettings settings) {
    _appSettings = settings;
    onSettingsChanged();
    notifyListeners();
  }

  /// 当设置变化时调用
  @protected
  void onSettingsChanged() {
    if (isSamuraiGame) {
      if (gameState.isAutoMarkMode && isPlaying) {
        autoMarkCandidates(visibleSubBoards: [currentSubGridIndex]);
      }
    } else {
      if (gameState.isAutoMarkMode && isPlaying) {
        autoMarkCandidates();
      }
    }
  }

  // ========== 游戏生命周期方法（委托给 Mixin）==========

  /// 开始新游戏
  Future<void> startNewGame(final Difficulty difficulty) =>
      startNewGameInternal(difficulty,
          generateNewGame: generateNewGame,
          resetGameState: resetGameState);

  /// 暂停游戏
  Future<void> pauseGame({bool notify = true}) => pauseGameInternal(notify: notify);

  /// 恢复游戏
  Future<void> resumeGame() => resumeGameInternal();

  /// 保存游戏状态（异步）
  Future<void> saveGame() => saveGameInternal();

  /// 保存游戏状态（同步）
  void saveGameSync() => saveGameFireAndForget();

  /// 加载游戏状态
  Future<void> loadGame() async {
    await loadGameInternal();
    await loadBestScore();
  }

  /// 加载指定的游戏状态
  void loadGameState(GameState<B> state) {
    gameState = state;
    gameTimer.setElapsedTime(state.elapsedTime);
    if (state.startTime != null && !state.isCompleted) {
      gameTimer.start();
    }
    notifyListeners();
    loadBestScore();
  }

  /// 取消游戏生成
  void cancelGameGeneration() => cancelGameGenerationInternal();

  // ========== 单元格操作方法（委托给 Mixin）==========

  /// 处理单元格点击
  @override
  Future<void> handleCellTap(final int row, final int col) async {
    if (!isPlaying) return;
    try {
      handleCellSelection(row, col);
      notifyListeners();
    } catch (e) {
      _handleError('处理单元格点击失败', e);
    }
  }

  /// 选择单元格
  @override
  void selectCell(final int row, final int col) => handleCellTap(row, col);

  /// 通过 Cell 对象选择单元格
  void selectCellByObject(Cell cell) => handleCellTap(cell.row, cell.col);

  /// 输入数字
  void inputNumber(final int number) {
    final selectedCell = gameState.getSelectedCell();
    if (selectedCell != null) {
      setCellValue(selectedCell.row, selectedCell.col, number);
    }
  }

  /// 设置单元格值
  Future<void> setCellValue(
    final int row,
    final int col,
    final int? value,
  ) async {
    if (!isPlaying) return;
    try {
      await setCellValueInternal(row, col, value);

      // 检查游戏是否完成
      if (gameState.isCompleted) {
        gameTimer.pause();
        if (PlatformDispatcher.instance.implicitView != null) {
          final audioManager = AudioManager();
          await audioManager.playCompleteSound();
        }
      }

      notifyListeners();

      // 自动标记模式下重新计算候选数
      if (gameState.isAutoMarkMode && isPlaying) {
        if (isSamuraiGame) {
          await autoMarkCandidates(visibleSubBoards: [currentSubGridIndex]);
        } else {
          await autoMarkCandidates();
        }
      }

      await saveGame();
    } catch (e) {
      _handleError('设置单元格值失败', e);
    }
  }

  /// 设置当前选中单元格的值
  Future<void> setCellValueByNumber(int? value) async {
    if (!isPlaying) return;
    final selectedCell = gameState.getSelectedCell();
    if (selectedCell != null) {
      if (gameState.isMarkMode && value != null) {
        await toggleCandidate(selectedCell.row, selectedCell.col, value);
      } else {
        await setCellValue(selectedCell.row, selectedCell.col, value);
      }
    }
  }

  /// 切换候选数标记
  Future<void> toggleCandidate(
    final int row,
    final int col,
    final int candidate,
  ) async {
    if (!isPlaying) return;
    try {
      await toggleCandidateInternal(row, col, candidate);
      notifyListeners();
      await saveGame();
    } catch (e) {
      _handleError('切换候选数失败', e);
    }
  }

  /// 清除输入
  Future<void> clearInput() => onClear();

  /// 清除当前选中单元格的值
  Future<void> clearCellValue() async {
    final selectedCell = gameState.getSelectedCell();
    if (selectedCell != null) {
      await clearCellInternal(selectedCell.row, selectedCell.col);
      notifyListeners();

      // 自动标记模式下重新计算候选数
      if (gameState.isAutoMarkMode && isPlaying) {
        if (isSamuraiGame) {
          await autoMarkCandidates(visibleSubBoards: [currentSubGridIndex]);
        } else {
          await autoMarkCandidates();
        }
      }

      await saveGame();
    }
  }

  // ========== 功能键盘相关方法（委托给 Mixin）==========

  /// 是否可以撤销
  bool get canUndo => gameState.history.canUndo();

  /// 是否可以重做
  bool get canRedo => gameState.history.canRedo();

  /// 撤销
  void undo() {
    if (!isPlaying) return;
    gameState = gameService.undo(gameState);
    if (gameState.isAutoMarkMode) {
      autoMarkCandidates();
    }
    notifyListeners();
  }

  /// 重做
  void redo() {
    if (!isPlaying) return;
    gameState = gameService.redo(gameState);
    if (gameState.isAutoMarkMode) {
      autoMarkCandidates();
    }
    notifyListeners();
  }

  /// 提示
  @override
  Future<void> hint() async {
    lastHintMessage = null;
    await super.hint();
    if (lastHintMessage != null) {
      notifyListeners();
    }
  }

  /// 切换标记模式
  @override
  Future<void> toggleMarkMode() async => super.toggleMarkMode();

  /// 切换自动标记模式
  @override
  Future<void> toggleAutoMarkMode() async {
    gameState = gameState.copyWith(isAutoMarkMode: !gameState.isAutoMarkMode);
    notifyListeners();

    if (gameState.isAutoMarkMode && isPlaying) {
      if (isSamuraiGame) {
        await autoMarkCandidates(visibleSubBoards: [currentSubGridIndex]);
      } else {
        await autoMarkCandidates();
      }
    } else if (!gameState.isAutoMarkMode) {
      await clearAllCandidates();
    }
  }

  /// 切换显示答案
  @override
  Future<void> toggleShowSolution() async => super.toggleShowSolution();

  // ========== 核心方法实现 ==========

  /// 生成新游戏
  @protected
  Future<void> generateNewGame(final Difficulty difficulty) async {
    if (isCancelled) return;

    final newState = await gameService.generateGame(
      difficulty: difficulty,
      onStageUpdate: updateGenerationStage,
    );

    gameState = newState;

    if (isSamuraiGame) {
      _currentSubGridIndex = 4; // 默认显示中心网格
      _isOverviewMode = false;
    }

    notifyListeners();

    gameTimer.start();
    unawaited(loadBestScore());
  }

  /// 重置游戏状态
  @protected
  Future<void> resetGameState() async {
    gameState = _createInitialState<B>(_createEmptyBoard(), _regionMatrix);

    if (isSamuraiGame) {
      _currentSubGridIndex = 4; // 默认显示中心网格
      _isOverviewMode = false;
    }

    notifyListeners();
  }

  /// 处理清除操作
  Future<void> onClear() async {
    final selectedCell = gameState.getSelectedCell();
    if (selectedCell == null || selectedCell.isFixed) return;

    if (selectedCell.value != null) {
      await setCellValueInternal(
        selectedCell.row,
        selectedCell.col,
        null,
      );

      if (gameState.isAutoMarkMode && isPlaying) {
        if (isSamuraiGame) {
          await autoMarkCandidates(visibleSubBoards: [currentSubGridIndex]);
        } else {
          await autoMarkCandidates();
        }
      }
    } else if (selectedCell.candidates.isNotEmpty) {
      final command = ClearCandidatesCommand(
        row: selectedCell.row,
        col: selectedCell.col,
      );
      gameState = gameService.updateBoardWithCommand(gameState, command);

      if (gameState.isAutoMarkMode && isPlaying) {
        if (isSamuraiGame) {
          await autoMarkCandidates(visibleSubBoards: [currentSubGridIndex]);
        } else {
          await autoMarkCandidates();
        }
      }
    }
    notifyListeners();
  }

  /// 开始自定义游戏（仅 standard 和 diagonal 支持）
  Future<void> startCustomGame(B initialBoard) async {
    if (_gameType != 'standard' && _gameType != 'diagonal') return;

    final board = initialBoard;
    final solution = initialBoard;
    final history = HistoryManager(initialBoard: board);
    final stats = SessionStatistics(
      board: board,
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

    final newState = GameState<B>(
      board: board,
      initialBoard: initialBoard,
      solution: solution,
      difficulty: Difficulty.custom.name,
      history: history,
      stats: stats,
      startTime: DateTime.now(),
    );
    gameState = newState;
    notifyListeners();
  }

  // ========== 工具方法 ==========

  /// 获取数字使用次数
  int? getNumberCount(int number) {
    if (isSamuraiGame) {
      // Samurai 仅计算当前子网格的数字计数
      final samuraiBoard = gameState.board;
      if (samuraiBoard is SamuraiBoard) {
        final subBoard = samuraiBoard.getSubBoard(currentSubGridIndex);
        int count = 0;
        for (int i = 0; i < subBoard.size; i++) {
          for (int j = 0; j < subBoard.size; j++) {
            if (subBoard.cells[i][j].value == number) {
              count++;
            }
          }
        }
        return count;
      }
    }
    final counts = gameState.board.calculateNumberCounts();
    return counts[number];
  }

  /// 获取本地化的难度字符串
  String getLocalizedDifficulty(BuildContext context) {
    final loc = LocalizationUtils.app(context);
    switch (gameState.difficulty) {
      case 'beginner':
        return loc.difficultyBeginner;
      case 'easy':
        return loc.difficultyEasy;
      case 'medium':
        return loc.difficultyMedium;
      case 'hard':
        return loc.difficultyHard;
      case 'expert':
        return loc.difficultyExpert;
      case 'master':
        return loc.difficultyMaster;
      case 'custom':
        return loc.difficultyCustom;
      default:
        return gameState.difficulty;
    }
  }

  /// 处理错误（内部使用）
  void _handleError(final String message, final Object error) {
    AppLogger.error('$message: $error');
  }

  /// 实现GameAssistMixin需要的抽象方法
  @override
  Future<void> setCellValueForHint(int row, int col, int value) async {
    await setCellValue(row, col, value);
  }

  /// 释放资源
  @override
  void dispose() {
    disposeAutoMarkTimer();
    disposeSaveTimer();
    _gameTimer.dispose();
    super.dispose();
  }
}
