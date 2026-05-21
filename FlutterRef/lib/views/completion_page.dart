import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 通用完成页面（重构版）
class FinishScreen<
  T extends GameViewModel<B>,
  S extends GameService<B>,
  B extends Board
>
    extends StatefulWidget {
  const FinishScreen({
    super.key,
    required this.gameType,
    required this.getViewModel,
    required this.getGameService,
    this.onStartNewGame,
    this.onBackToMenu,
  });
  
  final String gameType;  /// 游戏类型标识（用于统计和存储）

  
  final T Function(BuildContext context) getViewModel;  /// 获取 ViewModel 的回调
  final S Function(BuildContext context) getGameService;  /// 获取 GameService 的回调
  final Future<void> Function(BuildContext context)? onStartNewGame;  /// 自定义开始新游戏行为（可选）
  final void Function(BuildContext context)? onBackToMenu;  /// 自定义返回菜单行为（可选）

  @override
  State<FinishScreen<T, S, B>> createState() => _FinishScreenState<T, S, B>();
}

class _FinishScreenState<
  T extends GameViewModel<B>,
  S extends GameService<B>,
  B extends Board
>
    extends State<FinishScreen<T, S, B>>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _confettiController;

  late Future<FinishScreenData> _dataFuture;
  bool _dataLoaded = false;
  bool _hasShownNewRecordDialog = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _dataFuture = _loadAllData();
    }
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: AppConstants.finishScreenShortDelay,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );
    _confettiController = AnimationController(
      duration: AppConstants.finishScreenLongDelay,
      vsync: this,
    );
    _scaleController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ---------- 辅助 getter ----------
  T _viewModel() => widget.getViewModel(context);
  S _gameService() => widget.getGameService(context);
  GameState<B> _gameState() => _viewModel().state;

  int get _currentTime => _gameState().elapsedTime;
  int get _currentMistakes => _gameState().mistakes;
  String get _currentDifficulty => _gameState().difficulty;

  String _formatTime(int seconds) => GameUtils.formatTime(seconds);

  String _localizedDifficulty() =>
      GameUtils.getLocalizedDifficultyName(context, _currentDifficulty);

  // ---------- 核心数据加载 ----------
  Future<FinishScreenData> _loadAllData() async {
    final currentTime = _currentTime;
    final currentMistakes = _currentMistakes;
    final localizedDifficulty = _localizedDifficulty();

    if (currentTime <= 0) {
      return FinishScreenData(
        currentTime: currentTime,
        currentMistakes: currentMistakes,
        localizedDifficulty: localizedDifficulty,
        bestScoreTime: '--:--',
        bestScoreMistakes: 0,
        isNewBest: false,
      );
    }

    BestScoreRecord? bestScore;
    try {
      final viewModelBestScore = _viewModel().cachedBestScore;
      if (viewModelBestScore != null && viewModelBestScore.time > 0) {
        bestScore = viewModelBestScore;
      } else {
        final stats = await StatisticsManager.getGameStatistics(widget.gameType);
        final difficultyStats = stats.difficultyStats[_currentDifficulty];
        bestScore = difficultyStats?.bestScoreRecord;
        if (bestScore != null && bestScore.time <= 0) {
          bestScore = null;
        }
      }
    } catch (e) {
      AppLogger.error('读取最佳成绩失败: $e');
      bestScore = null;
    }

    final bool isNewBest;
    if (bestScore == null) {
      isNewBest = currentTime > 0;
    } else {
      isNewBest = currentTime < bestScore.time ||
          (currentTime == bestScore.time && currentMistakes < bestScore.mistakes);
    }

    final displayBest = isNewBest
        ? BestScoreRecord(time: currentTime, mistakes: currentMistakes, timestamp: DateTime.now())
        : bestScore;

    await Future.wait([
      _saveStatistics(time: currentTime, mistakes: currentMistakes),
      _clearCurrentGame(),
    ]);

    return FinishScreenData(
      currentTime: currentTime,
      currentMistakes: currentMistakes,
      localizedDifficulty: localizedDifficulty,
      bestScoreTime: displayBest != null
          ? _formatTime(displayBest.time)
          : '--:--',
      bestScoreMistakes: displayBest?.mistakes ?? 0,
      isNewBest: isNewBest,
    );
  }

  Future<void> _saveStatistics({
    required int time,
    required int mistakes,
  }) async {
    try {
      await StatisticsManager.addGameRecord(
        gameType: widget.gameType,
        difficulty: _currentDifficulty,
        isCompleted: true,
        time: time,
        mistakes: mistakes,
      );
    } catch (e) {
      AppLogger.error('❌ 保存统计信息失败: $e');
    }
  }

  Future<void> _clearCurrentGame() async {
    try {
      await _gameService().clearSavedGame('${widget.gameType}${AppConstants.currentGameKeySuffix}');
    } catch (e) {
      AppLogger.error('清除当前游戏失败: $e');
    }
  }

  void _retry() {
    setState(() {
      _dataFuture = _loadDataOnly();
    });
  }

  Future<FinishScreenData> _loadDataOnly() async {
    final currentTime = _currentTime;
    final currentMistakes = _currentMistakes;
    final localizedDifficulty = _localizedDifficulty();

    if (currentTime <= 0) {
      return FinishScreenData(
        currentTime: currentTime,
        currentMistakes: currentMistakes,
        localizedDifficulty: localizedDifficulty,
        bestScoreTime: '--:--',
        bestScoreMistakes: 0,
        isNewBest: false,
      );
    }

    BestScoreRecord? bestScore;
    try {
      final viewModelBestScore = _viewModel().cachedBestScore;
      if (viewModelBestScore != null && viewModelBestScore.time > 0) {
        bestScore = viewModelBestScore;
      } else {
        final stats = await StatisticsManager.getGameStatistics(widget.gameType);
        final difficultyStats = stats.difficultyStats[_currentDifficulty];
        bestScore = difficultyStats?.bestScoreRecord;
      }
    } catch (e) {
      bestScore = null;
    }

    final bool isNewBest;
    if (bestScore == null) {
      isNewBest = currentTime > 0;
    } else {
      isNewBest = currentTime < bestScore.time ||
          (currentTime == bestScore.time && currentMistakes < bestScore.mistakes);
    }

    final displayBest = isNewBest
        ? BestScoreRecord(time: currentTime, mistakes: currentMistakes, timestamp: DateTime.now())
        : bestScore;

    return FinishScreenData(
      currentTime: currentTime,
      currentMistakes: currentMistakes,
      localizedDifficulty: localizedDifficulty,
      bestScoreTime: _formatTime(displayBest?.time ?? 0),
      bestScoreMistakes: displayBest?.mistakes ?? 0,
      isNewBest: isNewBest,
    );
  }

  // ---------- UI 构建 ----------
  @override
  Widget build(BuildContext context) => FutureBuilder<FinishScreenData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error!);
        }
        final data = snapshot.data!;
        if (data.isNewBest && !_hasShownNewRecordDialog) {
          _hasShownNewRecordDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNewRecordDialog(data);
          });
        }
        return _buildContent(data);
      },
    );

  Widget _buildLoadingScreen() {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.homeBackgroundGradientDark.first : AppColors.homeBackgroundGradientLight.first,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              LocalizationUtils.app(context).loading,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.homeBackgroundGradientDark.first : AppColors.homeBackgroundGradientLight.first,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 16),
            Text(
              LocalizationUtils.app(context).operationFailed,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(LocalizationUtils.app(context).ok),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FinishScreenData data) {
    final isDark = context.isDarkMode;
    final responsivePadding = ResponsiveLayout.getResponsivePadding(context);
    final buttonSize = ResponsiveLayout.getResponsiveButtonSize(context);
    final textColor = isDark ? Colors.white : AppColors.darkText;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? AppColors.homeBackgroundGradientDark
                  : AppColors.homeBackgroundGradientLight,
            ),
          ),
        ),
        title: Text(
          LocalizationUtils.app(context).puzzleCompleted,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? AppColors.homeBackgroundGradientDark
                : AppColors.homeBackgroundGradientLight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildConfettiEffect(),
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsivePadding,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCelebrationIcon(),
                      const SizedBox(height: 16),
                      _buildCongratulationsText(),
                      const SizedBox(height: 16),
                      _buildStatsContainer(data, textColor),
                      const SizedBox(height: 32),
                      _buildActionButtons(buttonSize),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfettiEffect() => Positioned.fill(
    child: AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) => CustomPaint(
          painter: ConfettiPainter(_confettiController.value),
          size: Size.infinite,
        ),
    ),
  );

  Widget _buildCelebrationIcon() {
    final isDark = context.isDarkMode;
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.successColor.withAlpha(isDark ? 40 : 70),
                    context.successColor.withAlpha(isDark ? 25 : 50),
                  ],
                ),
                border: Border.all(
                  color: context.successColor.withAlpha(isDark ? 40 : 80),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.celebration, size: 48, color: context.successColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCongratulationsText() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primary.withAlpha(205)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withAlpha(77),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      LocalizationUtils.app(context).congratulations,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildStatsContainer(FinishScreenData data, Color textColor) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            _buildDifficultyCard(data.localizedDifficulty),
            const SizedBox(height: 8),
            _buildStatRow(
              label: LocalizationUtils.app(context).time,
              currentValue: _formatTime(data.currentTime),
              bestValue: data.bestScoreTime,
              icon: Icons.timer,
              iconColor: context.infoColor,
              textColor: textColor,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              label: LocalizationUtils.app(context).mistakes,
              currentValue: data.currentMistakes.toString(),
              bestValue: data.bestScoreMistakes.toString(),
              icon: data.currentMistakes == 0
                  ? Icons.check_circle
                  : Icons.warning,
              iconColor: data.currentMistakes == 0
                  ? context.successColor
                  : context.errorColor,
              textColor: textColor,
            ),
          ],
        ),
      );

  Widget _buildDifficultyCard(String difficulty) {
    final isDark = context.isDarkMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.warningColor.withAlpha(isDark ? 25 : 50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.warningColor.withAlpha(isDark ? 40 : 100),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 18, color: context.warningColor),
                const SizedBox(width: 8),
                Text(
                  difficulty,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String currentValue,
    required String bestValue,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    final isDark = context.isDarkMode;
    final isBetter = currentValue == bestValue;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isDark ? 10 : 70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(isDark ? 15 : 120),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withAlpha(178),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      label: LocalizationUtils.app(context).current,
                      value: currentValue,
                      icon: icon,
                      iconColor: iconColor,
                      highlight: isBetter,
                      textColor: textColor,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.dividerColor.withAlpha(128),
                    ),
                    _buildStatItem(
                      label: LocalizationUtils.app(context).bestScore,
                      value: bestValue,
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber,
                      highlight: false,
                      textColor: textColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool highlight,
    required Color textColor,
  }) => Column(
    children: [
      Icon(icon, size: 18, color: highlight ? context.successColor : iconColor),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: highlight ? context.successColor : textColor,
        ),
      ),
      Text(
        label,
        style: TextStyle(fontSize: 12, color: textColor.withAlpha(153)),
      ),
    ],
  );

  Widget _buildActionButtons(Size buttonSize) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: ResponsiveLayout.getResponsivePadding(context),
    ),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: buttonSize.height,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                LocalizationUtils.app(context).startNewGame,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
              onPressed: _handleStartNewGame,
            ).withGradientBackground(context.buttonPrimaryGradient),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: buttonSize.height,
            child:
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    LocalizationUtils.app(context).backToMenu,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        shadowColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                  onPressed: _handleBackToMenu,
                ).withGradientBackground(context.buttonPrimaryGradient),
          ),
        ),
      ],
    ),
  );

  Future<void> _handleStartNewGame() async {
    if (widget.onStartNewGame != null) {
      await widget.onStartNewGame!(context);
      return;
    }
    final viewModel = _viewModel();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _gameService().clearSavedGame('${widget.gameType}${AppConstants.currentGameKeySuffix}');
      await viewModel.startNewGame(
        DifficultyExtension.fromIdentifier(_currentDifficulty),
      );
      if (mounted) {
        Navigator.of(context).pop();
        await Navigator.of(context).pushReplacementNamed(GameFactory.getGameRoute(GameType.values.firstWhere((g) => g.toString().split('.').last == widget.gameType)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationUtils.app(context).operationFailed}: $e',
            ),
          ),
        );
      }
    }
  }

  void _handleBackToMenu() {
    if (widget.onBackToMenu != null) {
      widget.onBackToMenu!(context);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
  }

  void _showNewRecordDialog(FinishScreenData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            Text(LocalizationUtils.app(context).newRecord),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocalizationUtils.app(context).newRecordMessage),
            const SizedBox(height: 16),
            _buildDialogStatRow(
              LocalizationUtils.app(context).difficulty,
              data.localizedDifficulty,
            ),
            _buildDialogStatRow(
              LocalizationUtils.app(context).time,
              _formatTime(data.currentTime),
            ),
            _buildDialogStatRow(
              LocalizationUtils.app(context).mistakes,
              data.currentMistakes.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationUtils.app(context).ok),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStatRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    ),
  );
}

// ---------- 数据载体 ----------
class FinishScreenData {
  FinishScreenData({
    required this.currentTime,
    required this.currentMistakes,
    required this.localizedDifficulty,
    required this.bestScoreTime,
    required this.bestScoreMistakes,
    required this.isNewBest,
  });

  final int currentTime;
  final int currentMistakes;
  final String localizedDifficulty;
  final String bestScoreTime;
  final int bestScoreMistakes;
  final bool isNewBest;
}

// ---------- 高性能五彩纸屑绘制器 ----------
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.progress);

  final double progress;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < AppConstants.confettiParticleCount; i++) {
      final x = (i * 17.3) % size.width;
      final y = (progress * size.height * 1.2) - (i * 7 % 50);
      final color = [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.pink,
      ][i % 7];
      _paint.color = color;
      canvas.drawCircle(Offset(x, y), 3.0 + (i % 4), _paint);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ---------- 渐变背景扩展 ----------
extension GradientButton on Widget {
  Widget withGradientBackground(List<Color> colors) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: this,
  );
}
