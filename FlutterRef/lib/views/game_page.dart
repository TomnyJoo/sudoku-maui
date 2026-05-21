import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';
import 'package:sudoku/main.dart';
import 'package:sudoku/renderers/layout_calculator.dart';

/// 统一游戏屏幕页面
///
/// 通过构造函数参数接收游戏类型配置，支持所有6种游戏类型
class GameScreen<B extends Board> extends StatefulWidget {
  const GameScreen({
    super.key,
    this.autoLoadSavedGame = true,
  });
  final bool autoLoadSavedGame;

  @override
  State<GameScreen<B>> createState() => GameScreenState<B>();
}

class GameScreenState<B extends Board> extends State<GameScreen<B>>
    with WidgetsBindingObserver {
  late GameViewModel<B> _viewModel;

  // Diagonal 特有状态
  bool _showDiagonalLines = true;

  // Jigsaw 特有状态
  bool _showRegionNumbers = true;

  bool _hasNavigatedToFinish = false;

  bool get _isDiagonalGame => _viewModel.gameService.gameType == 'diagonal';
  bool get _isJigsawGame => _viewModel.gameService.gameType == 'jigsaw';
  bool get _isSamuraiGame => _viewModel.gameService.gameType == 'samurai';

  String get _gameType => _viewModel.gameService.gameType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appSettings = context.read<AppSettings>();
      final audioManager = AudioManager()
        ..setMusicEnabled(appSettings.musicEnabled);
      if (appSettings.musicEnabled && !audioManager.isMusicPlaying) {
        audioManager.playMusic();
      }
    });
    _viewModel = Provider.of<GameViewModel<B>>(context, listen: false);
    _viewModel.addListener(_onGameStateChanged);
    _hasNavigatedToFinish = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNavigation();
    });
  }

  void _handleInitialNavigation() {
    final args = ModalRoute.of(context)?.settings.arguments;

    // 如果参数是 GameState，直接使用该状态（从保存游戏列表加载）
    if (args is GameState<B>) {
      _viewModel.loadGameState(args);
      return;
    }

    // 如果参数是 Difficulty，开始新游戏（兼容旧方式）
    if (args is Difficulty) {
      _viewModel.startNewGame(args);
      return;
    }

    // 如果参数是 GameRouteArgs，提取 gameType 信息
    if (args is GameRouteArgs) {
      if (args.initialState != null && args.initialState is GameState<B>) {
        _viewModel.loadGameState(args.initialState as GameState<B>);
        return;
      }
      if (args.difficulty != null) {
        _viewModel.startNewGame(args.difficulty!);
        return;
      }
    }

    // 如果没有参数，尝试加载保存的游戏
    if (widget.autoLoadSavedGame) {
      _loadSavedGame();
    }
  }

  Future<void> _loadSavedGame() async {
    await _viewModel.loadGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _viewModel.saveGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onGameStateChanged);
    _viewModel.saveGameSync();
    _viewModel.pauseGame(notify: false);
    super.dispose();
  }

  // ========== 标题和路由配置 ==========

  String _getTitle(BuildContext context) {
    final gameLocalizations = LocalizationUtils.game(context);
    switch (_gameType) {
      case 'standard':
        return gameLocalizations.gameTypeStandardName;
      case 'diagonal':
        return gameLocalizations.gameTypeDiagonalName;
      case 'window':
        return gameLocalizations.gameTypeWindowName;
      case 'jigsaw':
        return gameLocalizations.gameTypeJigsawName;
      case 'killer':
        return gameLocalizations.gameTypeKillerName;
      case 'samurai':
        return gameLocalizations.gameTypeSamuraiName;
      default:
        return '';
    }
  }

  String get _settingsRoute => AppConstants.settingsRoute;

  // ========== 构建方法 ==========

  @override
  Widget build(BuildContext context) => Consumer<GameViewModel<B>>(
      builder: (context, viewModel, child) {
        final navigator = Navigator.of(context);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _viewModel.saveGame().then((_) {
                if (mounted) {
                  navigator.pop();
                }
              });
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;

              final gameAreaWidth = availableWidth;
              final gameAreaHeight = availableHeight - kToolbarHeight - AppConstants.gameAreaHeightOffset;

              final layout = LayoutCalculator.calculateStandardLayout(Size(gameAreaWidth, gameAreaHeight));

              final isDarkMode = context.isDarkMode;
              final iconColor = isDarkMode ? Colors.white.withAlpha(200) : AppColors.mutedText;

              return Scaffold(
                appBar: !layout.isHorizontalLayout
                    ? AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDarkMode
                                  ? AppColors.homeBackgroundGradientDark
                                  : AppColors.homeBackgroundGradientLight,
                            ),
                          ),
                        ),
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back, color: iconColor),
                          onPressed: () async {
                            await _viewModel.saveGame();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        title: _buildTitle(context),
                        foregroundColor: iconColor,
                        actions: [
                          ...?_buildTitleActions(context),
                          IconButton(
                            icon: Icon(Icons.help_outline, color: iconColor),
                            onPressed: _showGameRules,
                          ),
                          IconButton(
                            icon: Icon(Icons.settings, color: iconColor),
                            onPressed: () => _showSettings(context),
                          ),
                        ],
                      )
                    : null,
                body: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDarkMode
                          ? AppColors.homeBackgroundGradientDark
                          : AppColors.homeBackgroundGradientLight,
                    ),
                  ),
                  child: _buildGameLayout(
                    context,
                    availableWidth,
                    availableHeight,
                    layout,
                  ),
                ),
              );
            },
          ),
        );
      },
    );

  Widget _buildTitle(BuildContext context, {bool isPortrait = true}) => Text(
      _getTitle(context),
      style: TextStyle(
        fontSize: isPortrait ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: isPortrait ? null : (context.isDarkMode ? Colors.white : Colors.black87),
      ),
    );

  /// 构建标题栏的额外操作按钮
  List<Widget>? _buildTitleActions(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final iconColor = isDarkMode ? Colors.white.withAlpha(200) : AppColors.mutedText;

    if (_isDiagonalGame) {
      final diagonalIconColor = _showDiagonalLines
          ? context.primaryColor
          : iconColor;
      return [
        IconButton(
          icon: Icon(
            _showDiagonalLines ? Icons.show_chart : Icons.show_chart_outlined,
            color: diagonalIconColor,
          ),
          onPressed: () {
            setState(() {
              _showDiagonalLines = !_showDiagonalLines;
            });
          },
          tooltip: _showDiagonalLines
              ? LocalizationUtils.app(context).hideDiagonalLines
              : LocalizationUtils.app(context).showDiagonalLines,
        ),
      ];
    }

    if (_isJigsawGame) {
      final jigsawIconColor = _showRegionNumbers
          ? context.primaryColor
          : iconColor;
      return [
        IconButton(
          icon: Icon(
            _showRegionNumbers ? Icons.grid_on : Icons.grid_off,
            color: jigsawIconColor,
          ),
          onPressed: () {
            setState(() {
              _showRegionNumbers = !_showRegionNumbers;
            });
          },
          tooltip: _showRegionNumbers
              ? LocalizationUtils.app(context).hideRegionNumbers
              : LocalizationUtils.app(context).showRegionNumbers,
        ),
      ];
    }

    if (_isSamuraiGame) {
      return _buildSamuraiTitleActions(context, iconColor);
    }

    return null;
  }

  /// 构建 Samurai 子网格导航按钮
  List<Widget> _buildSamuraiTitleActions(BuildContext context, Color iconColor) {
    final subGridNames = LocalizationUtils.app(context).subGridNames;
    final currentIndex = _viewModel.currentSubGridIndex;

    return [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final prevIndex = (currentIndex - 1 + 5) % 5;
                    await _viewModel.switchSubGrid(prevIndex);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: iconColor.withAlpha(200),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  subGridNames[currentIndex],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor.withAlpha(200),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final nextIndex = (currentIndex + 1) % 5;
                    await _viewModel.switchSubGrid(nextIndex);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: iconColor.withAlpha(200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 4),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewModel.toggleOverviewMode(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _viewModel.isOverviewMode
                  ? iconColor.withAlpha(50)
                  : iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _viewModel.isOverviewMode ? Icons.zoom_in : Icons.zoom_out_map,
              size: 18,
              color: iconColor.withAlpha(200),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGameLayout(
    BuildContext context,
    double availableWidth,
    double availableHeight,
    GameLayout layout,
  ) {
    final viewModel = Provider.of<GameViewModel<B>>(context);
    if (viewModel.isLoading) {
      return _buildLoadingIndicator(context);
    }

    if (layout.isHorizontalLayout) {
      return Column(
        children: [
          _buildTopToolbar(context),
          _buildStatsBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  _buildHorizontalGameArea(context, layout, constraints),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildStatsBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  _buildVerticalGameArea(context, layout, constraints),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTopToolbar(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
      decoration: BoxDecoration(
        color: context.cardColor.withAlpha(180),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () async {
              await _viewModel.saveGame();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: AppConstants.spacingStandard),
          _buildTitle(context, isPortrait: false),
          const Spacer(),
          ...?_buildTitleActions(context),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _showGameRules,
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final responsiveBorderRadius = ResponsiveLayout.getResponsiveBorderRadius(context);
    final _ = Provider.of<AppSettings>(context);

    final statItems = <Widget>[
      _buildStatItem(
        Icons.timer,
        GameUtils.formatTime(_viewModel.currentGameState.elapsedTime),
        context.infoColor,
      ),
      _buildStatItem(
        Icons.warning_amber,
        _viewModel.errorCount.toString(),
        context.errorColor,
      ),
      _buildStatItem(
        Icons.star_half,
        _viewModel.getLocalizedDifficulty(context),
        context.warningColor,
      ),
      _buildStatItem(
        Icons.emoji_events,
        _viewModel.bestScoreDisplayTime ??
            GameUtils.formatTime(_viewModel.currentGameState.elapsedTime),
        Colors.amber,
      ),
    ];

    // Samurai 概览模式额外提示
    if (_isSamuraiGame && _viewModel.isOverviewMode) {
      statItems.add(
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  LocalizationUtils.app(context).tapSubGridToEdit,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.getResponsivePadding(context) * 0.8,
        vertical: AppConstants.spacingMedium,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMedium, horizontal: AppConstants.spacingStandard),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  context.primaryColor.withAlpha(51),
                  context.primaryColor.withAlpha(26),
                ]
              : [Colors.white.withAlpha(38), Colors.white.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        border: Border.all(
          color: isDarkMode
              ? context.borderColor.withAlpha(102)
              : Colors.white.withAlpha(51),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: statItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Row(
              children: [
                item,
                if (index < statItems.length - 1)
                  const SizedBox(width: AppConstants.spacingLarge),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    Color color,
  ) {
    final isDarkMode = context.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSmall),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppConstants.statsIconSize, color: color),
        ),
        const SizedBox(width: AppConstants.iconTextSpacing),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(14, context),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ========== 棋盘构建 ==========

  Widget _buildBoard(BuildContext context, GameViewModel<B> viewModel, double cellSize) {
    if (_isSamuraiGame) {
      return _buildSamuraiBoard(context, viewModel, cellSize);
    }

    return UnifiedBoardWidget(
      board: viewModel.state.board,
      onCellSelected: (Cell cell) => viewModel.selectCellByObject(cell),
      cellSize: cellSize,
      showDiagonalLines: _showDiagonalLines,
      showRegionNumbers: _showRegionNumbers,
    );
  }

  Widget _buildSamuraiBoard(BuildContext context, GameViewModel<B> viewModel, double cellSize) {
    final samuraiBoard = viewModel.state.board;
    final samuraiSolution = viewModel.state.solution;

    if (viewModel.isOverviewMode && samuraiBoard is SamuraiBoard && samuraiSolution is SamuraiBoard) {
      return SamuraiOverviewBoard(
        board: samuraiBoard,
        solution: samuraiSolution,
        isShowingSolution: viewModel.state.isShowingSolution,
        onCellSelected: (Cell cell) => viewModel.selectCellByObject(cell),
        currentSubGridIndex: viewModel.currentSubGridIndex,
        cellSize: cellSize * 0.6,
        onSubGridSelected: (int index) async {
          await viewModel.switchSubGrid(index);
          viewModel.exitOverviewMode();
        },
      );
    }

    return _SwipeableSamuraiBoard<B>(
      viewModel: viewModel,
      cellSize: cellSize,
    );
  }

  // ========== 数字键盘和功能键盘 ==========

  Widget _buildNumberKeyboard(BuildContext context, GameViewModel<B> viewModel, double buttonSize) => NumberKeyboard(
      onNumberSelected: (int? number) {
        if (number != null) {
          viewModel.setCellValueByNumber(number);
        }
      },
      buttonSize: buttonSize,
      getNumberCount: (context, number) => viewModel.getNumberCount(number),
    );

  Widget _buildFunctionKeyboard(BuildContext context, GameViewModel<B> viewModel, double buttonSize) => FunctionKeyboard(
      onUndo: viewModel.undo,
      onRedo: viewModel.redo,
      onHint: () => viewModel.hint(),
      onMark: viewModel.toggleMarkMode,
      onErase: viewModel.clearCellValue,
      onReset: viewModel.resetGame,
      onAutoMark: viewModel.toggleAutoMarkMode,
      onSolution: viewModel.toggleShowSolution,
      onNew: () {
        confirmNewGame(context, viewModel);
      },
      buttonSize: buttonSize,
      isMarkMode: () => viewModel.currentGameState.isMarkMode,
      isAutoMarkMode: () => viewModel.currentGameState.isAutoMarkMode,
      canUndo: () => viewModel.canUndo,
      canRedo: () => viewModel.canRedo,
      isShowingSolution: () => viewModel.currentGameState.isShowingSolution,
    );

  // ========== 游戏区域布局 ==========

  Widget _buildHorizontalGameArea(
    BuildContext context,
    GameLayout layout,
    BoxConstraints constraints,
  ) {
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;
    final viewModel = Provider.of<GameViewModel<B>>(context);

    return Stack(
      children: [
        Positioned(
          left: (availableWidth - layout.boardSize - LayoutCalculator.spacing - layout.keypadWidth) / 2,
          top: (availableHeight - layout.boardSize) / 2,
          child: SizedBox(
            width: layout.boardSize,
            height: layout.boardSize,
            child: _buildBoard(context, viewModel, layout.boardCellSize),
          ),
        ),
        Positioned(
          left: (availableWidth - layout.boardSize - LayoutCalculator.spacing - layout.keypadWidth) / 2 + layout.boardSize + LayoutCalculator.spacing,
          top: (availableHeight - layout.keypadHeight) / 2,
          child: SizedBox(
            width: layout.keypadWidth,
            height: layout.keypadHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: layout.keypadHeight / 2,
                  child: _buildNumberKeyboard(context, viewModel, layout.keypadCellSize),
                ),
                SizedBox(
                  height: layout.keypadHeight / 2,
                  child: _buildFunctionKeyboard(context, viewModel, layout.keypadCellSize),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalGameArea(
    BuildContext context,
    GameLayout layout,
    BoxConstraints constraints,
  ) {
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;
    final viewModel = Provider.of<GameViewModel<B>>(context);

    return Stack(
      children: [
        Positioned(
          left: (availableWidth - layout.boardSize) / 2,
          top: (availableHeight - layout.boardSize - LayoutCalculator.spacing - layout.keypadHeight) / 2,
          child: SizedBox(
            width: layout.boardSize,
            height: layout.boardSize,
            child: _buildBoard(context, viewModel, layout.boardCellSize),
          ),
        ),
        Positioned(
          left: (availableWidth - layout.keypadWidth) / 2,
          top: (availableHeight - layout.boardSize - LayoutCalculator.spacing - layout.keypadHeight - LayoutCalculator.keypadBottomMargin) / 2 + layout.boardSize + LayoutCalculator.spacing,
          child: SizedBox(
            width: layout.keypadWidth,
            height: layout.keypadHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: layout.keypadWidth / 2,
                  child: _buildNumberKeyboard(context, viewModel, layout.keypadCellSize),
                ),
                SizedBox(
                  width: layout.keypadWidth / 2,
                  child: _buildFunctionKeyboard(context, viewModel, layout.keypadCellSize),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== 游戏状态变化处理 ==========

  void _onGameStateChanged() {
    if (_viewModel.currentGameState.isCompleted && !_viewModel.showSolution && !_hasNavigatedToFinish) {
      _hasNavigatedToFinish = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider<GameViewModel<B>>.value(
                value: _viewModel,
                child: _createFinishScreen(),
              ),
            ),
          );
        }
      });
    }
  }

  Widget _createFinishScreen() {
    switch (_gameType) {
      case 'standard':
        return _buildFinishScreen<StandardBoard>(
          boardFromJson: StandardBoard.fromJson,
        );
      case 'diagonal':
        return _buildFinishScreen<DiagonalBoard>(
          boardFromJson: DiagonalBoard.fromJson,
        );
      case 'window':
        return _buildFinishScreen<WindowBoard>(
          boardFromJson: WindowBoard.fromJson,
        );
      case 'jigsaw':
        return _buildFinishScreen<JigsawBoard>(
          boardFromJson: JigsawBoard.fromJson,
        );
      case 'killer':
        return _buildFinishScreen<KillerBoard>(
          boardFromJson: KillerBoard.fromJson,
        );
      case 'samurai':
        return _buildFinishScreen<SamuraiBoard>(
          boardFromJson: SamuraiBoard.fromJson,
        );
      default:
        return _buildFinishScreen<StandardBoard>(
          boardFromJson: StandardBoard.fromJson,
        );
    }
  }

  /// 通用 FinishScreen 工厂方法
  Widget _buildFinishScreen<T extends Board>({
    required T Function(Map<String, dynamic>) boardFromJson,
  }) => FinishScreen<GameViewModel<T>, GameService<T>, T>(
      gameType: _gameType,
      getViewModel: (ctx) => ctx.read<GameViewModel<T>>(),
      getGameService: (ctx) => GameService<T>(
        gameType: _gameType,
        validator: GameValidator(),
        boardFromJson: boardFromJson,
      ),
    );

  // ========== 对话框 ==========

  void _showSettings(BuildContext context) {
    Navigator.pushNamed(context, _settingsRoute);
  }

  void _showGameRules() {
    final appLocalizations = LocalizationUtils.app(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gameLocalizations = LocalizationUtils.game(context);
    final rules = GameType.values.map((gameType) {
      try {
        final name = gameType.getLocalizedName(gameLocalizations);
        final description = gameType.getLocalizedDescription(gameLocalizations);
        return (name, description);
      } catch (e) {
        return (gameType.toString().split('.').last, '');
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        title: Text(
          appLocalizations.gameRules,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < rules.length; i++) ...[
                if (i > 0) const SizedBox(height: AppConstants.spacingStandard),
                _buildRuleSection(
                  context,
                  rules[i].$1,
                  rules[i].$2,
                ),
              ],
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.ok),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(
    BuildContext context,
    String title,
    String description,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode ? Colors.white : AppColors.darkText;
    final descriptionColor = isDarkMode
        ? Colors.white.withAlpha(200)
        : AppColors.mutedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: titleColor,
          ),
        ),
        const SizedBox(height: AppConstants.iconTextSpacing),
        Text(
          description,
          style: TextStyle(fontSize: 13, color: descriptionColor, height: 1.4),
        ),
      ],
    );
  }

  void confirmNewGame(BuildContext context, GameViewModel<B> gameVM) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.cardColor,
        title: Text(
          LocalizationUtils.app(dialogContext).newGameConfirm,
        ),
        content: Text(
          LocalizationUtils.app(dialogContext).newGameConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocalizationUtils.app(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final difficulty = GameUtils.getDifficultyFromIdentifier(gameVM.currentGameState.difficulty);
              if (difficulty != null) {
                showLoadingDialog(context, () => gameVM.startNewGame(difficulty), gameVM);
              }
            },
            child: Text(LocalizationUtils.app(dialogContext).ok),
          ),
        ],
      ),
    );
  }

  /// 显示游戏生成加载对话框
  static void showGameLoadingDialog({
    required BuildContext dialogContext,
    required BuildContext dismissContext,
    required Future<void> Function() onGenerate,
    required GameViewModel viewModel,
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AnimatedBuilder(
          animation: viewModel,
          builder: (context, child) {
            String progressText = '';
            final customProgress = GameUtils.getProgressText(context, viewModel.generationStage);
            if (customProgress != null) {
              progressText = customProgress;
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppConstants.spacingExtraLarge),
                  Text(
                    LocalizationUtils.app(context).generatingGame,
                    style: const TextStyle(fontSize: AppTextStyles.fontSizeBody),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  if (progressText.isNotEmpty)
                    Text(
                      progressText,
                      style: const TextStyle(fontSize: AppTextStyles.fontSizeLabel),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    viewModel.cancelGameGeneration();
                    Navigator.of(context).pop();
                  },
                  child: Text(LocalizationUtils.app(context).cancel),
                ),
              ],
            );
          },
        ),
      ),
    );

    onGenerate().then((_) {
      if (dismissContext.mounted) {
        Navigator.of(dismissContext).pop();
        if (onSuccess != null) {
          onSuccess();
        }
      }
    }).catchError((error) {
      if (dismissContext.mounted) {
        Navigator.of(dismissContext).pop();
        showDialog(
          context: dismissContext,
          barrierDismissible: false,
          builder: (errorDialogContext) => AlertDialog(
            backgroundColor: Theme.of(errorDialogContext).cardColor,
            title: Text(LocalizationUtils.app(errorDialogContext).generationFailedTitle),
            content: Text(
              '${LocalizationUtils.app(errorDialogContext).generationFailedMessage}\n\n${LocalizationUtils.app(errorDialogContext).generationFailedError(error.toString())}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(errorDialogContext).pop();
                  if (dismissContext.mounted) {
                    Navigator.of(dismissContext).pop();
                  }
                },
                child: Text(LocalizationUtils.app(errorDialogContext).okButton),
              ),
            ],
          ),
        );
      }
    });
  }

  void showLoadingDialog(
    BuildContext context,
    Future<void> Function() onGenerate,
    GameViewModel<B> viewModel, [
    VoidCallback? onSuccess,
  ]) {
    showGameLoadingDialog(
      dialogContext: context,
      dismissContext: this.context,
      onGenerate: onGenerate,
      viewModel: viewModel,
      onSuccess: onSuccess,
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) => AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        String progressText = '';
        final customProgress = GameUtils.getProgressText(context, _viewModel.generationStage);
        if (customProgress != null) {
          progressText = customProgress;
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
              const SizedBox(height: AppConstants.spacingHuge),
              Text(
                LocalizationUtils.app(context).generatingGame,
                style: TextStyle(
                  fontSize: AppTextStyles.fontSizeBody,
                  color: context.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              if (progressText.isNotEmpty)
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: AppTextStyles.fontSizeLabel,
                    fontWeight: FontWeight.w500,
                    color: context.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              const SizedBox(height: AppConstants.spacingMaximum),
              ElevatedButton.icon(
                onPressed: () {
                  _viewModel.cancelGameGeneration();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: Text(
                  LocalizationUtils.app(context).cancel,
                  style: const TextStyle(
                    fontSize: AppTextStyles.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMaximum, vertical: AppConstants.spacingLarge),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.spacingHuge),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
}

/// 支持滑动手势的武士数独棋盘组件
class _SwipeableSamuraiBoard<B extends Board> extends StatefulWidget {
  const _SwipeableSamuraiBoard({
    required this.viewModel,
    required this.cellSize,
  });
  final GameViewModel<B> viewModel;
  final double cellSize;

  @override
  State<_SwipeableSamuraiBoard<B>> createState() => _SwipeableSamuraiBoardState<B>();
}

class _SwipeableSamuraiBoardState<B extends Board> extends State<_SwipeableSamuraiBoard<B>> {
  static const double _swipeThreshold = 50.0;

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final currentIndex = widget.viewModel.currentSubGridIndex;

    if (details.primaryVelocity != null) {
      if (details.primaryVelocity! < -_swipeThreshold) {
        final nextIndex = (currentIndex + 1) % 5;
        await widget.viewModel.switchSubGrid(nextIndex);
      } else if (details.primaryVelocity! > _swipeThreshold) {
        final prevIndex = (currentIndex - 1 + 5) % 5;
        await widget.viewModel.switchSubGrid(prevIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: SamuraiBoardWidget(
        board: widget.viewModel.state.board as SamuraiBoard,
        solution: widget.viewModel.state.solution as SamuraiBoard,
        isShowingSolution: widget.viewModel.state.isShowingSolution,
        currentSubGridIndex: widget.viewModel.currentSubGridIndex,
        onCellSelected: (Cell cell) => widget.viewModel.selectCellByObject(cell),
        cellSize: widget.cellSize,
      ),
    );
}
