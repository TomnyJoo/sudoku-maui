import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  final Map<String, String> _strings = {};

  static Future<AppLocalizations> load(Locale locale) async {
    final appLocalizations = AppLocalizations(locale);
    await _loadFromAssetBundle(appLocalizations, locale);
    return appLocalizations;
  }

  static Future<void> _loadFromAssetBundle(
      AppLocalizations localizations, Locale locale) async {
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    final paths = [
      'assets/l10n/app_$languageCode.arb',
      if (countryCode != null)
        'assets/l10n/app_${languageCode}_$countryCode.arb',
    ];

    for (final path in paths) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        localizations._strings.clear();
        jsonMap.forEach((key, value) {
          if (!key.startsWith('@') && !key.startsWith('@@')) {
            localizations._strings[key] = value.toString();
          }
        });
        
        return;
      } catch (e) {
        // 忽略错误，尝试下一个路径
      }
    }

  }

  String? getString(String key) => _strings[key];

  // ========== 通用本地化 Getters ==========
  String get appName => getString('appName') ?? 'Sudoku';
  String get newGame => getString('newGame') ?? 'New Game';
  String get newGameConfirm => getString('newGameConfirm') ?? 'Start New Game?';
  String get newGameConfirmContent =>
      getString('newGameConfirmContent') ??
      'Are you sure you want to start a new game? Current progress will be lost.';
  String get cancel => getString('cancel') ?? 'Cancel';
  String get ok => getString('ok') ?? 'OK';
  String get generatingGame =>
      getString('generatingGame') ?? 'Generating game, please wait...';
  String get generationFailedTitle =>
      getString('generationFailedTitle') ?? 'Generation Failed';
  String get generationFailedMessage =>
      getString('generationFailedMessage') ??
      'Failed to generate game. Please try again.';
  String get okButton => getString('okButton') ?? 'OK';
  String get customGame => getString('customGame') ?? 'Custom Game';
  String get customSudoku => getString('customSudoku') ?? 'Custom Sudoku';
  String get customGameInstruction1 =>
      getString('customGameInstruction1') ??
      'Enter numbers from 1-9 in the grid.';
  String get customGameInstruction2 =>
      getString('customGameInstruction2') ??
      'Leave empty cells for the puzzle to solve.';
  String get clearBoard => getString('clearBoard') ?? 'Clear Board';
  String get clearBoardConfirm =>
      getString('clearBoardConfirm') ??
      'Are you sure you want to clear the board?';
  String get customGameErrorTooFew =>
      getString('customGameErrorTooFew') ??
      'Too few numbers entered. Please add more.';
  String get customGameErrorInvalid =>
      getString('customGameErrorInvalid') ??
      'Invalid Sudoku. Please check your input.';
  String get customGameErrorMultipleSolutions =>
      getString('customGameErrorMultipleSolutions') ??
      'This Sudoku has multiple solutions.';
  String get customGameError =>
      getString('customGameError') ?? 'Error creating custom game';
  String get error => getString('error') ?? 'Error';
  String get difficulty => getString('difficulty') ?? 'Difficulty';
  String get difficultyBeginner =>
      getString('difficultyBeginner') ?? 'Beginner';
  String get difficultyEasy => getString('difficultyEasy') ?? 'Easy';
  String get difficultyMedium => getString('difficultyMedium') ?? 'Medium';
  String get difficultyHard => getString('difficultyHard') ?? 'Hard';
  String get difficultyExpert => getString('difficultyExpert') ?? 'Expert';
  String get difficultyMaster => getString('difficultyMaster') ?? 'Master';
  String get difficultyCustom => getString('difficultyCustom') ?? 'Custom';
  String get undo => getString('undo') ?? 'Undo';
  String get redo => getString('redo') ?? 'Redo';
  String get hint => getString('hint') ?? 'Hint';
  String get mark => getString('mark') ?? 'Mark';
  String get autoMark => getString('autoMark') ?? 'Auto Mark';
  String get erase => getString('erase') ?? 'Erase';
  String get solution => getString('solution') ?? 'Solution';
  String get reset => getString('reset') ?? 'Reset';
  String get loading => getString('loading') ?? 'Loading...';
  String get processing => getString('processing') ?? 'Processing...';
  String get operationSuccess =>
      getString('operationSuccess') ?? 'Operation Successful';
  String get operationFailed =>
      getString('operationFailed') ?? 'Operation Failed';
  String get confirm => getString('confirm') ?? 'Confirm';
  String get puzzleCompleted =>
      getString('puzzleCompleted') ?? 'Puzzle Completed';
  String get congratulations =>
      getString('congratulations') ?? 'Congratulations!';
  String get time => getString('time') ?? 'Time';
  String get mistakes => getString('mistakes') ?? 'Mistakes';
  String get current => getString('current') ?? 'Current';
  String get bestScore => getString('bestScore') ?? 'Best Score';
  String get startNewGame => getString('startNewGame') ?? 'Start New Game';
  String get backToMenu => getString('backToMenu') ?? 'Back to Menu';
  String get newRecord => getString('newRecord') ?? 'New Record!';
  String get newRecordMessage =>
      getString('newRecordMessage') ?? 'You have set a new record!';
  String get gameRules => getString('gameRules') ?? 'Game Rules';
  String get settingsLanguage => getString('settingsLanguage') ?? 'Language';
  String get settingsTheme => getString('settingsTheme') ?? 'Theme';
  String get settingsThemeLight => getString('settingsThemeLight') ?? 'Light';
  String get settingsThemeDark => getString('settingsThemeDark') ?? 'Dark';
  String get settingsThemeSystem => getString('settingsThemeSystem') ?? 'System';
  String get settingsAudio => getString('settingsAudio') ?? 'Audio';
  String get settingsMusic => getString('settingsMusic') ?? 'Music';
  String get soundEffects => getString('soundEffects') ?? 'Sound Effects';
  String get selectSudokuType =>
      getString('selectSudokuType') ?? 'Select Sudoku Type';
  String get selectDifficulty =>
      getString('selectDifficulty') ?? 'Select Difficulty';
  String get selectSudokuTypeHint =>
      getString('selectSudokuTypeHint') ?? 'Please select a Sudoku type';
  String get homeCopyright =>
      getString('homeCopyright') ?? '© 2026 Topking Software';
  String get loadGame => getString('loadGame') ?? 'Load Game';
  String get activeGameTypes =>
      getString('activeGameTypes') ?? 'Active Game Types';
  String get averageMistakes =>
      getString('averageMistakes') ?? 'Average Mistakes';
  String get averageTime => getString('averageTime') ?? 'Average Time';
  String get bestTime => getString('bestTime') ?? 'Best Time';
  String get clearAllStatsConfirm =>
      getString('clearAllStatsConfirm') ??
      'Are you sure you want to clear all statistics?';
  String get clearStatistics =>
      getString('clearStatistics') ?? 'Clear Statistics';
  String get completedGames => getString('completedGames') ?? 'Completed Games';
  String get completionRate => getString('completionRate') ?? 'Completion Rate';
  String get consecutiveDays =>
      getString('consecutiveDays') ?? 'Consecutive Days';
  String get exportStatistics =>
      getString('exportStatistics') ?? 'Export Statistics';
  String get gameComparison => getString('gameComparison') ?? 'Game Comparison';
  String get incompleteGames =>
      getString('incompleteGames') ?? 'Incomplete Games';
  String get individualGameStats =>
      getString('individualGameStats') ?? 'Individual Game Stats';
  String get longestStreak => getString('longestStreak') ?? 'Longest Streak';
  String get noStatistics =>
      getString('noStatistics') ?? 'No statistics available';
  String get noGamesPlayed =>
      getString('noGamesPlayed') ?? 'No games played yet';
  String get playedMore =>
      getString('playedMore') ?? 'played the most';
  String get recentGames =>
      getString('recentGames') ?? 'Recent Games';
  String get overview => getString('overview') ?? 'Overview';
  String get statisticsExported =>
      getString('statisticsExported') ?? 'Statistics exported successfully';
  String get statisticsTitle => getString('statisticsTitle') ?? 'Statistics';
  String get statsCleared =>
      getString('statsCleared') ?? 'Statistics cleared successfully';
  String get summary => getString('summary') ?? 'Summary';
  String get totalGames => getString('totalGames') ?? 'Total Games';
  String get clear => getString('clear') ?? 'Clear';
  String get settingsAutoCheck =>
      getString('settingsAutoCheck') ?? 'Auto Check';
  String get settingsBasicSettings =>
      getString('settingsBasicSettings') ?? 'Basic Settings';
  String get settingsCandidateSettings =>
      getString('settingsCandidateSettings') ?? 'Candidate Settings';
  String get settingsGameSettings =>
      getString('settingsGameSettings') ?? 'Game Settings';
  String get settingsGameSettingsTab =>
      getString('settingsGameSettingsTab') ?? 'Game Settings';
  String get settingsHighlightMistakes =>
      getString('settingsHighlightMistakes') ?? 'Highlight Mistakes';
  String get settingsTitle => getString('settingsTitle') ?? 'Settings';
  String get settingsUseAdvancedStrategy =>
      getString('settingsUseAdvancedStrategy') ?? 'Use Advanced Strategy';
  String get difficultyStats =>
      getString('difficultyStats') ?? 'Difficulty Statistics';
  String get recommendedDifficulty =>
      getString('recommendedDifficulty') ?? 'Recommended Difficulty';
  String get timeDistribution =>
      getString('timeDistribution') ?? 'Time Distribution';
  String get commonErrors =>
      getString('commonErrors') ?? 'Common Errors';
  String get clearStatisticsConfirm =>
      getString('clearStatisticsConfirm') ??
      'Are you sure you want to clear all statistics for this game type?';
  String get noIncompleteGames =>
      getString('noIncompleteGames') ?? 'No incomplete games';
  String get startTime =>
      getString('startTime') ?? 'Start Time:';
  String get timeRange0to5 =>
      getString('timeRange0to5') ?? '0-5 min';
  String get timeRange5to10 =>
      getString('timeRange5to10') ?? '5-10 min';
  String get timeRange10to15 =>
      getString('timeRange10to15') ?? '10-15 min';
  String get timeRange15to20 =>
      getString('timeRange15to20') ?? '15-20 min';
  String get timeRange20to30 =>
      getString('timeRange20to30') ?? '20-30 min';
  String get timeRange30Plus =>
      getString('timeRange30Plus') ?? '30+ min';
  String get gameRulesTitle =>
      getString('gameRulesTitle') ?? 'Rules';
  String get gameRulesDetails =>
      getString('gameRulesDetails') ?? 'Rule Details';
  String get gameRulesSection =>
      getString('gameRulesSection') ?? 'Game Rules';
  String get validationRules =>
      getString('validationRules') ?? 'Validation Rules';
  String get noHintAvailable =>
      getString('noHintAvailable') ?? 'No hints available';
  String get close =>
      getString('close') ?? 'Close';
  String get appInitFailed =>
      getString('appInitFailed') ?? 'App initialization failed';
  String get retry =>
      getString('retry') ?? 'Retry';
  String get hideDiagonalLines =>
      getString('hideDiagonalLines') ?? 'Hide diagonal lines';
  String get showDiagonalLines =>
      getString('showDiagonalLines') ?? 'Show diagonal lines';
  String get hideRegionNumbers =>
      getString('hideRegionNumbers') ?? 'Hide region numbers';
  String get showRegionNumbers =>
      getString('showRegionNumbers') ?? 'Show region numbers';
  String get tapSubGridToEdit =>
      getString('tapSubGridToEdit') ?? 'Tap sub-grid to edit';
  String get subGridTopLeft =>
      getString('subGridTopLeft') ?? 'Top Left';
  String get subGridTopRight =>
      getString('subGridTopRight') ?? 'Top Right';
  String get subGridBottomLeft =>
      getString('subGridBottomLeft') ?? 'Bottom Left';
  String get subGridBottomRight =>
      getString('subGridBottomRight') ?? 'Bottom Right';
  String get subGridCenter =>
      getString('subGridCenter') ?? 'Center';
  String get progressInitializing =>
      getString('progressInitializing') ?? 'Initializing';
  String get progressLoadingTemplate =>
      getString('progressLoadingTemplate') ?? 'Loading template';
  String get progressCreatingRegions =>
      getString('progressCreatingRegions') ?? 'Creating regions';
  String get progressApplyingSubstitution =>
      getString('progressApplyingSubstitution') ?? 'Applying substitution';
  String get progressGeneratingSolution =>
      getString('progressGeneratingSolution') ?? 'Generating solution';
  String get progressDiggingPuzzle =>
      getString('progressDiggingPuzzle') ?? 'Digging puzzle';
  String get progressValidating =>
      getString('progressValidating') ?? 'Validating board';
  String get progressCompleted =>
      getString('progressCompleted') ?? 'Generation completed';
  String get difficultyDescBeginner =>
      getString('difficultyDescBeginner') ??
      'Suitable for beginners, fewer numbers to fill';
  String get difficultyDescEasy =>
      getString('difficultyDescEasy') ??
      'Easy difficulty, solvable with basic logic';
  String get difficultyDescMedium =>
      getString('difficultyDescMedium') ??
      'Medium difficulty, requires some techniques';
  String get difficultyDescHard =>
      getString('difficultyDescHard') ??
      'Hard difficulty, requires advanced techniques';
  String get difficultyDescExpert =>
      getString('difficultyDescExpert') ??
      'Expert difficulty, push your limits';
  String get difficultyDescMaster =>
      getString('difficultyDescMaster') ??
      'Master difficulty, only true Sudoku masters can complete';
  String get difficultyDescCustom =>
      getString('difficultyDescCustom') ?? 'Custom difficulty';
  String get failedToLoadStats =>
      getString('failedToLoadStats') ?? 'Failed to load statistics';
  String get failedToAddGameRecord =>
      getString('failedToAddGameRecord') ?? 'Failed to add game record';
  String get failedToClearStats =>
      getString('failedToClearStats') ?? 'Failed to clear statistics';
  String get failedToExportStats =>
      getString('failedToExportStats') ?? 'Failed to export statistics';
  String get failedToImportStats =>
      getString('failedToImportStats') ?? 'Failed to import statistics';
  String get notEnoughDataForTrend =>
      getString('notEnoughDataForTrend') ??
      'Not enough data for trend analysis';
  String get trendImprovement =>
      getString('trendImprovement') ?? 'Improvement';
  String get trendDecline =>
      getString('trendDecline') ?? 'Decline';
  String get cageDifficultyEasy =>
      getString('cageDifficultyEasy') ?? 'Easy';
  String get cageDifficultyMedium =>
      getString('cageDifficultyMedium') ?? 'Medium';
  String get cageDifficultyHard =>
      getString('cageDifficultyHard') ?? 'Hard';
  String get cageDifficultyExpert =>
      getString('cageDifficultyExpert') ?? 'Expert';
  String get cageDifficultyMaster =>
      getString('cageDifficultyMaster') ?? 'Master';

  String gameCount(int count) =>
      getString('gameCount')?.replaceAll('{count}', count.toString()) ??
      '$count Games';

  String getTimeRangeLabel(String range) {
    switch (range) {
      case '0-5':
        return timeRange0to5;
      case '5-10':
        return timeRange5to10;
      case '10-15':
        return timeRange10to15;
      case '15-20':
        return timeRange15to20;
      case '20-30':
        return timeRange20to30;
      case '30+':
        return timeRange30Plus;
      default:
        return range;
    }
  }

  List<String> get subGridNames => [
        subGridTopLeft,
        subGridTopRight,
        subGridBottomLeft,
        subGridBottomRight,
        subGridCenter,
      ];

  String getDifficultyDescription(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return difficultyDescBeginner;
      case 'easy':
        return difficultyDescEasy;
      case 'medium':
        return difficultyDescMedium;
      case 'hard':
        return difficultyDescHard;
      case 'expert':
        return difficultyDescExpert;
      case 'master':
        return difficultyDescMaster;
      case 'custom':
        return difficultyDescCustom;
      default:
        return difficulty;
    }
  }

  String getProgressText(String stage) {
    switch (stage) {
      case 'initializing':
        return progressInitializing;
      case 'loadingTemplate':
        return progressLoadingTemplate;
      case 'creatingRegions':
        return progressCreatingRegions;
      case 'applyingSubstitution':
        return progressApplyingSubstitution;
      case 'generatingSolution':
        return progressGeneratingSolution;
      case 'diggingPuzzle':
        return progressDiggingPuzzle;
      case 'validating':
        return progressValidating;
      case 'completed':
        return progressCompleted;
      default:
        return stage;
    }
  }

  String getCageDifficultyLevel(String level) {
    switch (level) {
      case 'easy':
        return cageDifficultyEasy;
      case 'medium':
        return cageDifficultyMedium;
      case 'hard':
        return cageDifficultyHard;
      case 'expert':
        return cageDifficultyExpert;
      case 'master':
        return cageDifficultyMaster;
      default:
        return level;
    }
  }

  String homeVersion(String version) =>
      getString('homeVersion')?.replaceAll('{version}', version) ??
      'Version $version';

  String generationFailedError(String error) =>
      getString('generationFailedError')?.replaceAll('{error}', error) ??
      'Error: $error';
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant AppLocalizationsDelegate old) => true;
}
