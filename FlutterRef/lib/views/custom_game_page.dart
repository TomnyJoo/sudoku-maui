import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';
import 'package:sudoku/renderers/layout_calculator.dart';

class CustomGameScreen<
  TBoard extends Board,
  TViewModel extends GameViewModel<TBoard>
>
    extends StatefulWidget {
  const CustomGameScreen({
    required this.initializeBoard,
    required this.createBoard,
    required this.buildBoardWidget,
    required this.minFilledCells,
    required this.boardSize,
    required this.boxSize,
    required this.maxSolutionsToCheck,
    required this.getViewModel,
    required this.getGameScreen,
    required this.isValidPlacementForSolver,
    super.key,
  });

  final void Function(List<List<Cell>>) initializeBoard;
  final TBoard Function(List<List<Cell>>) createBoard;
  final Widget Function(TBoard, Function(Cell), double) buildBoardWidget;
  final int minFilledCells;
  final int boardSize;
  final int boxSize;
  final int maxSolutionsToCheck;
  final TViewModel Function(BuildContext) getViewModel;
  final Widget Function() getGameScreen;
  final bool Function(List<List<int>>, int, int, int) isValidPlacementForSolver;

  @override
  CustomGameScreenState<TBoard, TViewModel> createState() =>
      CustomGameScreenState<TBoard, TViewModel>();
}

class CustomGameScreenState<
  TBoard extends Board,
  TViewModel extends GameViewModel<TBoard>
