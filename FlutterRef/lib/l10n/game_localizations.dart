import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameLocalizations {
  GameLocalizations(this.locale);

  final Locale locale;

  static GameLocalizations of(BuildContext context) =>
      Localizations.of<GameLocalizations>(context, GameLocalizations)!;

  final Map<String, String> _strings = {};

  static Future<GameLocalizations> load(Locale locale) async {
    final gameLocalizations = GameLocalizations(locale);
    await _loadGameStrings(gameLocalizations, locale);
    return gameLocalizations;
  }

  static Future<void> _loadGameStrings(
      GameLocalizations localizations, Locale locale) async {
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    final gameTypes = [
      'standard',
      'diagonal',
      'window',
      'jigsaw',
      'killer',
      'samurai'
    ];

    for (final type in gameTypes) {
      final paths = [
        'assets/l10n/game_${type}_$languageCode.arb',
        if (countryCode != null)
          'assets/l10n/game_${type}_${languageCode}_$countryCode.arb',
      ];
      for (final path in paths) {
        try {
          final jsonString = await rootBundle.loadString(path);
          final _ = json.decode(jsonString) as Map<String, dynamic>
          ..forEach((key, value) {
            if (!key.startsWith('@') && !key.startsWith('@@')) {
              localizations._strings[key] = value.toString();
            }
          });
          break;
        } catch (e) {
          // 忽略，尝试下一个路径
        }
      }
    }

  }

  String? getString(String key) => _strings[key];

  String getGameName(String gameType) =>
      getString('gameType${gameType.capitalize()}Name') ?? gameType;

  String getGameDescription(String gameType) =>
      getString('gameType${gameType.capitalize()}Description') ?? '';

  String getGameRules(String gameType) =>
      getString('gameType${gameType.capitalize()}Rules') ?? '';

  // 便捷 Getters
  String get gameTypeStandardName => getGameName('standard');
  String get gameTypeStandardDescription => getGameDescription('standard');
  String get gameTypeStandardRules => getGameRules('standard');

  String get gameTypeDiagonalName => getGameName('diagonal');
  String get gameTypeDiagonalDescription => getGameDescription('diagonal');
  String get gameTypeDiagonalRules => getGameRules('diagonal');

  String get gameTypeWindowName => getGameName('window');
  String get gameTypeWindowDescription => getGameDescription('window');
  String get gameTypeWindowRules => getGameRules('window');

  String get gameTypeJigsawName => getGameName('jigsaw');
  String get gameTypeJigsawDescription => getGameDescription('jigsaw');
  String get gameTypeJigsawRules => getGameRules('jigsaw');

  String get gameTypeKillerName => getGameName('killer');
  String get gameTypeKillerDescription => getGameDescription('killer');
  String get gameTypeKillerRules => getGameRules('killer');

  String get gameTypeSamuraiName => getGameName('samurai');
  String get gameTypeSamuraiDescription => getGameDescription('samurai');
  String get gameTypeSamuraiRules => getGameRules('samurai');
}

class GameLocalizationsDelegate
    extends LocalizationsDelegate<GameLocalizations> {
  const GameLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<GameLocalizations> load(Locale locale) => GameLocalizations.load(locale);

  @override
  bool shouldReload(covariant GameLocalizationsDelegate old) => true;
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
