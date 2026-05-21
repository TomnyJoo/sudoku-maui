import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sudoku/l10n/app_localizations.dart';
import 'package:sudoku/l10n/game_localizations.dart';
import 'package:sudoku/models/index.dart';

class LocalizationUtils {
  static AppLocalizations app(BuildContext context) =>
      AppLocalizations.of(context);

  static GameLocalizations game(BuildContext context) =>
      GameLocalizations.of(context);

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations.of(context); // 向后兼容

  static String getCurrentLocaleCode(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('zh', 'CN'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationDelegates = [
    AppLocalizationsDelegate(),
    GameLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static String getGameName(BuildContext context, String gameType) {
    final localizations = game(context);
    return localizations.getGameName(gameType);
  }

  static String getGameDescription(BuildContext context, String gameType) {
    final localizations = game(context);
    return localizations.getGameDescription(gameType);
  }

  static String getGameRules(BuildContext context, String gameType) {
    final localizations = game(context);
    return localizations.getGameRules(gameType);
  }

  static String getGameNameFromType(BuildContext context, GameType gameType) {
    final gameTypeString = gameType.toString().split('.').last;
    return getGameName(context, gameTypeString);
  }

  static String getGameDescriptionFromType(
      BuildContext context, GameType gameType) {
    final gameTypeString = gameType.toString().split('.').last;
    return getGameDescription(context, gameTypeString);
  }

  static String getGameRulesFromType(BuildContext context, GameType gameType) {
    final gameTypeString = gameType.toString().split('.').last;
    return getGameRules(context, gameTypeString);
  }

  /// 重新加载本地化资源
  static Future<void> reloadLocalizations(Locale locale) async {
    await AppLocalizations.load(locale);
    await GameLocalizations.load(locale);
  }
}

extension LocalizationExtensions on BuildContext {
  AppLocalizations get appLocalizations => LocalizationUtils.app(this);
  GameLocalizations get gameLocalizations => LocalizationUtils.game(this);

  String getGameName(String gameType) =>
      LocalizationUtils.getGameName(this, gameType);
  String getGameDescription(String gameType) =>
      LocalizationUtils.getGameDescription(this, gameType);
  String getGameRules(String gameType) =>
      LocalizationUtils.getGameRules(this, gameType);

  String getGameNameFromType(GameType gameType) =>
      LocalizationUtils.getGameNameFromType(this, gameType);
  String getGameDescriptionFromType(GameType gameType) =>
      LocalizationUtils.getGameDescriptionFromType(this, gameType);
  String getGameRulesFromType(GameType gameType) =>
      LocalizationUtils.getGameRulesFromType(this, gameType);
}
