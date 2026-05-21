import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/app_initializer.dart';
import 'package:sudoku/index.dart';

/// Summary: 应用入口点
void main() async {
  // 使用 runZonedGuarded 捕获所有异步错误
  await runZonedGuarded<Future<void>>(
    () async {
      // 确保 Flutter 绑定初始化，这是使用异步操作的前提
      WidgetsFlutterBinding.ensureInitialized();

      // 设置 Flutter 框架错误处理回调
      FlutterError.onError = (FlutterErrorDetails details) {
        // 记录 Flutter 框架错误
        AppLogger.error( 'Flutter框架错误', details.exception, details.stack);
        // 在调试模式下，将错误输出到控制台
        if (kDebugMode) { FlutterError.dumpErrorToConsole(details); }
      };

      // 执行应用初始化操作
      final initializationSuccess = await AppInitializer.initialize();

      // 如果初始化失败，显示错误页面
      if (!initializationSuccess) {
        runApp(const ErrorApp());
        return;
      }

      // 初始化成功，运行主应用
      // 使用 MultiProvider 提供应用所需的所有依赖
      runApp(
        MultiProvider(providers: DiModule.providers, child: const SudokuApp()),
      );
    },
    // 处理异步错误
    (Object error, StackTrace stackTrace) {
      // 记录未捕获的异步错误
      AppLogger.error('未捕获的异步错误', error, stackTrace);
      // 在调试模式下，重新抛出错误以便于调试
      if (kDebugMode) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    },
  );
}