>
    extends State<CustomGameScreen<TBoard, TViewModel>> {
  late List<List<Cell>> _board;
  Cell? _selectedCell;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    _board = List.generate(
      widget.boardSize,
      (final row) => List.generate(
        widget.boardSize,
        (final col) => Cell(row: row, col: col),
      ),
    );
    widget.initializeBoard(_board);
  }

  TBoard createBoard(List<List<Cell>> cells) => widget.createBoard(cells);
  Widget buildBoardWidget(
    TBoard board,
    Function(Cell) onCellSelected,
    double cellSize,
  ) => widget.buildBoardWidget(board, onCellSelected, cellSize);
  
  int get minFilledCells => widget.minFilledCells;
  int get boardSize => widget.boardSize;
  int get boxSize => widget.boxSize;
  int get maxSolutionsToCheck => widget.maxSolutionsToCheck;
  TViewModel getViewModel(BuildContext context) => widget.getViewModel(context);
  Widget getGameScreen() => widget.getGameScreen();
  bool _isValidPlacementForSolver(
    List<List<int>> board,
    int row,
    int col,
    int num,
  ) => widget.isValidPlacementForSolver(board, row, col, num);

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final context, final constraints) {
      final availableWidth = constraints.maxWidth;
      final availableHeight = constraints.maxHeight;
      final isDarkMode = context.isDarkMode;

      final isHorizontalLayout = availableWidth >= availableHeight;

      final gameAreaWidth = availableWidth;
      final gameAreaHeight = isHorizontalLayout
          ? availableHeight - kToolbarHeight
          : availableHeight - kToolbarHeight - 60;

      final layout = LayoutCalculator.calculateStandardLayout(
        Size(gameAreaWidth, gameAreaHeight),
      );

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
                foregroundColor: isDarkMode ? Colors.white : AppColors.darkText,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : AppColors.darkText),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(LocalizationUtils.app(context).customGame),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : AppColors.darkText),
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
  );

  Widget _buildGameLayout(
    final BuildContext context,
    final double availableWidth,
    final double availableHeight,
    final GameLayout layout,
  ) {
    if (layout.isHorizontalLayout) {
      return _buildHorizontalLayout(context, layout);
    } else {
      return _buildVerticalLayout(context, layout);
    }
  }

  Widget _buildHorizontalLayout(
    final BuildContext context,
    final GameLayout layout,
  ) => Column(
    children: [
      Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.cardColor.withAlpha(180),
          border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(51))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationUtils.app(context).customGame,
              style: TextStyle(
                fontSize: AppTextStyles.fontSizeButton,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            _buildInstructionsRow(),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (final context, final constraints) =>
              _buildHorizontalGameArea(context, layout, constraints),
        ),
      ),
    ],
  );

  Widget _buildVerticalLayout(
    final BuildContext context,
    final GameLayout layout,
  ) => Column(
    children: [
      _buildInstructionsBar(),
      Expanded(
        child: LayoutBuilder(
          builder: (final context, final constraints) =>
              _buildVerticalGameArea(context, layout, constraints),
        ),
      ),
    ],
  );

  Widget _buildInstructionsBar() {
    final isDarkMode = context.isDarkMode;
    final responsiveBorderRadius = ResponsiveLayout.getResponsiveBorderRadius(
      context,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInstructionItem(
            Icons.touch_app,
            LocalizationUtils.app(context).customGameInstruction1,
          ),
          const SizedBox(width: 16),
          _buildInstructionItem(
            Icons.dialpad,
            LocalizationUtils.app(context).customGameInstruction2,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsRow() {
    final localization = LocalizationUtils.app(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 500; // 减小判断阈值

    if (isNarrowScreen) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionItem(
            Icons.touch_app,
            localization.customGameInstruction1,
          ),
          const SizedBox(height: 8),
          _buildInstructionItem(
            Icons.dialpad,
            localization.customGameInstruction2,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInstructionItem(
            Icons.touch_app,
            localization.customGameInstruction1,
          ),
          const SizedBox(width: 16),
          _buildInstructionItem(
            Icons.dialpad,
            localization.customGameInstruction2,
          ),
        ],
      );
    }
  }

  Widget _buildInstructionItem(final IconData icon, final String text) =>
      Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: context.primaryColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: AppTextStyles.fontSizeLabel,
                  color: context.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildHorizontalGameArea(
    final BuildContext context,
    final GameLayout layout,
    final BoxConstraints constraints,
  ) {
    final board = createBoard(_board);
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    return Stack(
      children: [
        Positioned(
          left:
              (availableWidth -
                  layout.boardSize -
                  LayoutCalculator.spacing -
                  layout.keypadWidth) /
              2,
          top: (availableHeight - layout.boardSize) / 2,
          child: SizedBox(
            width: layout.boardSize,
            height: layout.boardSize,
            child: buildBoardWidget(
              board,
              _onCellSelected,
              layout.boardCellSize,
            ),
          ),
        ),
        Positioned(
          left:
              (availableWidth -
                      layout.boardSize -
                      LayoutCalculator.spacing -
                      layout.keypadWidth) /
                  2 +
              layout.boardSize +
              LayoutCalculator.spacing,
          top: (availableHeight - layout.keypadHeight) / 2,
          child: SizedBox(
            width: layout.keypadWidth,
            height: layout.keypadHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: layout.keypadHeight / 2,
                  child: CustomFunKeyboard(
                    onStartGame: _validateAndStartGame,
                    onClearBoard: _showClearConfirmDialog,
                    isValidating: _isValidating,
                    buttonSize: layout.keypadCellSize,
                  ),
                ),
                SizedBox(
                  height: layout.keypadHeight / 2,
                  child: NumberKeyboard(
                    onNumberSelected: _onNumberSelected,
                    buttonSize: layout.keypadCellSize,
                    getNumberCount: (context, number) {
                      final counts = board.calculateNumberCounts();
                      return counts[number];
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalGameArea(
    final BuildContext context,
    final GameLayout layout,
    final BoxConstraints constraints,
  ) {
    final board = createBoard(_board);
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    return Stack(
      children: [
        Positioned(
          left: (availableWidth - layout.boardSize) / 2,
          top:
              (availableHeight -
                  layout.boardSize -
                  LayoutCalculator.spacing -
                  layout.keypadHeight) /
              2,
          child: SizedBox(
            width: layout.boardSize,
            height: layout.boardSize,
            child: buildBoardWidget(
              board,
              _onCellSelected,
              layout.boardCellSize,
            ),
          ),
        ),
        Positioned(
          left: (availableWidth - layout.keypadWidth) / 2,
          top:
              (availableHeight -
                      layout.boardSize -
                      LayoutCalculator.spacing -
                      layout.keypadHeight -
                      LayoutCalculator.keypadBottomMargin) /
                  2 +
              layout.boardSize +
              LayoutCalculator.spacing,
          child: SizedBox(
            width: layout.keypadWidth,
            height: layout.keypadHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: layout.keypadWidth / 2,
                  child: CustomFunKeyboard(
                    onStartGame: _validateAndStartGame,
                    onClearBoard: _showClearConfirmDialog,
                    isValidating: _isValidating,
                    buttonSize: layout.keypadCellSize,
                  ),
                ),
                SizedBox(
                  width: layout.keypadWidth / 2,
                  child: NumberKeyboard(
                    onNumberSelected: _onNumberSelected,
                    buttonSize: layout.keypadCellSize,
                    getNumberCount: (context, number) {
                      final counts = board.calculateNumberCounts();
                      return counts[number];
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onCellSelected(final Cell cell) {
    setState(() {
      _selectedCell = cell;
      _updateSelection();
    });
  }

  void _onNumberSelected(final int? number) {
    if (_selectedCell == null) return;
    setState(() {
      final row = _selectedCell!.row;
      final col = _selectedCell!.col;
      if (_board[row][col].value == number) {
        _board[row][col] = _board[row][col].clear();
      } else {
        _board[row][col] = _board[row][col].setValue(number);
      }
      _updateSelection();
    });
  }

  void _updateSelection() {
    final selectedValue = _selectedCell != null
        ? _board[_selectedCell!.row][_selectedCell!.col].value
        : null;
    _board = _board
        .map(
          (final row) => row
              .map(
                (final cell) => cell.copyWith(
                  isSelected:
                      _selectedCell != null &&
                      cell.row == _selectedCell!.row &&
                      cell.col == _selectedCell!.col,
                  isHighlighted:
                      selectedValue != null && cell.value == selectedValue,
                ),
              )
              .toList(),
        )
        .toList();
  }

  void _showClearConfirmDialog() {
    final localization = LocalizationUtils.app(context);
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(localization.clearBoard),
        content: Text(localization.clearBoardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initializeBoard();
                _selectedCell = null;
              });
            },
            child: Text(localization.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndStartGame() async {
    final localization = LocalizationUtils.app(context);
    final validator = GameValidator();

    if (_isValidating) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final filledCells = _board
          .expand((final row) => row)
          .where((final cell) => cell.value != null)
          .length;

      if (filledCells < minFilledCells) {
        _showErrorDialog(localization.customGameErrorTooFew);
        setState(() {
          _isValidating = false;
        });
        return;
      }

      final tempBoard = createBoard(_board);
      if (!validator.validateBoard(tempBoard)) {
        _showErrorDialog(localization.customGameErrorInvalid);
        setState(() {
          _isValidating = false;
        });
        return;
      }

      final hasUniqueSolution = await _checkUniqueSolution();

      if (!hasUniqueSolution) {
        _showErrorDialog(localization.customGameErrorMultipleSolutions);
        setState(() {
          _isValidating = false;
        });
        return;
      }

      if (!mounted) return;

      final initialBoard = createBoard(
        _board
            .map(
              (row) => row
                  .map((cell) => cell.copyWith(isFixed: cell.value != null))
                  .toList(),
            )
            .toList(),
      );

      final dynamic gameVM = getViewModel(context);
      await gameVM.startCustomGame(initialBoard);

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (final context) => getGameScreen()),
      );
    } catch (e) {
      _showErrorDialog('${localization.customGameError}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  Future<bool> _checkUniqueSolution() async {
    final board = _board
        .map((final row) => row.map((final cell) => cell.value ?? 0).toList())
        .toList();

    var solutionCount = 0;
    final result = await _countSolutions(board, 0, 0, maxSolutionsToCheck);
    solutionCount = result;

    return solutionCount == 1;
  }

  Future<int> _countSolutions(
    final List<List<int>> board,
    final int row,
    final int col,
    final int maxSolutions,
  ) async {
    if (row == boardSize) return 1;

    final nextRow = col == boardSize - 1 ? row + 1 : row;
    final nextCol = col == boardSize - 1 ? 0 : col + 1;

    if (board[row][col] != 0) {
      return _countSolutions(board, nextRow, nextCol, maxSolutions);
    }

    var solutions = 0;
    for (var num = 1; num <= boardSize; num++) {
      if (_isValidPlacementForSolver(board, row, col, num)) {
        board[row][col] = num;
        solutions += await _countSolutions(
          board,
          nextRow,
          nextCol,
          maxSolutions,
        );
        board[row][col] = 0;

        if (solutions >= maxSolutions) {
          return solutions;
        }
      }
    }

    return solutions;
  }

  void _showErrorDialog(final String message) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(LocalizationUtils.app(context).error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationUtils.app(context).ok),
          ),
        ],
      ),
    );
  }

  void _showSettings(final BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }
}
