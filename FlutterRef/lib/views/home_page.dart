// ignore_for_file: use_decorated_box, prefer_expression_function_bodies, unnecessary_parenthesis, unnecessary_underscores, eol_at_end_of_file
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';
import 'package:sudoku/main.dart';

/// 首页 - PageView 两页式布局
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  String _currentGameName = '';
  int _currentPage = 0;

  // 入场动画
  late final AnimationController _staggerController;
  String? _version;

  @override
  void initState() {
    super.initState();
    _pageController = PageController()
      ..addListener(() {
        if (_pageController.hasClients) {
          final page = _pageController.page?.round() ?? 0;
          if (page != _currentPage) setState(() => _currentPage = page);
        }
      });

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appSettings = context.read<AppSettings>();
      await appSettings.loadSettings();
      final audioManager = AudioManager()
        ..setMusicEnabled(appSettings.musicEnabled);
      if (appSettings.musicEnabled) {
        await audioManager.playMusic();
      }
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = packageInfo.version);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // ==================== 配色 ====================

  static final _gameTypeStyles = {
    GameType.standard: (const Color(0xFF6366F1), const Color(0xFF818CF8), Icons.grid_view_rounded),
    GameType.diagonal: (const Color(0xFFA855F7), const Color(0xFFC084FC), Icons.tag_rounded),
    GameType.window: (const Color(0xFF3B82F6), const Color(0xFF60A5FA), Icons.window_rounded),
    GameType.jigsaw: (const Color(0xFF06B6D4), const Color(0xFF22D3EE), Icons.extension_rounded),
    GameType.killer: (const Color(0xFFEF4444), const Color(0xFFF87171), Icons.bolt_rounded),
    GameType.samurai: (const Color(0xFFF97316), const Color(0xFFFB923C), Icons.apps_rounded),
  };

  static const _difficultyStyles = [
    (Color(0xFF22C55E), Color(0xFF4ADE80), '★'),
    (Color(0xFF10B981), Color(0xFF34D399), '★★'),
    (Color(0xFFEAB308), Color(0xFFFACC15), '★★★'),
    (Color(0xFFF97316), Color(0xFFFB923C), '★★★★'),
    (Color(0xFFEF4444), Color(0xFFF87171), '★★★★★'),
    (Color(0xFFA855F7), Color(0xFFC084FC), '★★★★★★'),
  ];

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? AppColors.homeBackgroundGradientDark
                : AppColors.homeBackgroundGradientLight,
          ),
        ),
        child: Stack(
          children: [
            // PageView 两页切换
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildGameTypePage(context, isDarkMode),
                _buildDifficultyPage(context, isDarkMode),
              ],
            ),
            // 顶部工具栏（始终浮在最上层）
            _buildTopBar(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  // ==================== 顶部工具栏 ====================

  Widget _buildTopBar(BuildContext context, bool isDarkMode) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 第二页显示返回按钮
              if (_currentPage == 1)
                GestureDetector(
                  onTap: _backToGames,
                  child: _buildTopButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _backToGames,
                    isDarkMode: isDarkMode,
                  ),
                ),
              if (_currentPage == 1) const SizedBox(width: 8),
              const Spacer(),
              _buildTopButton(
                icon: Icons.help_outline_rounded,
                onTap: () => _showHelpDialog(context),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildTopButton(
                icon: Icons.settings_rounded,
                onTap: () => Navigator.pushNamed(context, '/settings'),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildTopButton(
                icon: Icons.bar_chart_rounded,
                onTap: () => Navigator.pushNamed(context, '/statistics'),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withAlpha(12) : Colors.white.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white.withAlpha(16) : Colors.white.withAlpha(80),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Icon(
              icon,
              size: 20,
              color: isDarkMode ? Colors.white.withAlpha(200) : const Color(0xFF3730A3),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 第一页：游戏类型选择 ====================

  Widget _buildGameTypePage(BuildContext context, bool isDarkMode) {
    final localizations = LocalizationUtils.app(context);
    final gameLocalizations = LocalizationUtils.game(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 顶部预留空间，避开浮动的工具栏
            const SizedBox(height: 52),
            _buildHeader(localizations.appName, localizations.selectSudokuType, isDarkMode),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = isLandscape ? 3 : 2;
                  final spacing = constraints.maxHeight < 300 ? 6.0 : (constraints.maxHeight < 500 ? 8.0 : 10.0);
                  // 动态计算 childAspectRatio：卡片恰好填满可用高度
                  final rows = (GameType.values.length / crossCount).ceil();
                  final totalSpacingV = spacing * (rows - 1);
                  final cardHeight = (constraints.maxHeight - totalSpacingV) / rows;
                  final cardWidth = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
                  final childAspectRatio = (cardWidth / cardHeight.clamp(30, 500));

                  return GridView.count(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                    children: GameType.values.map((type) {
                      final idx = GameType.values.indexOf(type);
                      return _buildStaggeredCard(
                        index: idx,
                        child: _buildGameTypeCard(
                          context: context,
                          type: type,
                          name: GameFactory.getLocalizedGameName(type, gameLocalizations),
                          gameLocalizations: gameLocalizations,
                          isDarkMode: isDarkMode,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildFooter(localizations, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF6366F1).withAlpha(30)
                : const Color(0xFF6366F1).withAlpha(20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.grid_view_rounded, size: 26, color: Color(0xFF818CF8)),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          ).createShader(bounds),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDarkMode ? Colors.white : const Color(0xFF312E81),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white.withAlpha(100) : const Color(0xFF6366F1).withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildStaggeredCard({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final delay = index * 0.08;
        final progress = ((_staggerController.value - delay).clamp(0.0, 1.0));
        final curve = Curves.easeOut.transform(progress);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: Transform.scale(scale: 0.95 + 0.05 * curve, child: child),
          ),
        );
      },
    );
  }

  Widget _buildGameTypeCard({
    required BuildContext context,
    required GameType type,
    required String name,
    required dynamic gameLocalizations,
    required bool isDarkMode,
  }) {
    final style = _gameTypeStyles[type] ?? _gameTypeStyles[GameType.standard]!;
    final primaryColor = style.$1;
    final lightColor = style.$2;
    final icon = style.$3;

    final subtitles = {
      GameType.standard: gameLocalizations.gameTypeStandardDescription,
      GameType.diagonal: gameLocalizations.gameTypeDiagonalDescription,
      GameType.window: gameLocalizations.gameTypeWindowDescription,
      GameType.jigsaw: gameLocalizations.gameTypeJigsawDescription,
      GameType.killer: gameLocalizations.gameTypeKillerDescription,
      GameType.samurai: gameLocalizations.gameTypeSamuraiDescription,
    };

    return GestureDetector(
      onTap: () => _goToDifficulty(type, name),
      child: _GlassCard(
        isDarkMode: isDarkMode,
        borderRadius: 16,
        child: Padding(
          padding: EdgeInsets.all(isDarkMode ? 12 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(isDarkMode ? 30 : 25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: lightColor),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitles[type] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white.withAlpha(80) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 第二页：难度选择 ====================

  Widget _buildDifficultyPage(BuildContext context, bool isDarkMode) {
    final localizations = LocalizationUtils.app(context);
    final style = _gameTypeStyles.values.firstWhere(
      (s) => true,
      orElse: () => _gameTypeStyles[GameType.standard]!,
    );
    final primaryColor = style.$1;
    final lightColor = style.$2;
    final icon = style.$3;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            final totalHeight = boxConstraints.maxHeight;
            // 动态计算间距和图标大小
            final compact = totalHeight < 500;
            final iconSize = compact ? 40.0 : 56.0;
            final verticalSpacing = compact ? 8.0 : 12.0;

            return Column(
              children: [
                // 顶部预留空间，与游戏类型页保持一致，避开浮动的工具栏
                const SizedBox(height: 52),
                SizedBox(height: verticalSpacing * 0.8),
                _buildDifficultyHeader(_currentGameName, localizations.selectDifficulty, icon, primaryColor, lightColor, isDarkMode, iconSize: iconSize),
                SizedBox(height: verticalSpacing),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildDifficultyList(context, isDarkMode, availableHeight: constraints.maxHeight),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _buildDifficultyActions(context, isDarkMode, primaryColor),
                const SizedBox(height: 8),
                _buildFooter(localizations, isDarkMode),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDifficultyHeader(String gameName, String subtitle, IconData icon, Color primaryColor, Color lightColor, bool isDarkMode, {double iconSize = 56.0}) {
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(isDarkMode ? 30 : 25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: iconSize * 0.54, color: lightColor),
        ),
        const SizedBox(height: 12),
        Text(
          gameName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white.withAlpha(100) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyList(BuildContext context, bool isDarkMode, {required double availableHeight}) {
    final localizations = LocalizationUtils.app(context);
    final difficultyLevels = GameFactory.getDifficultyLevels(
      GameType.values.firstWhere((t) => GameFactory.getLocalizedGameName(t, LocalizationUtils.game(context)) == _currentGameName, orElse: () => GameType.standard),
    );
    final difficulties = difficultyLevels.map((level) {
      Difficulty difficulty;
      switch (level) {
        case 'beginner':
          difficulty = Difficulty.beginner;
        case 'easy':
          difficulty = Difficulty.easy;
        case 'medium':
          difficulty = Difficulty.medium;
        case 'hard':
          difficulty = Difficulty.hard;
        case 'expert':
          difficulty = Difficulty.expert;
        case 'master':
          difficulty = Difficulty.master;
        default:
          difficulty = Difficulty.easy;
      }
      return difficulty;
    }).toList();

    final labels = [
      localizations.difficultyBeginner,
      localizations.difficultyEasy,
      localizations.difficultyMedium,
      localizations.difficultyHard,
      localizations.difficultyExpert,
      localizations.difficultyMaster,
    ];

    final count = difficulties.length;
    // 根据可用空间动态调整间距
    final spacing = availableHeight < 300 ? 4.0 : (availableHeight < 450 ? 6.0 : 10.0);

    // 用 Column + Expanded 均分空间，不硬计算内部尺寸
    return Column(
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          Expanded(
            child: _buildDifficultyItem(
              context: context,
              index: i,
              difficulty: difficulties[i],
              label: labels[i],
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDifficultyItem({
    required BuildContext context,
    required int index,
    required Difficulty difficulty,
    required String label,
    required bool isDarkMode,
  }) {
    final diffStyle = _difficultyStyles[index];
    final primaryColor = diffStyle.$1;
    final lightColor = diffStyle.$2;
    final stars = diffStyle.$3;

    return GestureDetector(
      onTap: () => _startGame(context, difficulty),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 48,
          maxHeight: 80,
        ),
        child: _GlassCard(
          isDarkMode: isDarkMode,
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
            children: [
              // 数字容器：固定宽度，高度随 Row 自适应
              SizedBox(
                width: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(isDarkMode ? 30 : 25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: lightColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        stars,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFFEAB308).withAlpha(isDarkMode ? 100 : 180),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDifficultyActions(BuildContext context, bool isDarkMode, Color primaryColor) {
    final gameType = GameType.values.firstWhere(
      (t) => GameFactory.getLocalizedGameName(t, LocalizationUtils.game(context)) == _currentGameName,
      orElse: () => GameType.standard,
    );
    final showCustomGame = GameFactory.showCustomGame(gameType);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: FutureBuilder<bool>(
        future: _checkHasSavedGameForCurrentType(gameType),
        builder: (context, snapshot) {
          final hasSaved = snapshot.data ?? false;
          if (!showCustomGame && !hasSaved) return const SizedBox.shrink();

          return Row(
            children: [
              if (hasSaved)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.play_circle_outline_rounded,
                    label: LocalizationUtils.app(context).loadGame,
                    color: primaryColor,
                    isDarkMode: isDarkMode,
                    onTap: () => _continueSavedGame(context, gameType),
                  ),
                ),
              if (hasSaved && showCustomGame) const SizedBox(width: 10),
              if (showCustomGame)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: LocalizationUtils.app(context).customGame,
                    color: primaryColor,
                    isDarkMode: isDarkMode,
                    onTap: () => _openCustomGame(context, gameType),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(isDarkMode ? 20 : 15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(isDarkMode ? 40 : 30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  // ==================== 底部信息 ====================

  Widget _buildFooter(dynamic localizations, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localizations.homeVersion(_version ?? ''),
            style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white.withAlpha(50) : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Text(
            localizations.homeCopyright,
            style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white.withAlpha(50) : const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ==================== 页面切换 ====================

  void _goToDifficulty(GameType type, String name) {
    setState(() => _currentGameName = name);
    _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  void _backToGames() {
    _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  // ==================== 游戏启动 ====================

  void _startGame(BuildContext context, Difficulty difficulty) {
    final gameType = GameType.values.firstWhere(
      (t) => GameFactory.getLocalizedGameName(t, LocalizationUtils.game(context)) == _currentGameName,
      orElse: () => GameType.standard,
    );
    Navigator.pushNamed(context, '/game', arguments: GameRouteArgs(gameType: gameType, difficulty: difficulty));
  }

  void _openCustomGame(BuildContext context, GameType gameType) {
    Navigator.pushNamed(context, GameFactory.getCustomGameRoute(gameType));
  }

  Future<void> _continueSavedGame(BuildContext context, GameType gameType) async {
    final gameTypeName = gameType.name;
    final savedGames = await GameStorageService.getSavedGameInfos();
    SavedGameInfo? savedGame;
    for (final game in savedGames) {
      if (game.gameType == gameTypeName) {
        savedGame = game;
        break;
      }
    }
    if (savedGame == null) return;
    await _loadSavedGame(savedGame);
  }

  Future<void> _loadSavedGame(SavedGameInfo gameInfo) async {
    try {
      final gameType = GameType.values.firstWhere(
        (type) => type.toString().split('.').last == gameInfo.gameType,
        orElse: () => GameType.standard,
      );
      final service = GameFactory.createGameService(gameType, GameValidator());
      final savedState = await service.loadGameState(gameInfo.saveKey);
      if (savedState != null && mounted) {
        await Navigator.pushNamed(context, '/game', arguments: GameRouteArgs(gameType: gameType, initialState: savedState));
      }
    } catch (e) {
      AppLogger.error('加载保存的游戏失败', e, StackTrace.current);
    }
  }

  Future<bool> _checkHasSavedGameForCurrentType(GameType gameType) async {
    final gameTypeName = gameType.name;
    final savedGames = await GameStorageService.getSavedGameInfos();
    return savedGames.any((game) => game.gameType == gameTypeName);
  }

  // ==================== 帮助对话框 ====================

  void _showHelpDialog(BuildContext context) {
    final localizations = LocalizationUtils.app(context);
    final gameLocalizations = LocalizationUtils.game(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localizations.gameRules,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: GameType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GameFactory.getLocalizedGameName(type, gameLocalizations),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gameLocalizations.getGameDescription(type.name),
                      style: TextStyle(fontSize: 12, height: 1.4, color: isDarkMode ? Colors.white.withAlpha(160) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ),
        ],
      ),
    );
  }
}

/// 毛玻璃卡片组件
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.isDarkMode, required this.borderRadius, required this.child});

  final bool isDarkMode;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(8) : Colors.white.withAlpha(70),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDarkMode ? Colors.white.withAlpha(10) : Colors.white.withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 20 : 8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      ),
    );
  }
}