/// Summary: 应用初始化失败时显示的错误页面
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('应用初始化失败'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => runApp(const SudokuApp()),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Summary: 主应用类, 负责配置应用的主题、语言、路由等
class SudokuApp extends StatefulWidget {
  const SudokuApp({super.key});

  @override
  State<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends State<SudokuApp> {
  @override
  Widget build(BuildContext context) {
    // 获取应用设置
    final appSettings = Provider.of<AppSettings>(context);
    // 获取主题管理器
    final themeManager = Provider.of<ThemeManager>(context);
    // 使用简单的语言代码构造 Locale，避免国家代码干扰
    final locale = Locale(appSettings.language);

    return MaterialApp(
       key: ValueKey(locale),   // 强制重建，确保语言切换生效
      // 应用标题
      title: 'Sudoku',
      // 亮色主题
      theme: themeManager.getTheme(context),
      // 暗色主题
      darkTheme: AppTheme.darkTheme,
      // 主题模式
      themeMode: themeManager.themeMode,
      // 当前语言
      locale: locale,
      // 本地化代理
      localizationsDelegates: LocalizationUtils.localizationDelegates,
      // 支持的语言
      supportedLocales: LocalizationUtils.supportedLocales,
      // 首页
      home: const HomeScreen(),
      // 隐藏调试模式横幅
      debugShowCheckedModeBanner: false,
      // 路由配置
      routes: {
        '/game': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          // 通过路由参数传递 gameType
          if (args is GameRouteArgs) {
            return _GameScreenWrapper(
              gameType: args.gameType,
              initialState: args.initialState,
            );
          }
          // 兼容旧的直接传 Difficulty 的方式
          if (args is Difficulty) {
            return const _GameScreenWrapper(gameType: GameType.standard);
          }
          return const _GameScreenWrapper(gameType: GameType.standard);
        },
        '/standard_custom': (context) => ChangeNotifierProvider(
              create: (context) => GameViewModel<StandardBoard>(
                gameType: 'standard',
                boardFromJson: StandardBoard.fromJson,
                createEmptyBoard: StandardBoard.empty,
                settings: context.read<AppSettings>(),
              ),
              child: CustomGameScreen<StandardBoard, GameViewModel<StandardBoard>>(
                initializeBoard: (board) {},
                createBoard: (cells) => StandardBoard(size: StandardConstants.boardSize, cells: cells),
                buildBoardWidget: (board, onCellSelected, cellSize) => UnifiedBoardWidget(
                  board: board,
                  onCellSelected: onCellSelected,
                  cellSize: cellSize,
                ),
                minFilledCells: StandardConstants.minFilledCells,
                boardSize: StandardConstants.boardSize,
                boxSize: StandardConstants.boxSize,
                maxSolutionsToCheck: StandardConstants.maxSolutionsToCheck,
                getViewModel: (context) => context.read<GameViewModel<StandardBoard>>(),
                getGameScreen: () => const _GameScreenWrapper(gameType: GameType.standard),
                isValidPlacementForSolver: (board, row, col, number) {
                  for (var i = 0; i < StandardConstants.boardSize; i++) {
                    if (board[row][i] == number || board[i][col] == number) return false;
                  }
                  final startRow = (row ~/ StandardConstants.boxSize) * StandardConstants.boxSize;
                  final startCol = (col ~/ StandardConstants.boxSize) * StandardConstants.boxSize;
                  for (var i = 0; i < StandardConstants.boxSize; i++) {
                    for (var j = 0; j < StandardConstants.boxSize; j++) {
                      if (board[startRow + i][startCol + j] == number) return false;
                    }
                  }
                  return true;
                },
              ),
            ),
        '/diagonal_custom': (context) => ChangeNotifierProvider(
              create: (context) => GameViewModel<DiagonalBoard>(
                gameType: 'diagonal',
                boardFromJson: DiagonalBoard.fromJson,
                createEmptyBoard: DiagonalBoard.empty,
                settings: context.read<AppSettings>(),
              ),
              child: CustomGameScreen<DiagonalBoard, GameViewModel<DiagonalBoard>>(
                initializeBoard: (board) {},
                createBoard: (cells) => DiagonalBoard(size: DiagonalConstants.boardSize, cells: cells),
                buildBoardWidget: (board, onCellSelected, cellSize) => UnifiedBoardWidget(
                  board: board,
                  onCellSelected: onCellSelected,
                  cellSize: cellSize,
                ),
                minFilledCells: DiagonalConstants.minFilledCells,
                boardSize: DiagonalConstants.boardSize,
                boxSize: DiagonalConstants.boxSize,
                maxSolutionsToCheck: DiagonalConstants.maxSolutionsToCheck,
                getViewModel: (context) => context.read<GameViewModel<DiagonalBoard>>(),
                getGameScreen: () => const _GameScreenWrapper(gameType: GameType.diagonal),
                isValidPlacementForSolver: (board, row, col, number) {
                  for (var i = 0; i < DiagonalConstants.boardSize; i++) {
                    if (board[row][i] == number || board[i][col] == number) return false;
                  }
                  final startRow = (row ~/ DiagonalConstants.boxSize) * DiagonalConstants.boxSize;
                  final startCol = (col ~/ DiagonalConstants.boxSize) * DiagonalConstants.boxSize;
                  for (var i = 0; i < DiagonalConstants.boxSize; i++) {
                    for (var j = 0; j < DiagonalConstants.boxSize; j++) {
                      if (board[startRow + i][startCol + j] == number) return false;
                    }
                  }
                  if (row == col) {
                    for (var i = 0; i < DiagonalConstants.boardSize; i++) {
                      if (board[i][i] == number) return false;
                    }
                  }
                  if (row + col == DiagonalConstants.boardSize - 1) {
                    for (var i = 0; i < DiagonalConstants.boardSize; i++) {
                      if (board[i][DiagonalConstants.boardSize - 1 - i] == number) return false;
                    }
                  }
                  return true;
                },
              ),
            ),
        '/window_custom': (context) => ChangeNotifierProvider(
              create: (context) => GameViewModel<WindowBoard>(
                gameType: 'window',
                boardFromJson: WindowBoard.fromJson,
                createEmptyBoard: WindowBoard.empty,
                settings: context.read<AppSettings>(),
              ),
              child: CustomGameScreen<WindowBoard, GameViewModel<WindowBoard>>(
                initializeBoard: (board) {},
                createBoard: (cells) => WindowBoard(size: WindowConstants.boardSize, cells: cells),
                buildBoardWidget: (board, onCellSelected, cellSize) => UnifiedBoardWidget(
                  board: board,
                  onCellSelected: onCellSelected,
                  cellSize: cellSize,
                ),
                minFilledCells: WindowConstants.minFilledCells,
                boardSize: WindowConstants.boardSize,
                boxSize: WindowConstants.boxSize,
                maxSolutionsToCheck: WindowConstants.maxSolutionsToCheck,
                getViewModel: (context) => context.read<GameViewModel<WindowBoard>>(),
                getGameScreen: () => const _GameScreenWrapper(gameType: GameType.window),
                isValidPlacementForSolver: (board, row, col, number) {
                  // 行列检查
                  for (var i = 0; i < WindowConstants.boardSize; i++) {
                    if (board[row][i] == number || board[i][col] == number) return false;
                  }
                  // 宫格检查
                  final startRow = (row ~/ WindowConstants.boxSize) * WindowConstants.boxSize;
                  final startCol = (col ~/ WindowConstants.boxSize) * WindowConstants.boxSize;
                  for (var i = 0; i < WindowConstants.boxSize; i++) {
                    for (var j = 0; j < WindowConstants.boxSize; j++) {
                      if (board[startRow + i][startCol + j] == number) return false;
                    }
                  }
                  // 窗口区域检查
                  for (final region in WindowConstants.windowRegions) {
                    if (row >= region.startRow && row <= region.endRow &&
                        col >= region.startCol && col <= region.endCol) {
                      for (var r = region.startRow; r <= region.endRow; r++) {
                        for (var c = region.startCol; c <= region.endCol; c++) {
                          if (r == row && c == col) continue;
                          if (board[r][c] == number) return false;
                        }
                      }
                    }
                  }
                  return true;
                },
              ),
            ),
        '/statistics': (context) => const GameStatisticsScreen(),
        '/settings': (context) => const SettingsScreenWrapper(),
      },
    );
  }
}

/// 游戏路由参数
class GameRouteArgs {
  const GameRouteArgs({
    required this.gameType,
    this.difficulty,
    this.initialState,
  });

  final GameType gameType;
  final Difficulty? difficulty;
  final GameState? initialState;
}

/// 统一游戏屏幕包装器
class _GameScreenWrapper extends StatelessWidget {
  const _GameScreenWrapper({
    required this.gameType,
    this.initialState,
  });

  final GameType gameType;
  final GameState? initialState;

  @override
  Widget build(BuildContext context) {
    switch (gameType) {
      case GameType.standard:
        return ChangeNotifierProvider(
          create: (context) => GameViewModel<StandardBoard>(
            gameType: 'standard',
            boardFromJson: StandardBoard.fromJson,
            createEmptyBoard: StandardBoard.empty,
            settings: context.read<AppSettings>(),
          ),
          child: const GameScreen<StandardBoard>(),
        );
      case GameType.diagonal:
        return ChangeNotifierProvider(
          create: (context) => GameViewModel<DiagonalBoard>(
            gameType: 'diagonal',
            boardFromJson: DiagonalBoard.fromJson,
            createEmptyBoard: DiagonalBoard.empty,
            settings: context.read<AppSettings>(),
          ),
          child: const GameScreen<DiagonalBoard>(),
        );
      case GameType.window:
        return ChangeNotifierProvider(
          create: (context) => GameViewModel<WindowBoard>(
            gameType: 'window',
            boardFromJson: WindowBoard.fromJson,
            createEmptyBoard: WindowBoard.empty,
            settings: context.read<AppSettings>(),
          ),
          child: const GameScreen<WindowBoard>(),
        );
      case GameType.jigsaw:
        return ChangeNotifierProvider(
          create: (context) => GameViewModel<JigsawBoard>(
            gameType: 'jigsaw',
            boardFromJson: JigsawBoard.fromJson,
            createEmptyBoard: () => JigsawBoard.empty(regionMatrix: List.generate(9, (_) => List.filled(9, 0))),
            settings: context.read<AppSettings>(),
          ),
          child: const GameScreen<JigsawBoard>(),
        );
      case GameType.killer:
        return ChangeNotifierProvider(
          create: (context) => GameViewModel<KillerBoard>(
            gameType: 'killer',
            boardFromJson: KillerBoard.fromJson,
            createEmptyBoard: KillerBoard.empty,
            settings: context.read<AppSettings>(),
          ),
          child: const GameScreen<KillerBoard>(),
        );
      case GameType.samurai:
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: context.read<AppSettings>()),
            ChangeNotifierProvider(
              create: (context) {
                if (initialState != null && initialState is GameState<SamuraiBoard>) {
                  return GameViewModel<SamuraiBoard>.withState(
                    gameType: 'samurai',
                    boardFromJson: SamuraiBoard.fromJson,
                    createEmptyBoard: SamuraiBoard.empty,
                    initialState: initialState as GameState<SamuraiBoard>,
                    settings: context.read<AppSettings>(),
                  );
                }
                return GameViewModel<SamuraiBoard>(
                  gameType: 'samurai',
                  boardFromJson: SamuraiBoard.fromJson,
                  createEmptyBoard: SamuraiBoard.empty,
                  settings: context.read<AppSettings>(),
                );
              },
            ),
          ],
          child: const GameScreen<SamuraiBoard>(),
        );
    }
  }
}
